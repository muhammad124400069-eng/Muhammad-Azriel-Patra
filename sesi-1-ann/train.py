"""
Sesi 1 — ANN untuk Deteksi Intrusi Jaringan (NSL-KDD)
Workshop Deep Learning · Teknik Telekomunikasi ITERA

Jalankan dari root repo:
    uv run python sesi-1-ann/train.py

Pengaturan (epoch, learning rate, dll.) ada di config.py.
Hasil (model, grafik, metrik) disimpan di sesi-1-ann/outputs/.
"""

import json

import numpy as np
import torch

import config
from data import load_nslkdd
from evaluation import evaluate, predict
from model import build_model, count_parameters
from plots import plot_confusion_matrix, plot_loss
from preprocessing import encode_features, make_labels, make_loader, scale_features, split_train_val
from training import train_model

# 1. PERSIAPAN — angka acak tetap supaya hasil bisa diulang
np.random.seed(config.SEED)
torch.manual_seed(config.SEED)

# 2. MUAT DATA
train_df, test_df = load_nslkdd()

# 3. PRA-PEMROSESAN
y_all = make_labels(train_df)
y_test = make_labels(test_df)
X_all, X_test = encode_features(train_df, test_df)
X_train, X_val, y_train, y_val = split_train_val(X_all, y_all)
X_train, X_val, X_test = scale_features(X_train, X_val, X_test)

train_loader = make_loader(X_train, y_train, shuffle=True)
val_loader = make_loader(X_val, y_val)

# 4. MODEL
model = build_model(n_features=X_train.shape[1])
print(model)
print(f"Total parameter: {count_parameters(model):,}")

# 5. TRAINING
history = train_model(model, train_loader, val_loader)

# 6. EVALUASI
val_metrics = evaluate("Validasi", y_val, predict(model, X_val))
y_pred = predict(model, X_test)
test_metrics = evaluate("Test (KDDTest+)", y_test, y_pred)

# 7. SIMPAN HASIL
config.OUTPUT_DIR.mkdir(exist_ok=True)
torch.save(model.state_dict(), config.OUTPUT_DIR / "model.pt")
plot_loss(history, config.OUTPUT_DIR / "loss_curve.png")
plot_confusion_matrix(y_test, y_pred, config.OUTPUT_DIR / "confusion_matrix.png")
with open(config.OUTPUT_DIR / "metrics.json", "w") as f:
    json.dump({"validation": val_metrics, "test": test_metrics, "history": history}, f, indent=2)
print("\nHasil disimpan di folder sesi-1-ann/outputs/")
