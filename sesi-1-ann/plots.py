"""Membuat grafik hasil training."""

import matplotlib

matplotlib.use("Agg")  # simpan grafik ke file, tanpa membuka jendela
import matplotlib.pyplot as plt
from sklearn.metrics import confusion_matrix


def plot_loss(history, path):
    """Kurva loss train vs validasi per epoch."""
    epochs = range(1, len(history["train"]) + 1)
    plt.figure(figsize=(6, 4))
    plt.plot(epochs, history["train"], "o-", color="#0B1F3A", label="train")
    plt.plot(epochs, history["val"], "o-", color="#C8102E", label="validasi")
    plt.xlabel("Epoch")
    plt.ylabel("BCE loss")
    plt.title("Kurva loss training")
    plt.grid(alpha=0.3)
    plt.legend()
    plt.tight_layout()
    plt.savefig(path, dpi=150)
    plt.close()


def plot_confusion_matrix(y_true, y_pred, path):
    """Confusion matrix: baris = label asli, kolom = prediksi."""
    cm = confusion_matrix(y_true, y_pred)
    labels = ["Normal", "Serangan"]
    plt.figure(figsize=(4.5, 4))
    plt.imshow(cm, cmap="Blues")
    for i in range(2):
        for j in range(2):
            color = "white" if cm[i, j] > cm.max() / 2 else "black"
            plt.text(j, i, f"{cm[i, j]:,}", ha="center", va="center", color=color)
    plt.xticks([0, 1], labels)
    plt.yticks([0, 1], labels)
    plt.xlabel("Prediksi")
    plt.ylabel("Label asli")
    plt.title("Confusion matrix (KDDTest+)")
    plt.tight_layout()
    plt.savefig(path, dpi=150)
    plt.close()
