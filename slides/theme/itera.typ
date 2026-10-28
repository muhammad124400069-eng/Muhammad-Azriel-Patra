// itera.typ — Tema slide workshop DL berbasis touying `university`
// Palet mengikuti tema Beamer ITERA (STM): navy, gold, red, teal, cream.
//
// Pemakaian di main.typ:
//   #import "../theme/itera.typ": *
//   #show: itera-theme.with(config-info(title: [...], ...))

#import "@preview/touying:0.6.1": *
#import themes.university: *
#import "@preview/cetz:0.4.2"

// ---------------------------------------------------------------
// Palet warna
// ---------------------------------------------------------------
#let navy = rgb("#0B1F3A")
#let navy2 = rgb("#1B3A5C")
#let gold = rgb("#D4A017")
#let gold2 = rgb("#E8C34A")
#let red = rgb("#C8102E")
#let teal = rgb("#1E8C8C")
#let green = rgb("#2E9E6B")
#let cream = rgb("#F7F6F3")
#let bluegray = rgb("#4A5B6E")
#let darkgray = rgb("#5A5A5A")

#let font-body = ("Fira Sans", "Inter", "Helvetica Neue")
#let font-head = ("Palatino", "Georgia", "Libertinus Serif")
#let font-code = ("JetBrains Mono NL", "Menlo")

// ---------------------------------------------------------------
// Komponen isi slide
// ---------------------------------------------------------------

/// Subjudul slide (padanan \framesubtitle), letakkan di baris pertama slide.
#let sub(body) = block(below: 0.8em, text(size: 0.8em, fill: bluegray, style: "italic", body))

/// Blok bergaya Beamer: header berwarna + isi berlatar terang.
#let blok(title: none, color: navy, body) = block(
  width: 100%,
  radius: 4pt,
  clip: true,
  stroke: 0.6pt + color.lighten(40%),
  above: 0.7em,
  below: 0.7em,
  {
    if title != none {
      block(
        width: 100%,
        fill: color,
        inset: (x: 0.7em, y: 0.4em),
        below: 0pt,
        text(fill: white, weight: "bold", size: 0.9em, title),
      )
    }
    block(width: 100%, fill: color.lighten(92%), inset: 0.7em, above: 0pt, body)
  },
)
#let alert-blok = blok.with(color: red)
#let contoh-blok = blok.with(color: teal)
#let emas-blok = blok.with(color: gold.darken(15%))

/// Dua kolom (default 1:1).
#let two-col(left, right, columns: (1fr, 1fr), gutter: 1.2em) = grid(
  columns: columns,
  column-gutter: gutter,
  align: top,
  left, right,
)

/// Badge kecil (mis. "Latihan", "Hands-on").
#let badge(body, color: gold) = box(
  fill: color,
  inset: (x: 0.45em, y: 0.2em),
  radius: 3pt,
  baseline: 0.2em,
  text(fill: white, weight: "bold", size: 0.7em, body),
)

/// Istilah bahasa Inggris (dicetak miring).
#let en(body) = emph(body)

/// Kotak angka besar untuk "hasil" perhitungan.
#let hasil(body) = box(
  fill: gold.lighten(75%),
  stroke: 0.8pt + gold,
  inset: (x: 0.4em, y: 0.25em),
  radius: 3pt,
  body,
)

// ---------------------------------------------------------------
// Slide khusus
// ---------------------------------------------------------------

/// Title slide ITERA.
#let itera-title-slide(..args) = touying-slide-wrapper(self => {
  self = utils.merge-dicts(
    self,
    config-common(freeze-slide-counter: true),
    config-page(margin: 0em, header: none, footer: none, fill: cream),
  )
  let info = self.info + args.named()
  let body = {
    // pita kiri navy
    place(left + top, rect(width: 34%, height: 100%, fill: navy))
    place(left + top, dx: 34%, rect(width: 0.6%, height: 100%, fill: gold))
    place(
      left + horizon,
      dx: 0%,
      box(width: 34%, align(center, {
        box(fill: white, radius: 50%, inset: 0.9em, image("../logos/itera_logo_trimmed.png", width: 3.2em))
        v(0.8em)
        text(fill: white, size: 0.62em, weight: "bold", tracking: 0.08em)[INSTITUT TEKNOLOGI SUMATERA]
      })),
    )
    place(
      left + horizon,
      dx: 39%,
      box(width: 56%, {
        text(fill: red, size: 0.6em, weight: "bold", tracking: 0.1em, upper(info.at("badge", default: "")))
        v(0.2em)
        text(font: font-head, fill: navy, size: 1.55em, weight: "bold", info.title)
        v(0.1em)
        line(length: 25%, stroke: 2.5pt + gold)
        v(0.2em)
        text(fill: navy2, size: 0.95em, info.subtitle)
        v(1.2em)
        set text(size: 0.68em, fill: darkgray)
        text(fill: navy, weight: "bold", size: 1.1em, info.author)
        linebreak()
        info.institution
        linebreak()
        utils.display-info-date(self)
        v(0.6em)
        text(fill: teal, weight: "bold", raw(info.at("url", default: "")))
      }),
    )
  }
  touying-slide(self: self, body)
})

/// Section slide dengan nomor bagian besar.
#let bagian = counter("itera-bagian")
#let itera-section-slide(config: (:), level: 1, numbered: true, body) = touying-slide-wrapper(self => {
  self = utils.merge-dicts(self, config-page(fill: navy, header: none, footer: none))
  let slide-body = {
    set std.align(horizon)
    show: pad.with(x: 12%)
    bagian.step()
    text(fill: gold, size: 0.8em, weight: "bold", tracking: 0.12em)[BAGIAN #context bagian.display()]
    v(0.2em)
    text(font: font-head, fill: white, size: 1.7em, weight: "bold", utils.display-current-heading(level: level, numbered: false))
    v(0.3em)
    line(length: 18%, stroke: 3pt + gold)
    body
  }
  touying-slide(self: self, config: config, slide-body)
})

/// Focus slide (padanan \standoutframe).
#let fokus(body) = focus-slide(background-color: navy, {
  set text(font: font-head, size: 0.95em)
  body
})

// ---------------------------------------------------------------
// Tema utama
// ---------------------------------------------------------------
#let itera-theme(..args, body) = {
  show: university-theme.with(
    aspect-ratio: "16-9",
    progress-bar: true,
    header: self => pad(left: 0.9em, text(size: 1.05em, utils.display-current-heading(level: 2, style: auto))),
    header-right: self => h(0.1em) + box(text(size: 0.75em, utils.display-current-heading(level: 1))) + h(0.4em) + box(image("../logos/itera_logo_trimmed.png", height: 1.1em), baseline: 0.25em) + h(0.9em),
    footer-columns: (25%, 1fr, 30%),
    footer-a: self => text(size: 1.5em, self.info.author),
    footer-b: self => text(size: 1.5em, if self.info.short-title == auto { self.info.title } else { self.info.short-title }),
    footer-c: self => text(size: 1.5em, {
      h(1fr)
      self.info.at("url", default: "")
      h(1fr)
      context utils.slide-counter.display() + " / " + utils.last-slide-number
      h(1fr)
    }),
    config-common(new-section-slide-fn: itera-section-slide),
    config-colors(
      primary: navy,
      secondary: navy2,
      tertiary: gold.darken(10%),
      neutral-lightest: white,
      neutral-darkest: rgb("#1A1A1A"),
    ),
    config-page(fill: cream, margin: (top: 2.9em, bottom: 1.6em, x: 1.6em)),
    config-methods(
      init: (self: none, body) => {
        set text(size: 20pt, font: font-body, lang: "id", fill: rgb("#1A1A1A"))
        set par(justify: false, leading: 0.62em)
        set list(marker: (text(fill: gold.darken(10%))[■], text(fill: teal)[▸]), spacing: 0.75em)
        set enum(numbering: n => text(fill: navy, weight: "bold")[#n.], spacing: 0.75em)
        set table(stroke: 0.5pt + navy.lighten(60%), inset: 0.45em)
        show heading.where(level: 3): set text(fill: navy, size: 1em)
        show strong: set text(fill: navy)
        show raw: set text(font: font-code)
        show raw.where(block: true): it => block(
          fill: navy.lighten(95%),
          stroke: (left: 3pt + teal),
          inset: 0.6em,
          radius: 2pt,
          width: 100%,
          text(size: 0.72em, it),
        )
        show link: it => text(fill: teal, underline(it))
        body
      },
      alert: (self: none, it) => text(fill: red, weight: "bold", it),
    ),
    ..args,
  )
  body
}

// ---------------------------------------------------------------
// Helper tambahan
// ---------------------------------------------------------------

/// Isian warna tabel: header navy + baris zebra.
#let tbl-fill = (_, y) => if y == 0 { navy } else if calc.even(y) { navy.lighten(93%) } else { white }
/// Sel header tabel (teks putih tebal).
#let th(body) = text(fill: white, weight: "bold", body)

/// Diagram alur horizontal: kotak-kotak dihubungkan panah.
#let flow(..steps, fill: navy, height: 3.4em, size: 0.72em) = {
  let items = steps.pos()
  let fills = if type(fill) == array { fill } else { items.map(_ => fill) }
  let cells = ()
  for (i, s) in items.enumerate() {
    if i > 0 { cells.push(align(center + horizon, text(fill: gold.darken(10%), size: 1.3em, sym.arrow.r))) }
    cells.push(block(
      fill: fills.at(i),
      radius: 4pt,
      inset: 0.4em,
      width: 100%,
      height: 100%,
      align(center + horizon, {
        show strong: it => text(fill: white, weight: "bold", it.body)
        text(fill: white, size: size, s)
      }),
    ))
  }
  grid(
    columns: items.map(_ => 1fr).intersperse(1.4em),
    rows: (height,),
    ..cells,
  )
}

/// Kartu isi dengan garis warna di atas.
#let kartu(title, body, color: navy, nomor: none, height: 100%) = block(
  fill: white,
  stroke: (top: 3pt + color, rest: 0.5pt + color.lighten(70%)),
  inset: 0.65em,
  radius: 3pt,
  width: 100%,
  height: height,
  {
    if nomor != none {
      box(fill: color, radius: 50%, width: 1.3em, height: 1.3em, align(center + horizon, text(fill: white, weight: "bold", size: 0.75em, str(nomor))))
      h(0.4em)
    }
    text(weight: "bold", fill: color, size: 0.9em, title)
    v(0.2em)
    set text(size: 0.74em)
    body
  },
)
