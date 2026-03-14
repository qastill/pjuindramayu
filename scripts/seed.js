/**
 * Seed script: Import meter_data.js into Supabase
 * Usage: SUPABASE_URL=xxx SUPABASE_ANON_KEY=xxx node scripts/seed.js
 */
const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');
const path = require('path');

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_KEY = process.env.SUPABASE_SERVICE_KEY || process.env.SUPABASE_ANON_KEY;

if (!SUPABASE_URL || !SUPABASE_KEY) {
  console.error('Set SUPABASE_URL and SUPABASE_ANON_KEY env vars');
  process.exit(1);
}

const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);

// Load meter data
const meterJs = fs.readFileSync(path.join(__dirname, '..', 'public', 'meter_data.js'), 'utf8');
const METER_DATA = eval(meterJs.replace('var METER_DATA = ', '(') + ')');

// Load dark zones
const dzJs = fs.readFileSync(path.join(__dirname, '..', 'public', 'dark_zones.js'), 'utf8');
const DARK_ZONES = eval(dzJs.replace('var DARK_ZONES = ', '(') + ')');

async function seed() {
  console.log(`Seeding ${METER_DATA.length} meters...`);

  // Insert meters in batches
  for (let i = 0; i < METER_DATA.length; i += 50) {
    const batch = METER_DATA.slice(i, i + 50).map(m => ({
      gardu: m.gardu,
      no_pln: m.pln || null,
      ulp: m.ulp,
      lokasi: m.lokasi,
      lat: m.lat,
      lng: m.lng,
      total_daya: m.totalDaya,
      jml_pju: m.jmlPJU,
      kwh_per_day: m.kwhPerDay,
      tagihan_bln: m.tagihanBln,
      anomali_pct: m.anomaliPct,
      status: m.tagihanBln === 0 ? 'pencurian' : m.status,
    }));

    const { error } = await supabase.from('kwh_meters').insert(batch);
    if (error) console.error(`Meter batch ${i}: ${error.message}`);
    else process.stdout.write('.');
  }
  console.log('\nMeters done.');

  // Get inserted meters for FK mapping
  const { data: allMeters } = await supabase.from('kwh_meters').select('id, gardu');
  const garduMap = {};
  (allMeters || []).forEach(m => { garduMap[m.gardu] = m.id; });

  // Insert PJU points
  let pjuCount = 0;
  for (let i = 0; i < METER_DATA.length; i++) {
    const m = METER_DATA[i];
    const meterId = garduMap[m.gardu];
    const pjuBatch = m.pjuList.map(p => ({
      idpel: p.id,
      meter_id: meterId || null,
      gardu: m.gardu,
      lat: p.lat,
      lng: p.lng,
      jenis_lampu: p.jenis || 'LED',
      daya: p.daya,
      tiang: p.tiang || null,
      status: p.status,
      is_legal: true,
    }));

    if (pjuBatch.length > 0) {
      const { error } = await supabase.from('pju_points').insert(pjuBatch);
      if (error) console.error(`PJU batch ${m.gardu}: ${error.message}`);
      else { pjuCount += pjuBatch.length; process.stdout.write('.'); }
    }
  }
  console.log(`\n${pjuCount} PJU points done.`);

  // Insert dark zones
  const dzBatch = DARK_ZONES.map(z => ({
    nama: z.nama,
    kecamatan: z.kec,
    lat: z.lat,
    lng: z.lng,
    radius: z.radius,
    prioritas: z.prioritas,
    warga_terdampak: z.warga,
    est_titik: z.est_titik,
    alasan: z.alasan,
  }));
  const { error: dzError } = await supabase.from('dark_zones').insert(dzBatch);
  if (dzError) console.error('Dark zones:', dzError.message);
  else console.log(`${dzBatch.length} dark zones done.`);

  console.log('\n✅ Seed complete!');
}

seed().catch(console.error);
