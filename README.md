<<<<<<< HEAD
# Studi Ablasi RNN, LSTM, GRU vs ANN untuk Prediksi Trafik Seluler Milan

Tugas Workshop Deep Learning — Teknik Telekomunikasi ITERA.

<!-- Ganti seluruh isian bertanda [ ... ] di bawah. Hapus komentar ini. -->

## Kelompok

| Peran | Nama | NIM |
|---|---|---|
| Ketua | [Nama Lengkap] | [NIM] |
| Anggota | [Nama Lengkap] | [NIM] |
| Anggota | [Nama Lengkap] | [NIM] |

- **Kelas:** [RA / RB]
- **Lokasi kelompok:** [kode] — [nama lokasi] (digit terakhir NIM terkecil)
- **Laporan:** [`laporan-latex/main.pdf` atau `laporan-typst/main.pdf`]

## Cara Menjalankan

```bash
uv sync
uv run jupyter lab
```

Buka `tugas_ablasi.ipynb`, isi `LOKASI_KELOMPOK`, lalu jalankan semua sel. Semua run tercatat di `hasil/ablasi.csv`.

Perangkat yang kami pakai: [contoh: laptop CPU Intel i5 / Google Colab T4], total waktu training: [x] menit.

## Ringkasan Hasil

[2–4 kalimat temuan utama, beserta angka test MAE terbaik per model.]

## Struktur

```
tugas_ablasi.ipynb      notebook eksperimen (di-commit beserta output)
data/                   data trafik per jam (Duomo + 10 lokasi tugas)
hasil/                  CSV seluruh run, tabel, dan grafik
laporan-latex/ atau laporan-typst/   sumber laporan + PDF
```

## Data

Telecom Italia Big Data Challenge (Barlacchi dkk., 2015, *Scientific Data*, lisensi ODbL), versi per jam dari Zhang dkk. (INFOCOM 2021). Disiapkan oleh pengajar di repo [mctosima/dl-workshop](https://github.com/mctosima/dl-workshop).
=======
# Workshop Deep Learning — Teknik Telekomunikasi ITERA

Workshop dasar *deep learning* dua sesi untuk mahasiswa Teknik Telekomunikasi,
berfokus pada *hands-on* dengan PyTorch.

| Sesi | Topik | Studi kasus |
|---|---|---|
| 1 | *Artificial Neural Network*: struktur, fungsi aktivasi, *feed forward*, *backpropagation* | Deteksi intrusi jaringan (NSL-KDD) |
| 2 | RNN, LSTM & GRU vs ANN (*time series*) | Prediksi trafik seluler kota Milan (Telecom Italia) |

Halaman workshop: <https://mctm.web.id/dl-workshop>

## Persiapan (peserta)

1. Instal [uv](https://docs.astral.sh/uv/):
   ```bash
   # macOS / Linux
   curl -LsSf https://astral.sh/uv/install.sh | sh
   # Windows (PowerShell)
   powershell -c "irm https://astral.sh/uv/install.ps1 | iex"
   ```
2. Clone repo ini lalu instal dependensi:
   ```bash
   git clone https://github.com/mctosima/dl-workshop.git
   cd dl-workshop
   uv sync
   ```
3. Jalankan materi Sesi 1:
   ```bash
   uv run jupyter lab                  # buka sesi-1-ann/konsep_ann.ipynb & eda_nslkdd.ipynb
   uv run python sesi-1-ann/train.py   # training ANN di NSL-KDD (±15 detik di CPU)
   ```
   `train.py` mengunduh NSL-KDD otomatis ke `sesi-1-ann/data/` dan menyimpan model,
   grafik loss, *confusion matrix*, serta `metrics.json` di `sesi-1-ann/outputs/`.
   Untuk bereksperimen, ubah angka di `sesi-1-ann/config.py` (epoch, *learning rate*,
   *batch size*, jumlah neuron) lalu jalankan ulang.
4. Jalankan materi Sesi 2 (buka di Jupyter Lab, berurutan):
   - `sesi-2-rnn/02_eksplorasi_data.ipynb` — mengenal data trafik
   - `sesi-2-rnn/03_rnn_lstm_gru_vs_ann.ipynb` — membandingkan baseline, ANN, RNN, LSTM, GRU (1 jam ke depan)
   - `sesi-2-rnn/04_prediksi_24_jam.ipynb` — perbandingan yang sama untuk 24 jam ke depan
   - `sesi-2-rnn/05_uji_ingatan.ipynb` — *adding problem*: kapan gerbang LSTM/GRU penting

   Tanpa GPU, set `CEPAT = True` di sel pengaturan agar selesai dalam beberapa menit.

## Tugas

Studi ablasi RNN, LSTM, GRU vs ANN (kelompok maks. 3 orang), tenggat **Rabu, 28 Oktober 2026, 23.59 WIB**.
Petunjuk lengkap di [`tugas/README.md`](tugas/README.md); folder [`tugas/starter/`](tugas/starter) disalin menjadi repo kelompok.

## Struktur repo

```
sesi-1-ann/                  # Sesi 1: ANN untuk deteksi intrusi jaringan
  konsep_ann.ipynb           # konsep ANN langkah demi langkah (data sintetis)
  eda_nslkdd.ipynb           # eksplorasi data (EDA) NSL-KDD sebelum training
  train.py                   # alur training utama — dibaca dari atas ke bawah
  config.py                  # semua pengaturan eksperimen
  data.py                    # unduh & baca NSL-KDD
  preprocessing.py           # label, one-hot, split, scaling, DataLoader
  model.py                   # arsitektur MLP 122-64-32-1
  training.py                # training loop + early stopping
  evaluation.py              # prediksi & metrik
  plots.py                   # grafik loss & confusion matrix
  data/, outputs/            # dibuat otomatis (tidak di-commit)
sesi-2-rnn/                  # Sesi 2: RNN, LSTM, GRU vs ANN untuk prediksi trafik
  01_siapkan_data.ipynb      # (pengajar) milano.h5 -> CSV kotak Duomo + 10 lokasi tugas
  02_eksplorasi_data.ipynb   # pola harian/mingguan, korelasi, autokorelasi, minggu Natal
  03_rnn_lstm_gru_vs_ann.ipynb  # windowing, baseline naif, 4 model x 2 jendela x 3 seed (1 jam ke depan)
  04_prediksi_24_jam.ipynb   # idem, ramalan 24 jam ke depan sekaligus + error per jarak ramalan
  05_uji_ingatan.ipynb       # adding problem T = 10..200: RNN vs LSTM vs GRU
  data/milano_duomo_5060.csv # trafik per jam kotak Duomo, 4 Nov - 29 Des 2013 (di-commit)
  data/milano_tugas_10_lokasi.csv  # 10 lokasi lain untuk Bagian D tugas (di-commit)
  hasil/                     # grafik EDA; h1/, h24/, ingatan/ = hasil notebook 03, 04, 05 (di-commit)
tugas/                       # tugas studi ablasi
  README.md                  # petunjuk lengkap, penilaian, luaran
  starter/                   # disalin peserta menjadi repo kelompok
    tugas_ablasi.ipynb       # notebook eksperimen (pencatatan run ke hasil/ablasi.csv)
    data/                    # salinan dua CSV di atas
    laporan-latex/, laporan-typst/  # template laporan IEEE dua kolom
eda-web/                     # website statis EDA NSL-KDD (buka index.html)
  index.html, style.css, app.js  # halaman & grafik SVG (tanpa pustaka, bisa offline)
  data.js                    # ringkasan data hasil build_data.py (di-commit)
  build_data.py              # hitung ulang data.js dari KDDTrain+/KDDTest+
paper/                       # paper EDA + MLP NSL-KDD (Typst)
  main.typ, refs.bib         # naskah & daftar pustaka
  scripts/experiments.py     # 5 seed, ablasi log1p, analisis per kategori & ambang -> results.json
  scripts/make_figures.py    # gambar paper -> img/
slides/
  theme/itera.typ            # tema touying (university) + palet ITERA
  logos/                     # logo ITERA
  scripts/make_figures.py    # gambar matplotlib untuk slide
  scripts/check_toy_example.py  # verifikasi angka contoh hitung manual
  sesi-1/main.typ, main.pdf  # slide Sesi 1 (Typst)
  sesi-2/main.typ, main.pdf  # slide Sesi 2 (Typst); img/ disalin dari sesi-2-rnn/hasil/
```

## Website EDA NSL-KDD

Halaman interaktif yang merangkum `eda_nslkdd.ipynb`: komposisi data, kualitas, label,
fitur kategorikal dan numerik, korelasi, serta perbandingan data latih vs uji.
Situs ini statis dan tidak butuh server. Cukup buka `eda-web/index.html` di *browser*
(fontnya dimuat dari Google Fonts bila online; jika offline dipakai font sistem).

```bash
open eda-web/index.html                    # macOS (Windows: start, Linux: xdg-open)
python3 -m http.server -d eda-web 8000     # alternatif: http://localhost:8000
uv run python eda-web/build_data.py        # hitung ulang data.js (mengunduh NSL-KDD bila perlu)
```

## Build slide (pengajar)

Butuh [Typst](https://typst.app) ≥ 0.14 (paket `touying` dan `cetz` diunduh otomatis).

```bash
uv run python slides/scripts/make_figures.py      # regenerasi gambar
uv run python slides/scripts/check_toy_example.py # cek angka contoh
cd slides && typst compile --root . sesi-1/main.typ sesi-1/main.pdf
typst compile --root . sesi-2/main.typ sesi-2/main.pdf   # dari folder slides/
```

## Build paper

```bash
uv run python paper/scripts/experiments.py    # ±1,5 menit di CPU
uv run python paper/scripts/make_figures.py
typst compile --root paper paper/main.typ paper/main.pdf
```

## Data Sesi 2

Trafik seluler kota Milan dari *Telecom Italia Big Data Challenge* (Barlacchi dkk., 2015,
*Scientific Data* 2:150055, lisensi ODbL), dalam versi agregat per jam `milano.h5` dari
Zhang dkk. (2021), *Dual Attention-Based Federated Learning for Wireless Traffic Prediction*,
IEEE INFOCOM ([repo FedDA](https://github.com/chuanting/FedDA)). Peserta cukup memakai
`sesi-2-rnn/data/milano_duomo_5060.csv`. Untuk membuat ulang CSV, unduh `milano.h5` (308 MB)
ke `sesi-2-rnn/data/` lalu jalankan `01_siapkan_data.ipynb` (bagian 5 juga membuat data 10 lokasi tugas;
salin ulang ke `tugas/starter/data/` bila berubah).
>>>>>>> 8f1b0ee6982687b90bb5940f8ed4b7addd020c75
