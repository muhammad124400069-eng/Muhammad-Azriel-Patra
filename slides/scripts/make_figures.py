"""Bangkitkan gambar untuk slide Sesi 1 (ANN) dengan palet ITERA.

Jalankan dari root repo:
    uv run python slides/scripts/make_figures.py
"""
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np

OUT = Path(__file__).resolve().parents[1] / "sesi-1" / "img"
OUT.mkdir(parents=True, exist_ok=True)

NAVY = "#0B1F3A"
NAVY2 = "#1B3A5C"
GOLD = "#D4A017"
RED = "#C8102E"
TEAL = "#1E8C8C"
GREEN = "#2E9E6B"
GRAY = "#5A5A5A"
BG = "#F7F6F3"

plt.rcParams.update({
    "font.family": ["Fira Sans", "DejaVu Sans"],
    "font.size": 13,
    "axes.edgecolor": GRAY,
    "axes.labelcolor": NAVY,
    "axes.titlecolor": NAVY,
    "axes.titleweight": "bold",
    "axes.spines.top": False,
    "axes.spines.right": False,
    "xtick.color": GRAY,
    "ytick.color": GRAY,
    "figure.facecolor": "white",
    "axes.facecolor": "white",
    "savefig.dpi": 200,
    "savefig.bbox": "tight",
})


def save(fig, name):
    fig.savefig(OUT / name)
    plt.close(fig)
    print("saved", OUT / name)


def activations():
    z = np.linspace(-5, 5, 400)
    funcs = [
        ("Step", np.where(z >= 0, 1.0, 0.0), GRAY),
        ("Sigmoid", 1 / (1 + np.exp(-z)), NAVY),
        ("Tanh", np.tanh(z), TEAL),
        ("ReLU", np.maximum(0, z), RED),
    ]
    fig, axes = plt.subplots(1, 4, figsize=(13, 3.2))
    for ax, (name, y, c) in zip(axes, funcs):
        ax.axhline(0, color="#cccccc", lw=0.8)
        ax.axvline(0, color="#cccccc", lw=0.8)
        ax.plot(z, y, color=c, lw=3)
        ax.set_title(name)
        ax.set_xlabel("z")
        ax.grid(alpha=0.25)
    axes[0].set_ylabel("f(z)")
    fig.tight_layout()
    save(fig, "aktivasi.png")


def xor():
    fig, axes = plt.subplots(1, 2, figsize=(9, 4))
    pts = np.array([[0, 0], [0, 1], [1, 0], [1, 1]])
    labels = {"AND": [0, 0, 0, 1], "XOR": [0, 1, 1, 0]}
    for ax, (name, lab) in zip(axes, labels.items()):
        for (x, y), l in zip(pts, lab):
            ax.scatter(x, y, s=380, color=GOLD if l else NAVY, edgecolor="white", lw=2, zorder=3)
            ax.text(x, y, str(l), ha="center", va="center", color="white", fontweight="bold", zorder=4)
        ax.set_xlim(-0.4, 1.4)
        ax.set_ylim(-0.4, 1.4)
        ax.set_xticks([0, 1])
        ax.set_yticks([0, 1])
        ax.set_xlabel("$x_1$")
        ax.set_ylabel("$x_2$")
        ax.set_aspect("equal")
    xs = np.linspace(-0.4, 1.4, 10)
    axes[0].plot(xs, 1.5 - xs, color=TEAL, lw=3)
    axes[0].set_title("AND: cukup 1 garis lurus")
    # XOR: dua garis (butuh hidden layer)
    axes[1].plot(xs, 0.5 - xs, color=RED, lw=3, ls="--")
    axes[1].plot(xs, 1.5 - xs, color=RED, lw=3, ls="--")
    axes[1].set_title("XOR: butuh batas non-linear")
    fig.tight_layout()
    save(fig, "xor.png")


def link_quality():
    rng = np.random.default_rng(7)
    n = 60
    good = np.column_stack([rng.normal(0.72, 0.12, n), rng.normal(0.65, 0.13, n)])
    bad = np.column_stack([rng.normal(0.3, 0.13, n), rng.normal(0.32, 0.13, n)])
    fig, ax = plt.subplots(figsize=(5.4, 4.4))
    ax.scatter(*bad.T, color=RED, alpha=0.75, label="Link buruk (y=0)", edgecolor="white")
    ax.scatter(*good.T, color=TEAL, alpha=0.75, label="Link baik (y=1)", edgecolor="white")
    xs = np.linspace(0, 1, 10)
    # batas keputusan neuron: 2.0 x1 + 1.5 x2 - 1.5 = 0
    ax.plot(xs, (1.5 - 2.0 * xs) / 1.5, color=NAVY, lw=3, label="Batas keputusan neuron")
    ax.scatter([0.8], [0.6], marker="*", s=420, color=GOLD, edgecolor=NAVY, zorder=5, label="Contoh x = (0.8, 0.6)")
    ax.set_xlim(0, 1)
    ax.set_ylim(0, 1)
    ax.set_xlabel("SNR (ternormalisasi)")
    ax.set_ylabel("RSSI (ternormalisasi)")
    ax.legend(loc="upper center", bbox_to_anchor=(0.5, -0.16), ncol=2, fontsize=9, frameon=False)
    ax.grid(alpha=0.25)
    save(fig, "link_quality.png")


def gradient_descent():
    w = np.linspace(-1, 5, 300)
    loss = lambda w: 0.5 * (w - 2.5) ** 2 + 0.4
    fig, ax = plt.subplots(figsize=(6.2, 4))
    ax.plot(w, loss(w), color=NAVY, lw=3)
    ws = [-0.5]
    for _ in range(6):
        ws.append(ws[-1] - 0.45 * (ws[-1] - 2.5))
    ws = np.array(ws)
    ax.plot(ws, loss(ws), "o--", color=GOLD, ms=10, mec=NAVY, lw=1.5)
    for i in range(len(ws) - 1):
        ax.annotate("", xy=(ws[i + 1], loss(ws[i + 1])), xytext=(ws[i], loss(ws[i])),
                    arrowprops=dict(arrowstyle="->", color=RED, lw=2))
    ax.scatter([2.5], [loss(2.5)], s=160, color=TEAL, zorder=5)
    ax.annotate("minimum", (2.5, loss(2.5)), xytext=(3.6, 2.6), color=TEAL, fontweight="bold",
                arrowprops=dict(arrowstyle="->", color=TEAL))
    ax.set_xlabel("bobot w")
    ax.set_ylabel("Loss L(w)")
    ax.set_title("Turun bukit mengikuti gradien")
    ax.grid(alpha=0.25)
    save(fig, "gradient_descent.png")


def learning_rates():
    w = np.linspace(-2.5, 7.5, 300)
    loss = lambda w: 0.5 * (w - 2.5) ** 2
    cases = [("η terlalu kecil", 0.08, TEAL), ("η pas", 0.6, GREEN), ("η terlalu besar", 1.9, RED)]
    fig, axes = plt.subplots(1, 3, figsize=(12, 3.4))
    for ax, (name, lr, c) in zip(axes, cases):
        ws = [-1.5]
        for _ in range(7):
            ws.append(ws[-1] - lr * (ws[-1] - 2.5))
        ws = np.clip(np.array(ws), -2.5, 7.5)
        ax.plot(w, loss(w), color=NAVY, lw=2.5)
        ax.plot(ws, loss(ws), "o-", color=c, ms=7, lw=1.8)
        ax.set_title(name)
        ax.set_xticks([])
        ax.set_yticks([])
        ax.set_xlabel("w")
    axes[0].set_ylabel("Loss")
    fig.tight_layout()
    save(fig, "learning_rate.png")


def overfitting():
    ep = np.arange(1, 61)
    train = 0.65 * np.exp(-ep / 12) + 0.05
    val = 0.62 * np.exp(-ep / 11) + 0.1 + 0.0035 * np.maximum(0, ep - 22) ** 1.15
    fig, ax = plt.subplots(figsize=(6.2, 4))
    ax.plot(ep, train, color=NAVY, lw=3, label="Loss training")
    ax.plot(ep, val, color=RED, lw=3, label="Loss validasi")
    best = ep[np.argmin(val)]
    ax.axvline(best, color=GOLD, lw=2, ls="--")
    ax.text(best + 1, 0.40, "titik terbaik\n(early stopping)", color=NAVY, fontsize=11)
    ax.axvspan(best, 60, color=RED, alpha=0.06)
    ax.text(45, 0.08, "overfitting", color=RED, fontweight="bold", ha="center", fontstyle="italic")
    ax.set_xlabel("Epoch")
    ax.set_ylabel("Loss")
    ax.legend(loc="upper right")
    ax.grid(alpha=0.25)
    save(fig, "overfitting.png")


def nslkdd_distribution():
    # Jumlah record KDDTrain+ (Tavallaee dkk., 2009)
    cats = ["Normal", "DoS", "Probe", "R2L", "U2R"]
    counts = [67343, 45927, 11656, 995, 52]
    colors = [TEAL, RED, GOLD, NAVY2, GRAY]
    fig, ax = plt.subplots(figsize=(6, 3.6))
    bars = ax.barh(cats[::-1], counts[::-1], color=colors[::-1])
    for b, c in zip(bars, counts[::-1]):
        ax.text(b.get_width() + 800, b.get_y() + b.get_height() / 2, f"{c:,}".replace(",", "."),
                va="center", color=NAVY, fontsize=11)
    ax.set_xlim(0, 80000)
    ax.set_xlabel("Jumlah record (KDDTrain+)")
    ax.spines["left"].set_visible(False)
    ax.tick_params(axis="y", length=0)
    save(fig, "nslkdd_distribusi.png")


if __name__ == "__main__":
    activations()
    xor()
    link_quality()
    gradient_descent()
    learning_rates()
    overfitting()
    nslkdd_distribution()
