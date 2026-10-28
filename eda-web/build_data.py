"""
Menghitung ringkasan EDA NSL-KDD -> eda-web/data.js

Website bersifat statis: semua angka dihitung SEKALI di sini, lalu ditulis ke data.js
(window.EDA = {...}). Dengan begitu index.html bisa dibuka langsung dari file manager,
tanpa server dan tanpa koneksi internet.

Jalankan dari root repo:
    uv run python eda-web/build_data.py
"""

import json
import sys
from pathlib import Path

import numpy as np
import pandas as pd

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "sesi-1-ann"))

import config                 # noqa: E402  daftar kolom (sama dengan train.py)
from data import load_nslkdd  # noqa: E402  unduh + baca NSL-KDD

OUT = Path(__file__).resolve().parent / "data.js"

CATEGORIES = ["Normal", "DoS", "Probe", "R2L", "U2R"]
ATTACK_CATEGORY = {
    "back": "DoS", "land": "DoS", "neptune": "DoS", "pod": "DoS", "smurf": "DoS", "teardrop": "DoS",
    "apache2": "DoS", "mailbomb": "DoS", "processtable": "DoS", "udpstorm": "DoS",
    "ipsweep": "Probe", "nmap": "Probe", "portsweep": "Probe", "satan": "Probe", "mscan": "Probe", "saint": "Probe",
    "ftp_write": "R2L", "guess_passwd": "R2L", "imap": "R2L", "multihop": "R2L", "phf": "R2L", "spy": "R2L",
    "warezclient": "R2L", "warezmaster": "R2L", "named": "R2L", "sendmail": "R2L", "snmpgetattack": "R2L",
    "snmpguess": "R2L", "worm": "R2L", "xlock": "R2L", "xsnoop": "R2L",
    "buffer_overflow": "U2R", "loadmodule": "U2R", "perl": "U2R", "rootkit": "U2R",
    "httptunnel": "U2R", "ps": "U2R", "sqlattack": "U2R", "xterm": "U2R",
}

FEATURES = config.COLUMNS[:41]
GROUPS = [
    ("Dasar", FEATURES[:9]),
    ("Konten", FEATURES[9:22]),
    ("Trafik (2 detik)", FEATURES[22:31]),
    ("Trafik (host tujuan)", FEATURES[31:41]),
]
N_BINS = 40


def r(x, nd=4):
    """Bulatkan & ubah ke tipe Python biasa agar bisa di-JSON-kan."""
    return None if x is None or (isinstance(x, float) and np.isnan(x)) else round(float(x), nd)


def counts_by(df, col):
    return {k: int(v) for k, v in df[col].value_counts().items()}


def crosstab(df, col):
    """Jumlah koneksi per nilai fitur x kategori, terurut dari yang terbanyak."""
    t = pd.crosstab(df[col], df["category"]).reindex(columns=CATEGORIES, fill_value=0)
    t = t.loc[t.sum(axis=1).sort_values(ascending=False).index]
    return {str(k): [int(v) for v in row] for k, row in t.iterrows()}


def histogram(values, flag, log):
    """Histogram ternormalisasi (density) normal vs serangan, bin sama untuk keduanya."""
    v = np.log1p(values) if log else values
    edges = np.histogram_bin_edges(v, bins=N_BINS)
    out = {"edges": [r(e, 5) for e in edges]}
    for name, mask in (("normal", flag == 0), ("attack", flag == 1)):
        h, _ = np.histogram(v[mask], bins=edges, density=True)
        out[name] = [r(x, 6) for x in h]
    return out


def main():
    train, test = load_nslkdd()
    for df in (train, test):
        df["category"] = df["label"].map(ATTACK_CATEGORY).fillna("Normal")
        df["is_attack"] = (df["label"] != "normal").astype(int)

    categorical = config.CATEGORICAL
    numeric = [c for c in FEATURES if c not in categorical]
    binary = [c for c in numeric if set(train[c].unique()) <= {0, 1}]
    n_unique = train[FEATURES].nunique()
    constant = n_unique[n_unique == 1].index.tolist()
    usable = [c for c in numeric if c not in constant]

    # ---- label ----
    label_info = {}
    for lbl in sorted(set(train["label"]) | set(test["label"])):
        label_info[lbl] = {
            "category": ATTACK_CATEGORY.get(lbl, "Normal"),
            "train": int((train["label"] == lbl).sum()),
            "test": int((test["label"] == lbl).sum()),
        }
    new_attacks = sorted(set(test["label"]) - set(train["label"]))
    is_new = test["label"].isin(new_attacks)

    # ---- fitur numerik ----
    groups_of = {c: g for g, cols in GROUPS for c in cols}
    features = {}
    for c in FEATURES:
        entry = {"group": groups_of[c], "kind": "kategorikal" if c in categorical else
                 ("biner" if c in binary else "numerik"), "unique": int(n_unique[c])}
        if c in numeric:
            s = train[c]
            entry.update(
                min=r(s.min()), max=r(s.max()), mean=r(s.mean()), std=r(s.std()), median=r(s.median()),
                zero=r((s == 0).mean() * 100, 2),
                corr=None if c in constant else r(s.corr(train["is_attack"]), 4),
            )
            if c not in constant:
                vals = s.to_numpy(dtype=float)
                flag = train["is_attack"].to_numpy()
                entry["hist"] = histogram(vals, flag, log=False)
                entry["hist_log"] = histogram(vals, flag, log=True)
            # rata-rata per kategori (untuk profil)
            entry["by_cat"] = {k: r(v) for k, v in train.groupby("category")[c].mean().items()}
        features[c] = entry

    # ---- korelasi antar fitur ----
    corr = train[usable].corr()
    upper = corr.where(np.triu(np.ones(corr.shape, dtype=bool), k=1)).stack()
    redundant = upper[upper.abs() > 0.95].sort_values(ascending=False)

    # urutan fitur untuk heatmap: dikelompokkan agar blok korelasi terlihat (hierarchical-ish: urut per grup)
    # ---- difficulty ----
    diff_bins = list(range(0, 22))

    def diff_hist(df):
        h = df["difficulty"].value_counts(normalize=True).reindex(diff_bins, fill_value=0)
        return [r(x * 100, 3) for x in h]

    # ---- sampel baris untuk tabel penjelajah ----
    rng = np.random.default_rng(42)
    sample = train.iloc[np.sort(rng.choice(len(train), 400, replace=False))].copy()
    sample_cols = ["duration", "protocol_type", "service", "flag", "src_bytes", "dst_bytes",
                   "count", "serror_rate", "same_srv_rate", "logged_in", "label", "category"]
    sample_rows = [[(x.item() if hasattr(x, "item") else x) for x in row] for row in sample[sample_cols].to_numpy()]

    eda = {
        "categories": CATEGORIES,
        "sizes": {"train": len(train), "test": len(test)},
        "nFeatures": len(FEATURES),
        "quality": {
            name: {"missing": int(df.isna().sum().sum()), "duplicates": int(df.duplicated().sum())}
            for name, df in (("train", train), ("test", test))
        },
        "constant": constant,
        "groups": [{"name": g, "cols": cols} for g, cols in GROUPS],
        "categorical": categorical,
        "binary": binary,
        "numericCount": len(numeric),
        "features": features,
        "labels": label_info,
        "categoryCounts": {
            "train": counts_by(train, "category"), "test": counts_by(test, "category"),
        },
        "binaryShare": {
            "train": [int((train["is_attack"] == 0).sum()), int((train["is_attack"] == 1).sum())],
            "test": [int((test["is_attack"] == 0).sum()), int((test["is_attack"] == 1).sum())],
        },
        "newAttacks": {
            "names": new_attacks,
            "records": int(is_new.sum()),
            "share": r(is_new.mean() * 100, 2),
            "byCategory": counts_by(test[is_new], "category"),
        },
        "crosstab": {c: {"train": crosstab(train, c), "test": crosstab(test, c)} for c in categorical},
        "testMissingLevels": {c: sorted(set(test[c]) - set(train[c])) for c in categorical},
        "trainMissingLevels": {c: sorted(set(train[c]) - set(test[c])) for c in categorical},
        "corrMatrix": {"cols": usable, "values": [[r(v, 3) for v in row] for row in corr.to_numpy()]},
        "redundantPairs": [[a, b, r(v, 3)] for (a, b), v in redundant.items()],
        "difficulty": {"bins": diff_bins, "train": diff_hist(train), "test": diff_hist(test),
                       "trainMean": r(train["difficulty"].mean(), 2), "testMean": r(test["difficulty"].mean(), 2)},
        "protocolAttack": {
            "train": {k: r(v * 100, 2) for k, v in train.groupby("protocol_type")["is_attack"].mean().items()},
            "test": {k: r(v * 100, 2) for k, v in test.groupby("protocol_type")["is_attack"].mean().items()},
        },
        "oneHotWidth": len(pd.get_dummies(train[FEATURES], columns=categorical).columns),
        "sample": {"cols": sample_cols, "rows": sample_rows},
    }

    OUT.write_text(
        "// Dibuat otomatis oleh build_data.py - jangan diedit manual.\n"
        "window.EDA = " + json.dumps(eda, ensure_ascii=False, separators=(",", ":")) + ";\n",
        encoding="utf-8",
    )
    print(f"Ditulis: {OUT}  ({OUT.stat().st_size / 1024:.0f} KB)")


if __name__ == "__main__":
    main()
