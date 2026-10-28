// main.typ — Workshop Deep Learning Sesi 2: RNN, LSTM & GRU
// Peserta: Mahasiswa Teknik Telekomunikasi ITERA (105 menit)
// Tema: touying `university` + palet ITERA (lihat ../theme/itera.typ)
//
// Compile dari folder slides/:
//   typst compile --root . sesi-2/main.typ sesi-2/main.pdf
// Gambar di sesi-2/img/ disalin dari ../sesi-2-rnn/hasil/ (hasil notebook 02–05, dijalankan di GPU RTX 5070).
// Angka di slide diambil dari hasil/h1, hasil/h24, hasil/ingatan (ringkasan.json & hasil_*.csv).
//
// Aturan judul: judul slide 3–5 kata, subjudul (#sub) singkat.

#import "../theme/itera.typ": *

#show: itera-theme.with(
  config-info(
    title: [RNN, LSTM & GRU],
    short-title: [Workshop DL · Sesi 2 — RNN, LSTM & GRU],
    subtitle: [Model Bermemori untuk Data Deret Waktu: Studi Kasus Prediksi Trafik Seluler],
    author: [Martin C.T. Manullang],
    institution: [Workshop Deep Learning untuk Mahasiswa Teknik Telekomunikasi — Institut Teknologi Sumatera],
    date: [Semester Ganjil 2026/2027],
    url: "mctm.web.id/dl-workshop",
    badge: "Workshop Deep Learning · Sesi 2",
  ),
)

// ---------------------------------------------------------------
// Diagram (CeTZ)
// ---------------------------------------------------------------

/// RNN yang "dibuka" sepanjang waktu: x_1..x_W -> h_1..h_W -> ŷ
#let rnn-unrolled() = cetz.canvas(length: 1.45cm, {
  import cetz.draw: *
  let labels = ([jam 1], [jam 2], [jam 3], [⋯], [jam $W$])
  let xs = (0, 2.6, 5.2, 7.3, 9.4)
  for (i, x) in xs.enumerate() {
    if i == 3 {
      content((x, 1.6), text(size: 1.2em, fill: bluegray)[⋯])
      continue
    }
    // input
    circle((x, 0), radius: 0.42, fill: teal, stroke: none)
    content((x, 0), text(fill: white, size: 0.7em)[$x_#if i == 4 [W] else [#(i + 1)]$])
    content((x, -0.8), text(size: 0.55em, fill: bluegray, labels.at(i)))
    line((x, 0.45), (x, 1.05), stroke: 1.2pt + bluegray, mark: (end: ">", fill: bluegray, scale: 0.5))
    // sel
    rect((x - 0.65, 1.1), (x + 0.65, 2.1), fill: navy, stroke: none, radius: 0.12)
    content((x, 1.6), text(fill: white, size: 0.7em)[$h_#if i == 4 [W] else [#(i + 1)]$])
  }
  // panah hidden state
  for (a, b) in ((0, 2.6), (2.6, 5.2), (5.2, 6.8), (7.8, 9.4)) {
    line((a + 0.65, 1.6), (b - 0.65, 1.6), stroke: 2pt + gold.darken(10%), mark: (end: ">", fill: gold.darken(10%), scale: 0.6))
  }
  content((1.3, 2.05), text(size: 0.55em, fill: gold.darken(25%), weight: "bold")[ingatan])
  // output
  line((9.4, 2.1), (9.4, 2.85), stroke: 1.2pt + bluegray, mark: (end: ">", fill: bluegray, scale: 0.5))
  circle((9.4, 3.3), radius: 0.42, fill: red, stroke: none)
  content((9.4, 3.3), text(fill: white, size: 0.75em)[$hat(y)$])
  content((8.8, 3.3), anchor: "east", text(size: 0.6em, fill: red, weight: "bold")[prediksi jam berikutnya])
  content((3.9, 2.85), text(size: 0.6em, fill: navy)[bobot *sama* dipakai di setiap jam])
})

/// Sel LSTM disederhanakan: jalur cell state + tiga gerbang.
#let lstm-cell() = cetz.canvas(length: 1.5cm, {
  import cetz.draw: *
  // jalur cell state
  line((-0.6, 3), (10.2, 3), stroke: 5pt + gold, mark: (end: ">", fill: gold, scale: 0.5))
  content((-0.6, 3.7), anchor: "west", text(size: 0.6em, fill: gold.darken(25%), weight: "bold")[_cell state_ $c$ — "jalan tol" ingatan jangka panjang])
  let gate(x, warna, simbol, nama, ket) = {
    circle((x, 3), radius: 0.38, fill: white, stroke: 2pt + warna)
    content((x, 3), text(size: 0.9em, fill: warna, weight: "bold", simbol))
    rect((x - 1.0, 0.6), (x + 1.0, 1.6), fill: warna, stroke: none, radius: 0.12)
    content((x, 1.1), text(fill: white, size: 0.62em, weight: "bold", nama))
    content((x, 0.15), text(size: 0.52em, fill: bluegray, ket))
    line((x, 1.6), (x, 2.6), stroke: 1.2pt + warna, mark: (end: ">", fill: warna, scale: 0.5))
  }
  gate(1.8, red, $times$, [_forget_], [apa yang dihapus?])
  gate(5.0, teal, $+$, [_input_], [apa yang ditulis?])
  // output gate: membaca cell state
  rect((7.4, 0.6), (9.4, 1.6), fill: navy, stroke: none, radius: 0.12)
  content((8.4, 1.1), text(fill: white, size: 0.62em, weight: "bold")[_output_])
  content((8.4, 0.15), text(size: 0.52em, fill: bluegray)[apa yang dibaca?])
  line((8.4, 2.95), (8.4, 1.65), stroke: 1.2pt + navy, mark: (end: ">", fill: navy, scale: 0.5))
  line((9.4, 1.1), (10.3, 1.1), stroke: 1.2pt + navy, mark: (end: ">", fill: navy, scale: 0.5))
  content((10.75, 1.1), text(size: 0.7em, fill: navy)[$h_t$])
  // input sel
  content((-0.6, 1.1), text(size: 0.65em, fill: teal.darken(10%))[$x_t, h_(t-1)$])
})

// ===============================================================
// PEMBUKA
// ===============================================================

#itera-title-slide()

== Capaian Pembelajaran Sesi Ini

#sub[Apa yang bisa kamu lakukan setelah 105 menit ini?]

#two-col(columns: (1.35fr, 1fr))[
  #blok(title: [Setelah sesi ini, peserta mampu:])[
    #set text(size: 0.82em)
    + Menjelaskan mengapa *data berurutan* butuh model *bermemori*.
    + Memahami *intuisi* sel RNN serta *gerbang* pada LSTM dan GRU.
    + Menyiapkan data deret waktu dengan *_windowing_* dan *baseline naif*.
    + *Membandingkan* ANN, RNN, LSTM, dan GRU secara adil untuk prediksi trafik seluler.
  ]
][
  #set text(size: 0.7em)
  #table(
    columns: (auto, 1fr),
    fill: tbl-fill,
    align: (center, left),
    th[Menit], th[Agenda],
    [0–10], [Motivasi: trafik seluler],
    [10–30], [RNN & masalah ingatan],
    [30–45], [LSTM & GRU],
    [45–60], [Data trafik Milan],
    [60–75], [Hasil perbandingan],
    [75–85], [Uji ingatan],
    [85–105], [#badge[Hands-on] Notebook],
  )
]

== Peta Materi Hari Ini

#sub[Dari ANN di Sesi 1 menuju model bermemori]

#columns(2, {
  set text(size: 0.95em)
  show outline.entry: it => block(below: 0.55em, {
    text(fill: gold.darken(10%))[■]
    h(0.5em)
    text(fill: navy, it.body())
  })
  outline(title: none, depth: 1)
})

#v(0.5em)
#flow([ANN (Sesi 1)], [RNN], [LSTM & GRU], [Trafik Milan], [Uji ingatan], fill: (gold.darken(15%), red, navy, teal, navy2), height: 2.4em, size: 0.75em)

// ===============================================================
= Motivasi
// ===============================================================

== Trafik Seluler Itu Berdenyut

#sub[Delapan minggu trafik internet di satu sel pusat kota Milan]

#align(center, image("img/deret_waktu.png", height: 50%))

#v(0.1em)
#grid(
  columns: (1fr, 1fr, 1fr),
  column-gutter: 0.7em,
  kartu(nomor: 1, color: teal, height: auto)[Kapasitas][Menambah kanal/_carrier_ sebelum jam sibuk.],
  kartu(nomor: 2, color: navy, height: auto)[Hemat energi][Mematikan sebagian sel (_sleep mode_) saat sepi.],
  kartu(nomor: 3, color: red, height: auto)[Deteksi anomali][Trafik jauh dari ramalan = ada yang tidak beres.],
)

== Data Berurutan Itu Berbeda

#sub[Urutan menyimpan informasi]

#two-col(columns: (1fr, 1fr))[
  #set text(size: 0.8em)
  *Sesi 1 (NSL-KDD):* setiap koneksi berdiri sendiri. Urutan baris tidak penting, boleh diacak.

  #v(0.3em)
  *Sesi 2 (trafik):* nilai jam ini *bergantung* pada jam-jam sebelumnya.

  - Pukul 07.00 trafik naik → pukul 08.00 hampir pasti lebih tinggi.
  - Senin mirip Senin minggu lalu.
  - Mengacak urutan = membuang informasi.
][
  #alert-blok(title: [Kalau tetap memakai ANN?])[
    #set text(size: 0.8em)
    + Jendela 24 jam × 7 fitur *diratakan* menjadi 168 angka: ANN tidak tahu mana yang "kemarin" dan mana yang "barusan".
    + Jendela diperpanjang → *parameter membengkak* (24 jam: 6.5 ribu, 168 jam: 38.8 ribu).
    + Panjang input harus *tetap*.
  ]
]

// ===============================================================
= Recurrent Neural Network
// ===============================================================

== Ide Dasar RNN

#sub[Membaca jam demi jam sambil membawa "catatan"]

#align(center, rnn-unrolled())

#v(0.3em)
#two-col[
  #set text(size: 0.78em)
  - Setiap jam, sel menerima *input jam ini* $x_t$ dan *catatan sebelumnya* $h_(t-1)$.
  - Hasilnya *catatan baru* $h_t$ (_hidden state_), diteruskan ke jam berikutnya.
][
  #set text(size: 0.78em)
  - Catatan terakhir $h_W$ merangkum seluruh jendela → dipakai untuk prediksi.
  - *Bobotnya sama* di setiap jam → parameter *tidak* bertambah walau jendela diperpanjang.
]

== Satu Langkah Sel RNN

#sub[Rumusnya mirip neuron di Sesi 1]

#two-col(columns: (1.1fr, 1fr))[
  #blok(title: [Perbarui catatan])[
    $ h_t = tanh(W_x x_t + W_h h_(t-1) + b) $
  ]
  #blok(title: [Prediksi di akhir jendela])[
    $ hat(y) = W_y h_W + c $
  ]
][
  #set text(size: 0.78em)
  - $W_x x_t$: informasi *baru* dari jam ini.
  - $W_h h_(t-1)$: informasi *lama* dari catatan.
  - $tanh$: menjaga catatan tetap di rentang $-1$ s.d. $1$.
  #v(0.3em)
  #contoh-blok(title: [Analogi])[
    #set text(size: 0.9em)
    Seperti membaca laporan trafik per jam sambil memperbarui *satu kertas ringkasan*. Kertasnya terbatas, jadi yang lama perlahan tertimpa.
  ]
]

== Masalah: Ingatan Memudar

#sub[Vanishing gradient sepanjang waktu]

#two-col(columns: (1fr, 1fr))[
  #set text(size: 0.8em)
  Saat _backpropagation_, gradien dari jam terakhir harus *mengalir mundur* melewati setiap jam. Di setiap langkah, gradien dikali faktor yang biasanya *< 1*.

  #v(0.3em)
  #table(
    columns: (1fr, 1fr),
    fill: tbl-fill,
    align: (center, center),
    th[Mundur sejauh], th[Sisa sinyal ($0.9^k$)],
    [1 jam], [0.9],
    [24 jam], [0.08],
    [100 jam], [0.00003],
    [168 jam], [0.00000002],
  )
][
  #alert-blok(title: [Akibatnya])[
    #set text(size: 0.82em)
    RNN biasa *sulit belajar* hubungan dengan kejadian yang *jauh di masa lalu*. Ia praktis hanya "ingat" beberapa puluh langkah terakhir.
  ]
  #contoh-blok(title: [Analogi: pesan berantai])[
    #set text(size: 0.82em)
    Bisikkan pesan melewati 100 orang. Di ujung, pesan aslinya hampir hilang.
  ]
]

// ===============================================================
= LSTM dan GRU
// ===============================================================

== LSTM: Jalan Tol Ingatan

#sub[Long Short-Term Memory (Hochreiter & Schmidhuber, 1997)]

#align(center, lstm-cell())

#v(0.2em)
#text(size: 0.78em)[Selain $h_t$, LSTM membawa *_cell state_* $c_t$. Informasi di jalur ini hanya *dikali gerbang* dan *ditambah*, bukan diremas berulang kali oleh $tanh$. Karena itu gradien bisa mengalir jauh ke belakang tanpa memudar.]

== Tiga Gerbang LSTM

#sub[Setiap gerbang adalah "keran" bernilai 0–1]

#two-col(columns: (1.3fr, 1fr))[
  #set text(size: 0.74em)
  #table(
    columns: (auto, 1fr, 1fr),
    fill: tbl-fill,
    th[Gerbang], th[Tugas], th[Contoh trafik],
    [*_Forget_*], [Menghapus ingatan yang tidak relevan lagi], [Hari berganti → lupakan pola kemarin sore],
    [*_Input_*], [Menulis informasi baru yang penting], [Lonjakan pagi ini → simpan],
    [*_Output_*], [Memilih bagian ingatan yang dipakai sekarang], [Ambil "pola jam sibuk" saat mendekati siang],
  )
][
  #emas-blok(title: [Intuisi kunci])[
    #set text(size: 0.82em)
    Gerbang bernilai *0* = tutup, *1* = buka penuh. Nilainya *dipelajari* dari data, sama seperti bobot di Sesi 1.

    #v(0.2em)
    Bila _forget gate_ ≈ 1, ingatan dibawa *utuh* dari langkah ke langkah.
  ]
]

== GRU: LSTM yang Ringkas

#sub[Gated Recurrent Unit (Cho dkk., 2014)]

#two-col(columns: (1fr, 1.1fr))[
  #set text(size: 0.8em)
  - Hanya *dua gerbang*:
    - *_Update_*: seberapa banyak catatan lama dipertahankan vs diganti.
    - *_Reset_*: seberapa banyak catatan lama dipakai saat membuat kandidat baru.
  - Tidak ada _cell state_ terpisah: $h_t$ sekaligus menjadi ingatan.
  - Lebih sedikit parameter, sering *sama baiknya* dengan LSTM.
][
  #set text(size: 0.74em)
  #table(
    columns: (auto, auto, auto, auto),
    fill: tbl-fill,
    align: (left, center, center, center),
    th[], th[RNN], th[LSTM], th[GRU],
    [Gerbang], [0], [3], [2],
    [Blok bobot], [1×], [4×], [3×],
    [Ingatan], [$h$], [$h$ + $c$], [$h$],
    [_Hidden_ kita], [68], [33], [38],
    [Parameter], [5.3 rb], [5.6 rb], [5.4 rb],
  )
  #text(size: 0.9em, fill: bluegray)[_Hidden_ dipilih agar parameter ketiganya *setara*.]
]

== Di PyTorch: Ganti Satu Baris

#sub[`nn.RNN`, `nn.LSTM`, dan `nn.GRU` punya antarmuka yang sama]

#two-col(columns: (1.45fr, 1fr))[
  #set text(size: 0.72em)
  ```python
  class Rekuren(nn.Module):
      def __init__(self, jenis, n_fitur, hidden):
          super().__init__()
          sel = {"RNN": nn.RNN, "LSTM": nn.LSTM,
                 "GRU": nn.GRU}[jenis]
          self.rnn = sel(n_fitur, hidden,
                         batch_first=True)
          self.head = nn.Linear(hidden, 1)

      def forward(self, x):       # [batch, W, 7]
          out, _ = self.rnn(x)    # [batch, W, hidden]
          return self.head(out[:, -1])  # jam terakhir
  ```
][
  #set text(size: 0.78em)
  - Input berbentuk *[batch, waktu, fitur]*.
  - `out[:, -1]`: _hidden state_ pada jam terakhir.
  - `head`: lapisan linear biasa (seperti Sesi 1) → 1 angka.
  #v(0.3em)
  #emas-blok(title: [Loss & training])[
    #set text(size: 0.9em)
    Regresi → loss *MSE*. Optimizer Adam, _mini-batch_, _early stopping_: sama seperti Sesi 1.
  ]
]

// ===============================================================
= Studi Kasus: Trafik Milan
// ===============================================================

== Dataset Telecom Italia

#sub[Big Data Challenge 2014 (Barlacchi dkk., 2015)]

#two-col(columns: (1fr, 1fr))[
  #set text(size: 0.76em)
  - Kota Milan dibagi *grid 100 × 100* kotak, masing-masing ± *235 m × 235 m*.
  - Aktivitas *internet*, *telepon*, dan *SMS* per kotak, 1 Nov – 31 Des 2013.
  - Versi per jam (308 MB) dari Zhang dkk. (2021): *8 minggu penuh*, 4 Nov – 29 Des.
  - Kita pakai *satu kotak*: sekitar *Katedral Duomo* (pusat kota, kotak ke-95 tersibuk).
  #v(0.2em)
  #alert-blok(title: [Catatan satuan])[
    #set text(size: 0.9em)
    Nilai berupa *"aktivitas"* yang dinormalisasi operator, *bukan* Mbps. Cocok untuk pola, bukan untuk dibaca sebagai kecepatan.
  ]
][
  #align(center, image("img/peta_milano.png", height: 88%))
]

== Pola Harian dan Mingguan

#sub[Sepi menjelang subuh, puncak siang hingga sore]

#align(center, image("img/pola_harian.png", width: 100%))

#text(size: 0.78em)[Hari kerja dan akhir pekan berbeda sedikit. Area 10–90% menunjukkan variasi antar-hari: polanya *kuat tetapi tidak identik*.]

== Berapa Jauh Perlu Mengingat?

#sub[Autokorelasi: kemiripan dengan $k$ jam sebelumnya]

#align(center, image("img/autokorelasi.png", width: 100%))

#text(size: 0.78em)[Puncak di *24 jam* (0.91) dan *168 jam* (0.95): trafik sekarang sangat mirip trafik *kemarin* dan *minggu lalu* pada jam yang sama. Maka kita coba dua jendela: *W = 24* dan *W = 168* jam.]

== _Windowing_: Deret Jadi (X, y)

#sub[Jendela geser sepanjang deret waktu]

#two-col(columns: (1.1fr, 1fr))[
  #set text(size: 0.76em)
  ```
  jam:  0 1 2 … 23 | 24   ← target
        └─ X (W=24) ┘  y
  jam:    1 2 … 24 | 25
          └─ X ───┘    y   … dst.
  ```
  #blok(title: [7 fitur per jam])[
    #set text(size: 0.92em)
    `net`, `call`, `sms`, jam (sin, cos), hari (sin, cos)
  ]
][
  #set text(size: 0.76em)
  #blok(title: [Bentuk tensor])[
    X: *[672, W, 7]* #h(0.6em) y: *[672, 1]*
  ]
  #contoh-blok(title: [Kenapa sin & cos?])[
    #set text(size: 0.92em)
    Jam 23 dan jam 0 bertetangga, tetapi angka 23 dan 0 berjauhan. Sebagai titik pada lingkaran, keduanya berdekatan.
    $ "jam"_(sin) = sin(2 pi dot "jam" / 24) $
  ]
]

== Pembagian Waktu yang Jujur

#sub[Latih dengan masa lalu, uji pada masa depan — jangan diacak]

#table(
  columns: (auto, auto, 1fr),
  fill: tbl-fill,
  align: (left, left, left),
  th[Bagian], th[Tanggal (2013)], th[Peran],
  [Konteks], [4 – 10 Nov], [Hanya sebagai input jendela 168 jam],
  [*Train*], [11 Nov – 8 Des], [Melatih bobot (4 minggu, 672 sampel)],
  [*Validasi*], [9 – 15 Des], [_Early stopping_],
  [*Test*], [16 – 22 Des], [Minggu normal — angka utama],
  [*Natal*], [23 – 29 Des], [Uji tambahan: pola berubah drastis],
)

#v(0.3em)
#emas-blok(title: [Perbandingan yang adil])[
  #set text(size: 0.78em)
  Semua model memakai *data, fitur, split, dan normalisasi yang sama*. Model rekuren diberi *parameter setara* (± 5.5 ribu). Setiap konfigurasi dilatih dengan *3 _seed_* lalu dirata-rata.
]

== Baseline Naif Dulu

#sub[Apakah tebakan sederhana sudah cukup?]

#two-col(columns: (1fr, 1fr))[
  #set text(size: 0.74em)
  #table(
    columns: (1.4fr, 1fr, auto),
    fill: tbl-fill,
    align: (left, center, center),
    th[Tebakan], th[MAE], th[MAPE],
    [Nilai jam sebelumnya], [601], [18.4%],
    [Jam yang sama kemarin], [552], [23.8%],
    [Jam yang sama minggu lalu], [*468*], [19.9%],
  )
  #text(size: 0.9em, fill: bluegray)[Minggu test, prediksi 1 jam ke depan.]
][
  #set text(size: 0.78em)
  - *MAE*: rata-rata |error| (satuan aktivitas).
  - *MAPE*: rata-rata error dalam *persen*.
  #v(0.3em)
  #alert-blok(title: [Aturan emas])[
    #set text(size: 0.9em)
    Model _deep learning_ yang *tidak* mengalahkan baseline naif *tidak berguna*, sebagus apa pun arsitekturnya.
  ]
]

// ===============================================================
= Hasil Perbandingan
// ===============================================================

== Prediksi 1 Jam ke Depan

#sub[MAE minggu test, rata-rata 3 _seed_ (GPU RTX 5070)]

#align(center, image("img/h1_perbandingan_mae.png", width: 92%))

#text(size: 0.76em)[Semua model jauh mengalahkan baseline terbaik (468). MAPE turun dari ± 20% menjadi *8–11%*.]

== Apa Arti Angka Ini?

#sub[Bandingkan dengan jujur, termasuk variasi antar-_seed_]

#two-col(columns: (1fr, 1fr))[
  #set text(size: 0.72em)
  #table(
    columns: (auto, auto, auto, auto, auto),
    fill: tbl-fill,
    align: (left, center, center, center, center),
    th[W = 24], th[seed 0], th[seed 1], th[seed 2], th[MAPE],
    [ANN], [311], [315], [304], [11.3%],
    [RNN], [*225*], [235], [229], [8.5%],
    [LSTM], [250], [300], [271], [9.1%],
    [GRU], [243], [*226*], [242], [*8.0%*],
  )
][
  #set text(size: 0.76em)
  + *Model rekuren > ANN*: setiap _seed_ RNN/GRU lebih baik dari setiap _seed_ ANN (± 25%).
  + *RNN ≈ GRU*: selisihnya lebih kecil dari variasi antar-_seed_; menurut MAPE urutannya malah terbalik.
  + *LSTM* sedikit di bawah, dengan variasi besar.
  + *W = 168 tidak membantu*. ANN malah memburuk (38.8 ribu parameter, hanya 672 sampel → _overfitting_).
]

== Prediksi vs Data Asli

#sub[Minggu test 16–22 Des, W = 168, rata-rata 3 _seed_]

#align(center, image("img/h1_prediksi_test.png", height: 84%))

== Seberapa Jauh Model Melihat?

#sub[Pengaruh tiap jam input terhadap prediksi: $|partial hat(y) \/ partial x_t|$]

#align(center, image("img/h1_pengaruh_per_jam.png", width: 100%))

#text(size: 0.76em)[Pengaruh 24 jam lalu tinggal ± 1% dan 168 jam lalu ≈ 0. *Ketiga model hanya memakai ± 1 hari terakhir.* Untuk 1 jam ke depan, beberapa jam terakhir + fitur jam & hari sudah cukup, jadi gerbang LSTM/GRU tidak memberi keuntungan.]

== Ramalan 24 Jam ke Depan

#sub[Seluruh hari esok sekaligus (24 output)]

#two-col(columns: (1.5fr, 1fr))[
  #align(center, image("img/h24_error_per_jarak.png", width: 100%))
][
  #set text(size: 0.7em)
  #table(
    columns: (1.5fr, auto, auto),
    fill: tbl-fill,
    align: (left, center, center),
    th[W = 168], th[MAE], th[MAPE],
    [Naif: minggu lalu], [*466*], [19.1%],
    [RNN], [481], [*16.8%*],
    [GRU], [506], [18.0%],
    [LSTM], [514], [17.7%],
    [ANN], [510], [20.3%],
  )
  #v(0.2em)
  Model hanya unggul untuk *± 3 jam pertama*. Setelah itu, "jam yang sama minggu lalu" *lebih baik* menurut MAE.
]

== Pelajaran dari Hari Esok

#sub[Baseline sederhana bisa sangat sulit dikalahkan]

#two-col(columns: (1fr, 1fr))[
  #set text(size: 0.8em)
  - Pola mingguan Duomo *sangat kuat* (autokorelasi 0.95).
  - Data latih hanya *4 minggu*: model belum cukup contoh untuk mengalahkan "salin minggu lalu".
  - Menurut MAPE model unggul (lebih tepat saat trafik rendah di malam hari), tetapi *meleset di puncak siang*.
][
  #emas-blok(title: [Untuk praktisi])[
    #set text(size: 0.82em)
    - Selalu laporkan baseline naif.
    - Pilih metrik sesuai kebutuhan: MAE untuk kapasitas puncak, MAPE untuk kesalahan relatif.
    - Ide perbaikan: latih model memprediksi *selisih* terhadap minggu lalu (lihat Latihan).
  ]
]

== Minggu Natal: Pola Berubah

#sub[Model dilatih dengan minggu normal, lalu diuji saat libur]

#two-col(columns: (1.55fr, 1fr))[
  #align(center, image("img/minggu_natal.png", width: 100%))
][
  #set text(size: 0.7em)
  #table(
    columns: (1.5fr, auto),
    fill: tbl-fill,
    align: (left, center),
    th[1 jam ke depan], th[MAE],
    [Naif: minggu lalu], [1426],
    [Naif: jam sebelumnya], [431],
    [RNN (W = 24)], [*421*],
    [GRU (W = 24)], [468],
    [ANN (W = 24)], [680],
  )
  #v(0.2em)
  "Salin minggu lalu" *runtuh*. Model yang membaca jam-jam terakhir masih bisa *menyesuaikan diri*.
]

// ===============================================================
= Uji Ingatan
// ===============================================================

#fokus[
  Di data trafik, RNN biasa sama baiknya dengan GRU. \
  #v(0.4em)
  #text(fill: gold, size: 0.9em)[Lalu kapan gerbang LSTM & GRU \ benar-benar penting?]
]

== _Adding Problem_

#sub[Tugas yang memaksa model mengingat jauh ke belakang]

#align(center, image("img/contoh_urutan.png", width: 100%))

#two-col[
  #set text(size: 0.76em)
  - Setiap langkah: *nilai* acak 0–1 dan *penanda* 0/1.
  - Penanda pertama di *10% awal*, kedua di *paruh akhir*.
  - Target: *jumlah dua nilai bertanda*.
][
  #set text(size: 0.76em)
  - Nilai pertama harus *diingat* sampai akhir urutan.
  - Tebak 1.0 terus → MSE 0.167 (*tidak mengingat apa pun*).
  - Parameter ketiga model setara (± 17 ribu).
]

== Hasil Uji Ingatan

#sub[Persentase jawaban yang meleset < 0.1]

#two-col(columns: (1.5fr, 1fr))[
  #align(center, image("img/error_vs_panjang.png", width: 100%))
][
  #set text(size: 0.7em)
  #table(
    columns: (auto, auto, auto, auto),
    fill: tbl-fill,
    align: (center, center, center, center),
    th[T], th[RNN], th[LSTM], th[GRU],
    [10], [100%], [100%], [100%],
    [50], [44%], [76%], [*100%*],
    [100], [18%], [86%], [*99.5%*],
    [200], [19%], [22%], [*99.7%*],
  )
  #v(0.2em)
  RNN *gagal total* mulai T = 100. GRU tetap tepat hingga T = 200. LSTM belajar lebih lambat: dengan 4000 langkah ia belum berhasil di T = 200.
]

== Ke Mana Model Melihat?

#sub[Pengaruh tiap langkah input terhadap jawaban, T = 100]

#two-col(columns: (1.6fr, 1fr))[
  #align(center, image("img/pengaruh_ingatan.png", width: 100%))
][
  #set text(size: 0.76em)
  - *RNN* hanya melihat ± 30 langkah terakhir. Nilai bertanda pertama (langkah 8) *tidak terlihat sama sekali*.
  - *LSTM & GRU* menunjukkan lonjakan tajam *tepat di kedua langkah bertanda*.
  #v(0.3em)
  #emas-blok(title: [Inilah fungsi gerbang])[
    #set text(size: 0.9em)
    Menyimpan informasi penting, mengabaikan sisanya, lalu membawanya jauh tanpa memudar.
  ]
]

// ===============================================================
= Penutup
// ===============================================================

== Ringkasan Sesi 2

#sub[Empat pelajaran dari eksperimen hari ini]

#grid(
  columns: (1fr, 1fr),
  rows: (5.6em, 5.6em),
  column-gutter: 0.7em,
  row-gutter: 0.7em,
  kartu(nomor: 1, color: red)[Urutan itu penting][Untuk 1 jam ke depan, RNN/LSTM/GRU mengalahkan ANN ± 25% dengan parameter lebih sedikit.],
  kartu(nomor: 2, color: navy)[Rumit ≠ lebih baik][Bila tugas hanya butuh ingatan pendek, RNN biasa sama baiknya dengan GRU.],
  kartu(nomor: 3, color: teal)[Gerbang untuk ingatan panjang][Saat informasi penting ada jauh di belakang, GRU/LSTM berhasil dan RNN gagal.],
  kartu(nomor: 4, color: gold.darken(15%))[Selalu pakai baseline][Untuk 24 jam ke depan, "jam yang sama minggu lalu" masih menang menurut MAE.],
)

== Persiapan Hands-on

#sub[Repo yang sama dengan Sesi 1]

#two-col(columns: (1fr, 1fr))[
  #set text(size: 0.74em)
  ```bash
  cd dl-workshop
  git pull          # ambil materi Sesi 2
  uv sync
  uv run jupyter lab
  ```
  #v(0.2em)
  #alert-blok(title: [Tanpa GPU?])[
    #set text(size: 0.9em)
    Set `CEPAT = True` di sel pengaturan: 1 _seed_ dan epoch lebih sedikit, selesai dalam beberapa menit di laptop.
  ]
][
  #set text(size: 0.72em)
  #table(
    columns: (auto, 1fr),
    fill: tbl-fill,
    th[Notebook], th[Isi],
    [`02`], [Eksplorasi data trafik Milan],
    [`03`], [Baseline, ANN, RNN, LSTM, GRU — 1 jam ke depan],
    [`04`], [Perbandingan yang sama — 24 jam ke depan],
    [`05`], [Uji ingatan (_adding problem_)],
  )
  #v(0.2em)
  #text(fill: bluegray)[`01` hanya untuk pengajar (membuat CSV dari `milano.h5`).]
]

== Latihan

#sub[Ubah satu hal, jalankan ulang, amati]

#grid(
  columns: (1fr, 1fr, 1fr),
  rows: (5.4em, 5.4em),
  column-gutter: 0.7em,
  row-gutter: 0.7em,
  kartu(nomor: 1, color: teal)[Jendela][`WINDOWS = [6, 48]` di notebook 03. Model mana yang paling terpengaruh?],
  kartu(nomor: 2, color: navy2)[Fitur][Hapus `call` & `sms` dari `FITUR`. Apakah error naik?],
  kartu(nomor: 3, color: navy)[Ukuran][Gandakan `HIDDEN`. Lebih akurat, atau _overfitting_?],
  kartu(nomor: 4, color: red)[Dua lapis][Tambahkan `num_layers=2` pada sel rekuren.],
  kartu(nomor: 5, color: gold.darken(15%))[Selisih][Notebook 04: prediksi selisih terhadap "minggu lalu".],
  kartu(nomor: 6, color: bluegray)[Lebih panjang][Notebook 05: `PANJANG` hingga 400. Masih mampu?],
)

== Referensi

#[
  #set text(size: 0.68em)
  #set par(hanging-indent: 1.5em, spacing: 0.85em)

Barlacchi, G., De Nadai, M., Larcher, R., dkk. (2015). A multi-source dataset of urban life in the city of Milan and the Province of Trentino. _Scientific Data_, 2, 150055.

Cho, K., van Merriënboer, B., Gulcehre, C., dkk. (2014). Learning phrase representations using RNN encoder–decoder for statistical machine translation. _EMNLP_.

Hochreiter, S., & Schmidhuber, J. (1997). Long short-term memory. _Neural Computation_, 9(8), 1735–1780.

Bengio, Y., Simard, P., & Frasconi, P. (1994). Learning long-term dependencies with gradient descent is difficult. _IEEE Transactions on Neural Networks_, 5(2), 157–166.

Hyndman, R. J., & Athanasopoulos, G. (2021). _Forecasting: Principles and Practice_ (3rd ed.). OTexts. #link("https://otexts.com/fpp3/")[otexts.com/fpp3]

Olah, C. (2015). Understanding LSTM networks. #link("https://colah.github.io/posts/2015-08-Understanding-LSTMs/")[colah.github.io]

Zhang, C., Dang, S., Shihada, B., & Alouini, M.-S. (2021). Dual attention-based federated learning for wireless traffic prediction. _IEEE INFOCOM_.

PyTorch Documentation: #link("https://pytorch.org/docs/stable/nn.html#recurrent-layers")[Recurrent Layers]
]

#fokus[
  #align(center)[
    Terima Kasih
    #v(0.3em)
    #text(size: 0.55em, fill: gold, font: font-body)[Saatnya _hands-on_ — buka notebook Sesi 2!]
    #v(0.2em)
    #text(size: 0.45em, fill: white.darken(20%), font: font-body, weight: "regular")[mctm.web.id/dl-workshop]
  ]
]
