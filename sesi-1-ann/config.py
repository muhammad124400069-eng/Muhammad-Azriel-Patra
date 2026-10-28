"""
Pengaturan eksperimen.
Ubah angka di sini lalu jalankan ulang train.py untuk mencoba hal baru.
"""

from pathlib import Path

# ---- Hyperparameter training ----
EPOCHS = 10            # berapa kali model melihat seluruh data latih
BATCH_SIZE = 64        # jumlah data per satu langkah update bobot
LEARNING_RATE = 0.001  # besar langkah gradient descent
VAL_SIZE = 0.2         # 20% data latih disisihkan untuk validasi
PATIENCE = 3           # berhenti jika val loss tidak membaik 3 epoch berturut-turut
SEED = 42              # angka acak tetap -> hasil bisa diulang

# ---- Arsitektur model: 122 input -> 64 -> 32 -> 1 output ----
HIDDEN_1 = 64
HIDDEN_2 = 32

# ---- Lokasi file (relatif terhadap folder ini) ----
FOLDER = Path(__file__).parent
DATA_DIR = FOLDER / "data"
OUTPUT_DIR = FOLDER / "outputs"

# ---- Dataset NSL-KDD (sumber asli: https://www.unb.ca/cic/datasets/nsl.html) ----
TRAIN_URL = "https://raw.githubusercontent.com/defcom17/NSL_KDD/master/KDDTrain%2B.txt"
TEST_URL = "https://raw.githubusercontent.com/defcom17/NSL_KDD/master/KDDTest%2B.txt"

# 41 fitur koneksi jaringan + label serangan + tingkat kesulitan
COLUMNS = [
    "duration", "protocol_type", "service", "flag", "src_bytes", "dst_bytes", "land",
    "wrong_fragment", "urgent", "hot", "num_failed_logins", "logged_in", "num_compromised",
    "root_shell", "su_attempted", "num_root", "num_file_creations", "num_shells",
    "num_access_files", "num_outbound_cmds", "is_host_login", "is_guest_login", "count",
    "srv_count", "serror_rate", "srv_serror_rate", "rerror_rate", "srv_rerror_rate",
    "same_srv_rate", "diff_srv_rate", "srv_diff_host_rate", "dst_host_count",
    "dst_host_srv_count", "dst_host_same_srv_rate", "dst_host_diff_srv_rate",
    "dst_host_same_src_port_rate", "dst_host_srv_diff_host_rate", "dst_host_serror_rate",
    "dst_host_srv_serror_rate", "dst_host_rerror_rate", "dst_host_srv_rerror_rate",
    "label", "difficulty",
]

# fitur berupa teks (bukan angka) -> perlu one-hot encoding
CATEGORICAL = ["protocol_type", "service", "flag"]
