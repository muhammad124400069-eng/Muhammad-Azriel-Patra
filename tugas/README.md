# Tugas — Studi Ablasi RNN, LSTM, GRU vs ANN

**Workshop Deep Learning · Teknik Telekomunikasi ITERA · Kelas RA & RB**

| | |
|---|---|
| **Tenggat** | **Rabu, 28 Oktober 2026, 23.59 WIB**. Form pengumpulan otomatis ditutup. |
| **Kelompok** | 1–3 orang dari kelas yang sama |
| **Pengumpulan** | Form Tally: <https://tally.so/r/VLRYba>, cukup sekali per kelompok oleh ketua |
| **Luaran** | (1) repo GitHub **publik**, (2) laporan PDF format IEEE dua kolom, maks. 6 halaman, ditulis dengan **LaTeX atau Typst** |
| **Petunjuk daring** | <https://mctm.web.id/dl-workshop/tugas> |

## Latar Belakang

Di Sesi 2 kita membandingkan ANN, RNN, LSTM, dan GRU untuk meramal trafik internet satu jam ke depan di kotak Duomo, Milan, dengan **satu** konfigurasi hyperparameter. Hasilnya: RNN ≈ GRU < LSTM < ANN. Apakah kesimpulan itu tetap berlaku bila hyperparameter diubah?

Tugas ini adalah **studi ablasi**: ubah **satu faktor dalam satu waktu** dari konfigurasi acuan, amati dampaknya pada keempat model, lalu pilih konfigurasi terbaik secara jujur (dengan data validasi) dan uji di lokasi lain.

## Memulai

1. Salin folder [`starter/`](starter) menjadi repo kelompok. Nama repo yang disarankan: `dlw-tugas-<kelas>-<NIM ketua>`, misalnya `dlw-tugas-ra-122140057`.

   ```bash
   git clone https://github.com/mctosima/dl-workshop.git
   cp -r dl-workshop/tugas/starter dlw-tugas-ra-122140057      # Windows: Copy-Item -Recurse
   cd dlw-tugas-ra-122140057
   git init && git add . && git commit -m "Mulai tugas"
   ```

   Lalu buat repo **publik** kosong di GitHub, `git remote add origin …`, dan `git push -u origin main`. Tanpa git? Unduh `tugas-starter.zip` dari halaman petunjuk daring.
2. Isi README repo: nama & NIM seluruh anggota, kelas, dan lokasi kelompok.
3. `uv sync`, lalu `uv run jupyter lab`, buka `tugas_ablasi.ipynb`, isi `LOKASI_KELOMPOK`, dan jalankan.

Isi `starter/`:

```
tugas_ablasi.ipynb   notebook eksperimen siap pakai (fungsi data, model, training, pencatatan, grafik)
data/                milano_duomo_5060.csv + milano_tugas_10_lokasi.csv
laporan-latex/       template IEEE (IEEEtran), bisa langsung diunggah ke Overleaf
laporan-typst/       template IEEE (charged-ieee), bisa langsung diunggah ke typst.app
README.md            template README repo
pyproject.toml       dependensi untuk uv
```

**Waktu komputasi.** Seluruh tugas ± 280 run (sebagian besar < 15 detik). Di laptop CPU total ± 1–2 jam; dengan GPU (misalnya Google Colab) jauh lebih cepat. Notebook mencatat setiap run ke `hasil/ablasi.csv` dan melewati run yang sudah ada, jadi aman dihentikan dan dilanjutkan. Coba kode dulu dengan `CEPAT = True`, tetapi **hasil akhir wajib dengan `CEPAT = False`** (3 seed).

## Lokasi Kelompok

Lokasi = **digit terakhir NIM terkecil** di antara anggota kelompok. Contoh: NIM 122140057, 122140112, 122140230 → NIM terkecil 122140057 → lokasi **7**.

| Kode | Lokasi | Kotak | Karakter |
|---|---|---|---|
| 0 | Stazione Centrale | 6165 | stasiun utama, sangat ramai |
| 1 | Navigli (Darsena) | 4555 | kawasan kanal & hiburan malam |
| 2 | Università Bocconi | 4460 | kampus |
| 3 | Stadio San Siro | 5738 | stadion, trafik rendah dengan lonjakan saat ada acara |
| 4 | Politecnico di Milano | 5772 | kampus |
| 5 | Bandara Linate | 4489 | sekitar bandara, trafik rendah |
| 6 | Parco Sempione | 5455 | taman kota |
| 7 | Università Bicocca | 7467 | kampus di pinggir kota |
| 8 | CityLife | 5749 | kawasan perkantoran & hunian baru |
| 9 | Corso Como | 5859 | kawasan malam dekat Porta Garibaldi |

## Konfigurasi Acuan

Semua ablasi berangkat dari konfigurasi notebook 03 Sesi 2 (W = 24):

| Hyperparameter | Acuan |
|---|---|
| Panjang jendela `W` | 24 jam |
| Horizon | 1 jam |
| Ukuran hidden | ANN 32, RNN 68, LSTM 33, GRU 38 |
| Jumlah lapisan | ANN 2, rekuren 1 |
| Fitur | net, call, sms, jam (sin, cos), hari (sin, cos) |
| Optimizer, learning rate | Adam, 0,001 |
| Batch size | 64 |
| Dropout, gradient clipping | 0, tidak ada |
| Loss | MSE |
| Early stopping | patience 30, maks. 300 epoch |
| Seed | 0, 1, 2 |

## Yang Harus Dikerjakan

### Bagian 0 — Acuan & baseline naif (wajib)

Jalankan konfigurasi acuan (4 model × 3 seed) dan hitung tiga baseline naif (nilai terakhir, kemarin, minggu lalu) di kotak Duomo.

### Bagian A — Ablasi wajib (5 faktor, keempat model)

| Kode | Faktor | Nilai yang diuji | Yang diamati |
|---|---|---|---|
| A1 | Panjang jendela `W` | 6, 12, 24, 48, 168 jam | Apakah lebih panjang selalu lebih baik? Jumlah parameter ANN vs rekuren. |
| A2 | Ukuran hidden | 16, 32, 64, 128 | Kapasitas vs *overfitting* pada 672 sampel train; MAE terhadap jumlah parameter. |
| A3 | Jumlah lapisan | 1, 2, 3 | Apakah menumpuk lapisan membantu? Lihat jumlah epoch sampai berhenti. |
| A4 | Learning rate | 0,0001, 0,001, 0,01 | Konvergensi (epoch mentok 300?) dan kestabilan antar seed. |
| A5 | Kelompok fitur | `net`, `net+call+sms`, `net+waktu`, `semua` | Fitur mana yang paling berguna, dan apakah berbeda antar model? |

### Bagian B — Ablasi pilihan (minimal 2 faktor)

Tuliskan **hipotesis sebelum menjalankan**, lalu periksa apakah terbukti.

| Kode | Faktor | Nilai |
|---|---|---|
| B1 | Batch size | 16, 64, 256 |
| B2 | Dropout | 0, 0,2, 0,5 |
| B3 | Optimizer | Adam, AdamW, SGD (momentum 0,9) |
| B4 | Fungsi loss | MSE, MAE, Huber |
| B5 | Early stopping patience | 10, 30, 60 |
| B6 | Horizon | 1, 6, 24 jam (bandingkan dengan baseline naif) |
| B7 | Gradient clipping (dengan lr 0,01) | tidak ada, 0,5, 1,0 |

### Bagian C — Konfigurasi terbaik per model (wajib)

Gabungkan nilai terbaik dari A dan B untuk **setiap model** berdasarkan **val MAE rata-rata**. Latih dengan 3 seed, lalu laporkan hasilnya di minggu test (16–22 Des) dan minggu Natal (23–29 Des), dibandingkan dengan acuan dan baseline naif. Bila gabungan justru lebih buruk dari acuan, laporkan juga. Itu temuan yang sah.

> ⚠️ **Jangan memilih konfigurasi berdasarkan test MAE.** Minggu test hanya dipakai sekali untuk pelaporan akhir.

### Bagian D — Uji generalisasi (wajib)

Latih ulang konfigurasi **acuan** dan **terbaik** (tanpa diubah) di lokasi kelompok. Apakah urutan model dan manfaat konfigurasi terbaik tetap sama seperti di Duomo? Kaitkan dengan pola trafik lokasi tersebut.

## Luaran 1 — Repo GitHub

- **Publik** sampai nilai diumumkan.
- `README.md` memuat **nama dan NIM seluruh anggota**, kelas, kode & nama lokasi, cara menjalankan, perangkat yang dipakai, dan ringkasan hasil (template sudah tersedia).
- `tugas_ablasi.ipynb` di-commit **beserta output-nya**.
- Folder `hasil/` lengkap: `ablasi.csv` (seluruh run), tabel, dan grafik.
- Sumber laporan (LaTeX atau Typst) beserta PDF-nya.
- Commit terakhir **sebelum tenggat** yang dinilai.

## Luaran 2 — Laporan PDF

- Format **IEEE conference dua kolom**, **maksimal 6 halaman** termasuk referensi, bahasa Indonesia.
- Ditulis dengan **LaTeX** ([`starter/laporan-latex/`](starter/laporan-latex)) atau **Typst** ([`starter/laporan-typst/`](starter/laporan-typst)). **Laporan dari Microsoft Word tidak diterima.**
- Struktur: Abstrak · Pendahuluan · Data dan Metode · Hasil (0, A, B, C, D) · Pembahasan · Kesimpulan · Kontribusi Anggota · Pernyataan Penggunaan AI · Pustaka.
- Semua hasil dilaporkan sebagai **rata-rata ± simpangan baku (3 seed)**. Setiap gambar dan tabel dirujuk dan dibahas di teks.
- Pembahasan menjelaskan **mengapa**, tidak hanya mengulang angka.

## Komponen Penilaian

| Komponen | Bobot |
|---|---|
| Repo & reprodusibilitas (README lengkap, notebook dengan output, `hasil/` lengkap) | 15 % |
| Bagian 0 & A: kelengkapan dan ketepatan eksperimen | 30 % |
| Bagian B: hipotesis, eksperimen, dan analisis | 15 % |
| Bagian C & D: pemilihan konfigurasi yang jujur dan uji generalisasi | 15 % |
| Laporan: format IEEE, kualitas tabel/gambar, kedalaman pembahasan | 25 % |

## Integritas

- Seluruh angka di laporan harus berasal dari run kelompok sendiri yang ada di `hasil/ablasi.csv`. Angka yang tidak dapat dilacak ke repo dianggap rekayasa.
- Alat AI boleh dipakai untuk membantu kode atau bahasa, asalkan dituliskan di bagian *Pernyataan Penggunaan AI*.
- Lokasi kelompok berbeda-beda, sehingga hasil Bagian D antar kelompok seharusnya berbeda.

## Data

Telecom Italia Big Data Challenge (Barlacchi dkk., 2015, *Scientific Data*, [doi:10.1038/sdata.2015.55](https://doi.org/10.1038/sdata.2015.55), lisensi ODbL), versi per jam dari Zhang dkk. (IEEE INFOCOM 2021). Data 10 lokasi disiapkan di [`sesi-2-rnn/01_siapkan_data.ipynb`](../sesi-2-rnn/01_siapkan_data.ipynb), bagian 5.
