// Paper: EDA & MLP untuk deteksi intrusi pada NSL-KDD
// Kompilasi dari root repo:
//   typst compile --root paper paper/main.typ ~/Downloads/paper_nslkdd_mlp.pdf

#let navy = rgb("#0B1F3A")

#set document(
  title: "Analisis Data Eksploratif dan Evaluasi Multilayer Perceptron untuk Deteksi Intrusi Jaringan pada Dataset NSL-KDD",
  author: "Martin Manullang",
)
#set page(
  paper: "a4",
  margin: (x: 1.7cm, top: 2cm, bottom: 2cm),
  columns: 2,
  numbering: "1",
  number-align: center,
)
#set columns(gutter: 0.6cm)
#set text(font: ("Times New Roman", "Libertinus Serif"), size: 10pt, lang: "id")
#set par(justify: true, leading: 0.55em, spacing: 0.65em, first-line-indent: (amount: 1em, all: false))
#set math.equation(numbering: "(1)")
#show math.equation: set text(font: ("STIX Two Math", "New Computer Modern Math"))
#show raw: set text(font: ("Menlo", "DejaVu Sans Mono"), size: 0.85em)

#set heading(numbering: "1.1")
#show heading.where(level: 1): it => {
  set text(size: 10pt, weight: "bold")
  set align(center)
  v(0.6em)
  upper(it)
  v(0.25em)
}
#show heading.where(level: 2): it => {
  set text(size: 10pt, weight: "bold", style: "italic")
  v(0.4em)
  it
  v(0.15em)
}

#set figure(gap: 0.5em)
#show figure.caption: set text(size: 8.5pt)
#show figure.caption: set align(left)
#show figure.where(kind: table): set figure.caption(position: top)
#set table(stroke: none, inset: (x: 4pt, y: 2.6pt))
#show table: set text(size: 8.5pt)

#let toprule = table.hline(stroke: 0.8pt)
#let midrule = table.hline(stroke: 0.4pt)
#let kw(body) = text(style: "italic", body)

// ---------------------------------------------------------------- judul
#place(top + center, float: true, scope: "parent", clearance: 1.4em)[
  #set par(first-line-indent: 0em, justify: true)
  #align(center)[
    #text(size: 15pt, weight: "bold", fill: navy)[
      Analisis Data Eksploratif dan Evaluasi _Multilayer Perceptron_ \
      untuk Deteksi Intrusi Jaringan pada Dataset NSL-KDD
    ]
    #v(0.9em)
    #text(size: 11pt)[Martin Manullang]
    #v(0.2em)
    #text(size: 9pt)[
      Institut Teknologi Sumatera (ITERA), Lampung Selatan, Indonesia \
      #link("mailto:martin.manullang@if.itera.ac.id")[`martin.manullang@if.itera.ac.id`]
    ]
  ]
  #v(1em)
  #block(inset: (x: 1.2cm))[
    #set text(size: 9pt)
    *Abstrak* --- Sistem deteksi intrusi berbasis pembelajaran mesin kerap dilaporkan sangat akurat, tetapi angka tersebut sering diukur pada data yang berdistribusi sama dengan data latih. Penelitian ini melakukan analisis data eksploratif (EDA) terhadap dataset NSL-KDD, lalu melatih _multilayer perceptron_ (MLP) 122-64-32-1 berparameter 9.985 untuk klasifikasi biner normal/serangan. EDA menemukan ketidakseimbangan kelas yang ekstrem (U2R hanya 0,04% data latih), rentang skala fitur hingga 10#super[9], sepuluh pasang fitur yang nyaris redundan (|_r_| > 0,95), serta pergeseran distribusi antara KDDTrain+ dan KDDTest+: 17 jenis serangan (16,6% data uji) tidak pernah muncul di data latih. Dari lima kali pelatihan dengan _seed_ berbeda, model mencapai F1 99,46 ± 0,04% pada data validasi, tetapi hanya 79,17 ± 1,00% pada KDDTest+ (akurasi 79,32%, _recall_ 69,08%, AUC 0,893). Analisis per kategori menunjukkan bahwa serangan R2L menyumbang 63,2% serangan yang lolos, dengan tingkat deteksi hanya 12,5% untuk jenis R2L yang dikenal. Menurunkan ambang keputusan maupun transformasi logaritmik tidak menutup kesenjangan ini secara berarti. Hasil ini menegaskan bahwa kinerja validasi pada NSL-KDD bukan indikator generalisasi yang andal, dan bahwa kelemahan utama MLP terletak pada serangan berbasis konten yang jarang muncul di data latih.

    #v(0.3em)
    *Kata kunci* --- deteksi intrusi, NSL-KDD, _multilayer perceptron_, analisis data eksploratif, ketidakseimbangan kelas

    #v(0.7em)
    #text(style: "italic")[*Abstract* --- Machine-learning intrusion detection systems are often reported as highly accurate, yet such figures are frequently measured on data drawn from the training distribution. We perform an exploratory data analysis (EDA) of NSL-KDD and train a 122-64-32-1 multilayer perceptron (9,985 parameters) for binary normal/attack classification. The EDA reveals extreme class imbalance (U2R is 0.04% of the training set), feature scales spanning up to 10#super[9], ten nearly redundant feature pairs, and a distribution shift between KDDTrain+ and KDDTest+: 17 attack types (16.6% of the test set) never appear in training. Across five seeds, the model reaches an F1 of 99.46 ± 0.04% on validation but only 79.17 ± 1.00% on KDDTest+ (recall 69.08%, AUC 0.893). R2L attacks account for 63.2% of missed attacks. Neither lowering the decision threshold nor a log transform closes this gap, showing that validation performance on NSL-KDD is an unreliable proxy for generalization.]

    #v(0.3em)
    #text(style: "italic")[*Keywords* --- intrusion detection, NSL-KDD, multilayer perceptron, exploratory data analysis, class imbalance]
  ]
]

// ---------------------------------------------------------------- isi
= Pendahuluan

Sistem deteksi intrusi (_intrusion detection system_, IDS) memantau trafik jaringan untuk mengenali aktivitas berbahaya, sebuah gagasan yang dirumuskan secara formal sejak model deteksi intrusi Denning @denning1987. IDS berbasis tanda tangan (_signature_) hanya mengenali serangan yang polanya sudah diketahui, sehingga pendekatan pembelajaran mesin banyak diteliti untuk menangkap pola serangan secara otomatis dari data @buczak2016. Di antara pendekatan tersebut, jaringan saraf tiruan (_artificial neural network_, ANN) dan varian _deep learning_ seperti DNN dan RNN telah diuji secara luas @tang2016 @yin2017.

Dataset NSL-KDD @tavallaee2009 menjadi salah satu tolok ukur paling populer untuk tugas ini. NSL-KDD merupakan perbaikan KDD Cup 99, yang dikritik karena banyaknya record duplikat dan cacat metodologis pada data DARPA asalnya @mchugh2000. Meski demikian, Sommer dan Paxson @sommer2010 mengingatkan bahwa deteksi intrusi berbeda dari tugas klasifikasi pada umumnya: serangan baru terus bermunculan, sehingga model yang tampak sangat akurat di data latih belum tentu berguna di dunia nyata.

Penelitian ini tidak bertujuan mencapai akurasi tertinggi. Tujuannya adalah memahami *mengapa* model sederhana berperilaku seperti yang diamati, dengan menghubungkan temuan analisis data eksploratif (_exploratory data analysis_, EDA) dengan kinerja model. Kontribusi penelitian ini adalah:
+ EDA terhadap NSL-KDD yang mengungkap ketidakseimbangan kelas, sifat skala fitur, redundansi fitur, dan pergeseran distribusi antara data latih dan uji;
+ evaluasi MLP _baseline_ dengan lima _seed_ acak, lengkap dengan rerata dan simpangan baku;
+ analisis kegagalan per kategori serangan, yang memisahkan jenis serangan yang dikenal dan jenis yang baru; serta
+ analisis sensitivitas terhadap ambang keputusan dan transformasi logaritmik fitur.

= Dataset dan Analisis Data Eksploratif

== Deskripsi dataset

Setiap record NSL-KDD mewakili satu koneksi jaringan yang dirangkum menjadi 41 fitur. Fitur tersebut terbagi menjadi empat kelompok: fitur dasar header TCP/IP (9 fitur, mis. `duration`, `protocol_type`, `src_bytes`), fitur konten _payload_ (13 fitur, mis. `num_failed_logins`, `root_shell`), fitur trafik dua detik terakhir (9 fitur, mis. `count`, `serror_rate`), dan fitur trafik ke host tujuan (10 fitur, mis. `dst_host_srv_count`). Tiga fitur bersifat kategorikal (`protocol_type`, `service`, `flag`) dan 38 fitur numerik, lima di antaranya biner.

Kolom `label` berisi nama serangan spesifik yang dikelompokkan ke dalam empat kategori @tavallaee2009: _Denial of Service_ (DoS), _Probe_ (pemindaian), _Remote to Local_ (R2L, akses tanpa akun sah), dan _User to Root_ (U2R, eskalasi hak akses). Kolom tambahan `difficulty` merupakan metadata dataset, bukan fitur koneksi. @tab:dataset merangkum komposisi kedua subset resmi.

#figure(
  table(
    columns: (auto, 1fr, 1fr, 1fr, 1fr),
    align: (left, right, right, right, right),
    toprule,
    table.header([*Kategori*], table.cell(colspan: 2, align: center)[*KDDTrain+*], table.cell(colspan: 2, align: center)[*KDDTest+*]),
    table.hline(start: 1, end: 3, stroke: 0.4pt),
    table.hline(start: 3, end: 5, stroke: 0.4pt),
    [], [record], [%], [record], [%],
    midrule,
    [Normal], [67.343], [53,46], [9.711], [43,08],
    [DoS], [45.927], [36,46], [7.458], [33,08],
    [Probe], [11.656], [9,25], [2.421], [10,74],
    [R2L], [995], [0,79], [2.754], [12,22],
    [U2R], [52], [0,04], [200], [0,89],
    midrule,
    [*Total*], [*125.973*], [100], [*22.544*], [100],
    toprule,
  ),
  caption: [Komposisi kategori pada kedua subset NSL-KDD.],
) <tab:dataset>

== Kualitas data

Kedua subset tidak memiliki _missing value_ maupun baris duplikat, sehingga tidak diperlukan imputasi. Fitur `num_outbound_cmds` bernilai nol untuk seluruh record sehingga tidak membawa informasi. Sebanyak 16 dari 38 fitur numerik bernilai nol pada lebih dari 90% record; mayoritasnya adalah fitur konten seperti `num_shells` dan `root_shell` yang hanya aktif pada koneksi tertentu.

== Ketidakseimbangan kelas dan pergeseran distribusi

@fig:distribusi memperlihatkan dua masalah utama. Pertama, ketidakseimbangan kelas yang ekstrem: U2R hanya 52 record (0,04%) dan R2L 995 record (0,79%) di data latih. Kedua, proporsi kategori berubah drastis di data uji; R2L naik dari 0,79% menjadi 12,22%, atau sekitar lima belas kali lipat.

#figure(
  image("img/distribusi.png", width: 100%),
  caption: [Proporsi kategori serangan pada KDDTrain+ dan KDDTest+. Proporsi R2L dan U2R melonjak di data uji.],
) <fig:distribusi>

Pergeseran ini diperparah oleh 17 jenis serangan (mis. `mscan`, `apache2`, `snmpguess`, `processtable`) yang hanya ada di KDDTest+. Jenis serangan baru ini mencakup 3.750 record, atau 16,6% data uji: 1.717 DoS, 1.315 _Probe_, 555 R2L, dan 163 U2R. Distribusi `difficulty` juga berbeda: record sulit (`difficulty` < 18) mencakup 29,5% data uji, dibanding hanya 10,4% data latih. Dengan kata lain, KDDTest+ sengaja dirancang lebih sulit daripada KDDTrain+ @tavallaee2009.

Setelah seluruh kategori serangan digabung menjadi satu kelas, label biner relatif seimbang: 53,5% normal berbanding 46,5% serangan di data latih, dan 43,1% berbanding 56,9% di data uji.

== Fitur kategorikal

Fitur kategorikal sangat informatif. _Flag_ `S0` (SYN tanpa balasan) 99% berasal dari serangan DoS, khususnya `neptune` (SYN _flood_). Layanan `private` 96% berupa serangan, sedangkan `http` hanya 6%. Layanan yang jarang digunakan, seperti `Z39_50`, `uucp`, dan `courier`, seluruhnya berupa serangan karena koneksi ke layanan tersebut umumnya muncul akibat pemindaian _port_. Ketiga fitur ini memiliki 3, 70, dan 11 nilai unik. Seluruh nilai di data uji juga muncul di data latih.

== Fitur numerik

Rentang nilai fitur numerik sangat lebar: `src_bytes` dan `dst_bytes` mencapai sekitar 1,3 × 10#super[9], sedangkan fitur rasio (`*_rate`) berada di $[0, 1]$. Sebaran fitur bervolume juga sangat miring (_heavy-tailed_). @fig:fitur memperlihatkan tiga fitur dengan pemisahan kelas yang jelas. Serangan DoS membuka ratusan koneksi ke host yang sama dalam dua detik (`count` tinggi). Koneksi normal cenderung menuju layanan yang sama (`same_srv_rate` ≈ 1), sedangkan pemindaian berpindah-pindah layanan.

#figure(
  image("img/fitur.png", width: 100%),
  caption: [Sebaran tiga fitur numerik untuk koneksi normal dan serangan (KDDTrain+, histogram ternormalisasi).],
  placement: top,
  scope: "parent",
) <fig:fitur>

Profil rata-rata per kategori memperlihatkan karakter serangan yang berbeda. DoS ditandai oleh `serror_rate` tinggi (0,75), dan _Probe_ oleh `rerror_rate` tinggi (0,44). Sebaliknya, R2L justru menyerupai koneksi normal: `same_srv_rate` 0,997 (normal 0,969) dan `logged_in` 0,91 (normal 0,71). Pembedanya hanya terlihat pada fitur konten seperti `hot` dan `num_failed_logins`.

== Korelasi

Fitur dengan korelasi Pearson terkuat terhadap label biner adalah `same_srv_rate` (_r_ = −0,75), `dst_host_srv_count` (−0,72), `logged_in` (−0,69), dan kelompok `*serror_rate` (+0,65). Antarfitur, terdapat sepuluh pasangan dengan |_r_| > 0,95, misalnya `num_compromised`--`num_root` (0,999) dan `serror_rate`--`srv_serror_rate` (0,993). Redundansi ini tidak menghambat MLP, tetapi menambah parameter tanpa menambah informasi.

= Metode

== Pra-pemrosesan

Label biner didefinisikan sebagai $y = 0$ untuk `normal` dan $y = 1$ untuk serangan apa pun. Kolom `difficulty` dibuang. Ketiga fitur kategorikal diubah dengan _one-hot encoding_, menghasilkan $38 + 3 + 70 + 11 = 122$ fitur; kolom data uji disamakan dengan kolom data latih. Sebanyak 20% KDDTrain+ disisihkan secara terstratifikasi sebagai data validasi (100.778 latih, 25.195 validasi). Setiap fitur kemudian distandardisasi,
$ x'_j = (x_j - mu_j) / sigma_j, $ <eq:scale>
dengan $mu_j$ dan $sigma_j$ yang dihitung *hanya* dari data latih, lalu diterapkan ke data validasi dan uji untuk mencegah kebocoran informasi.

== Arsitektur dan pelatihan

Model berupa MLP dua lapis tersembunyi 122-64-32-1 dengan aktivasi ReLU @nair2010, sehingga total parameternya $122 dot 64 + 64 + 64 dot 32 + 32 + 32 + 1 = 9.985$. Keluaran berupa logit $z$, dengan probabilitas serangan $hat(y) = sigma(z)$. Model dilatih dengan _binary cross-entropy_,
$ cal(L) = -1/N sum_(i=1)^N [y_i log hat(y)_i + (1 - y_i) log(1 - hat(y)_i)], $ <eq:bce>
menggunakan _backpropagation_ @rumelhart1986 dan optimizer Adam @kingma2015. _Early stopping_ @prechelt1998 menghentikan pelatihan jika _loss_ validasi tidak membaik selama tiga epoch, lalu mengembalikan bobot dengan _loss_ validasi terendah. Hiperparameter dirangkum pada @tab:hparam. Implementasi menggunakan PyTorch 2.14 @paszke2019 dan scikit-learn 1.9 @pedregosa2011.

#figure(
  table(
    columns: (1fr, auto),
    align: (left, left),
    toprule,
    table.header([*Hiperparameter*], [*Nilai*]),
    midrule,
    [Arsitektur], [122-64-32-1, ReLU],
    [Fungsi _loss_], [`BCEWithLogitsLoss`],
    [_Optimizer_ / _learning rate_], [Adam / $10^(-3)$],
    [Ukuran _batch_], [64],
    [Epoch maksimum / _patience_], [10 / 3],
    [Ambang keputusan $tau$], [0,5],
    [_Seed_], [42, 0, 1, 2, 3],
    toprule,
  ),
  caption: [Hiperparameter pelatihan.],
) <tab:hparam>

== Evaluasi dan protokol eksperimen

Prediksi serangan diberikan jika $hat(y) > tau$. Metrik yang digunakan adalah akurasi, _precision_ $P = "TP" slash ("TP" + "FP")$, _recall_ $R = "TP" slash ("TP" + "FN")$, $F_1 = 2 P R slash (P + R)$, dan luas di bawah kurva ROC (AUC). Kelas positif adalah serangan. Mengingat ketidakseimbangan kelas, _recall_ dipandang paling penting karena setiap _false negative_ berarti serangan yang lolos.

Setiap konfigurasi dilatih lima kali dengan _seed_ berbeda. Pembagian latih/validasi dibuat tetap agar variasi hanya berasal dari inisialisasi bobot dan urutan _batch_. Tiga analisis tambahan dilakukan: (i) tingkat deteksi per kategori, dipisahkan antara jenis serangan yang ada di data latih ("dikenal") dan yang tidak ("baru"); (ii) sensitivitas terhadap ambang _τ_ ∈ [0,05; 0,95]; dan (iii) ablasi transformasi $log(1 + x)$ pada 12 fitur bervolume (`duration`, `src_bytes`, `dst_bytes`, `count`, `srv_count`, dan lainnya) sebelum standardisasi. Seluruh eksperimen dijalankan pada CPU Apple M1 Pro, dengan waktu sekitar 8 detik per pelatihan.

= Hasil dan Pembahasan

== Kinerja model

@tab:hasil membandingkan kinerja pada data validasi dan data uji. Pada data validasi, model nyaris sempurna, dengan F1 99,46% dan AUC 0,9998. Pada KDDTest+, F1 turun menjadi 79,17% dan _recall_ hanya 69,08%. Simpangan baku antar-_seed_ di data uji (hingga 1,4 poin untuk _recall_) jauh lebih besar daripada di data validasi. Artinya, bagian data uji yang berada di luar distribusi latih diperlakukan berbeda oleh setiap inisialisasi.

#figure(
  table(
    columns: (auto, 1fr, 1fr, 1fr),
    align: (left, center, center, center),
    toprule,
    table.header([*Metrik (%)*], [*Validasi*], [*Uji*], [*Uji + log*]),
    midrule,
    [Akurasi], [99,50 ± 0,03], [79,32 ± 0,83], [79,30 ± 1,08],
    [_Precision_], [99,46 ± 0,08], [92,74 ± 0,17], [92,53 ± 0,26],
    [_Recall_], [99,47 ± 0,10], [69,08 ± 1,44], [69,21 ± 1,87],
    [$F_1$], [99,46 ± 0,04], [79,17 ± 1,00], [79,18 ± 1,30],
    [AUC], [99,98 ± 0,00], [89,26 ± 1,31], [89,75 ± 0,19],
    toprule,
  ),
  caption: [Rerata $plus.minus$ simpangan baku dari lima _seed_. Kolom "Uji + log" adalah model yang dilatih dengan transformasi $log(1+x)$.],
) <tab:hasil>

@fig:loss menunjukkan kurva _loss_ untuk _seed_ 42. _Loss_ validasi mencapai minimum pada epoch 8 (0,0148), lalu naik pada epoch 10, tanda awal _overfitting_ yang ditangani oleh pengembalian bobot terbaik. Kesenjangan antara validasi dan uji tidak dapat dijelaskan oleh _overfitting_ semata. Data validasi berasal dari distribusi yang sama dengan data latih, sehingga tidak mengukur kemampuan model menghadapi serangan atau proporsi kategori yang berbeda.

#figure(
  image("img/loss.png", width: 92%),
  caption: [Kurva _loss_ latih dan validasi (_seed_ 42).],
) <fig:loss>

_Confusion matrix_ pada KDDTest+ (_seed_ 42) menunjukkan 8.923 _true positive_, 9.023 _true negative_, 688 _false positive_, dan 3.910 _false negative_. Model bersifat konservatif: bila model memprediksi serangan, prediksinya hampir selalu benar (_precision_ 92,8%), tetapi hampir sepertiga serangan lolos.

== Analisis per kategori serangan

@fig:deteksi menguraikan ke mana 3.910 serangan yang lolos tersebut berasal. DoS dan _Probe_ yang dikenal terdeteksi dengan baik (99,0% dan 89,9%). Kelemahan terbesar ada pada R2L: hanya 12,5% R2L yang dikenal dan 1,4% R2L yang baru terdeteksi. R2L sendiri menyumbang 2.472 dari 3.910 serangan yang lolos (63,2%). Temuan ini selaras dengan EDA. R2L hanya 0,79% data latih, dan profil fitur trafiknya hampir identik dengan koneksi normal; pembedanya tersembunyi pada fitur konten yang jarang bernilai tidak nol.

#figure(
  image("img/deteksi.png", width: 100%),
  caption: [Tingkat deteksi per kategori pada KDDTest+ (_seed_ 42), dipisahkan antara jenis serangan yang dikenal dan yang baru.],
) <fig:deteksi>

Jenis serangan baru juga jauh lebih sulit: tingkat deteksinya 52,1%, dibanding 76,7% untuk jenis yang dikenal. Penurunan paling tajam terjadi pada DoS, dari 99,0% menjadi 49,4%. Serangan DoS baru, yaitu `apache2` (`http`), `processtable` (`telnet`), dan `mailbomb` (`smtp`), menghabiskan sumber daya layanan melalui koneksi yang tampak sah. Rerata `count` ketiganya hanya 1–43 dan `same_srv_rate` ≥ 0,96, sangat berbeda dari `neptune` di data latih (`count` 173, `same_srv_rate` 0,10, `serror_rate` 0,83). Dengan demikian, serangan tersebut tidak memiliki ciri volumetrik yang dipelajari model. Hal ini menggambarkan argumen Sommer dan Paxson @sommer2010: model belajar mengenali *jenis serangan yang dilihatnya*, bukan konsep "serangan" secara umum.

== Sensitivitas terhadap ambang keputusan

Karena _precision_ jauh lebih tinggi daripada _recall_, wajar untuk menduga bahwa menurunkan ambang $tau$ akan menyeimbangkan keduanya. @fig:ambang menunjukkan bahwa efeknya kecil. Menurunkan $tau$ dari 0,5 ke 0,05 hanya menaikkan _recall_ dari 69,5% ke 74,1% (F1 dari 79,5% ke 82,2%), sementara _precision_ nyaris tidak berubah. Kurva ROC juga mendatar pada TPR sekitar 0,89 hingga FPR 0,3. Artinya, sebagian besar serangan yang lolos diberi probabilitas sangat rendah: model *yakin* bahwa koneksi tersebut normal. Selain itu, ambang yang dipilih berdasarkan data validasi tetap berada di sekitar 0,5–0,7 (F1 validasi maksimum 99,47% pada _τ_ = 0,7), sehingga penyetelan ambang tanpa melihat data uji tidak memperbaiki kinerja.

#figure(
  image("img/ambang.png", width: 100%),
  caption: [(a) Kurva ROC pada KDDTest+ dan (b) _precision_, _recall_, serta $F_1$ uji sebagai fungsi ambang $tau$ (_seed_ 42). Garis putus-putus menandai _τ_ = 0,5.],
  placement: top,
  scope: "parent",
) <fig:ambang>

== Ablasi transformasi logaritmik

EDA menunjukkan bahwa fitur bervolume sangat miring, sehingga transformasi $log(1+x)$ sebelum standardisasi merupakan perbaikan yang wajar dicoba. Transformasi ini memang menaikkan F1 validasi dari 99,46% ke 99,78%, tetapi F1 uji praktis tidak berubah (79,17% vs. 79,18%; @tab:hasil). Satu-satunya perbaikan yang konsisten adalah AUC, yang naik tipis (89,26% ke 89,75%) dengan simpangan baku jauh lebih kecil (1,31 ke 0,19). Hasil ini kembali menunjukkan bahwa perbaikan di data validasi tidak menjamin perbaikan di data uji yang terdistribusi berbeda.

== Keterbatasan

Penelitian ini memiliki beberapa keterbatasan. Pertama, hanya satu arsitektur dan satu konfigurasi hiperparameter yang dievaluasi. Kedua, analisis per kategori dan analisis ambang dilaporkan untuk satu _seed_. Ketiga, NSL-KDD mewarisi trafik tahun 1998 dan kritik metodologis terhadap data DARPA @mchugh2000, sehingga hasilnya belum tentu mewakili trafik jaringan modern. Terakhir, analisis ambang pada data uji bersifat diagnostik dan tidak boleh digunakan untuk memilih model.

= Kesimpulan

EDA terhadap NSL-KDD mengungkap ketidakseimbangan kelas yang ekstrem, skala fitur yang sangat beragam, redundansi fitur, dan pergeseran distribusi yang disengaja antara KDDTrain+ dan KDDTest+. MLP 122-64-32-1 sederhana mencapai F1 99,46% pada data validasi, tetapi hanya 79,17% pada KDDTest+. Kesenjangan ini terutama disebabkan oleh serangan R2L, yang menyumbang 63,2% serangan lolos, dan oleh jenis serangan baru yang tingkat deteksinya hanya 52,1%. Penurunan ambang keputusan dan transformasi logaritmik tidak menutup kesenjangan tersebut, karena model memberi probabilitas rendah secara meyakinkan kepada serangan yang tidak dikenalnya.

Penelitian selanjutnya dapat mengkaji penanganan ketidakseimbangan kelas (pembobotan _loss_ atau _oversampling_ R2L/U2R), pemodelan eksplisit fitur konten, klasifikasi multikelas, serta evaluasi pada dataset yang lebih baru. Temuan utama penelitian ini berlaku umum: pada deteksi intrusi, kinerja validasi yang tinggi harus selalu diuji terhadap data yang berbeda distribusi sebelum dianggap sebagai bukti generalisasi.

#heading(numbering: none)[Ketersediaan Kode]
Seluruh kode EDA, pelatihan, dan eksperimen tersedia di #link("https://github.com/mctosima/dl-workshop")[`github.com/mctosima/dl-workshop`].

#set text(size: 8.5pt)
#bibliography("refs.bib", title: "Daftar Pustaka", style: "ieee")
