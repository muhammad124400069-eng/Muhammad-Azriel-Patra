"""
Eksperimen pendukung paper: multi-seed, ablasi log1p, analisis per kategori & ambang.
Memakai modul pipeline Sesi 1 apa adanya.

Jalankan dari root repo:
    uv run python paper/scripts/experiments.py
Hasil: paper/results.json dan gambar di paper/img/.
"""

import json
import sys
from pathlib import Path

import numpy as np
import torch
from sklearn.metrics import accuracy_score, f1_score, precision_score, recall_score, roc_auc_score

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "sesi-1-ann"))

import config  # noqa: E402
from data import load_nslkdd  # noqa: E402
from model import build_model  # noqa: E402
from preprocessing import encode_features, make_labels, make_loader, scale_features, split_train_val  # noqa: E402
from training import train_model  # noqa: E402

SEEDS = [42, 0, 1, 2, 3]
HEAVY = ["duration", "src_bytes", "dst_bytes", "hot", "num_compromised", "num_root",
         "num_file_creations", "num_access_files", "count", "srv_count",
         "dst_host_count", "dst_host_srv_count"]
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


def proba(model, X):
    model.eval()
    with torch.no_grad():
        return torch.sigmoid(model(torch.tensor(X))).numpy().ravel()


def metrics(y, p, thr=0.5):
    pred = (p > thr).astype(int)
    return {"accuracy": accuracy_score(y, pred), "precision": precision_score(y, pred),
            "recall": recall_score(y, pred), "f1": f1_score(y, pred), "auc": roc_auc_score(y, p)}


def prepare(train_df, test_df, log_transform):
    if log_transform:
        train_df, test_df = train_df.copy(), test_df.copy()
        for df in (train_df, test_df):
            df[HEAVY] = np.log1p(df[HEAVY])
    y_all, y_test = make_labels(train_df), make_labels(test_df)
    X_all, X_test = encode_features(train_df, test_df)
    X_tr, X_val, y_tr, y_val = split_train_val(X_all, y_all)
    X_tr, X_val, X_test = scale_features(X_tr, X_val, X_test)
    return X_tr, X_val, X_test, y_tr, y_val, y_test


def run(seed, data):
    X_tr, X_val, X_test, y_tr, y_val, y_test = data
    np.random.seed(seed)
    torch.manual_seed(seed)
    model = build_model(X_tr.shape[1])
    history = train_model(model, make_loader(X_tr, y_tr, shuffle=True), make_loader(X_val, y_val))
    return model, history


def main():
    train_df, test_df = load_nslkdd()
    results = {"seeds": SEEDS, "variants": {}}

    for variant, log_t in [("baseline", False), ("log1p", True)]:
        data = prepare(train_df, test_df, log_t)
        X_val, X_test, y_val, y_test = data[1], data[2], data[4], data[5]
        runs = []
        for seed in SEEDS:
            model, history = run(seed, data)
            p_val, p_test = proba(model, X_val), proba(model, X_test)
            runs.append({"seed": seed, "epochs": len(history["train"]),
                         "val": metrics(y_val, p_val), "test": metrics(y_test, p_test)})

            if variant == "baseline" and seed == 42:
                pred = p_test > 0.5
                labels = test_df["label"]
                cat = labels.map(ATTACK_CATEGORY).fillna("Normal")
                known = labels.isin(set(train_df["label"]))
                per_cat = {}
                for c in ["DoS", "Probe", "R2L", "U2R"]:
                    for kname, kmask in [("dikenal", known), ("baru", ~known)]:
                        m = ((cat == c) & kmask).to_numpy()
                        if m.sum():
                            per_cat[f"{c}|{kname}"] = {"n": int(m.sum()), "detected": int(pred[m].sum())}
                normal = (cat == "Normal").to_numpy()
                per_cat["Normal|-"] = {"n": int(normal.sum()), "false_alarm": int(pred[normal].sum())}
                thresholds = np.round(np.arange(0.05, 0.96, 0.05), 2)
                sweep = [{"thr": float(t), **{k: v for k, v in metrics(y_test, p_test, t).items() if k != "auc"},
                          "val_f1": f1_score(y_val, (p_val > t).astype(int))} for t in thresholds]
                results["seed42"] = {"history": history, "per_category": per_cat, "threshold_sweep": sweep,
                                     "roc_test": roc_points(y_test, p_test)}
        results["variants"][variant] = runs

    out = ROOT / "paper" / "results.json"
    out.write_text(json.dumps(results, indent=2))
    for variant, runs in results["variants"].items():
        print(f"\n== {variant}")
        for split in ("val", "test"):
            for k in ("accuracy", "precision", "recall", "f1", "auc"):
                v = [r[split][k] for r in runs]
                print(f"  {split:4s} {k:9s} {np.mean(v):.4f} ± {np.std(v, ddof=1):.4f}")
    print(json.dumps(results["seed42"]["per_category"], indent=1))


def roc_points(y, p):
    from sklearn.metrics import roc_curve
    fpr, tpr, _ = roc_curve(y, p)
    idx = np.linspace(0, len(fpr) - 1, 200).astype(int)
    return {"fpr": fpr[idx].tolist(), "tpr": tpr[idx].tolist()}


if __name__ == "__main__":
    main()
