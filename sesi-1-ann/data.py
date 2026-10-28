"""Mengunduh dan membaca dataset NSL-KDD."""

import urllib.request

import pandas as pd

import config


def download(url, filename):
    """Unduh file ke folder data/ (hanya jika belum ada)."""
    path = config.DATA_DIR / filename
    if not path.exists():
        print(f"Mengunduh {filename} ...")
        config.DATA_DIR.mkdir(exist_ok=True)
        urllib.request.urlretrieve(url, path)
    return path


def load_nslkdd():
    """Baca data latih (KDDTrain+) dan data uji (KDDTest+) sebagai tabel."""
    train_path = download(config.TRAIN_URL, "KDDTrain+.txt")
    test_path = download(config.TEST_URL, "KDDTest+.txt")

    train_df = pd.read_csv(train_path, names=config.COLUMNS)
    test_df = pd.read_csv(test_path, names=config.COLUMNS)

    print(f"KDDTrain+: {len(train_df):,} koneksi | KDDTest+: {len(test_df):,} koneksi")
    return train_df, test_df
