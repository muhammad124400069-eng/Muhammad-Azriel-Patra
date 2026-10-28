"""Mengubah tabel mentah menjadi angka yang siap dimasukkan ke model."""

import numpy as np
import pandas as pd
import torch
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from torch.utils.data import DataLoader, TensorDataset

import config


def make_labels(df):
    """Label biner: normal -> 0, serangan apa pun (DoS, Probe, R2L, U2R) -> 1."""
    is_attack = df["label"] != "normal"
    return is_attack.to_numpy().astype(np.float32)


def encode_features(train_df, test_df):
    """One-hot encoding untuk 3 fitur teks. Hasil: 41 fitur -> 122 kolom angka."""
    features = train_df.drop(columns=["label", "difficulty"])
    X_train = pd.get_dummies(features, columns=config.CATEGORICAL)

    features = test_df.drop(columns=["label", "difficulty"])
    X_test = pd.get_dummies(features, columns=config.CATEGORICAL)

    # samakan kolom data uji dengan data latih (kategori yang tidak ada diisi 0)
    X_test = X_test.reindex(columns=X_train.columns, fill_value=0)

    print(f"Jumlah fitur setelah one-hot: {X_train.shape[1]}")
    return X_train.to_numpy(np.float32), X_test.to_numpy(np.float32)


def split_train_val(X, y):
    """Sisihkan sebagian data latih untuk validasi (proporsi normal/serangan dijaga)."""
    X_train, X_val, y_train, y_val = train_test_split(
        X, y, test_size=config.VAL_SIZE, stratify=y, random_state=config.SEED
    )
    print(f"Data latih: {len(X_train):,} | Data validasi: {len(X_val):,}")
    return X_train, X_val, y_train, y_val


def scale_features(X_train, X_val, X_test):
    """Standardization: rata-rata 0, standar deviasi 1.
    Scaler HANYA belajar dari data latih, lalu dipakai ke validasi & uji."""
    scaler = StandardScaler()
    X_train = scaler.fit_transform(X_train).astype(np.float32)
    X_val = scaler.transform(X_val).astype(np.float32)
    X_test = scaler.transform(X_test).astype(np.float32)
    return X_train, X_val, X_test


def make_loader(X, y, shuffle=False):
    """Bungkus data menjadi DataLoader yang membagi data ke dalam batch."""
    inputs = torch.tensor(X)
    targets = torch.tensor(y).reshape(-1, 1)  # bentuk (N, 1), sama dengan output model
    dataset = TensorDataset(inputs, targets)
    return DataLoader(dataset, batch_size=config.BATCH_SIZE, shuffle=shuffle)
