# SIPJU Indramayu v3.1

Sistem Informasi Penerangan Jalan Umum Kabupaten Indramayu

## Cara Deploy ke GitHub Pages

Upload 3 file berikut ke satu folder/repository:
- `index.html`   — Website utama
- `pju_data.js`  — Data 1.875 titik PJU (dari Excel PLN)
- `gardu_lines.js` — Data jalur kabel gardu ke PJU

Lalu aktifkan GitHub Pages:
Settings → Pages → Deploy from branch → main → Save

## Akses

- **Publik** (tidak perlu login): Peta, Lapor PJU, Minta Pasang, Forum
- **Admin** (login): Dashboard PLN/PUPR → username: admin / password: sipju2025

## Fitur
- Peta langsung muncul saat buka website (1.875 titik PJU nyata)
- Klik marker → foto + detail lengkap (daya, gardu, meter, merk, tahun)
- Jalur kabel dari gardu ke setiap PJU dalam satu jaringan
- Lapor PJU bermasalah dengan upload foto
- Ajukan pasang PJU baru
- Forum diskusi warga (tanpa login)
- Dashboard admin (PLN & Dinas PUPR): laporan aktif, konsumsi kWh, indikasi ilegal, zona gelap
