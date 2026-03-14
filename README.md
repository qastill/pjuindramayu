# SIPJU Indramayu
Sistem Informasi Penerangan Jalan Umum - Kabupaten Indramayu

## Tech Stack
- Frontend: HTML/CSS/JS + Leaflet.js + Chart.js
- Backend: Supabase (PostgreSQL + Storage)
- Deploy: Vercel
- Data: 454 KWH Meter, 1317 titik PJU

## Setup Supabase
1. Buka SQL Editor di Supabase Dashboard
2. Paste isi file `supabase_schema.sql`
3. Run

## Deploy Vercel
1. Import repo di vercel.com
2. Set env: SUPABASE_URL dan SUPABASE_ANON_KEY
3. Deploy

## Fitur
- Masyarakat: Pengaduan, Permohonan, Lapor Ilegal, Peta
- Admin: Dashboard, Tag PJU/Meter, Data, Prediksi Ilegal
