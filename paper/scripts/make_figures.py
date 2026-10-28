"""
Gambar untuk paper (butuh paper/results.json dari experiments.py).

Jalankan dari root repo:
    uv run python paper/scripts/make_figures.py
"""

import json
import sys
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "sesi-1-ann"))
sys.path.insert(0, str(ROOT / "paper" / "scripts"))

from data import load_nslkdd  # noqa: E402
from experiments import ATTACK_CATEGORY  # noqa: E402

IMG = ROOT / "paper" / "img"
IMG.mkdir(parents=True, exist_ok=True)
RESULTS = json.loads((ROOT / "paper" / "results.json").read_text())

NAVY, NAVY2, GOLD, RED, TEAL, PURPLE, GRAY = "#0B1F3A", "#1B3A5C", "#D4A017", "#C8102E", "#1E8C8C", "#8E5BA8", "#5A5A5A"
CATEGORIES = ["Normal", "DoS", "Probe", "R2L", "U2R"]
COLORS = {"Normal": TEAL, "DoS": RED, "Probe": GOLD, "R2L": NAVY2, "U2R": PURPLE}
W = 3.4  # lebar satu kolom (inci)

plt.rcParams.update({
    "font.family": "serif", "font.serif": ["Times New Roman", "Times", "DejaVu Serif"],
    "mathtext.fontset": "stix", "font.size": 8, "axes.titlesize": 8.5, "axes.labelsize": 8,
    "xtick.labelsize": 7, "ytick.labelsize": 7, "legend.fontsize": 7,
    "axes.spines.top": False, "axes.spines.right": False, "axes.grid": True,
    "grid.alpha": 0.25, "grid.linewidth": 0.5, "axes.axisbelow": True, "axes.linewidth": 0.6,
    "savefig.dpi": 300, "savefig.bbox": "tight", "savefig.pad_inches": 0.02,
})


def save(fig, name):
    fig.savefig(IMG / name)
    plt.close(fig)
    print("->", IMG / name)


def distribution(train_df, test_df):
    share = {name: 100 * df["label"].map(ATTACK_CATEGORY).fillna("Normal").value_counts(normalize=True)
             for name, df in [("KDDTrain+", train_df), ("KDDTest+", test_df)]}
    fig, ax = plt.subplots(figsize=(W, 2.0))
    y = np.arange(len(CATEGORIES))
    h = 0.38
    for off, (name, color) in zip([-h / 2, h / 2], [("KDDTrain+", NAVY2), ("KDDTest+", GOLD)]):
        vals = share[name].reindex(CATEGORIES).to_numpy()
        ax.barh(y + off, vals, height=h, color=color, label=name, edgecolor="white", linewidth=0.8)
        for yy, v in zip(y + off, vals):
            ax.text(v + 0.8, yy, f"{v:.2f}%" if v < 1 else f"{v:.1f}%", va="center", fontsize=6.5, color=NAVY)
    ax.set_yticks(y, CATEGORIES)
    ax.invert_yaxis()
    ax.set_xlim(0, 64)
    ax.set_xlabel("Persentase record (%)")
    ax.grid(axis="y", visible=False)
    ax.legend(loc="lower right", frameon=False)
    save(fig, "distribusi.png")


def features(train_df):
    attack = train_df["label"] != "normal"
    fig, axes = plt.subplots(1, 3, figsize=(W * 2.05, 1.7))
    for ax, (feat, log) in zip(axes, [("src_bytes", True), ("count", False), ("same_srv_rate", False)]):
        v = np.log1p(train_df[feat]) if log else train_df[feat]
        bins = np.histogram_bin_edges(v, bins=40)
        for mask, color, name in [(~attack, TEAL, "normal"), (attack, RED, "serangan")]:
            ax.hist(v[mask], bins=bins, density=True, color=color, alpha=0.3)
            ax.hist(v[mask], bins=bins, density=True, color=color, histtype="step", linewidth=1.2, label=name)
        ax.set_title(r"$\log(1+\mathtt{src\_bytes})$" if log else feat.replace("_", r"\_").join([r"$\mathtt{", "}$"]))
        ax.set_yticks([])
    axes[0].legend(frameon=False)
    fig.tight_layout(w_pad=1.0)
    save(fig, "fitur.png")


def loss_curve():
    hist = RESULTS["seed42"]["history"]
    ep = np.arange(1, len(hist["train"]) + 1)
    best = int(np.argmin(hist["val"])) + 1
    fig, ax = plt.subplots(figsize=(W, 1.9))
    ax.plot(ep, hist["train"], "o-", color=NAVY, lw=1.4, ms=3.5, label="latih")
    ax.plot(ep, hist["val"], "s-", color=RED, lw=1.4, ms=3.5, label="validasi")
    ax.axvline(best, color=GRAY, lw=0.8, ls="--")
    ax.annotate(f"terbaik (epoch {best})", (best, max(hist["train"]) * 0.8), xytext=(-4, 0),
                textcoords="offset points", ha="right", fontsize=6.5, color=GRAY)
    ax.set_xticks(ep)
    ax.set_xlabel("Epoch")
    ax.set_ylabel("BCE loss")
    ax.legend(frameon=False)
    save(fig, "loss.png")


def detection():
    pc = RESULTS["seed42"]["per_category"]
    cats = ["DoS", "Probe", "R2L", "U2R"]
    fig, ax = plt.subplots(figsize=(W, 1.9))
    x = np.arange(len(cats))
    w = 0.38
    for off, kind, color, label in [(-w / 2, "dikenal", NAVY2, "jenis dikenal"), (w / 2, "baru", GOLD, "jenis baru")]:
        rates = [100 * pc[f"{c}|{kind}"]["detected"] / pc[f"{c}|{kind}"]["n"] for c in cats]
        ns = [pc[f"{c}|{kind}"]["n"] for c in cats]
        ax.bar(x + off, rates, width=w, color=color, label=label, edgecolor="white", linewidth=0.8)
        for xx, r, n in zip(x + off, rates, ns):
            ax.text(xx, r + 2, f"{r:.0f}", ha="center", fontsize=6.5, color=NAVY)
    ax.set_xticks(x, cats)
    ax.set_ylim(0, 112)
    ax.set_ylabel("Tingkat deteksi (%)")
    ax.grid(axis="x", visible=False)
    ax.legend(frameon=False, loc="upper right", ncol=2)
    save(fig, "deteksi.png")


def threshold():
    sweep = RESULTS["seed42"]["threshold_sweep"]
    roc = RESULTS["seed42"]["roc_test"]
    auc = [r["test"]["auc"] for r in RESULTS["variants"]["baseline"] if r["seed"] == 42][0]
    t = [s["thr"] for s in sweep]
    fig, axes = plt.subplots(1, 2, figsize=(W * 2.05, 1.9))
    ax = axes[0]
    ax.plot(roc["fpr"], roc["tpr"], color=NAVY, lw=1.4, label=f"MLP (AUC = {auc:.3f})")
    ax.plot([0, 1], [0, 1], color=GRAY, lw=0.8, ls="--", label="acak")
    ax.set_xlabel("False positive rate")
    ax.set_ylabel("True positive rate (recall)")
    ax.set_title("(a) Kurva ROC pada KDDTest+")
    ax.legend(frameon=False, loc="lower right")
    ax = axes[1]
    for key, color, marker, label in [("precision", TEAL, "o", "precision"), ("recall", RED, "s", "recall"),
                                      ("f1", NAVY, "^", "F1")]:
        ax.plot(t, [s[key] for s in sweep], marker=marker, ms=2.8, lw=1.2, color=color, label=label)
    ax.axvline(0.5, color=GRAY, lw=0.8, ls="--")
    ax.set_ylim(0.55, 1.0)
    ax.set_xlabel(r"Ambang keputusan $\tau$")
    ax.set_title(r"(b) Metrik uji terhadap ambang $\tau$")
    ax.legend(frameon=False, loc="lower left", ncol=3)
    fig.tight_layout(w_pad=2.0)
    save(fig, "ambang.png")


if __name__ == "__main__":
    train_df, test_df = load_nslkdd()
    distribution(train_df, test_df)
    features(train_df)
    loss_curve()
    detection()
    threshold()
