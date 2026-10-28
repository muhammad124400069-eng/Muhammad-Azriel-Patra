// main.typ — Workshop Deep Learning Sesi 1: Artificial Neural Network
// Peserta: Mahasiswa Teknik Telekomunikasi ITERA (~120 menit)
// Tema: touying `university` + palet ITERA (lihat ../theme/itera.typ)
//
// Compile dari folder slides/:
//   typst compile --root . sesi-1/main.typ sesi-1/main.pdf
// Gambar: uv run python slides/scripts/make_figures.py
// Angka contoh toy: uv run python slides/scripts/check_toy_example.py
//
// Aturan judul: judul slide 3–5 kata, subjudul (#sub) singkat.

#import "../theme/itera.typ": *

#show: itera-theme.with(
  config-info(
    title: [Artificial Neural Network],
    short-title: [Workshop DL · Sesi 1 — ANN],
    subtitle: [Struktur, Fungsi Aktivasi, _Feed Forward_ & _Backpropagation_ untuk Kasus Telekomunikasi],
    author: [Martin C.T. Manullang],
    institution: [Workshop Deep Learning untuk Mahasiswa Teknik Telekomunikasi — Institut Teknologi Sumatera],
    date: [Semester Ganjil 2026/2027],
    url: "mctm.web.id/dl-workshop",
    badge: "Workshop Deep Learning · Sesi 1",
  ),
)

// ---------------------------------------------------------------
// Diagram (CeTZ)
// ---------------------------------------------------------------

/// Titik pada segmen a→b dengan parameter t.
#let lerp(a, b, t) = (a.at(0) + t * (b.at(0) - a.at(0)), a.at(1) + t * (b.at(1) - a.at(1)))

/// Label kecil berlatar putih di tengah garis.
#let edge-label(pos, body, color: navy) = {
  import cetz.draw: *
  content(pos, box(fill: white, inset: 1.5pt, radius: 2pt, text(size: 0.62em, fill: color, weight: "bold", body)))
}

/// Diagram satu neuron: x_i --w_i--> Σ --> f --> ŷ
#let neuron-diagram(inputs: ($x_1$, $x_2$, $x_3$), weights: ($w_1$, $w_2$, $w_3$), bias: $b$, act: $f$, out: $hat(y)$) = cetz.canvas(length: 1.3cm, {
  import cetz.draw: *
  let n = inputs.len()
  let sum = (4.2, 0)
  let actp = (6.4, 0)
  for (i, x) in inputs.enumerate() {
    let y = (n - 1) / 2 * 1.4 - i * 1.4
    line((0.45, y), (sum.at(0) - 0.6, sum.at(1)), stroke: 1.2pt + bluegray, mark: (end: ">", fill: bluegray, scale: 0.6))
    circle((0, y), radius: 0.45, fill: teal, stroke: none)
    content((0, y), text(fill: white, size: 0.8em, x))
    edge-label(lerp((0.45, y), sum, 0.45), weights.at(i), color: navy)
  }
  // bias
  line((sum.at(0), 1.9), (sum.at(0), 0.62), stroke: 1.2pt + gold.darken(10%), mark: (end: ">", fill: gold.darken(10%), scale: 0.6))
  content((sum.at(0), 2.2), text(size: 0.75em, fill: gold.darken(20%), weight: "bold")[bias #bias])
  circle(sum, radius: 0.6, fill: navy, stroke: none)
  content(sum, text(fill: white, size: 1em, $Sigma$))
  line((sum.at(0) + 0.6, 0), (actp.at(0) - 0.55, 0), stroke: 1.2pt + bluegray, mark: (end: ">", fill: bluegray, scale: 0.6))
  content((5.3, 0.35), text(size: 0.65em, fill: navy)[$z$])
  rect((actp.at(0) - 0.55, -0.55), (actp.at(0) + 0.55, 0.55), fill: red, stroke: none, radius: 0.1)
  content(actp, text(fill: white, size: 0.9em, act))
  line((actp.at(0) + 0.55, 0), (8.3, 0), stroke: 1.2pt + bluegray, mark: (end: ">", fill: bluegray, scale: 0.6))
  content((8.75, 0), text(size: 0.9em, fill: navy, out))
  content((sum.at(0), -1.05), text(size: 0.6em, fill: darkgray)[penjumlahan])
  content((actp.at(0), -1.0), text(size: 0.6em, fill: darkgray)[aktivasi])
})

/// Diagram MLP umum: daftar jumlah neuron per lapisan.
#let mlp-diagram(layers, names: none, dx: 2.4, dy: 0.85, r: 0.28, fills: none) = cetz.canvas(length: 1.25cm, {
  import cetz.draw: *
  let pos = ()
  for (i, n) in layers.enumerate() {
    let col = ()
    for j in range(n) { col.push((i * dx, (n - 1) / 2 * dy - j * dy)) }
    pos.push(col)
  }
  for i in range(layers.len() - 1) {
    for a in pos.at(i) { for b in pos.at(i + 1) { line(a, b, stroke: 0.5pt + bluegray.lighten(40%)) } }
  }
  let default-fills = layers.enumerate().map(((i, _)) => if i == 0 { teal } else if i == layers.len() - 1 { red } else { navy })
  let fl = if fills == none { default-fills } else { fills }
  for (i, col) in pos.enumerate() {
    for p in col { circle(p, radius: r, fill: fl.at(i), stroke: 1pt + white) }
  }
  if names != none {
    let ymin = calc.min(..pos.map(c => c.last().at(1)))
    for (i, nm) in names.enumerate() {
      content((i * dx, ymin - 0.75), text(size: 0.6em, fill: navy, weight: "bold", nm))
    }
  }
})

/// Jaringan contoh 2-2-1 dengan bobot numerik.
#let toy-network(show-values: true) = cetz.canvas(length: 1.3cm, {
  import cetz.draw: *
  let x = ((0, 1.1), (0, -1.1))
  let h = ((4, 1.1), (4, -1.1))
  let o = (8, 0)
  let W1 = (("0.5", "−0.3"), ("0.2", "0.8"))
  let w2 = ("1.0", "−0.5")
  let st = 1pt + bluegray
  for (j, hp) in h.enumerate() {
    for (i, xp) in x.enumerate() {
      line(xp, hp, stroke: st)
    }
    line(hp, o, stroke: st)
  }
  if show-values {
    for (j, hp) in h.enumerate() {
      for (i, xp) in x.enumerate() {
        let t = if i == j { 0.5 } else { 0.28 }
        edge-label(lerp(xp, hp, t), W1.at(j).at(i))
      }
      edge-label(lerp(hp, o, 0.45), w2.at(j), color: red)
    }
  }
  let xlab = ($x_1$, $x_2$)
  let xval = ("SNR = 0.8", "RSSI = 0.6")
  for (i, p) in x.enumerate() {
    circle(p, radius: 0.45, fill: teal, stroke: 1pt + white)
    content(p, text(fill: white, size: 0.8em, xlab.at(i)))
    content((p.at(0) - 1.35, p.at(1)), text(size: 0.6em, fill: teal, weight: "bold", xval.at(i)))
  }
  let hb = ("b = 0.1", "b = −0.2")
  for (j, p) in h.enumerate() {
    circle(p, radius: 0.5, fill: navy, stroke: 1pt + white)
    content(p, text(fill: white, size: 0.75em)[$h_#(j + 1)$])
    content((p.at(0), p.at(1) + if j == 0 { 0.8 } else { -0.8 }), text(size: 0.55em, fill: gold.darken(25%), weight: "bold", hb.at(j)))
  }
  circle(o, radius: 0.55, fill: red, stroke: 1pt + white)
  content(o, text(fill: white, size: 0.8em, $hat(y)$))
  content((o.at(0), -0.9), text(size: 0.55em, fill: gold.darken(25%), weight: "bold")[b = 0.2])
  content((4, -2.35), text(size: 0.6em, fill: navy)[_hidden_: ReLU])
  content((8, -1.45), text(size: 0.6em, fill: red)[_output_: sigmoid])
})

// ===============================================================
// PEMBUKA
// ===============================================================

#itera-title-slide()

== Capaian Pembelajaran Sesi Ini

#sub[Apa yang bisa kamu lakukan setelah 120 menit ini?]

#two-col(columns: (1.35fr, 1fr))[
  #blok(title: [Setelah sesi ini, peserta mampu:])[
    #set text(size: 0.82em)
    + Menjelaskan *struktur ANN*: neuron, bobot, bias, dan lapisan.
    + Membedakan *fungsi aktivasi* dan memilihnya sesuai kebutuhan.
    + Menghitung *_feed forward_* dan memahami intuisi *_backpropagation_*.
    + Membangun & melatih ANN dengan *PyTorch* untuk *deteksi intrusi jaringan*.
  ]
][
  #set text(size: 0.7em)
  #table(
    columns: (auto, 1fr),
    fill: tbl-fill,
    align: (center, left),
    th[Menit], th[Agenda],
    [0–10], [Motivasi: AI di telekomunikasi],
    [10–30], [Struktur ANN],
    [30–45], [Fungsi aktivasi],
    [45–60], [_Feed forward_ & _loss_],
    [60–80], [_Backpropagation_],
    [80–90], [Studi kasus NSL-KDD],
    [90–120], [#badge[Hands-on] Notebook PyTorch],
  )
]

== Peta Materi Hari Ini

#sub[Dari satu neuron sampai model deteksi intrusi]

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
#flow([Neuron], [Aktivasi], [_Feed Forward_], [_Backprop_], [Kasus IDS], fill: (teal, navy2, navy, red, gold.darken(15%)), height: 2.4em, size: 0.75em)

// ===============================================================
= Motivasi
// ===============================================================

== AI di Dunia Telekomunikasi

#sub[Jaringan modern menghasilkan data dalam jumlah masif]

#grid(
  columns: (1fr, 1fr, 1fr, 1fr),
  rows: (8.6em,),
  column-gutter: 0.7em,
  kartu(nomor: 1, color: red)[Deteksi Intrusi][Mengenali koneksi berbahaya (DoS, _port scan_) di trafik jaringan. *#text(fill: red)[Kasus hari ini.]*],
  kartu(nomor: 2, color: teal)[Prediksi QoS][Memperkirakan _throughput_, _latency_, atau kualitas link dari hasil _drive test_.],
  kartu(nomor: 3, color: navy)[Prediksi Trafik][Meramal beban sel/BTS per jam untuk alokasi sumber daya. *Sesi 2 (LSTM).*],
  kartu(nomor: 4, color: gold.darken(15%))[Lapisan Fisik][Klasifikasi modulasi, estimasi kanal, dan _beamforming_ di 5G/6G.],
)

#v(0.6em)
#alert-blok(title: [Masalahnya])[
  #set text(size: 0.82em)
  Pola di data ini *rumit & berdimensi tinggi* — sulit ditulis sebagai aturan `if-else` manual. Kita butuh model yang *belajar sendiri dari data*.
]

== Dari Aturan ke Belajar

#sub[Pemrograman tradisional vs _machine learning_]

#two-col[
  #text(weight: "bold", fill: navy, size: 0.85em)[Pemrograman tradisional]
  #v(0.2em)
  #flow([Data], [Aturan (ditulis manusia)], [Jawaban], fill: (teal, navy, red), height: 2.8em, size: 0.66em)
  #v(0.4em)
  ```python
  if snr > 20 and rssi > -80:
      kualitas = "baik"
  ```
  #text(size: 0.72em)[Mudah untuk 2 fitur. Bagaimana dengan *41 fitur* koneksi jaringan?]
][
  #text(weight: "bold", fill: navy, size: 0.85em)[_Machine learning_]
  #v(0.2em)
  #flow([Data + Jawaban], [Model belajar], [Aturan (bobot)], fill: (teal, gold.darken(15%), navy), height: 2.8em, size: 0.66em)
  #v(0.4em)
  #contoh-blok(title: [Ide kunci])[
    #set text(size: 0.78em)
    Kita memberi *contoh berlabel* (koneksi → normal/serangan). Model mencari sendiri aturan terbaik, yang tersimpan sebagai *bobot* (_weights_).
  ]
]

== AI, ML, dan Deep Learning

#sub[Posisi _neural network_ dalam peta kecerdasan buatan]

#two-col(columns: (1fr, 1fr))[
  #align(center, block(fill: navy.lighten(88%), radius: 8pt, inset: 0.6em, width: 95%, {
    text(weight: "bold", fill: navy, size: 0.8em)[_Artificial Intelligence_]
    block(fill: teal.lighten(75%), radius: 8pt, inset: 0.6em, width: 100%, {
      text(weight: "bold", fill: teal.darken(20%), size: 0.75em)[_Machine Learning_]
      block(fill: red.lighten(70%), radius: 8pt, inset: 0.6em, width: 100%, {
        text(weight: "bold", fill: red.darken(20%), size: 0.72em)[_Deep Learning_]
        block(fill: red, radius: 8pt, inset: 0.5em, width: 100%, text(fill: white, weight: "bold", size: 0.72em)[ANN berlapis banyak])
      })
    })
  }))
][
  #set text(size: 0.8em)
  - *AI*: sistem yang meniru kecerdasan manusia.
  - *ML*: AI yang *belajar dari data*, bukan diprogram eksplisit.
  - *_Deep Learning_*: ML memakai *_neural network_ dengan banyak lapisan*.
  #v(0.3em)
  #emas-blok(title: [Hari ini])[
    #set text(size: 0.9em)
    Kita bangun fondasinya: *ANN* (_Artificial Neural Network_) atau *MLP* (_Multi-Layer Perceptron_).
  ]
]

// ===============================================================
= Struktur ANN
// ===============================================================

== Neuron Biologis vs Buatan

#sub[Inspirasi dari otak, disederhanakan jadi matematika]

#two-col(columns: (1fr, 1.1fr))[
  #set text(size: 0.72em)
  #table(
    columns: (1fr, 1fr, 1.2fr),
    fill: tbl-fill,
    th[Biologis], th[Buatan], th[Peran],
    [Dendrit], [Input $x_i$], [Menerima sinyal],
    [Sinapsis], [Bobot $w_i$], [Kuat/lemahnya sinyal],
    [Soma], [Penjumlahan $Sigma$], [Mengumpulkan sinyal],
    [Ambang aktivasi], [Bias $b$ + fungsi $f$], [Memutuskan "menyala"],
    [Akson], [Output $hat(y)$], [Meneruskan hasil],
  )
][
  #align(center + horizon, neuron-diagram())
]

#v(0.3em)
#text(size: 0.72em, fill: bluegray)[Catatan: neuron buatan *hanya terinspirasi*, bukan simulasi otak yang sebenarnya.]

== Anatomi Neuron Buatan

#sub[Dua langkah: jumlahkan berbobot, lalu aktivasi]

#two-col(columns: (1fr, 1fr))[
  #blok(title: [Langkah 1 — Penjumlahan berbobot])[
    $ z = w_1 x_1 + w_2 x_2 + dots + w_n x_n + b $
    $ z = sum_(i=1)^n w_i x_i + b $
  ]
  #blok(title: [Langkah 2 — Fungsi aktivasi])[
    $ hat(y) = f(z) $
  ]
][
  #set text(size: 0.8em)
  - *Input* $x_i$: fitur data, mis. SNR, RSSI, jumlah paket.
  - *Bobot* $w_i$: seberapa *penting* fitur tersebut (bisa negatif).
  - *Bias* $b$: menggeser ambang keputusan.
  - *Aktivasi* $f$: mengubah $z$ jadi output (mis. peluang 0–1).
  #v(0.3em)
  #emas-blok(title: [Yang dipelajari])[
    #set text(size: 0.9em)
    Saat _training_, yang diubah-ubah hanyalah *$w$ dan $b$*. Itulah "pengetahuan" model.
  ]
]

== Normalisasi Input Dulu

#sub[Samakan skala fitur sebelum masuk neuron]

#two-col(columns: (1fr, 1fr))[
  #set text(size: 0.8em)
  Fitur telekomunikasi punya satuan & rentang berbeda:
  - SNR: $0$ s.d. $30$ dB
  - RSSI: $-100$ s.d. $-40$ dBm
  - `src_bytes`: $0$ s.d. jutaan _byte_
  #v(0.3em)
  Tanpa normalisasi, fitur berangka besar akan *mendominasi* dan _training_ jadi tidak stabil.
][
  #blok(title: [_Min-max scaling_ ke rentang 0–1])[
    $ x' = (x - x_min) / (x_max - x_min) $
  ]
  #contoh-blok(title: [Contoh])[
    #set text(size: 0.8em)
    SNR $= 24$ dB $arrow.r x_1 = (24 - 0) / (30 - 0) = #hasil[$0.8$]$ \
    RSSI $= -64$ dBm $arrow.r x_2 = (-64 + 100) / (-40 + 100) = #hasil[$0.6$]$
  ]
]

== Contoh: Kualitas Link Radio

#sub[Satu neuron memutuskan link _baik_ atau _buruk_]

#two-col(columns: (1.1fr, 1fr))[
  #set text(size: 0.8em)
  Input: $x = (0.8, 0.6)$ #h(0.4em) Bobot: $w = (2.0, 1.5)$ #h(0.4em) Bias: $b = -1.5$

  #blok(title: [Hitung])[
    $ z &= 2.0 dot 0.8 + 1.5 dot 0.6 - 1.5 = 1.6 + 0.9 - 1.5 = #hasil[$1.0$] \
      hat(y) &= sigma(1.0) = 1 / (1 + e^(-1.0)) = #hasil[$0.731$] $
  ]
  Karena $hat(y) > 0.5$ → prediksi *link baik* (peluang 73%).

  #text(size: 0.9em, fill: bluegray)[Garis navy di kanan adalah *batas keputusan*: $2.0 x_1 + 1.5 x_2 - 1.5 = 0$.]
][
  #align(center, image("img/link_quality.png", height: 82%))
]

== Perceptron dan Keterbatasannya

#sub[Neuron pertama (Rosenblatt, 1958) hanya bisa garis lurus]

#two-col(columns: (1fr, 1.25fr))[
  #set text(size: 0.8em)
  - *Perceptron* = satu neuron dengan aktivasi _step_ (output 0 atau 1).
  - Batas keputusannya selalu *garis lurus* (_linear_).
  - Cocok untuk AND, OR ✓
  - *Gagal* untuk XOR ✗ (Minsky & Papert, 1969)
  #v(0.3em)
  #alert-blok(title: [Solusinya])[
    #set text(size: 0.9em)
    *Tumpuk neuron* dalam beberapa lapisan + aktivasi *non-linear* → _Multi-Layer Perceptron_ (MLP).
  ]
][
  #align(center, image("img/xor.png", width: 100%))
]

== Lapisan dalam ANN

#sub[_Input layer_, _hidden layer_, dan _output layer_]

#two-col(columns: (1.25fr, 1fr))[
  #align(center, mlp-diagram((4, 5, 5, 2), names: ([_Input_], [_Hidden_ 1], [_Hidden_ 2], [_Output_])))
][
  #set text(size: 0.78em)
  - *_Input layer_*: satu neuron per fitur (tidak menghitung apa-apa).
  - *_Hidden layer_*: tempat pola diekstraksi; bisa lebih dari satu.
  - *_Output layer_*: jumlah neuron sesuai tugas (1 untuk biner, $K$ untuk $K$ kelas).
  - *_Fully connected_*: setiap neuron tersambung ke *semua* neuron lapisan berikutnya.
  #v(0.2em)
  #emas-blok(title: [Kenapa "_deep_"?])[
    #set text(size: 0.9em)
    Semakin banyak _hidden layer_, semakin "dalam" jaringannya.
  ]
]

== Menghitung Jumlah Parameter

#sub[Setiap sambungan = satu bobot, setiap neuron = satu bias]

#two-col(columns: (1fr, 1.1fr))[
  #blok(title: [Rumus per lapisan])[
    $ "parameter" = n_"in" times n_"out" + n_"out" $
  ]
  #set text(size: 0.8em)
  Contoh jaringan kecil 2-2-1:
  $ (2 times 2 + 2) + (2 times 1 + 1) = 6 + 3 = #hasil[$9$] $
][
  #set text(size: 0.72em)
  Model *hands-on* kita (122-64-32-1):
  #table(
    columns: (1fr, auto, auto),
    fill: tbl-fill,
    align: (left, center, right),
    th[Lapisan], th[Hitungan], th[Parameter],
    [_Input_ → _Hidden_ 1], [$122 times 64 + 64$], [7.872],
    [_Hidden_ 1 → _Hidden_ 2], [$64 times 32 + 32$], [2.080],
    [_Hidden_ 2 → _Output_], [$32 times 1 + 1$], [33],
    table.cell(colspan: 2)[*Total*], [*9.985*],
  )
  #text(fill: bluegray)[Hampir 10 ribu angka yang akan disetel otomatis oleh _training_.]
]

// ===============================================================
= Fungsi Aktivasi
// ===============================================================

== Kenapa Perlu Non-linearitas?

#sub[Tanpa aktivasi, sedalam apa pun jaringannya tetap linear]

#two-col(columns: (1fr, 1fr))[
  #blok(title: [Tanpa fungsi aktivasi])[
    #set text(size: 0.85em)
    $ hat(y) = W_2 (W_1 x) = underbrace((W_2 W_1), W') x $
    Dua lapisan linear = *satu* lapisan linear. Menumpuk layer jadi percuma.
  ]
][
  #contoh-blok(title: [Dengan fungsi aktivasi])[
    #set text(size: 0.85em)
    $ hat(y) = W_2 thin f(W_1 x) $
    $f$ non-linear "membengkokkan" ruang fitur, sehingga batas keputusan bisa *melengkung* (menyelesaikan XOR).
  ]
]

#v(0.4em)
#text(size: 0.78em)[Analogi: garis lurus hanya bisa membelah peta jadi dua. Dengan *banyak potongan garis yang ditekuk*, kita bisa menggambar batas wilayah serumit apa pun.]

== Fungsi Aktivasi Populer

#sub[Empat fungsi yang paling sering kamu temui]

#align(center, image("img/aktivasi.png", width: 100%))

#text(size: 0.85em, grid(
  columns: (1fr, 1fr, 1fr, 1fr),
  align: center,
  $"step"(z) = cases(1 & "jika" z >= 0, 0 & "jika" z < 0)$,
  $sigma(z) = 1 / (1 + e^(-z))$,
  $tanh(z) = (e^z - e^(-z)) / (e^z + e^(-z))$,
  $"ReLU"(z) = max(0, z)$,
))

== Membandingkan Fungsi Aktivasi

#sub[Kapan memakai yang mana?]

#text(size: 0.74em, table(
  columns: (auto, auto, 1.3fr, 1.3fr, 1fr),
  fill: tbl-fill,
  th[Fungsi], th[Rentang], th[Kelebihan], th[Kekurangan], th[Dipakai di],
  [Step], [$\{0, 1\}$], [Sederhana, historis], [Gradien nol → tidak bisa di-_train_], [Perceptron klasik],
  [Sigmoid], [$(0, 1)$], [Output = peluang], [_Vanishing gradient_, lambat], [_Output_ biner],
  [Tanh], [$(-1, 1)$], [Terpusat di nol], [Masih _vanishing gradient_], [RNN/LSTM (Sesi 2)],
  [*ReLU*], [$[0, infinity)$], [Cepat, gradien tidak hilang untuk $z > 0$], [Neuron bisa "mati" ($z < 0$)], [*_Hidden layer_ (default)*],
  [Softmax], [$(0, 1)$, total 1], [Distribusi peluang $K$ kelas], [Hanya untuk _output_], [_Output_ multi-kelas],
))

#v(0.3em)
#emas-blok(title: [Aturan praktis])[
  #set text(size: 0.8em)
  _Hidden layer_ → *ReLU*. #h(1em) _Output_ biner → *sigmoid*. #h(1em) _Output_ multi-kelas → *softmax*. #h(1em) Regresi → *linear* (tanpa aktivasi).
]

== Aktivasi di Lapisan Output

#sub[Bentuk output mengikuti jenis tugas]

#two-col(columns: (1fr, 1.1fr))[
  #set text(size: 0.78em)
  #table(
    columns: (1fr, 1.2fr),
    fill: tbl-fill,
    th[Tugas], th[Output layer],
    [Regresi \ (_throughput_ Mbps)], [1 neuron, linear],
    [Klasifikasi biner \ (normal/serangan)], [1 neuron, sigmoid],
    [Multi-kelas \ (Normal/DoS/Probe)], [$K$ neuron, softmax],
  )
][
  #contoh-blok(title: [Contoh softmax: 3 kelas])[
    #set text(size: 0.8em)
    $ "softmax"(z_k) = e^(z_k) / (sum_j e^(z_j)) $
    #table(
      columns: (1fr, auto, auto, auto),
      align: center,
      fill: tbl-fill,
      th[Kelas], th[Normal], th[DoS], th[Probe],
      [$z$ (_logit_)], [2.0], [1.0], [0.1],
      [$e^z$], [7.389], [2.718], [1.105],
      [Peluang], [*0.659*], [0.242], [0.099],
    )
    Prediksi: *Normal* (66%). Total peluang = 1.
  ]
]

== Masalah _Vanishing Gradient_

#sub[Mengapa ReLU menggantikan sigmoid di _hidden layer_]

#two-col(columns: (1fr, 1fr))[
  #set text(size: 0.8em)
  - Turunan sigmoid *maksimal 0.25*: $sigma'(z) = sigma(z)(1 - sigma(z))$.
  - _Backprop_ mengalikan turunan dari lapisan ke lapisan.
  - 10 lapisan sigmoid: $0.25^(10) approx 0.000001$ → gradien *menghilang*, lapisan awal berhenti belajar.
][
  #contoh-blok(title: [ReLU sebagai solusi])[
    #set text(size: 0.8em)
    $ "ReLU"'(z) = cases(1 & "jika" z > 0, 0 & "jika" z <= 0) $
    Untuk $z > 0$ gradien diteruskan *utuh* (dikali 1). Inilah salah satu alasan jaringan *dalam* bisa dilatih sejak sekitar tahun 2010.
  ]
]

// ===============================================================
= Feed Forward
// ===============================================================

== Alur _Feed Forward_

#sub[Data mengalir satu arah: input → hidden → output]

#flow([Input $x$], [$z^((1)) = W^((1)) x + b^((1))$], [$h = "ReLU"(z^((1)))$], [$z^((2)) = W^((2)) h + b^((2))$], [$hat(y) = sigma(z^((2)))$], fill: (teal, navy2, navy, navy2, red), height: 3.2em, size: 0.72em)

#v(0.6em)
#two-col[
  #blok(title: [Bentuk matriks])[
    #set text(size: 0.85em)
    Satu lapisan = *perkalian matriks + bias + aktivasi*:
    $ h = f(W x + b) $
    $W$ berukuran $n_"out" times n_"in"$.
  ]
][
  #set text(size: 0.8em)
  - Tiap lapisan mengubah representasi data.
  - GPU sangat cepat untuk perkalian matriks → itulah kenapa _deep learning_ butuh GPU.
  - Di PyTorch: satu baris `nn.Linear(n_in, n_out)`.
]

== Jaringan Contoh 2-2-1

#sub[Kita hitung manual: link radio dengan SNR & RSSI]

#two-col(columns: (1.35fr, 1fr))[
  #align(center + horizon, toy-network())
][
  #set text(size: 0.74em)
  #blok(title: [Parameter awal])[
    $ W^((1)) = mat(0.5, -0.3; 0.2, 0.8), quad b^((1)) = vec(0.1, -0.2) $
    $ w^((2)) = (1.0, -0.5), quad b^((2)) = 0.2 $
  ]
  Input $x = (0.8, 0.6)$, label sebenarnya $y = 1$ (link *baik*).

  #text(fill: bluegray)[Bobot awal biasanya *acak*; di sini dipilih agar mudah dihitung.]
]

== Hitung _Hidden Layer_

#sub[Langkah 1: dari input ke $h_1$ dan $h_2$]

#two-col[
  #blok(title: [Neuron $h_1$])[
    #set text(size: 0.85em)
    $ z_1 &= 0.5 dot 0.8 + (-0.3) dot 0.6 + 0.1 \
         &= 0.40 - 0.18 + 0.1 = #hasil[$0.32$] \
      h_1 &= "ReLU"(0.32) = #hasil[$0.32$] $
  ]
][
  #blok(title: [Neuron $h_2$])[
    #set text(size: 0.85em)
    $ z_2 &= 0.2 dot 0.8 + 0.8 dot 0.6 + (-0.2) \
         &= 0.16 + 0.48 - 0.2 = #hasil[$0.44$] \
      h_2 &= "ReLU"(0.44) = #hasil[$0.44$] $
  ]
]

#v(0.3em)
#text(size: 0.78em)[Karena kedua $z$ positif, ReLU meneruskan nilainya apa adanya. Jika $z < 0$, ReLU akan mengeluarkan $0$.]

== Hitung _Output Layer_

#sub[Langkah 2: dari $h$ ke prediksi $hat(y)$]

#two-col(columns: (1.1fr, 1fr))[
  #blok(title: [Neuron output])[
    #set text(size: 0.85em)
    $ z &= 1.0 dot 0.32 + (-0.5) dot 0.44 + 0.2 \
        &= 0.32 - 0.22 + 0.2 = #hasil[$0.30$] \
      hat(y) &= sigma(0.30) = 1 / (1 + e^(-0.30)) = #hasil[$0.574$] $
  ]
][
  #set text(size: 0.8em)
  - Model memprediksi peluang link baik *57.4%*.
  - Label sebenarnya $y = 1$ (100% baik).
  - Prediksi *benar arah* ($> 0.5$), tapi *kurang yakin*.
  #v(0.3em)
  #alert-blok(title: [Pertanyaan])[
    #set text(size: 0.9em)
    Seberapa "salah" prediksi ini? Kita butuh *angka* untuk mengukurnya → *_loss function_*.
  ]
]

== Mengukur Kesalahan: _Loss_

#sub[Satu angka yang ingin kita buat sekecil mungkin]

#two-col(columns: (1fr, 1fr))[
  #blok(title: [_Mean Squared Error_ (regresi)])[
    #set text(size: 0.82em)
    $ L_"MSE" = (y - hat(y))^2 = (1 - 0.574)^2 = #hasil[$0.181$] $
  ]
  #blok(title: [_Binary Cross-Entropy_ (klasifikasi)])[
    #set text(size: 0.82em)
    $ L_"BCE" = -[y ln hat(y) + (1-y) ln(1 - hat(y))] $
    $ = -ln(0.574) = #hasil[$0.554$] $
  ]
][
  #set text(size: 0.74em)
  Perilaku BCE saat $y = 1$:
  #table(
    columns: (1fr, 1fr, 1.4fr),
    fill: tbl-fill,
    align: center,
    th[$hat(y)$], th[$L_"BCE"$], th[Arti],
    [0.99], [0.01], [yakin & benar ✓],
    [0.574], [0.554], [ragu-ragu],
    [0.50], [0.693], [menebak],
    [0.01], [4.605], [yakin & *salah* ✗],
  )
  #text(fill: bluegray)[BCE menghukum keras prediksi yang yakin tapi salah — cocok untuk klasifikasi.]
]

// ===============================================================
= Backpropagation
// ===============================================================

#fokus[
  Prediksi kita 0.574, padahal targetnya 1. \
  #v(0.4em)
  #text(fill: gold, size: 0.9em)[Bobot mana yang harus diubah, \ dan seberapa banyak?]
]

== Intuisi: Turun Bukit

#sub[_Gradient descent_ mencari lembah _loss_ terendah]

#two-col(columns: (1.1fr, 1fr))[
  #align(center, image("img/gradient_descent.png", height: 80%))
][
  #set text(size: 0.8em)
  Bayangkan kamu di bukit berkabut dan ingin turun ke lembah:
  + Rasakan *kemiringan* tanah di kakimu (*gradien*).
  + Melangkah ke arah *menurun*.
  + Ulangi sampai dasar.
  #blok(title: [Aturan update])[
    $ w arrow.l w - eta (partial L) / (partial w) $
  ]
  $eta$ = _learning rate_ (besar langkah).
]

== _Chain Rule_: Kunci Backprop

#sub[Menelusuri pengaruh tiap bobot terhadap _loss_]

#flow([$w$], [$z$], [$hat(y)$], [$L$], fill: (teal, navy, red, gold.darken(15%)), height: 2.2em, size: 0.85em)
#v(0.2em)
#align(center, text(size: 0.7em, fill: bluegray)[Mengubah $w$ → mengubah $z$ → mengubah $hat(y)$ → mengubah $L$ (efek domino)])

#two-col(columns: (1.1fr, 1fr))[
  #blok(title: [_Chain rule_])[
    #set text(size: 0.85em)
    $ (partial L) / (partial w) = (partial L) / (partial hat(y)) dot (partial hat(y)) / (partial z) dot (partial z) / (partial w) $
  ]
][
  #contoh-blok(title: [Hasil yang indah])[
    #set text(size: 0.8em)
    Untuk sigmoid + BCE, dua suku pertama menyederhana menjadi:
    $ (partial L) / (partial z) = hat(y) - y $
    "Prediksi dikurangi target" — sangat intuitif!
  ]
]

== Alur Maju dan Mundur

#sub[_Forward_ menghitung prediksi, _backward_ membagi "kesalahan"]

#align(center, cetz.canvas(length: 1cm, {
  import cetz.draw: *
  let boxes = (("Input", teal), ("Hidden", navy), ("Output", red), ("Loss", gold.darken(15%)))
  for (i, (lbl, c)) in boxes.enumerate() {
    rect((i * 5.2, 0), (i * 5.2 + 3, 1.6), fill: c, stroke: none, radius: 0.15, name: "b" + str(i))
    content("b" + str(i), text(fill: white, weight: "bold", size: 0.85em, lbl))
  }
  for i in range(3) {
    line((i * 5.2 + 3.1, 1.25), (i * 5.2 + 5.1, 1.25), stroke: 2pt + navy, mark: (end: ">", fill: navy, scale: 0.7))
    line((i * 5.2 + 5.1, 0.35), (i * 5.2 + 3.1, 0.35), stroke: 2pt + red, mark: (end: ">", fill: red, scale: 0.7))
  }
  content((8.1, 2.3), text(fill: navy, weight: "bold", size: 0.75em)[_Forward pass_: hitung $hat(y)$ dan $L$ →])
  content((8.1, -0.7), text(fill: red, weight: "bold", size: 0.75em)[← _Backward pass_: hitung $(partial L) / (partial w)$ tiap bobot])
}))

#v(0.3em)
#[
  #set text(size: 0.8em)
  - _Backpropagation_ (Rumelhart, Hinton & Williams, 1986) = _chain rule_ yang dihitung *mundur* lapis demi lapis, memakai ulang hasil lapisan sesudahnya.
  - Di PyTorch cukup satu baris: `loss.backward()` — gradien semua bobot dihitung otomatis (*autograd*).
]

== Backprop di _Output Layer_

#sub[Mulai dari kesalahan di ujung jaringan]

#two-col(columns: (1fr, 1fr))[
  #blok(title: [Sinyal error output])[
    #set text(size: 0.85em)
    $ delta_"out" = hat(y) - y = 0.574 - 1 = #hasil[$-0.426$] $
  ]
  #set text(size: 0.78em)
  Tanda negatif artinya: *naikkan* $z$ agar $hat(y)$ mendekati 1.
][
  #blok(title: [Gradien bobot output])[
    #set text(size: 0.8em)
    $ (partial L) / (partial w_1^((2))) &= delta_"out" dot h_1 = -0.426 dot 0.32 = #hasil[$-0.136$] \
      (partial L) / (partial w_2^((2))) &= delta_"out" dot h_2 = -0.426 dot 0.44 = #hasil[$-0.187$] \
      (partial L) / (partial b^((2))) &= delta_"out" = #hasil[$-0.426$] $
  ]
]

#v(0.2em)
#text(size: 0.74em, fill: bluegray)[Pola umum: *gradien bobot = error neuron tujuan × aktivasi neuron asal*.]

== Backprop ke _Hidden Layer_

#sub[Error dibagi mundur sesuai besar bobotnya]

#two-col(columns: (1fr, 1fr))[
  #blok(title: [Error di tiap neuron hidden])[
    #set text(size: 0.8em)
    $ delta_j = delta_"out" dot w_j^((2)) dot "ReLU"'(z_j) $
    $ delta_1 &= -0.426 dot 1.0 dot 1 = #hasil[$-0.426$] \
      delta_2 &= -0.426 dot (-0.5) dot 1 = #hasil[$0.213$] $
  ]
][
  #blok(title: [Gradien bobot $W^((1))$])[
    #set text(size: 0.8em)
    $ (partial L) / (partial W^((1))_(j i)) = delta_j dot x_i $
    $ (partial L) / (partial W^((1))) = mat(-0.340, -0.255; 0.170, 0.128) $
  ]
  #set text(size: 0.74em)
  $h_2$ tersambung dengan bobot *negatif* ke output, jadi error-nya berbalik tanda: model ingin $h_2$ *mengecil*.
]

== Update Bobot ($eta = 0.5$)

#sub[Satu langkah _gradient descent_, lalu cek hasilnya]

#two-col(columns: (1fr, 1fr))[
  #set text(size: 0.74em)
  #table(
    columns: (auto, auto, auto, auto),
    fill: tbl-fill,
    align: center,
    th[Parameter], th[Lama], th[Gradien], th[Baru],
    [$w_1^((2))$], [1.000], [−0.136], [*1.068*],
    [$w_2^((2))$], [−0.500], [−0.187], [*−0.406*],
    [$b^((2))$], [0.200], [−0.426], [*0.413*],
    [$W^((1))_(11)$], [0.500], [−0.340], [*0.670*],
    [$W^((1))_(22)$], [0.800], [0.128], [*0.736*],
  )
  #text(fill: bluegray)[Baru = Lama − 0.5 × Gradien (semua 9 parameter di-_update_).]
][
  #contoh-blok(title: [_Forward_ lagi dengan bobot baru])[
    #set text(size: 0.85em)
    #table(
      columns: (1fr, auto, auto),
      align: center,
      stroke: none,
      [], [*Sebelum*], [*Sesudah*],
      [$hat(y)$], [0.574], [#text(fill: green, weight: "bold")[0.753]],
      [$L_"BCE"$], [0.554], [#text(fill: green, weight: "bold")[0.283]],
    )
  ]
  #set text(size: 0.8em)
  Satu langkah saja, _loss_ turun hampir *setengahnya*. _Training_ = mengulang ini *ribuan kali* pada banyak data.
]

== Memilih _Learning Rate_

#sub[Besar langkah menentukan cepat & stabilnya _training_]

#align(center, image("img/learning_rate.png", width: 96%))

#text(size: 0.8em, grid(
  columns: (1fr, 1fr, 1fr),
  column-gutter: 1em,
  [*Terlalu kecil*: sangat lambat, butuh banyak _epoch_.],
  [*Pas*: turun cepat & stabil ke minimum. Nilai umum: $10^(-3)$ (Adam).],
  [*Terlalu besar*: melompat-lompat, _loss_ bisa meledak (_diverge_).],
))

== Epoch, Batch, dan Iterasi

#sub[Cara data dimasukkan ke _training_ secara bertahap]

#two-col(columns: (1fr, 1fr))[
  #set text(size: 0.78em)
  #table(
    columns: (auto, 1fr),
    fill: tbl-fill,
    th[Istilah], th[Arti],
    [*_Batch_*], [Sekelompok sampel yang diproses sekaligus sebelum 1 kali _update_],
    [*Iterasi*], [Satu kali _update_ bobot (1 _batch_)],
    [*_Epoch_*], [Seluruh data _training_ sudah dilihat 1 kali],
  )
][
  #contoh-blok(title: [Contoh hands-on])[
    #set text(size: 0.8em)
    - Data latih: *100.778* koneksi (80% KDDTrain+)
    - _Batch size_: *64*
    - Iterasi per _epoch_: $ceil(100778 / 64) = #hasil[$1575$]$
    - 10 _epoch_ → *15.750* kali _update_ bobot
  ]
  #text(size: 0.72em, fill: bluegray)[Memakai _mini-batch_ = _Stochastic Gradient Descent_ (SGD) dan variannya, mis. Adam.]
]

== Siklus _Training_ ANN

#sub[Lima langkah yang diulang di setiap iterasi]

#flow([*1. Forward* \ prediksi $hat(y)$], [*2. Loss* \ bandingkan dgn $y$], [*3. Backward* \ hitung gradien], [*4. Update* \ $w arrow.l w - eta nabla L$], [*5. Reset* \ nol-kan gradien], fill: (teal, gold.darken(15%), red, navy, bluegray), height: 3.6em, size: 0.68em)

#v(0.5em)
#two-col(columns: (1fr, 1fr))[
  ```python
  for xb, yb in train_loader:   # tiap batch
      y_hat = model(xb)           # 1. forward
      loss = loss_fn(y_hat, yb)   # 2. loss
      optimizer.zero_grad()       # 5. reset
      loss.backward()             # 3. backward
      optimizer.step()            # 4. update
  ```
][
  #set text(size: 0.76em)
  - Semua perhitungan manual tadi dilakukan PyTorch *otomatis*.
  - `zero_grad()` wajib: PyTorch *menjumlahkan* gradien jika tidak di-_reset_.
  - Kita cukup memahami *konsepnya* dan memilih arsitektur, _loss_, & _optimizer_.
]

== Waspada _Overfitting_

#sub[Model menghafal data latih, gagal di data baru]

#two-col(columns: (1.1fr, 1fr))[
  #align(center, image("img/overfitting.png", height: 78%))
][
  #set text(size: 0.78em)
  - Pisahkan data: *train* / *validasi* / *test*.
  - _Loss_ train terus turun, tapi _loss_ validasi naik → *overfitting*.
  #blok(title: [Cara mengatasi])[
    #set text(size: 0.9em)
    - _Early stopping_
    - _Dropout_
    - Regularisasi (_weight decay_)
    - Tambah data / sederhanakan model
  ]
]

== Coba Sendiri: Visualisasi Interaktif

#sub[Lihat neuron belajar secara langsung di _browser_]

#two-col[
  #kartu(color: teal, nomor: 1, height: auto)[TensorFlow Playground][
    #link("https://playground.tensorflow.org")[playground.tensorflow.org]
    #v(0.3em)
    - Ubah jumlah _hidden layer_ & neuron.
    - Bandingkan aktivasi ReLU vs sigmoid.
    - Coba dataset "XOR" dan "spiral".
    - Amati efek _learning rate_.
  ]
][
  #kartu(color: red, nomor: 2, height: auto)[Backprop Explainer][
    #link("https://xnought.github.io/backprop-explainer/")[xnought.github.io/backprop-explainer]
    #v(0.3em)
    - Animasi _forward_ & _backward pass_.
    - Lihat gradien mengalir mundur.
    - Amati kurva _loss_ turun per _epoch_.
  ]
]

// ===============================================================
= Studi Kasus: Deteksi Intrusi
// ===============================================================

== Deteksi Intrusi Jaringan

#sub[_Intrusion Detection System_ (IDS) berbasis ANN]

#two-col(columns: (1fr, 1fr))[
  #set text(size: 0.8em)
  - Operator jaringan memantau jutaan koneksi setiap hari.
  - Serangan (DoS, _port scan_, pembobolan _password_) harus terdeteksi *cepat*.
  - IDS berbasis aturan (_signature_) sulit mengenali pola serangan baru.
  #v(0.3em)
  #emas-blok(title: [Tugas ANN kita])[
    #set text(size: 0.9em)
    Diberi 41 fitur sebuah koneksi → prediksi *normal* ($y = 0$) atau *serangan* ($y = 1$). *Klasifikasi biner*.
  ]
][
  #v(0.5em)
  #flow([Trafik jaringan], [Ekstraksi 41 fitur], [ANN], [Normal / Serangan], fill: (teal, navy2, navy, red), height: 4.2em, size: 0.66em)
  #v(0.6em)
  #text(size: 0.72em, fill: bluegray)[Pola yang sama dipakai di _Network Detection & Response_ (NDR) dan _firewall_ modern berbasis ML.]
]

== Mengenal Dataset NSL-KDD

#sub[_Benchmark_ klasik deteksi intrusi (Tavallaee dkk., 2009)]

#two-col(columns: (1fr, 1fr))[
  #set text(size: 0.74em)
  #table(
    columns: (auto, 1fr),
    fill: tbl-fill,
    th[Kelompok], th[Contoh fitur],
    [Dasar], [`duration`, `protocol_type`, `service`, `flag`, `src_bytes`, `dst_bytes`],
    [Konten], [`num_failed_logins`, `logged_in`, `root_shell`],
    [Trafik], [`count`, `srv_count`, `serror_rate`, `dst_host_count`],
  )
  - *41 fitur*: 38 numerik + 3 kategorikal.
  - KDDTrain+: *125.973* record, KDDTest+: *22.544* record.
  - Versi perbaikan KDD Cup 99 (duplikat dihapus).
][
  #align(center, image("img/nslkdd_distribusi.png", width: 100%))
  #text(size: 0.68em, fill: bluegray)[Hands-on: semua kategori serangan digabung jadi label *serangan* (biner).]
]

== Kategori Serangan Jaringan

#sub[Empat keluarga serangan di NSL-KDD]

#grid(
  columns: (1fr, 1fr, 1fr, 1fr),
  rows: (9.5em,),
  column-gutter: 0.7em,
  kartu(color: red)[DoS][_Denial of Service_: membanjiri server hingga layanan lumpuh. \ #v(0.3em) Contoh: `neptune` (SYN _flood_), `smurf`.],
  kartu(color: gold.darken(15%))[Probe][Memindai jaringan untuk mencari celah. \ #v(0.3em) Contoh: `portsweep`, `ipsweep`, `nmap`.],
  kartu(color: navy2)[R2L][_Remote to Local_: masuk dari luar tanpa akun sah. \ #v(0.3em) Contoh: `guess_passwd`, `ftp_write`.],
  kartu(color: bluegray)[U2R][_User to Root_: user biasa menaikkan hak akses jadi _root_. \ #v(0.3em) Contoh: `buffer_overflow`.],
)

#v(0.5em)
#alert-blok(title: [Tantangan])[
  #set text(size: 0.8em)
  Data *tidak seimbang*: U2R hanya 52 record dari 125 ribu. Akurasi tinggi belum tentu berarti model bagus → perlu metrik lain.
]

== Pipeline Hands-on

#sub[Dari file CSV sampai evaluasi model]

#flow(
  [*Load CSV* \ KDDTrain+ \ KDDTest+],
  [*Label biner* \ normal = 0 \ serangan = 1],
  [*_One-hot_* \ 3 fitur kategorikal \ → 122 fitur],
  [*_Scaling_* \ `StandardScaler`],
  [*MLP* \ PyTorch],
  [*Evaluasi* \ _confusion matrix_],
  fill: (teal, navy2, navy, navy2, red, gold.darken(15%)),
  height: 4.4em,
  size: 0.62em,
)

#v(0.6em)
#two-col[
  #blok(title: [_One-hot encoding_])[
    #set text(size: 0.78em)
    Fitur teks seperti `protocol_type` ∈ {tcp, udp, icmp} diubah jadi 3 kolom 0/1. Neuron hanya bisa menghitung *angka*.
  ]
][
  #blok(title: [_Standardization_])[
    #set text(size: 0.78em)
    $x' = (x - mu) / sigma$ → rata-rata 0, simpangan baku 1. `src_bytes` (jutaan) tidak lagi mendominasi.
  ]
]

== Arsitektur MLP Kita

#sub[122 input → 64 → 32 → 1 output]

#two-col(columns: (1.2fr, 1fr))[
  #align(center, mlp-diagram((6, 5, 4, 1), names: ([_Input_ (122)], [64 · ReLU], [32 · ReLU], [1 · sigmoid]), dx: 2.6, dy: 0.72))
][
  #set text(size: 0.74em)
  #table(
    columns: (1fr, auto),
    fill: tbl-fill,
    th[Komponen], th[Pilihan],
    [_Hidden_ aktivasi], [ReLU],
    [_Output_ aktivasi], [Sigmoid],
    [_Loss_], [BCE],
    [_Optimizer_], [Adam, $eta = 10^(-3)$],
    [_Batch size_], [64],
    [_Epoch_], [10],
    [Parameter], [9.985],
  )
]

== ANN dengan PyTorch

#sub[Mendefinisikan model cukup beberapa baris]

#two-col(columns: (1.15fr, 1fr))[
  ```python
  import torch
  import torch.nn as nn

  model = nn.Sequential(
      nn.Linear(122, 64),   # input -> hidden 1
      nn.ReLU(),
      nn.Linear(64, 32),    # hidden 1 -> hidden 2
      nn.ReLU(),
      nn.Linear(32, 1),     # hidden 2 -> output
  )

  loss_fn = nn.BCEWithLogitsLoss()  # sigmoid + BCE
  optimizer = torch.optim.Adam(model.parameters(), lr=1e-3)
  ```
][
  #set text(size: 0.76em)
  - `nn.Linear(n_in, n_out)` = $W x + b$ (satu lapisan).
  - `nn.ReLU()` = fungsi aktivasi.
  - `BCEWithLogitsLoss` menggabungkan *sigmoid + BCE* agar lebih stabil secara numerik.
  - `Adam` = varian _gradient descent_ dengan _learning rate_ adaptif.
  #v(0.3em)
  #emas-blok(title: [Cek jumlah parameter])[
    ```python
    sum(p.numel() for p in model.parameters())
    # 9985
    ```
  ]
]

== Metrik Evaluasi Klasifikasi

#sub[Akurasi saja tidak cukup untuk keamanan jaringan]

#two-col(columns: (1fr, 1.1fr))[
  #set text(size: 0.74em)
  #table(
    columns: (auto, 1fr, 1fr),
    align: center + horizon,
    fill: (x, y) => if x == 0 or y == 0 { navy } else if x == y { teal.lighten(70%) } else { red.lighten(80%) },
    [], th[Prediksi: Serangan], th[Prediksi: Normal],
    th[Asli: Serangan], [*TP* = 520], [*FN* = 80 \ #text(size: 0.85em, fill: red)[serangan lolos!]],
    th[Asli: Normal], [*FP* = 30 \ #text(size: 0.85em)[alarm palsu]], [*TN* = 370],
  )
  #text(size: 0.9em, fill: bluegray)[Angka ilustrasi (1.000 koneksi uji).]
][
  #set text(size: 0.76em)
  #table(
    columns: (auto, auto, auto),
    fill: tbl-fill,
    align: (left, center, center),
    th[Metrik], th[Rumus], th[Nilai],
    [Akurasi], [$(T P + T N) / "semua"$], [0.890],
    [_Precision_], [$(T P) / (T P + F P)$], [0.945],
    [_Recall_], [$(T P) / (T P + F N)$], [0.867],
    [F1], [$2 dot (P dot R) / (P + R)$], [0.904],
  )
  Di IDS, *_recall_* penting: setiap FN adalah serangan yang tidak terdeteksi.
]

// ===============================================================
= Hands-on
// ===============================================================

== Persiapan Lingkungan dengan uv

#sub[Satu alat untuk Python, _virtual environment_, dan paket]

#two-col(columns: (1.55fr, 1fr))[
  #text(size: 0.78em, weight: "bold", fill: navy)[1. Instal uv (sekali saja)]
  ```bash
  # macOS / Linux
  curl -LsSf https://astral.sh/uv/install.sh | sh
  # Windows (PowerShell)
  powershell -c "irm https://astral.sh/uv/install.ps1 | iex"
  ```
  #text(size: 0.78em, weight: "bold", fill: navy)[2. Unduh repo & instal dependensi]
  ```bash
  # tautan repo: mctm.web.id/dl-workshop
  git clone <URL-repo-workshop>
  cd dl-workshop
  uv sync   # buat .venv + instal semua paket
  ```
  #text(size: 0.78em, weight: "bold", fill: navy)[3. Jalankan Jupyter]
  ```bash
  uv run jupyter lab
  ```
][
  #set text(size: 0.76em)
  #blok(title: [Kenapa uv?])[
    - Sangat cepat (ditulis dengan Rust).
    - `uv sync` membaca `pyproject.toml` → semua peserta punya versi paket yang *sama*.
    - Tidak perlu `pip`, `venv`, atau `conda` terpisah.
  ]
  #alert-blok(title: [Lakukan sebelum sesi])[
    Unduhan PyTorch cukup besar (±200 MB–1 GB). Jalankan `uv sync` dengan Wi-Fi yang stabil.
  ]
]

== Alur Notebook Hands-on

#sub[Isi bagian `TODO` secara bertahap]

#grid(
  columns: (1fr, 1fr, 1fr),
  rows: (5.4em, 5.4em),
  column-gutter: 0.7em,
  row-gutter: 0.7em,
  kartu(nomor: 1, color: teal)[Eksplorasi data][Baca CSV, lihat fitur, hitung distribusi normal vs serangan.],
  kartu(nomor: 2, color: navy2)[Pra-pemrosesan][Label biner, _one-hot encoding_, _standardization_.],
  kartu(nomor: 3, color: navy)[Bangun model][Definisikan MLP 122-64-32-1 dengan `nn.Sequential`.],
  kartu(nomor: 4, color: red)[_Training_][Tulis _training loop_, pantau _loss_ train & validasi.],
  kartu(nomor: 5, color: gold.darken(15%))[Evaluasi][_Confusion matrix_, _precision_, _recall_, F1 di KDDTest+.],
  kartu(nomor: 6, color: bluegray)[Eksperimen][Ubah neuron, aktivasi, _learning rate_ — amati efeknya.],
)

== Latihan 1: _Forward Pass_

#sub[#badge[Latihan] Gunakan jaringan 2-2-1 dan bobot yang sama]

#two-col(columns: (1.2fr, 1fr))[
  #align(center + horizon, toy-network())
][
  #set text(size: 0.8em)
  #blok(title: [Soal])[
    Sebuah link memiliki SNR dan RSSI ternormalisasi $x = (0.2, 0.3)$ dengan label *link buruk* ($y = 0$).
    + Hitung $h_1$ dan $h_2$.
    + Hitung $hat(y)$.
    + Hitung $L_"BCE"$. Apakah prediksinya benar?
  ]
  #text(size: 0.9em, fill: bluegray)[Petunjuk: $sigma(0.27) approx 0.567$.]
]

== Solusi 1: _Forward Pass_

#sub[Pembahasan langkah demi langkah]

#two-col(columns: (1fr, 1fr))[
  #blok(title: [_Hidden layer_])[
    #set text(size: 0.8em)
    $ z_1 &= 0.5 dot 0.2 - 0.3 dot 0.3 + 0.1 = 0.11 arrow.r h_1 = #hasil[$0.11$] \
      z_2 &= 0.2 dot 0.2 + 0.8 dot 0.3 - 0.2 = 0.08 arrow.r h_2 = #hasil[$0.08$] $
  ]
  #blok(title: [_Output layer_])[
    #set text(size: 0.8em)
    $ z = 1.0 dot 0.11 - 0.5 dot 0.08 + 0.2 = 0.27 $
    $ hat(y) = sigma(0.27) = #hasil[$0.567$] $
  ]
][
  #blok(title: [_Loss_ ($y = 0$)])[
    #set text(size: 0.8em)
    $ L_"BCE" = -ln(1 - 0.567) = #hasil[$0.837$] $
  ]
  #alert-blok(title: [Interpretasi])[
    #set text(size: 0.8em)
    $hat(y) > 0.5$ → model memprediksi *baik*, padahal *buruk*. _Loss_ besar (0.837 > 0.554) → _backprop_ akan mengoreksi bobot lebih kuat. Model belum di-_train_!
  ]
]

== Latihan 2: Rancang Arsitektur

#sub[#badge[Latihan] Dari biner ke multi-kelas]

#blok(title: [Soal])[
  #set text(size: 0.82em)
  Kita ingin memprediksi *5 kelas* NSL-KDD (Normal, DoS, Probe, R2L, U2R) dengan MLP *122-128-64-?*.
  + Berapa neuron dan fungsi aktivasi di _output layer_?
  + _Loss function_ apa yang cocok?
  + Hitung total parameter model.
]

#v(0.3em)
#text(size: 0.78em, fill: bluegray)[Kerjakan 3 menit, lalu diskusikan dengan teman sebelahmu.]

== Solusi 2: Rancang Arsitektur

#sub[Pembahasan]

#two-col(columns: (1fr, 1.1fr))[
  #set text(size: 0.8em)
  + *5 neuron* + *softmax* (satu peluang per kelas).
  + *_Cross-Entropy Loss_* (versi multi-kelas dari BCE). Di PyTorch: `nn.CrossEntropyLoss()` (sudah termasuk softmax).
  + Lihat tabel di kanan.
][
  #set text(size: 0.74em)
  #table(
    columns: (1fr, auto, auto),
    fill: tbl-fill,
    align: (left, center, right),
    th[Lapisan], th[Hitungan], th[Parameter],
    [122 → 128], [$122 times 128 + 128$], [15.744],
    [128 → 64], [$128 times 64 + 64$], [8.256],
    [64 → 5], [$64 times 5 + 5$], [325],
    table.cell(colspan: 2)[*Total*], [*24.325*],
  )
]

// ===============================================================
= Penutup
// ===============================================================

== Ringkasan Sesi 1

#sub[Empat ide yang perlu dibawa pulang]

#grid(
  columns: (1fr, 1fr),
  rows: (5.2em, 5.2em),
  column-gutter: 0.8em,
  row-gutter: 0.7em,
  kartu(nomor: 1, color: teal)[Struktur][Neuron = $f(sum w_i x_i + b)$. Neuron disusun dalam lapisan _input_, _hidden_, _output_.],
  kartu(nomor: 2, color: navy)[Aktivasi][Non-linearitas membuat ANN bisa belajar pola rumit. ReLU di _hidden_, sigmoid/softmax di _output_.],
  kartu(nomor: 3, color: red)[_Feed forward_ & _loss_][Hitung prediksi lapis demi lapis, ukur kesalahan dengan MSE atau BCE.],
  kartu(nomor: 4, color: gold.darken(15%))[_Backprop_][_Chain rule_ menghitung gradien; _gradient descent_ memperbarui bobot berulang-ulang.],
)

== Sesi 2: RNN & LSTM

#sub[Ketika urutan waktu menjadi penting]

#two-col(columns: (1fr, 1fr))[
  #set text(size: 0.8em)
  #alert-blok(title: [Keterbatasan ANN])[
    #set text(size: 0.95em)
    ANN melihat setiap sampel *terpisah* — tidak punya *memori*. Padahal trafik jaringan jam 20.00 sangat dipengaruhi trafik jam 19.00.
  ]
  #contoh-blok(title: [Sesi berikutnya])[
    #set text(size: 0.95em)
    - _Recurrent Neural Network_ (RNN)
    - _Long Short-Term Memory_ (LSTM)
    - Hands-on: *prediksi trafik jaringan / beban sel* (_time series forecasting_)
  ]
][
  #v(1em)
  #flow([$x_(t-2)$], [$x_(t-1)$], [$x_t$], [$hat(x)_(t+1)$], fill: (teal, teal, teal, red), height: 2.6em, size: 0.8em)
  #v(0.4em)
  #align(center, text(size: 0.72em, fill: bluegray)[LSTM "mengingat" pola masa lalu untuk meramal masa depan.])
]

== Referensi

#[
  #set text(size: 0.7em)
  #set par(hanging-indent: 1.5em, spacing: 0.9em)

Goodfellow, I., Bengio, Y., & Courville, A. (2016). _Deep Learning_. MIT Press. #link("https://www.deeplearningbook.org")[deeplearningbook.org]

Nielsen, M. (2015). _Neural Networks and Deep Learning_. Determination Press. #link("http://neuralnetworksanddeeplearning.com")[neuralnetworksanddeeplearning.com]

Rosenblatt, F. (1958). The perceptron: A probabilistic model for information storage and organization in the brain. _Psychological Review_, 65(6), 386–408.

Rumelhart, D. E., Hinton, G. E., & Williams, R. J. (1986). Learning representations by back-propagating errors. _Nature_, 323, 533–536.

Tavallaee, M., Bagheri, E., Lu, W., & Ghorbani, A. A. (2009). A detailed analysis of the KDD CUP 99 data set. _IEEE Symposium on Computational Intelligence for Security and Defense Applications (CISDA)_.

Zhang, C., Patras, P., & Haddadi, H. (2019). Deep learning in mobile and wireless networking: A survey. _IEEE Communications Surveys & Tutorials_, 21(3), 2224–2287.

PyTorch Documentation. #link("https://pytorch.org/docs/stable/nn.html")[pytorch.org/docs/stable/nn.html] · uv Documentation. #link("https://docs.astral.sh/uv/")[docs.astral.sh/uv]
]

#fokus[
  #align(center)[
    Terima Kasih
    #v(0.3em)
    #text(size: 0.55em, fill: gold, font: font-body)[Saatnya _hands-on_ — buka notebook Sesi 1!]
    #v(0.2em)
    #text(size: 0.45em, fill: white.darken(20%), font: font-body, weight: "regular")[mctm.web.id/dl-workshop]
  ]
]
