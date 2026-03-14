const { supabase } = require('../lib/supabase');

module.exports = async (req, res) => {
  if (req.method !== 'GET') return res.status(405).json({ error: 'Method not allowed' });

  try {
    const [meters, pjuAktif, pjuMati, pengaduan, permohonan, ilegal] = await Promise.all([
      supabase.from('kwh_meters').select('*', { count: 'exact', head: false }),
      supabase.from('pju_points').select('*', { count: 'exact', head: true }).eq('status', 'aktif'),
      supabase.from('pju_points').select('*', { count: 'exact', head: true }).eq('status', 'mati'),
      supabase.from('pengaduan').select('*', { count: 'exact', head: true }).eq('status', 'baru'),
      supabase.from('permohonan').select('*', { count: 'exact', head: true }).eq('status', 'baru'),
      supabase.from('kwh_meters').select('*', { count: 'exact', head: true }).in('status', ['anomali', 'pencurian']),
    ]);

    const meterData = meters.data || [];
    const totalTagihan = meterData.reduce((a, m) => a + (m.tagihan_bln || 0), 0);
    const totalKwh = meterData.reduce((a, m) => a + (m.kwh_per_day || 0), 0);
    const totalDaya = meterData.reduce((a, m) => a + (m.total_daya || 0), 0);

    return res.json({
      totalMeters: meters.count || 0,
      totalPJU: (pjuAktif.count || 0) + (pjuMati.count || 0),
      pjuAktif: pjuAktif.count || 0,
      pjuMati: pjuMati.count || 0,
      pengaduanBaru: pengaduan.count || 0,
      permohonanBaru: permohonan.count || 0,
      ilegalCount: ilegal.count || 0,
      totalTagihan,
      totalKwh: Math.round(totalKwh),
      totalDaya,
    });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
};
