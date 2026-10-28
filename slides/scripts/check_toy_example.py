"""Verifikasi angka contoh toy (kualitas link dari SNR & RSSI) yang dipakai di slide Sesi 1."""
import numpy as np

sig = lambda z: 1 / (1 + np.exp(-z))
relu = lambda z: np.maximum(0, z)

# --- Neuron tunggal ---
x = np.array([0.8, 0.6])
w, b = np.array([2.0, 1.5]), -1.5
z = w @ x + b
print(f"[neuron] z={z:.4f} sigmoid={sig(z):.4f}")

# --- Jaringan 2-2-1 ---
W1 = np.array([[0.5, -0.3], [0.2, 0.8]]); b1 = np.array([0.1, -0.2])
w2 = np.array([1.0, -0.5]); b2 = 0.2
y = 1.0

def forward(x, W1, b1, w2, b2):
    z1 = W1 @ x + b1; h = relu(z1)
    z2 = w2 @ h + b2; yhat = sig(z2)
    return z1, h, z2, yhat

def bce(y, p): return -(y * np.log(p) + (1 - y) * np.log(1 - p))

z1, h, z2, yhat = forward(x, W1, b1, w2, b2)
L = bce(y, yhat)
print(f"[ff] z1={z1} h={h} z2={z2:.4f} yhat={yhat:.4f} BCE={L:.4f} MSE={(y-yhat)**2:.4f}")

d2 = yhat - y
gw2 = d2 * h; gb2 = d2
d1 = d2 * w2 * (z1 > 0)
gW1 = np.outer(d1, x); gb1 = d1
print(f"[bp] delta_out={d2:.4f} dL/dw2={gw2} dL/db2={gb2:.4f}")
print(f"[bp] delta_hidden={d1} dL/dW1=\n{gW1}\n dL/db1={gb1}")

lr = 0.5
w2n = w2 - lr * gw2; b2n = b2 - lr * gb2
W1n = W1 - lr * gW1; b1n = b1 - lr * gb1
print(f"[upd] w2={w2n} b2={b2n:.4f}\n W1=\n{W1n}\n b1={b1n}")
_, hn, z2n, yhn = forward(x, W1n, b1n, w2n, b2n)
print(f"[after] h={hn} z2={z2n:.4f} yhat={yhn:.4f} BCE={bce(y, yhn):.4f}")

# --- Latihan: link buruk ---
xb = np.array([0.2, 0.3]); yb = 0.0
z1b, hb, z2b, yhb = forward(xb, W1, b1, w2, b2)
print(f"[latihan] z1={z1b} h={hb} z2={z2b:.4f} yhat={yhb:.4f} BCE={bce(yb, yhb):.4f}")
# params count
print("params NSL-KDD MLP (122-64-32-1):", 122*64+64 + 64*32+32 + 32*1+1)
