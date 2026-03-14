-- ============================================================
-- SIPJU Indramayu - Supabase Database Schema
-- Run this in Supabase SQL Editor (Dashboard > SQL Editor > New Query)
-- ============================================================

-- 1. KWH Meters
CREATE TABLE IF NOT EXISTS kwh_meters (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  gardu TEXT NOT NULL,
  no_pln TEXT,
  ulp TEXT,
  lokasi TEXT,
  lat DOUBLE PRECISION,
  lng DOUBLE PRECISION,
  foto_url TEXT,
  total_daya INTEGER DEFAULT 0,
  jml_pju INTEGER DEFAULT 0,
  kwh_per_day DOUBLE PRECISION DEFAULT 0,
  tagihan_bln INTEGER DEFAULT 0,
  anomali_pct INTEGER DEFAULT 0,
  status TEXT DEFAULT 'normal' CHECK (status IN ('normal','anomali','pencurian')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. PJU Points
CREATE TABLE IF NOT EXISTS pju_points (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  idpel TEXT,
  meter_id UUID REFERENCES kwh_meters(id) ON DELETE SET NULL,
  gardu TEXT,
  lat DOUBLE PRECISION NOT NULL,
  lng DOUBLE PRECISION NOT NULL,
  foto_url TEXT,
  jenis_lampu TEXT DEFAULT 'LED',
  daya INTEGER DEFAULT 900,
  merk TEXT,
  tiang TEXT,
  status TEXT DEFAULT 'aktif' CHECK (status IN ('aktif','mati','rusak')),
  is_legal BOOLEAN DEFAULT TRUE,
  catatan TEXT,
  petugas TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Pengaduan (Public - Lampu Mati)
CREATE TABLE IF NOT EXISTS pengaduan (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  nomor_tiket TEXT UNIQUE,
  lokasi TEXT NOT NULL,
  kecamatan TEXT,
  lat DOUBLE PRECISION,
  lng DOUBLE PRECISION,
  foto_url TEXT,
  jenis_masalah TEXT NOT NULL,
  keterangan TEXT,
  nama_pelapor TEXT,
  no_hp TEXT,
  status TEXT DEFAULT 'baru' CHECK (status IN ('baru','proses','selesai')),
  catatan_admin TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Permohonan Pasang PJU (Public)
CREATE TABLE IF NOT EXISTS permohonan (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  nomor_permohonan TEXT UNIQUE,
  lokasi TEXT NOT NULL,
  kecamatan TEXT,
  alasan TEXT,
  est_titik INTEGER DEFAULT 1,
  nama_pemohon TEXT,
  no_hp TEXT,
  status TEXT DEFAULT 'baru' CHECK (status IN ('baru','review','disetujui','ditolak')),
  catatan_admin TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Laporan PJU Ilegal (Public)
CREATE TABLE IF NOT EXISTS laporan_ilegal (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  nomor_laporan TEXT UNIQUE,
  lokasi TEXT NOT NULL,
  foto_url TEXT,
  keterangan TEXT,
  nama_pelapor TEXT,
  status TEXT DEFAULT 'baru' CHECK (status IN ('baru','investigasi','terbukti','tidak_terbukti')),
  catatan_admin TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. Dark Zones
CREATE TABLE IF NOT EXISTS dark_zones (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  nama TEXT NOT NULL,
  kecamatan TEXT,
  lat DOUBLE PRECISION,
  lng DOUBLE PRECISION,
  radius INTEGER DEFAULT 500,
  prioritas TEXT DEFAULT 'sedang' CHECK (prioritas IN ('tinggi','sedang','rendah')),
  warga_terdampak INTEGER DEFAULT 0,
  est_titik INTEGER DEFAULT 0,
  alasan TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================

-- Enable RLS on all tables
ALTER TABLE kwh_meters ENABLE ROW LEVEL SECURITY;
ALTER TABLE pju_points ENABLE ROW LEVEL SECURITY;
ALTER TABLE pengaduan ENABLE ROW LEVEL SECURITY;
ALTER TABLE permohonan ENABLE ROW LEVEL SECURITY;
ALTER TABLE laporan_ilegal ENABLE ROW LEVEL SECURITY;
ALTER TABLE dark_zones ENABLE ROW LEVEL SECURITY;

-- Public can READ all data
CREATE POLICY "Public read kwh_meters" ON kwh_meters FOR SELECT USING (true);
CREATE POLICY "Public read pju_points" ON pju_points FOR SELECT USING (true);
CREATE POLICY "Public read pengaduan" ON pengaduan FOR SELECT USING (true);
CREATE POLICY "Public read permohonan" ON permohonan FOR SELECT USING (true);
CREATE POLICY "Public read laporan_ilegal" ON laporan_ilegal FOR SELECT USING (true);
CREATE POLICY "Public read dark_zones" ON dark_zones FOR SELECT USING (true);

-- Public can INSERT pengaduan, permohonan, laporan_ilegal
CREATE POLICY "Public insert pengaduan" ON pengaduan FOR INSERT WITH CHECK (true);
CREATE POLICY "Public insert permohonan" ON permohonan FOR INSERT WITH CHECK (true);
CREATE POLICY "Public insert laporan_ilegal" ON laporan_ilegal FOR INSERT WITH CHECK (true);

-- Authenticated (admin) can do everything
CREATE POLICY "Admin all kwh_meters" ON kwh_meters FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Admin all pju_points" ON pju_points FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Admin all pengaduan" ON pengaduan FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Admin all permohonan" ON permohonan FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Admin all laporan_ilegal" ON laporan_ilegal FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Admin all dark_zones" ON dark_zones FOR ALL USING (auth.role() = 'authenticated');

-- ============================================================
-- STORAGE BUCKET for photos
-- ============================================================
INSERT INTO storage.buckets (id, name, public) VALUES ('photos', 'photos', true)
ON CONFLICT (id) DO NOTHING;

-- Allow public uploads to photos bucket
CREATE POLICY "Public upload photos" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'photos');
CREATE POLICY "Public read photos" ON storage.objects FOR SELECT USING (bucket_id = 'photos');

-- ============================================================
-- INDEXES for performance
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_pju_meter ON pju_points(meter_id);
CREATE INDEX IF NOT EXISTS idx_pju_gardu ON pju_points(gardu);
CREATE INDEX IF NOT EXISTS idx_pju_status ON pju_points(status);
CREATE INDEX IF NOT EXISTS idx_meter_gardu ON kwh_meters(gardu);
CREATE INDEX IF NOT EXISTS idx_meter_status ON kwh_meters(status);
CREATE INDEX IF NOT EXISTS idx_pengaduan_status ON pengaduan(status);

-- ============================================================
-- AUTO-GENERATE TICKET NUMBERS
-- ============================================================
CREATE OR REPLACE FUNCTION gen_ticket_number()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_TABLE_NAME = 'pengaduan' THEN
    NEW.nomor_tiket := 'ADU-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || LPAD(FLOOR(RANDOM()*9999)::TEXT, 4, '0');
  ELSIF TG_TABLE_NAME = 'permohonan' THEN
    NEW.nomor_permohonan := 'PRM-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || LPAD(FLOOR(RANDOM()*9999)::TEXT, 4, '0');
  ELSIF TG_TABLE_NAME = 'laporan_ilegal' THEN
    NEW.nomor_laporan := 'ILG-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || LPAD(FLOOR(RANDOM()*9999)::TEXT, 4, '0');
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_pengaduan_ticket BEFORE INSERT ON pengaduan
FOR EACH ROW WHEN (NEW.nomor_tiket IS NULL) EXECUTE FUNCTION gen_ticket_number();

CREATE OR REPLACE TRIGGER trg_permohonan_ticket BEFORE INSERT ON permohonan
FOR EACH ROW WHEN (NEW.nomor_permohonan IS NULL) EXECUTE FUNCTION gen_ticket_number();

CREATE OR REPLACE TRIGGER trg_ilegal_ticket BEFORE INSERT ON laporan_ilegal
FOR EACH ROW WHEN (NEW.nomor_laporan IS NULL) EXECUTE FUNCTION gen_ticket_number();
