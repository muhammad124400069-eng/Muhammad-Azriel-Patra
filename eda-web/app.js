/* EDA NSL-KDD — semua grafik digambar dengan SVG murni (tanpa pustaka, bisa dijalankan offline).
   Data ada di window.EDA (data.js, dibuat oleh build_data.py). */
(() => {
"use strict";

const E = window.EDA;
const CATS = E.categories;                       // Normal, DoS, Probe, R2L, U2R
const key = (c) => c.toLowerCase();
const $ = (id) => document.getElementById(id);

// ---------------------------------------------------------------- format angka (locale Indonesia)
const nf = new Intl.NumberFormat("id-ID");
const fmtN = (n) => nf.format(n);
const fmtD = (x, d = 1) => x.toLocaleString("id-ID", { minimumFractionDigits: d, maximumFractionDigits: d });
const fmtPct = (x, d = 1) => fmtD(x, d) + "%";
const fmtSigned = (x, d = 2) => (x >= 0 ? "+" : "−") + fmtD(Math.abs(x), d);
const SUP = "⁰¹²³⁴⁵⁶⁷⁸⁹";
const sup = (n) => String(n).split("").map((c) => SUP[+c]).join("");
function fmtShort(v) {
  if (v == null) return "—";
  const a = Math.abs(v);
  if (a >= 1e6) { const e = Math.floor(Math.log10(a)); return fmtD(v / 10 ** e, 2) + "×10" + sup(e); }
  if (Number.isInteger(v)) return fmtN(v);
  return fmtD(v, a < 1 ? 3 : 2);
}
function compactId(v) {
  if (v >= 1e9) return fmtD(v / 1e9, v % 1e9 ? 1 : 0) + " mlr";
  if (v >= 1e6) return fmtD(v / 1e6, v % 1e6 ? 1 : 0) + " jt";
  if (v >= 1e3) return fmtD(v / 1e3, v % 1e3 ? 1 : 0) + " rb";
  return fmtD(v, Number.isInteger(v) ? 0 : 1);
}

// ---------------------------------------------------------------- DOM
const SVGNS = "http://www.w3.org/2000/svg";
function make(ns, tag, attrs, kids) {
  const n = ns ? document.createElementNS(ns, tag) : document.createElement(tag);
  for (const [k, v] of Object.entries(attrs || {})) {
    if (v == null || v === false) continue;
    if (k === "text") n.textContent = v;
    else if (k.startsWith("on") && typeof v === "function") n.addEventListener(k.slice(2), v);
    else n.setAttribute(k, v === true ? "" : v);
  }
  for (const c of kids.flat(Infinity)) {
    if (c == null || c === false) continue;
    n.append(c.nodeType ? c : document.createTextNode(String(c)));
  }
  return n;
}
const h = (tag, attrs, ...kids) => make(null, tag, attrs, kids);
const s = (tag, attrs, ...kids) => make(SVGNS, tag, attrs, kids);
const code = (t) => h("code", { text: t });

// ---------------------------------------------------------------- tooltip (satu elemen, isi dibuat dengan textContent)
const tipEl = $("tip");
function showTip(x, y, c) {
  tipEl.replaceChildren(
    h("div", { class: "tt", text: c.title }),
    ...(c.rows || []).map((r) =>
      h("div", { class: "tr" }, r.color ? h("i", { style: `background:${r.color}` }) : null,
        h("span", { class: "tl", text: r.label }), h("span", { class: "tv", text: r.value }))),
  );
  tipEl.classList.add("show");
  const w = tipEl.offsetWidth, hh = tipEl.offsetHeight;
  let left = x + 16, top = y + 16;
  if (left + w > innerWidth - 8) left = x - w - 16;
  if (top + hh > innerHeight - 8) top = y - hh - 16;
  tipEl.style.left = Math.max(8, left) + "px";
  tipEl.style.top = Math.max(8, top) + "px";
}
const hideTip = () => tipEl.classList.remove("show");
/** Pasang tooltip pada node: pointer (hover) dan fokus keyboard. */
function tip(node, get, focusable = false) {
  node.addEventListener("pointermove", (e) => showTip(e.clientX, e.clientY, get(e)));
  node.addEventListener("pointerleave", hideTip);
  if (focusable) {
    node.setAttribute("tabindex", "0");
    node.addEventListener("focus", () => { const b = node.getBoundingClientRect(); showTip(b.left + 20, b.top, get({})); });
    node.addEventListener("blur", hideTip);
  }
}
addEventListener("scroll", hideTip, { passive: true });

// ---------------------------------------------------------------- mount responsif
function mount(root, draw) {
  // Satu observer per elemen: pemanggilan ulang hanya mengganti fungsi gambar (hindari grafik basi menimpa yang baru).
  if (root._mount) { root._mount.draw = draw; root._mount.redraw(); return root._mount; }
  const m = { draw, w: 0, redraw() { m.w = 0; render(); } };
  const render = () => {
    const nw = Math.floor(root.clientWidth);
    if (!nw || nw === m.w) return;
    m.w = nw;
    hideTip();
    root.replaceChildren(m.draw(nw));
  };
  root._mount = m;
  new ResizeObserver(render).observe(root);
  render();
  return m;
}

// ---------------------------------------------------------------- kontrol
function segmented(root, options, initial, onChange) {
  let cur = initial;
  const draw = () => root.replaceChildren(...options.map(([v, label]) =>
    h("button", { type: "button", text: label, "aria-pressed": v === cur ? "true" : "false",
      onclick: () => { if (v === cur) return; cur = v; draw(); onChange(v); } })));
  draw();
  return { set(v) { cur = v; draw(); }, get: () => cur };
}

/** Lihat sebagai tabel: setiap nilai pada grafik juga tersedia tanpa tooltip. */
function tableView(root, headers, rows, numFrom = 1) {
  root.replaceChildren(h("details", { class: "tv-details" },
    h("summary", { text: "Lihat sebagai tabel" }),
    h("div", { class: "tablewrap" }, h("table", {},
      h("thead", {}, h("tr", {}, headers.map((t, i) => h("th", { class: i >= numFrom ? "num" : "", text: t })))),
      h("tbody", {}, rows.map((r) => h("tr", {}, r.map((c, i) => h("td", { class: i >= numFrom ? "num" : "", text: c })))))))));
}

// ---------------------------------------------------------------- skala & sumbu
function niceTicks(max, n = 5) {
  if (max <= 0) return [0];
  const raw = max / n, p = 10 ** Math.floor(Math.log10(raw)), f = raw / p;
  const step = (f <= 1 ? 1 : f <= 2 ? 2 : f <= 5 ? 5 : 10) * p;
  const out = [];
  for (let v = 0; ; v += step) { out.push(+v.toFixed(10)); if (v >= max - step * 0.001) break; }  // tick terakhir >= max
  return out;
}
const textW = (str, px = 6.9) => Math.ceil(String(str).length * px);

/** Batang dengan ujung-data membulat 4px dan pangkal rata. */
function barPath(x, y, w, hgt, r = 4) {
  r = Math.min(r, w, hgt / 2);
  return `M${x} ${y}H${x + w - r}Q${x + w} ${y} ${x + w} ${y + r}V${y + hgt - r}Q${x + w} ${y + hgt} ${x + w - r} ${y + hgt}H${x}Z`;
}
function barPathL(x, y, w, hgt, r = 4) { // tumbuh ke kiri dari pangkal x
  r = Math.min(r, w, hgt / 2);
  return `M${x} ${y}H${x - w + r}Q${x - w} ${y} ${x - w} ${y + r}V${y + hgt - r}Q${x - w} ${y + hgt} ${x - w + r} ${y + hgt}H${x}Z`;
}

// =================================================================================================
// Grafik batang horizontal (skala linear/log). rows: {label, value, cls|fill, text, tip}
// =================================================================================================
function hbar(root, rows, o = {}) {
  const barH = o.barH || 14, gap = o.gap || 7;
  const labelW0 = o.labelW || Math.max(...rows.map((r) => textW(r.label))) + 14;
  const valueW0 = o.valueW || Math.max(...rows.map((r) => textW(r.text || ""))) + 14;
  return mount(root, (w) => {
    const narrow = w < labelW0 + valueW0 + 200;          // label di atas batang bila ruang sempit
    const labelW = narrow ? 0 : labelW0, valueW = valueW0;
    const rowH = narrow ? barH + 22 : barH + gap, off = narrow ? 14 : 0;
    const plotW = Math.max(100, w - labelW - valueW);
    const max = o.max, lo = o.log ? 0.5 : 0;
    const xOf = (v) => o.log
      ? (Math.log10(Math.max(v, lo)) - Math.log10(lo)) / (Math.log10(max) - Math.log10(lo)) * plotW
      : (v / max) * plotW;
    const extra = rows.filter((r) => r.gapBefore).length * 10;
    const H = rows.length * rowH + extra + 28;
    const svg = s("svg", { width: w, height: H, role: "img", "aria-label": o.aria || "Grafik batang" });
    let ticks = o.ticks || niceTicks(max);
    if (narrow && ticks.length > 6) ticks = ticks.filter((_, i) => i % 2 === 0);
    ticks.forEach((t) => {
      const x = labelW + xOf(t);
      svg.append(s("line", { class: "gl", x1: x, x2: x, y1: 0, y2: H - 22 }),
        s("text", { class: "ax", x, y: H - 6, "text-anchor": "middle", text: o.tickFmt ? o.tickFmt(t) : fmtN(t) }));
    });
    svg.append(s("line", { class: "bl", x1: labelW, x2: labelW, y1: 0, y2: H - 22 }));
    let y = 2;
    for (const r of rows) {
      if (r.gapBefore) y += 10;
      const by = y + off, bw = Math.max(r.value > 0 ? 2 : 0, xOf(r.value));
      const g = s("g", { class: "row" });
      g.append(
        narrow ? s("text", { class: "lbl", x: 0, y: y + 10, text: r.label })
          : s("text", { class: "lbl", x: labelW - 10, y: by + barH / 2 + 4, "text-anchor": "end", text: r.label }),
        s("path", { class: `mark ${r.cls || ""}`, d: barPath(labelW, by, bw, barH), style: r.fill ? `fill:${r.fill}` : null, opacity: r.opacity || null }),
        s("text", { class: "val", x: labelW + bw + 8, y: by + barH / 2 + 4, text: r.text }),
        s("rect", { class: "hit", x: 0, y: y - gap / 2, width: w, height: rowH }),
      );
      tip(g, () => r.tip || { title: r.label, rows: [{ label: o.unit || "Nilai", value: r.text }] }, rows.length <= 20);
      svg.append(g);
      y += rowH;
    }
    return svg;
  });
}

// =================================================================================================
// Batang 100% bertumpuk per baris. rows: {label, total, values[]}; series: CATS
// =================================================================================================
let clipId = 0;
function stackedShare(root, rows, o = {}) {
  const series = o.series || CATS.map((c) => ({ name: c, cls: key(c), color: `var(--c-${key(c)})` }));
  const barH = o.barH || 20;
  const labelW0 = Math.max(...rows.map((r) => textW(r.label))) + 14;
  const nW0 = Math.max(...rows.map((r) => textW("n=" + fmtN(r.total)))) + 12;
  return mount(root, (w) => {
    const narrow = w < labelW0 + nW0 + 260;              // label & n di atas batang bila sempit
    const labelW = narrow ? 0 : labelW0, nW = narrow ? 0 : nW0;
    const rowH = narrow ? barH + 26 : barH + 9, off = narrow ? 15 : 0;
    const plotW = Math.max(160, w - labelW - nW);
    const H = rows.length * rowH + 26;
    const svg = s("svg", { width: w, height: H, role: "img", "aria-label": o.aria || "Komposisi kategori" });
    [0, 25, 50, 75, 100].forEach((t) => {
      const x = labelW + plotW * t / 100;
      svg.append(s("line", { class: "gl", x1: x, x2: x, y1: 0, y2: H - 22 }),
        s("text", { class: "ax", x, y: H - 6, "text-anchor": t === 0 && narrow ? "start" : t === 100 && narrow ? "end" : "middle", text: t + "%" }));
    });
    let y = 2;
    for (const r of rows) {
      const g = s("g", { class: "row" });
      const by = y + off, id = "cp" + (++clipId);
      g.append(s("clipPath", { id }, s("rect", { x: labelW, y: by, width: plotW, height: barH, rx: 4 })));
      if (narrow) g.append(s("text", { class: "lbl", x: 0, y: y + 10, text: r.label }),
        s("text", { class: "ax", x: w, y: y + 10, "text-anchor": "end", text: "n=" + fmtN(r.total) }));
      else g.append(s("text", { class: "lbl", x: labelW - 10, y: by + barH / 2 + 4, "text-anchor": "end", text: r.label }));
      const bars = s("g", { "clip-path": `url(#${id})` });
      let x = labelW;
      r.values.forEach((v, i) => {
        const sw = plotW * v / r.total;
        if (sw <= 0) return;
        bars.append(s("rect", { class: `mark ${series[i].cls ? "c-" + series[i].cls : ""}`, style: series[i].cls ? null : `fill:${series[i].color}`,
          x, y: by, width: Math.max(0, sw - 1), height: barH }));
        const p = 100 * v / r.total;
        if (sw >= 40) bars.append(s("text", { class: `on-seg ${series[i].cls ? "t-" + series[i].cls : ""}`, x: x + sw / 2, y: by + barH / 2 + 4,
          "text-anchor": "middle", text: Math.round(p) + "%" }));
        x += sw;
      });
      g.append(bars);
      if (!narrow) g.append(s("text", { class: "ax", x: labelW + plotW + 8, y: by + barH / 2 + 4, text: "n=" + fmtN(r.total) }));
      g.append(s("rect", { class: "hit", x: 0, y: y - 4, width: w, height: rowH }));
      tip(g, () => ({
        title: `${r.label} · n=${fmtN(r.total)}`,
        rows: series.map((se, i) => ({ color: se.color, label: se.name, value: `${fmtPct(100 * r.values[i] / r.total, r.values[i] && r.values[i] / r.total < 0.001 ? 2 : 1)} (${fmtN(r.values[i])})` })),
      }), rows.length <= 20);
      svg.append(g);
      y += rowH;
    }
    return svg;
  });
}

// =================================================================================================
// 0. Waffle: seluruh dataset, 1 kotak ≈ N koneksi
// =================================================================================================
function initWaffle() {
  const N = 1260;
  let ds = "train", hl = null;
  const counts = (d) => CATS.map((c) => E.categoryCounts[d][c] || 0);
  function apportion(cs) {
    const tot = cs.reduce((a, b) => a + b, 0);
    const cells = cs.map((c) => (c ? Math.max(1, Math.floor(c * N / tot)) : 0));
    let diff = N - cells.reduce((a, b) => a + b, 0);
    const rem = cs.map((c, i) => [c * N / tot - Math.floor(c * N / tot), i]).sort((a, b) => b[0] - a[0]);
    for (let k = 0; diff > 0; k++, diff--) cells[rem[k % rem.length][1]]++;
    while (diff < 0) { cells[cells.indexOf(Math.max(...cells))]--; diff++; }
    return cells;
  }
  const dsOpts = [["train", "KDDTrain+"], ["test", "KDDTest+"]];
  const seg = segmented($("waffle-ds"), dsOpts, ds, (v) => { ds = v; hl = null; draw(); });

  const chart = mount($("waffle"), (w) => {
    const cs = counts(ds), cells = apportion(cs), tot = E.sizes[ds];
    const cols = w >= 560 ? 60 : w >= 380 ? 42 : 30, rowsN = Math.ceil(N / cols);
    const gap = 2, cs_ = Math.floor((w - gap * (cols - 1)) / cols);
    const svg = s("svg", { width: w, height: rowsN * (cs_ + gap), role: "img",
      "aria-label": "Komposisi kategori koneksi, satu kotak mewakili sekitar " + fmtN(Math.round(tot / N)) + " koneksi" });
    svg.classList.add("waffle");
    svg.classList.toggle("dim", hl !== null);
    let idx = 0;
    cells.forEach((n, ci) => {
      for (let k = 0; k < n; k++, idx++) {
        const r = Math.floor(idx / cols), c = idx % cols;
        const rect = s("rect", { class: `cell c-${key(CATS[ci])}${hl === ci ? " on" : ""}`, x: c * (cs_ + gap), y: r * (cs_ + gap),
          width: cs_, height: cs_, rx: 2, style: `animation-delay:${Math.round(idx * 0.7)}ms` });
        tip(rect, () => ({ title: CATS[ci], rows: [
          { color: `var(--c-${key(CATS[ci])})`, label: "Koneksi", value: fmtN(cs[ci]) },
          { label: "Persentase", value: fmtPct(100 * cs[ci] / tot, cs[ci] / tot < 0.01 ? 2 : 1) }] }));
        svg.append(rect);
      }
    });
    return svg;
  });

  function draw() {
    const cs = counts(ds), tot = E.sizes[ds];
    $("cellsize").textContent = fmtN(Math.round(E.sizes.train / N)) + " koneksi pada data latih atau " + fmtN(Math.round(E.sizes.test / N)) + " pada data uji";
    $("waffle-note").textContent = `${fmtN(tot)} koneksi · 1 kotak ≈ ${fmtN(Math.round(tot / N))} koneksi`;
    $("waffle-legend").replaceChildren(...CATS.map((c, i) => h("button", { type: "button", class: "lg", "aria-pressed": hl === i ? "true" : "false",
      title: "Sorot kategori ini",
      onclick: () => { hl = hl === i ? null : i; draw(); } },
      h("i", { style: `background:var(--c-${key(c)})` }), c, " ", h("b", { text: fmtPct(100 * cs[i] / tot, cs[i] / tot < 0.01 ? 2 : 1) }))));
    chart.redraw();
    tableView($("waffle-tv"), ["Kategori", "Koneksi", "Persentase"], CATS.map((c, i) => [c, fmtN(cs[i]), fmtPct(100 * cs[i] / tot, 2)]));
  }
  draw();
}

// =================================================================================================
// 1. Struktur data
// =================================================================================================
function initStruct() {
  const labTrain = Object.values(E.labels).filter((l) => l.train > 0).length;
  const labTest = Object.values(E.labels).filter((l) => l.test > 0).length;
  const tile = (l, n, d) => h("div", { class: "tile" }, h("p", { class: "tl", text: l }), h("p", { class: "tn", text: n }), h("p", { class: "td", text: d }));
  $("tiles-struct").replaceChildren(
    tile("Koneksi latih (KDDTrain+)", fmtN(E.sizes.train), `uji ${fmtN(E.sizes.test)} · rasio ${fmtD(E.sizes.train / E.sizes.test)} : 1`),
    tile("Fitur koneksi", String(E.nFeatures), `${E.categorical.length} kategorikal, ${E.numericCount} numerik (${E.binary.length} di antaranya biner)`),
    tile("Jenis label", String(labTrain), `di data latih; data uji memuat ${labTest} jenis, 4 kategori serangan`),
  );

  // --- kelompok fitur + filter kamus
  const dict = { group: null, type: "all", q: "", sort: "order", dir: 1 };
  const order = Object.keys(E.features);
  const gEl = $("groups");
  const drawGroups = () => gEl.replaceChildren(h("div", { style: "display:grid;grid-template-columns:repeat(auto-fit,minmax(190px,1fr));gap:12px" },
    E.groups.map((g, i) => h("button", { type: "button", "aria-pressed": dict.group === g.name ? "true" : "false",
      style: `text-align:left;font:inherit;color:var(--ink);cursor:pointer;border-radius:10px;padding:12px 14px;background:${dict.group === g.name ? "var(--hover)" : "var(--surface)"};border:1px solid ${dict.group === g.name ? "var(--accent)" : "var(--line)"}`,
      onclick: () => { dict.group = dict.group === g.name ? null : g.name; drawGroups(); drawDict(); } },
      h("div", { style: "font:600 12px var(--mono);color:var(--muted)" }, `kolom ${order.indexOf(g.cols[0]) + 1}–${order.indexOf(g.cols[g.cols.length - 1]) + 1}`),
      h("div", { style: "font:600 17px var(--cond);margin:2px 0 4px" }, g.name),
      h("div", { style: "font-size:13px;color:var(--ink2)" }, `${g.cols.length} fitur: `, g.cols.slice(0, 3).join(", "), ", …"),
      h("div", { style: "font-size:12.5px;color:var(--muted);margin-top:6px" }, GROUP_NOTE[g.name])))));
  const GROUP_NOTE = {
    "Dasar": "Header koneksi TCP/IP: durasi, protokol, layanan, jumlah byte.",
    "Konten": "Isi payload: gagal login, akses root, pembuatan file.",
    "Trafik (2 detik)": "Statistik koneksi ke host/layanan yang sama dalam 2 detik terakhir.",
    "Trafik (host tujuan)": "Statistik 100 koneksi terakhir ke host tujuan yang sama.",
  };
  drawGroups();

  // --- kamus fitur
  const cols = [
    ["name", "Fitur", false], ["group", "Kelompok", false], ["kind", "Tipe", false], ["unique", "Nilai unik", true],
    ["min", "Min", true], ["median", "Median", true], ["max", "Maks", true], ["zero", "% nol", true], ["corr", "Korelasi (r)", false],
  ];
  const typeOpts = [["all", "Semua"], ["numerik", "Numerik"], ["biner", "Biner"], ["kategorikal", "Kategorikal"]];
  segmented($("dict-type"), typeOpts, "all", (v) => { dict.type = v; drawDict(); });
  $("dict-q").addEventListener("input", (e) => { dict.q = e.target.value.trim().toLowerCase(); drawDict(); });
  function drawDict() {
    let rows = order.map((name, i) => ({ name, order: i, ...E.features[name] }));
    if (dict.group) rows = rows.filter((r) => r.group === dict.group);
    if (dict.type !== "all") rows = rows.filter((r) => r.kind === dict.type);
    if (dict.q) rows = rows.filter((r) => r.name.includes(dict.q));
    const k = dict.sort;
    rows.sort((a, b) => {
      const x = a[k], y = b[k];
      if (x == null && y == null) return 0;
      if (x == null) return 1;
      if (y == null) return -1;
      return (typeof x === "string" ? x.localeCompare(y) : x - y) * dict.dir;
    });
    $("dict").replaceChildren(
      h("thead", {}, h("tr", {}, cols.map(([c, t, num]) => h("th", { class: num ? "num" : "", "aria-sort": dict.sort === c ? (dict.dir > 0 ? "ascending" : "descending") : null },
        h("button", { type: "button", text: t, onclick: () => { dict.dir = dict.sort === c ? -dict.dir : 1; dict.sort = c; drawDict(); } }))))),
      h("tbody", {}, rows.length ? rows.map((r) => {
        const cat = r.kind === "kategorikal";
        const cr = r.corr;
        return h("tr", {},
          h("td", { class: "mono", text: r.name }), h("td", { text: r.group }), h("td", { text: r.kind }),
          h("td", { class: "num", text: fmtN(r.unique) }),
          h("td", { class: "num", text: cat ? "—" : fmtShort(r.min) }), h("td", { class: "num", text: cat ? "—" : fmtShort(r.median) }),
          h("td", { class: "num", text: cat ? "—" : fmtShort(r.max) }), h("td", { class: "num", text: cat ? "—" : fmtD(r.zero, r.zero > 99 ? 2 : 1) }),
          h("td", {}, cr == null ? h("span", { class: "muted", text: cat ? "—" : "konstan" }) : h("span", { class: "mono" },
            h("span", { class: "minibar" }, h("b", { style: `background:var(--${cr >= 0 ? "pos" : "neg"});width:${Math.abs(cr) * 50}%;left:${cr >= 0 ? 50 : 50 - Math.abs(cr) * 50}%` })), fmtSigned(cr))));
      }) : h("tr", {}, h("td", { colspan: cols.length, class: "muted", text: "Tidak ada fitur yang cocok dengan filter ini." }))));
  }
  drawDict();

  // --- contoh baris
  const S = E.sample, sc = S.cols;
  const st = { q: "", cat: "all", page: 0 }, PER = 12;
  $("rows-cat").replaceChildren(h("option", { value: "all", text: "Semua kategori" }), ...CATS.map((c) => h("option", { value: c, text: c })));
  $("rows-cat").addEventListener("change", (e) => { st.cat = e.target.value; st.page = 0; drawRows(); });
  $("rows-q").addEventListener("input", (e) => { st.q = e.target.value.trim().toLowerCase(); st.page = 0; drawRows(); });
  const ci = Object.fromEntries(sc.map((c, i) => [c, i]));
  const numCols = new Set(["duration", "src_bytes", "dst_bytes", "count", "serror_rate", "same_srv_rate", "logged_in"]);
  function drawRows() {
    const rows = S.rows.filter((r) => (st.cat === "all" || r[ci.category] === st.cat) &&
      (!st.q || r[ci.service].includes(st.q) || r[ci.label].includes(st.q)));
    const pages = Math.max(1, Math.ceil(rows.length / PER));
    st.page = Math.min(st.page, pages - 1);
    const view = rows.slice(st.page * PER, (st.page + 1) * PER);
    $("rows").replaceChildren(
      h("thead", {}, h("tr", {}, sc.map((c) => h("th", { class: numCols.has(c) ? "num" : "", text: c })))),
      h("tbody", {}, view.length ? view.map((r) => h("tr", {}, r.map((v, i) => {
        const c = sc[i];
        if (c === "category") return h("td", {}, h("span", { class: `dot k-${key(v)}` }), v);
        return h("td", { class: numCols.has(c) ? "num" : (c === "label" || c === "service" ? "mono" : ""), text: typeof v === "number" ? (Number.isInteger(v) ? fmtN(v) : fmtD(v, 2)) : v });
      }))) : h("tr", {}, h("td", { colspan: sc.length, class: "muted", text: "Tidak ada baris yang cocok. Coba kata kunci lain atau ganti kategori." }))));
    $("rows-pager").replaceChildren(
      h("button", { type: "button", text: "← Sebelumnya", disabled: st.page === 0, onclick: () => { st.page--; drawRows(); } }),
      h("button", { type: "button", text: "Berikutnya →", disabled: st.page >= pages - 1, onclick: () => { st.page++; drawRows(); } }),
      h("span", { class: "sp", text: `${fmtN(rows.length)} baris · halaman ${st.page + 1} dari ${pages}` }));
  }
  drawRows();
}

// =================================================================================================
// 2. Kualitas
// =================================================================================================
function initQuality() {
  const q = E.quality;
  const tile = (l, n, d) => h("div", { class: "tile" }, h("p", { class: "tl", text: l }), h("p", { class: "tn", text: n }), h("p", { class: "td", text: d }));
  $("tiles-quality").replaceChildren(
    tile("Missing value", fmtN(q.train.missing + q.test.missing), "di data latih maupun uji"),
    tile("Baris duplikat", fmtN(q.train.duplicates + q.test.duplicates), "masalah utama KDD Cup 99 yang diperbaiki di NSL-KDD"),
    tile("Fitur konstan", String(E.constant.length), E.constant.join(", ") + " selalu bernilai 0"),
  );
  const rows = Object.entries(E.features).filter(([, f]) => f.zero != null && f.zero > 50).sort((a, b) => b[1].zero - a[1].zero)
    .map(([name, f]) => ({ label: name, value: f.zero, fill: "var(--seq)", text: fmtPct(f.zero, f.zero > 99 ? 2 : 1),
      tip: { title: name, rows: [{ label: "Baris bernilai 0", value: fmtPct(f.zero, 2) }] } }));
  hbar($("zeros"), rows, { max: 100, ticks: [0, 25, 50, 75, 100], tickFmt: (t) => t + "%", aria: "Persentase nol per fitur" });
}

// =================================================================================================
// 3. Label
// =================================================================================================
function initLabels() {
  const info = {
    Normal: ["Koneksi wajar", "normal"],
    DoS: ["Denial of Service: membanjiri layanan", "neptune (SYN flood), smurf"],
    Probe: ["Memindai jaringan mencari celah", "portsweep, ipsweep, nmap, satan"],
    R2L: ["Remote to Local: masuk dari luar tanpa akun sah", "guess_passwd, warezclient"],
    U2R: ["User to Root: menaikkan hak akses menjadi root", "buffer_overflow, rootkit"],
  };
  const kinds = (c) => Object.values(E.labels).filter((l) => l.category === c && l.train > 0).length;
  $("cat-table").replaceChildren(...CATS.map((c) => h("tr", {},
    h("td", {}, h("span", { class: `dot k-${key(c)}` }), h("b", { text: c }), h("span", { class: "muted", text: `  ${kinds(c)} jenis di data latih` })),
    h("td", { class: "wrapc", text: info[c][0] }),
    h("td", { class: "wrapc mono", text: info[c][1] }))));

  // --- jenis label
  let ds = "train", cat = "all";
  segmented($("lab-ds"), [["train", "KDDTrain+"], ["test", "KDDTest+"]], ds, (v) => { ds = v; draw(); });
  segmented($("lab-cat"), [["all", "Semua"], ...CATS.map((c) => [c, c])], cat, (v) => { cat = v; draw(); });
  let chart = null;
  function draw() {
    const rows = Object.entries(E.labels).filter(([, l]) => l[ds] > 0 && (cat === "all" || l.category === cat))
      .sort((a, b) => b[1][ds] - a[1][ds]);
    const tot = E.sizes[ds];
    const mk = (name, l) => {
      const isNew = ds === "test" && l.train === 0;
      return { label: name, value: l[ds], cls: "c-" + key(l.category), text: fmtN(l[ds]) + (isNew ? "  baru" : ""),
        tip: { title: name, rows: [{ color: `var(--c-${key(l.category)})`, label: "Kategori", value: l.category },
          { label: "Jumlah record", value: fmtN(l[ds]) }, { label: "Persentase", value: fmtPct(100 * l[ds] / tot, 2) },
          ...(isNew ? [{ label: "Status", value: "tidak ada di data latih" }] : [])] } };
    };
    $("lab-sub").textContent = `${rows.length} jenis label di ${ds === "train" ? "KDDTrain+" : "KDDTest+"}` +
      (ds === "test" ? ". Tanda “baru” berarti jenis itu tidak ada di data latih." : ".");
    hbar($("labels"), rows.map(([n, l]) => mk(n, l)), { max: 1e5, log: true, ticks: [1, 10, 100, 1e3, 1e4, 1e5], tickFmt: compactId, unit: "Record", aria: "Jumlah record per jenis label (skala log)" });
    tableView($("labels-tv"), ["Label", "Kategori", "Record"], rows.map(([n, l]) => [n, l.category, fmtN(l[ds])]), 2);
  }
  draw();

  // --- proporsi kategori
  const pr = [];
  CATS.forEach((c, i) => ["train", "test"].forEach((d, j) => {
    const n = E.categoryCounts[d][c] || 0, p = 100 * n / E.sizes[d];
    pr.push({ label: `${c} · ${d === "train" ? "latih" : "uji"}`, value: p, cls: "c-" + key(c), opacity: d === "test" ? 0.5 : null, gapBefore: i > 0 && j === 0,
      text: fmtPct(p, p < 1 ? 2 : 1) + `  (${fmtN(n)})`,
      tip: { title: `${c} di ${d === "train" ? "KDDTrain+" : "KDDTest+"}`, rows: [{ label: "Record", value: fmtN(n) }, { label: "Persentase", value: fmtPct(p, 2) }] } });
  }));
  hbar($("catshare"), pr, { max: 60, ticks: [0, 10, 20, 30, 40, 50, 60], tickFmt: (t) => t + "%", aria: "Proporsi kategori, latih dan uji" });
  tableView($("catshare-tv"), ["Kategori", "Latih (record)", "Latih (%)", "Uji (record)", "Uji (%)"], CATS.map((c) => {
    const a = E.categoryCounts.train[c] || 0, b = E.categoryCounts.test[c] || 0;
    return [c, fmtN(a), fmtPct(100 * a / E.sizes.train, 2), fmtN(b), fmtPct(100 * b / E.sizes.test, 2)];
  }));

  const cc = E.categoryCounts, T = E.sizes.train, U = E.sizes.test;
  const share = (d, c) => 100 * (cc[d][c] || 0) / E.sizes[d];
  $("f-imbalance").replaceChildren(
    h("li", {}, "Kelas ", h("strong", { text: "sangat tidak seimbang" }), `: U2R hanya ${fmtPct(share("train", "U2R"), 2)} data latih (${cc.train.U2R} dari ${fmtN(T)} record).`),
    h("li", {}, `Model “malas” yang selalu menebak normal sudah mendapat akurasi sekitar ${fmtD(100 * E.binaryShare.train[0] / T, 0)}% di data latih. Karena itu evaluasi juga memakai `, h("em", { text: "precision" }), ", ", h("em", { text: "recall" }), ", dan F1, bukan akurasi saja."),
    h("li", {}, `Proporsi kategori `, h("strong", { text: "berbeda" }), ` antara latih dan uji: R2L naik dari ${fmtPct(share("train", "R2L"))} menjadi ${fmtPct(share("test", "R2L"))}, U2R dari ${fmtPct(share("train", "U2R"), 2)} menjadi ${fmtPct(share("test", "U2R"))}. Data uji sengaja dibuat lebih menantang.`));

  // --- serangan baru
  const na = E.newAttacks;
  $("newatk-h").textContent = `${na.names.length} jenis serangan baru · ${fmtN(na.records)} record (${fmtPct(na.share)} data uji)`;
  $("newatk").replaceChildren(...na.names.map((n) => ({ n, l: E.labels[n] })).sort((a, b) => b.l.test - a.l.test).map(({ n, l }) =>
    h("span", { class: "chip" }, h("i", { style: `background:var(--c-${key(l.category)})` }), `${n} ${fmtN(l.test)}`)));
  $("newatk-p").textContent = `Hampir 1 dari 6 koneksi di data uji berasal dari serangan yang tidak ada di data latih. Ini meniru kondisi nyata: penyerang selalu membuat teknik baru. Model yang baik harus menggeneralisasi pola serangan, bukan menghafal namanya.`;

  // --- label biner
  const bs = E.binaryShare;
  const brows = ["train", "test"].map((d) => ({ label: d === "train" ? "KDDTrain+" : "KDDTest+", total: E.sizes[d], values: bs[d] }));
  stackedShare($("binary"), brows, { series: [
    { name: "Normal (0)", color: "var(--c-normal)", cls: "normal" }, { name: "Serangan (1)", color: "var(--attack)", cls: null }], aria: "Proporsi normal dan serangan" });
  $("binary-p").replaceChildren(`Setelah digabung, kelas biner cukup seimbang (${fmtD(100 * bs.train[0] / T, 1)} : ${fmtD(100 * bs.train[1] / T, 1)} di data latih, ${fmtD(100 * bs.test[0] / U, 1)} : ${fmtD(100 * bs.test[1] / U, 1)} di data uji). Meski begitu, `, code("train.py"), " tetap memakai ", code("stratify"), " saat memisahkan data validasi agar proporsi ini terjaga.");
}

// =================================================================================================
// 4. Fitur kategorikal
// =================================================================================================
function initCategorical() {
  const st = { f: "protocol_type", ds: "train", all: false };
  const TOP = 15;
  segmented($("cf-feature"), E.categorical.map((c) => [c, c]), st.f, (v) => { st.f = v; st.all = false; draw(); });
  segmented($("cf-ds"), [["train", "KDDTrain+"], ["test", "KDDTest+"]], st.ds, (v) => { st.ds = v; draw(); });
  $("cf-legend").replaceChildren(...CATS.map((c) => h("span", { class: "lg" }, h("i", { style: `background:var(--c-${key(c)})` }), c)));
  $("cf-more").addEventListener("click", () => { st.all = !st.all; draw(); });
  const desc = { protocol_type: "Protokol lapisan transport.", service: "Layanan jaringan tujuan (port).", flag: "Status koneksi TCP: apakah dibuka dan ditutup dengan benar." };

  function draw() {
    const ct = E.crosstab[st.f][st.ds];
    let entries = Object.entries(ct);
    const total = entries.length;
    const limited = st.f === "service" && !st.all;
    if (limited) entries = entries.slice(0, TOP);
    const rows = entries.map(([k, v]) => ({ label: k, total: v.reduce((a, b) => a + b, 0), values: v }));
    $("cf-more").hidden = st.f !== "service";
    $("cf-more").textContent = st.all ? `Tampilkan ${TOP} teratas` : `Tampilkan semua ${total} layanan`;
    $("cf-sub").textContent = `${desc[st.f]} Komposisi kategori untuk tiap nilai ${st.f}, diurutkan dari yang terbanyak` +
      (limited ? ` (${TOP} teratas dari ${total} nilai).` : ".") + (st.ds === "test" && E.trainMissingLevels[st.f].length ? ` Data uji hanya memakai ${total} dari ${total + E.trainMissingLevels[st.f].length} nilai.` : "");
    stackedShare($("cf"), rows, { aria: `Komposisi kategori per ${st.f}` });
    tableView($("cf-tv"), [st.f, "n", ...CATS.map((c) => c + " (%)")], rows.map((r) => [r.label, fmtN(r.total), ...r.values.map((v) => fmtD(100 * v / r.total, 1))]));
  }
  draw();

  // --- tabel flag
  const flags = [
    ["SF", "Koneksi normal: dibuka dan ditutup dengan benar", "Mayoritas normal"],
    ["S0", "Paket SYN dikirim, tidak ada balasan", "Ciri khas SYN flood (neptune, DoS)"],
    ["REJ", "Koneksi ditolak", "neptune (DoS) dan satan (Probe)"],
    ["RSTR", "Koneksi diputus (RST) oleh penerima", "portsweep (Probe)"],
    ["RSTO", "Koneksi diputus (RST) oleh pengirim", "neptune (DoS)"],
    ["SH", "SYN lalu langsung FIN, tanpa balasan", "Stealth scan nmap (Probe)"],
  ];
  const fx = E.crosstab.flag.train;
  $("flag-table").replaceChildren(...flags.map(([f, a, k]) => {
    const v = fx[f], n = v.reduce((x, y) => x + y, 0);
    return h("tr", {}, h("td", { text: f }), h("td", { class: "wrapc", text: a }), h("td", { class: "wrapc", text: k }), h("td", { class: "num", text: fmtPct(100 * (1 - v[0] / n), 0) }));
  }));

  // --- one-hot
  const n = { protocol_type: Object.keys(E.crosstab.protocol_type.train).length, service: Object.keys(E.crosstab.service.train).length, flag: Object.keys(E.crosstab.flag.train).length };
  const term = (b, l, cls) => h("div", { class: "term" + (cls ? " " + cls : "") }, h("b", { text: String(b) }), h("span", { text: l }));
  $("onehot").replaceChildren(term(E.numericCount, "numerik"), h("span", { class: "op", text: "+" }), term(n.protocol_type, "protocol_type"),
    h("span", { class: "op", text: "+" }), term(n.service, "service"), h("span", { class: "op", text: "+" }), term(n.flag, "flag"),
    h("span", { class: "op", text: "=" }), term(E.oneHotWidth, "fitur input", "sum"));
  const usedSvc = n.service - E.trainMissingLevels.service.length;
  $("onehot-p").replaceChildren(`Data uji hanya memakai ${usedSvc} dari ${n.service} layanan, sehingga `, code("encode_features()"), " di ", code("preprocessing.py"), " menyamakan kolomnya dengan data latih (", code("reindex"), "; kolom yang tidak ada diisi 0).");
}

// =================================================================================================
// 5. Fitur numerik
// =================================================================================================
function initNumeric() {
  // --- skala
  const numFeat = Object.entries(E.features).filter(([n, f]) => f.kind !== "kategorikal" && !E.constant.includes(n));
  const rows = numFeat.sort((a, b) => b[1].max - a[1].max).map(([n, f]) => ({ label: n, value: Math.max(f.max, 0.5), fill: "var(--seq)", text: fmtShort(f.max),
    tip: { title: n, rows: [{ label: "Maksimum", value: fmtShort(f.max) }, { label: "Median", value: fmtShort(f.median) }, { label: "Rata-rata", value: fmtShort(f.mean) }] } }));
  hbar($("scale"), rows, { max: 1e10, log: true, ticks: [1, 10, 100, 1e3, 1e4, 1e5, 1e6, 1e7, 1e8, 1e9], tickFmt: compactId, barH: 11, gap: 5, labelW: 200, valueW: 90, aria: "Nilai maksimum tiap fitur (skala log)" });
  const mx = E.features.src_bytes.max;
  $("scale-p").replaceChildren(code("src_bytes"), ` bisa mencapai ${fmtShort(mx)} (sekitar 1,4 miliar), sedangkan fitur `, code("*_rate"),
    " hanya bernilai 0–1. Jika dimasukkan apa adanya, fitur berskala besar akan mendominasi penjumlahan berbobot ", h("em", { text: "z = Σ wᵢxᵢ + b" }), " dan membuat ", h("em", { text: "gradient descent" }), " tidak stabil. Solusinya: ", h("em", { text: "standardization" }), " (", code("StandardScaler"), "), sehingga setiap fitur memiliki rata-rata 0 dan standar deviasi 1.");

  // --- penjelajah histogram
  const sel = $("h-feature");
  const usable = E.corrMatrix.cols;
  const byGroup = E.groups.map((g) => [g.name, g.cols.filter((c) => usable.includes(c))]).filter(([, c]) => c.length);
  sel.replaceChildren(...byGroup.map(([g, cs]) => h("optgroup", { label: g }, ...cs.map((c) => h("option", { value: c, text: c })))));
  const st = { f: "count", log: false };
  sel.value = st.f;
  const scaleSeg = segmented($("h-scale"), [["raw", "Nilai asli"], ["log", "log(1 + x)"]], "raw", (v) => { st.log = v === "log"; draw(); });
  sel.addEventListener("change", () => { st.f = sel.value; draw(); });
  const quick = [["count", false], ["serror_rate", false], ["same_srv_rate", false], ["logged_in", false], ["src_bytes", true], ["dst_host_srv_count", false]];
  $("h-quick").replaceChildren(h("span", { class: "ctl-label", text: "Coba:" }), ...quick.map(([f, lg]) => h("button", { type: "button", class: "chip", style: "cursor:pointer", text: f,
    onclick: () => { st.f = f; st.log = lg; sel.value = f; scaleSeg.set(lg ? "log" : "raw"); draw(); } })));

  const root = $("hist");
  const chart = mount(root, (w) => drawHist(w, st));
  function draw() {
    const f = E.features[st.f];
    $("h-stats").textContent = `r = ${fmtSigned(f.corr)} · ${fmtD(f.zero, 1)}% bernilai 0 · rentang ${fmtShort(f.min)} – ${fmtShort(f.max)}`;
    chart.redraw();
  }
  draw();

  // --- profil kategori
  const pcols = ["count", "serror_rate", "rerror_rate", "same_srv_rate", "logged_in", "num_failed_logins", "hot", "root_shell", "num_file_creations"];
  $("profile").replaceChildren(
    h("thead", {}, h("tr", {}, h("th", { text: "Fitur" }), CATS.map((c) => h("th", {}, h("span", { class: `dot k-${key(c)}` }), c)))),
    h("tbody", {}, pcols.map((f) => {
      const vals = CATS.map((c) => E.features[f].by_cat[c]), mx = Math.max(...vals);
      return h("tr", {}, h("td", { class: "mono", text: f }), vals.map((v) => {
        const p = mx > 0 ? 6 + 88 * v / mx : 6;
        return h("td", { style: `background:color-mix(in srgb, var(--seq) ${p}%, var(--surface));color:${p > 80 ? "#fff" : "var(--ink)"}`, text: fmtD(v, 2) });
      }));
    })));
}

function drawHist(w, st) {
  const f = E.features[st.f];
  const H = 280, m = { l: 46, r: 14, t: 10, b: 46 };
  const pw = w - m.l - m.r, ph = H - m.t - m.b;
  const svg = s("svg", { width: w, height: H, role: "img", "aria-label": `Sebaran ${st.f}, normal dibanding serangan` });
  const hd = st.log ? f.hist_log : f.hist;
  const ed = hd.edges, bw = ed[1] - ed[0];
  const massN = hd.normal.map((d) => d * bw * 100), massA = hd.attack.map((d) => d * bw * 100);
  const toVal = (x) => (st.log ? Math.expm1(x) : x);

  if (f.kind === "biner") {
    // fitur biner: dua kelompok (nilai 0 dan 1), bukan histogram
    const last = massN.length - 1;
    const groups = [["0", massN[0], massA[0]], ["1", massN[last], massA[last]]];
    const ymax = Math.max(...groups.flatMap((g) => [g[1], g[2]]));
    const ticks = niceTicks(Math.min(100, ymax * 1.05), 4), ytop = ticks[ticks.length - 1];
    const y = (v) => m.t + ph - (v / ytop) * ph;
    ticks.forEach((t) => svg.append(s("line", { class: "gl", x1: m.l, x2: w - m.r, y1: y(t), y2: y(t) }), s("text", { class: "ax", x: m.l - 8, y: y(t) + 4, "text-anchor": "end", text: t + "%" })));
    const gw = pw / 2, barW = Math.min(44, gw / 4);
    groups.forEach(([lab, n, a], i) => {
      const cx = m.l + gw * i + gw / 2;
      const g = s("g", { class: "row" });
      g.append(s("path", { class: "mark", style: "fill:var(--c-normal)", d: barPath2(cx - barW - 1, y(n), barW, m.t + ph - y(n)) }),
        s("path", { class: "mark", style: "fill:var(--attack)", d: barPath2(cx + 1, y(a), barW, m.t + ph - y(a)) }),
        s("text", { class: "val", x: cx - barW / 2 - 1, y: y(n) - 6, "text-anchor": "middle", text: fmtPct(n, 1) }),
        s("text", { class: "val", x: cx + barW / 2 + 1, y: y(a) - 6, "text-anchor": "middle", text: fmtPct(a, 1) }),
        s("text", { class: "ax-strong", x: cx, y: H - m.b + 22, "text-anchor": "middle", text: `${st.f} = ${lab}` }),
        s("rect", { class: "hit", x: m.l + gw * i, y: m.t, width: gw, height: ph }));
      tip(g, () => ({ title: `${st.f} = ${lab}`, rows: [{ color: "var(--c-normal)", label: "Normal", value: fmtPct(n, 1) + " koneksi normal" }, { color: "var(--attack)", label: "Serangan", value: fmtPct(a, 1) + " koneksi serangan" }] }), true);
      svg.append(g);
    });
    svg.append(s("line", { class: "bl", x1: m.l, x2: w - m.r, y1: m.t + ph, y2: m.t + ph }));
    return svg;
  }

  const ymax = Math.max(...massN, ...massA);
  const yt = niceTicks(Math.min(100, ymax * 1.08), 4), ytop = yt[yt.length - 1];
  const x0 = ed[0], x1 = ed[ed.length - 1];
  const x = (v) => m.l + ((v - x0) / (x1 - x0 || 1)) * pw;
  const y = (v) => m.t + ph - (v / ytop) * ph;
  yt.forEach((t) => svg.append(s("line", { class: "gl", x1: m.l, x2: w - m.r, y1: y(t), y2: y(t) }), s("text", { class: "ax", x: m.l - 8, y: y(t) + 4, "text-anchor": "end", text: t + "%" })));
  // sumbu x
  let xt;
  if (st.log) {
    xt = [0, 1, 10, 100, 1e3, 1e4, 1e5, 1e6, 1e7, 1e8, 1e9].filter((v) => Math.log1p(v) <= x1 + 1e-9).map((v) => [Math.log1p(v), compactId(v)]);
    if (xt.length > 7) xt = xt.filter((_, i) => i % 2 === 0);
  } else {
    xt = niceTicks(x1 - x0, 5).map((t) => [x0 + t, fmtShort(+(x0 + t).toFixed(6))]).filter(([v]) => v <= x1 + 1e-9);
  }
  xt.forEach(([v, lab]) => svg.append(s("line", { class: "gl", x1: x(v), x2: x(v), y1: m.t + ph, y2: m.t + ph + 4 }), s("text", { class: "ax", x: x(v), y: m.t + ph + 18, "text-anchor": "middle", text: lab })));
  svg.append(s("text", { class: "ax", x: m.l + pw / 2, y: H - 6, "text-anchor": "middle", text: st.log ? `${st.f} (skala log(1 + x))` : st.f }));
  // kurva langkah + area 12%
  const series = [[massN, "var(--c-normal)"], [massA, "var(--attack)"]];
  series.forEach(([mass, color]) => {
    let d = `M${x(ed[0])} ${y(0)}`;
    mass.forEach((v, i) => { d += `L${x(ed[i])} ${y(v)}L${x(ed[i + 1])} ${y(v)}`; });
    d += `L${x(ed[ed.length - 1])} ${y(0)}Z`;
    let line = "";
    mass.forEach((v, i) => { line += `${i ? "L" : "M"}${x(ed[i])} ${y(v)}L${x(ed[i + 1])} ${y(v)}`; });
    svg.append(s("path", { d, style: `fill:${color}`, "fill-opacity": 0.14 }), s("path", { d: line, fill: "none", style: `stroke:${color}`, "stroke-width": 2, "stroke-linejoin": "round" }));
  });
  svg.append(s("line", { class: "bl", x1: m.l, x2: w - m.r, y1: m.t + ph, y2: m.t + ph }));
  // crosshair yang menempel ke bin terdekat
  const guide = s("rect", { y: m.t, height: ph, fill: "var(--ink)", "fill-opacity": 0.07, width: 0, pointerEvents: "none" });
  const hit = s("rect", { class: "hit", x: m.l, y: m.t, width: pw, height: ph });
  const bin = (e) => { const b = svg.getBoundingClientRect(); return Math.max(0, Math.min(massN.length - 1, Math.floor(((e.clientX - b.left - m.l) / pw) * massN.length))); };
  hit.addEventListener("pointermove", (e) => {
    const i = bin(e);
    guide.setAttribute("x", x(ed[i])); guide.setAttribute("width", x(ed[i + 1]) - x(ed[i]));
    const a = toVal(ed[i]), b = toVal(ed[i + 1]);
    showTip(e.clientX, e.clientY, { title: `${st.f}: ${fmtShort(+a.toFixed(4))} – ${fmtShort(+b.toFixed(4))}`, rows: [
      { color: "var(--c-normal)", label: "Normal", value: fmtPct(massN[i], 1) }, { color: "var(--attack)", label: "Serangan", value: fmtPct(massA[i], 1) }] });
  });
  hit.addEventListener("pointerleave", () => { guide.setAttribute("width", 0); hideTip(); });
  svg.append(guide, hit);
  return svg;
}
function barPath2(x, y, w, hgt) { // kolom: ujung atas membulat, pangkal rata
  const r = Math.min(4, w / 2, hgt);
  if (hgt <= 0) return "";
  return `M${x} ${y + hgt}V${y + r}Q${x} ${y} ${x + r} ${y}H${x + w - r}Q${x + w} ${y} ${x + w} ${y + r}V${y + hgt}Z`;
}

// =================================================================================================
// 6. Korelasi
// =================================================================================================
function initCorrelation() {
  // --- batang diverging: 15 teratas
  const top = Object.entries(E.features).filter(([, f]) => f.corr != null).sort((a, b) => Math.abs(b[1].corr) - Math.abs(a[1].corr)).slice(0, 15);
  const labelW0 = Math.max(...top.map(([n]) => textW(n))) + 14;
  mount($("corr-label"), (w) => {
    const narrow = w < labelW0 + 340;
    const labelW = narrow ? 0 : labelW0;
    const barH = 14, rowH = narrow ? 38 : 22, off = narrow ? 16 : 0, H = top.length * rowH + 30;
    const x0 = labelW + 44, pw = w - x0 - 44, cx = x0 + pw / 2;
    const xOf = (v) => cx + v * pw / 2;
    const svg = s("svg", { width: w, height: H, role: "img", "aria-label": "Korelasi tiap fitur dengan label serangan" });
    (narrow ? [-1, 0, 1] : [-1, -0.5, 0, 0.5, 1]).forEach((t) => svg.append(s("line", { class: t === 0 ? "bl" : "gl", x1: xOf(t), x2: xOf(t), y1: 0, y2: H - 22 }),
      s("text", { class: "ax", x: xOf(t), y: H - 6, "text-anchor": "middle", text: t === 0 ? "0" : fmtSigned(t, 1) })));
    top.forEach(([n, f], i) => {
      const y = 2 + i * rowH, by = y + off, v = f.corr, len = Math.abs(v) * pw / 2;
      const g = s("g", { class: "row" });
      g.append(narrow ? s("text", { class: "lbl", x: 0, y: y + 10, text: n }) : s("text", { class: "lbl", x: labelW, y: by + barH / 2 + 4, "text-anchor": "end", text: n }),
        s("path", { class: "mark", style: `fill:var(--${v >= 0 ? "pos" : "neg"})`, d: v >= 0 ? barPath(cx, by, len, barH) : barPathL(cx, by, len, barH) }),
        s("text", { class: "val", x: v >= 0 ? cx + len + 8 : cx - len - 8, y: by + barH / 2 + 4, "text-anchor": v >= 0 ? "start" : "end", text: fmtSigned(v) }),
        s("rect", { class: "hit", x: 0, y: y - 4, width: w, height: rowH }));
      tip(g, () => ({ title: n, rows: [{ color: `var(--${v >= 0 ? "pos" : "neg"})`, label: "Korelasi dgn is_attack", value: fmtSigned(v, 3) }] }), true);
      svg.append(g);
    });
    return svg;
  });
  tableView($("corr-label-tv"), ["Fitur", "Korelasi dengan is_attack"], top.map(([n, f]) => [n, fmtSigned(f.corr, 3)]));

  // --- heatmap korelasi antar fitur
  const { cols, values } = E.corrMatrix;
  const cell = 15, left = 184, topPad = 176, n = cols.length;
  const W = left + n * cell + 4, Hh = topPad + n * cell + 4;
  const svg = s("svg", { width: W, height: Hh, role: "img", "aria-label": "Matriks korelasi antar fitur numerik", style: "min-width:" + W + "px" });
  const pair = s("g", { pointerEvents: "none" });
  const gIdx = {}; E.groups.forEach((g, gi) => g.cols.forEach((c) => { gIdx[c] = gi; }));
  cols.forEach((c, i) => {
    svg.append(s("text", { class: "ax", x: left - 6, y: topPad + i * cell + cell / 2 + 3.5, "text-anchor": "end", style: "font-size:10px", text: c }),
      s("text", { class: "ax", transform: `translate(${left + i * cell + cell / 2 + 3.5} ${topPad - 6}) rotate(-90)`, style: "font-size:10px", text: c }));
  });
  values.forEach((row, i) => row.forEach((v, j) => {
    const p = Math.round(100 * Math.abs(v));
    svg.append(s("rect", { x: left + j * cell, y: topPad + i * cell, width: cell - 1, height: cell - 1, rx: 2,
      style: `fill:color-mix(in srgb, var(--${v >= 0 ? "pos" : "neg"}) ${p}%, var(--mid))` }));
  }));
  // pemisah kelompok
  cols.forEach((c, i) => { if (i && gIdx[c] !== gIdx[cols[i - 1]]) {
    svg.append(s("line", { x1: left + i * cell - 0.5, x2: left + i * cell - 0.5, y1: topPad, y2: topPad + n * cell, stroke: "var(--ink)", "stroke-opacity": 0.35, "stroke-width": 1 }),
      s("line", { y1: topPad + i * cell - 0.5, y2: topPad + i * cell - 0.5, x1: left, x2: left + n * cell, stroke: "var(--ink)", "stroke-opacity": 0.35, "stroke-width": 1 }));
  } });
  const hl = s("rect", { width: cell - 1, height: cell - 1, rx: 2, fill: "none", stroke: "var(--ink)", "stroke-width": 2, display: "none" });
  const hit = s("rect", { class: "hit", x: left, y: topPad, width: n * cell, height: n * cell });
  hit.addEventListener("pointermove", (e) => {
    const b = svg.getBoundingClientRect();
    const j = Math.floor((e.clientX - b.left - left) / cell), i = Math.floor((e.clientY - b.top - topPad) / cell);
    if (i < 0 || j < 0 || i >= n || j >= n) return;
    hl.setAttribute("x", left + j * cell); hl.setAttribute("y", topPad + i * cell); hl.removeAttribute("display");
    const v = values[i][j];
    showTip(e.clientX, e.clientY, { title: `${cols[i]} × ${cols[j]}`, rows: [{ color: `var(--${v >= 0 ? "pos" : "neg"})`, label: "Korelasi Pearson", value: fmtSigned(v, 3) }] });
  });
  hit.addEventListener("pointerleave", () => { hl.setAttribute("display", "none"); hideTip(); });
  svg.append(pair, hl, hit);
  const legend = h("div", { class: "legend", style: "margin-top:10px" },
    h("span", { class: "lg" }, h("i", { style: "background:var(--neg)" }), "−1 (cenderung berlawanan)"),
    h("span", { class: "lg" }, h("i", { style: "background:var(--mid)" }), "0"),
    h("span", { class: "lg" }, h("i", { style: "background:var(--pos)" }), "+1 (bergerak bersama)"));
  $("heatmap").replaceChildren(svg);
  $("heatmap").parentElement.append(legend);

  // --- pasangan redundan
  const rp = E.redundantPairs;
  $("redund-h").textContent = `${rp.length} pasangan fitur dengan |korelasi| > 0,95`;
  $("redund").replaceChildren(h("thead", {}, h("tr", {}, h("th", { text: "Fitur A" }), h("th", { text: "Fitur B" }), h("th", { class: "num", text: "Korelasi" }))),
    h("tbody", {}, rp.map(([a, b, v]) => h("tr", {}, h("td", { class: "mono", text: a }), h("td", { class: "mono", text: b }), h("td", { class: "num", text: fmtSigned(v, 3) })))));
}

// =================================================================================================
// 7. Latih vs uji
// =================================================================================================
function initShift() {
  const D = E.difficulty, n = D.bins.length;
  mount($("diff"), (w) => {
    const H = 260, m = { l: 44, r: 10, t: 12, b: 48 }, pw = w - m.l - m.r, ph = H - m.t - m.b;
    const ymax = Math.max(...D.train, ...D.test), ticks = niceTicks(ymax * 1.05, 4), top = ticks[ticks.length - 1];
    const y = (v) => m.t + ph - (v / top) * ph;
    const svg = s("svg", { width: w, height: H, role: "img", "aria-label": "Tingkat kesulitan record, latih dibanding uji" });
    ticks.forEach((t) => svg.append(s("line", { class: "gl", x1: m.l, x2: w - m.r, y1: y(t), y2: y(t) }), s("text", { class: "ax", x: m.l - 8, y: y(t) + 4, "text-anchor": "end", text: t + "%" })));
    const bw = pw / n, barW = Math.min(10, bw / 2 - 1);
    const guide = s("rect", { y: m.t, height: ph, fill: "var(--ink)", "fill-opacity": 0.07, width: 0, pointerEvents: "none" });
    D.bins.forEach((b, i) => {
      const cx = m.l + bw * i + bw / 2;
      svg.append(s("path", { class: "mark", style: "fill:var(--train)", d: barPath2(cx - barW - 1, y(D.train[i]), barW, m.t + ph - y(D.train[i])) }),
        s("path", { class: "mark", style: "fill:var(--test)", d: barPath2(cx + 1, y(D.test[i]), barW, m.t + ph - y(D.test[i])) }));
      if (b % 3 === 0 || b === 21) svg.append(s("text", { class: "ax", x: cx, y: m.t + ph + 16, "text-anchor": "middle", text: b }));
    });
    svg.append(s("line", { class: "bl", x1: m.l, x2: w - m.r, y1: m.t + ph, y2: m.t + ph }),
      s("text", { class: "ax", x: m.l + pw / 2, y: H - 8, "text-anchor": "middle", text: "difficulty (21 = paling mudah)" }));
    const hit = s("rect", { class: "hit", x: m.l, y: m.t, width: pw, height: ph });
    hit.addEventListener("pointermove", (e) => {
      const r = svg.getBoundingClientRect(), i = Math.max(0, Math.min(n - 1, Math.floor((e.clientX - r.left - m.l) / bw)));
      guide.setAttribute("x", m.l + bw * i); guide.setAttribute("width", bw);
      showTip(e.clientX, e.clientY, { title: `difficulty = ${D.bins[i]}`, rows: [
        { color: "var(--train)", label: "KDDTrain+", value: fmtPct(D.train[i], 2) }, { color: "var(--test)", label: "KDDTest+", value: fmtPct(D.test[i], 2) }] });
    });
    hit.addEventListener("pointerleave", () => { guide.setAttribute("width", 0); hideTip(); });
    svg.append(guide, hit);
    return svg;
  });

  const P = E.protocolAttack;
  const prow = Object.keys(P.train).sort((a, b) => P.train[b] - P.train[a]);
  $("proto").replaceChildren(h("thead", {}, h("tr", {}, h("th", { text: "protocol_type" }), h("th", { class: "num", text: "Latih" }), h("th", { class: "num", text: "Uji" }), h("th", { class: "num", text: "Selisih" }))),
    h("tbody", {}, prow.map((p) => h("tr", {}, h("td", { class: "mono", text: p }), h("td", { class: "num", text: fmtPct(P.train[p]) }), h("td", { class: "num", text: fmtPct(P.test[p]) }),
      h("td", { class: "num", text: fmtSigned(P.test[p] - P.train[p], 1) + " poin" })))));
  const biggest = prow.slice().sort((a, b) => (P.test[b] - P.train[b]) - (P.test[a] - P.train[a]))[0];
  $("f-shift").replaceChildren(
    h("li", {}, `Data uji jauh lebih banyak berisi record sulit: rata-rata `, code("difficulty"), ` ${fmtD(D.testMean)} di uji dibanding ${fmtD(D.trainMean)} di latih.`),
    h("li", {}, `Ada ${E.newAttacks.names.length} jenis serangan baru yang hanya muncul di data uji (${fmtPct(E.newAttacks.share)} record uji).`),
    h("li", {}, `Proporsi serangan naik di setiap protokol; kenaikan terbesar pada `, code(biggest), ` (${fmtSigned(P.test[biggest] - P.train[biggest], 1)} poin).`),
    h("li", {}, h("strong", { text: "Wajar jika akurasi di KDDTest+ lebih rendah" }), " daripada akurasi validasi yang diambil dari KDDTrain+. Ini bukan bug, melainkan gambaran jujur kemampuan generalisasi model."));
}

// =================================================================================================
// 8. Keputusan
// =================================================================================================
function initDecision() {
  const lt = Object.values(E.labels).filter((l) => l.train > 0).length;
  const sv = Object.keys(E.crosstab.service.train).length, pt = Object.keys(E.crosstab.protocol_type.train).length, fl = Object.keys(E.crosstab.flag.train).length;
  const rows = [
    ["Tidak ada missing value dan duplikat", ["Tidak perlu pembersihan data"]],
    [[code("difficulty"), " adalah metadata"], ["Dibuang sebelum training"]],
    [`${lt} jenis label, 4 kategori serangan`, ["Digabung menjadi ", h("strong", { text: "label biner" }), " (", code("make_labels"), ")"]],
    [`3 fitur teks (${pt} + ${sv} + ${fl} nilai)`, [h("em", { text: "One-hot encoding" }), ` menjadi ${E.oneHotWidth} fitur (`, code("encode_features"), ")"]],
    ["Skala fitur berbeda hingga 10⁹ kali", [h("em", { text: "Standardization" }), ", scaler hanya di-fit pada data latih (", code("scale_features"), ")"]],
    ["Kelas tidak seimbang", [code("stratify"), " saat split, serta metrik ", h("em", { text: "precision" }), ", ", h("em", { text: "recall" }), ", dan F1"]],
    ["Serangan baru dan record sulit di data uji", ["Akurasi uji lebih rendah dari akurasi validasi adalah hal yang wajar"]],
    [[code("num_outbound_cmds"), " konstan, beberapa fitur redundan"], ["Dibiarkan (ANN tetap bisa belajar); kandidat ", h("em", { text: "feature selection" })]],
  ];
  $("decision").replaceChildren(h("thead", {}, h("tr", {}, h("th", { text: "Temuan EDA" }), h("th", { text: "Keputusan di pipeline (preprocessing.py)" }))),
    h("tbody", {}, rows.map(([a, b]) => h("tr", {}, h("td", {}, a), h("td", {}, b)))));
  $("decision").parentElement.parentElement.append(h("p", { style: "padding:16px 22px;margin:0;border-top:1px solid var(--line);max-width:none" }, h("strong", { text: "Berikutnya: " }), "jalankan ", code("uv run python sesi-1-ann/train.py"), " dan lihat bagaimana keputusan-keputusan ini diterapkan."));
}

// =================================================================================================
// Kerangka: tema & navigasi
// =================================================================================================
function initChrome() {
  const btn = $("theme");
  const eff = () => document.documentElement.dataset.theme || (matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light");
  const label = () => { btn.textContent = eff() === "dark" ? "Mode terang" : "Mode gelap"; };
  label();
  btn.addEventListener("click", () => {
    const next = eff() === "dark" ? "light" : "dark";
    document.documentElement.dataset.theme = next;
    try { localStorage.setItem("eda-theme", next); } catch (e) { /* mode privat: abaikan */ }
    label();
  });
  matchMedia("(prefers-color-scheme: dark)").addEventListener("change", label);

  const links = [...document.querySelectorAll("#nav a")];
  const secs = links.map((a) => document.querySelector(a.getAttribute("href")));
  const mark = (id) => links.forEach((a) => a.setAttribute("aria-current", a.getAttribute("href") === "#" + id ? "true" : "false"));
  const io = new IntersectionObserver((es) => es.forEach((e) => { if (e.isIntersecting) mark(e.target.id); }), { rootMargin: "-25% 0px -65% 0px" });
  secs.forEach((el) => el && io.observe(el));
  mark("ringkas");
}

initChrome();
initWaffle();
initStruct();
initQuality();
initLabels();
initCategorical();
initNumeric();
initCorrelation();
initShift();
initDecision();
})();
