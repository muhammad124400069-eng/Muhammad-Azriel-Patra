"""Mengukur kinerja model: prediksi, metrik, dan confusion matrix."""

import torch
from sklearn.metrics import accuracy_score, confusion_matrix, f1_score, precision_score, recall_score


def predict(model, X):
    """Prediksi 0 (normal) atau 1 (serangan) untuk setiap koneksi."""
    model.eval()
    with torch.no_grad():
        outputs = model(torch.tensor(X))
        probabilities = torch.sigmoid(outputs)  # ubah output menjadi peluang 0..1
    predictions = (probabilities > 0.5).float()   # ambang batas 0.5
    return predictions.numpy().flatten()


def evaluate(name, y_true, y_pred):
    """Cetak metrik evaluasi dan kembalikan dalam bentuk dictionary."""
    metrics = {
        "accuracy": accuracy_score(y_true, y_pred),
        "precision": precision_score(y_true, y_pred),
        "recall": recall_score(y_true, y_pred),
        "f1": f1_score(y_true, y_pred),
    }
    tn, fp, fn, tp = confusion_matrix(y_true, y_pred).ravel()

    print(f"\n[{name}]")
    print(f"  Akurasi  : {metrics['accuracy']:.4f}")
    print(f"  Precision: {metrics['precision']:.4f}")
    print(f"  Recall   : {metrics['recall']:.4f}   <- serangan yang terdeteksi")
    print(f"  F1       : {metrics['f1']:.4f}")
    print(f"  TP={tp:,}  FN={fn:,} (serangan lolos)  FP={fp:,} (alarm palsu)  TN={tn:,}")
    return metrics
