"""Proses training: forward, loss, backward, update bobot."""

import copy

import torch
import torch.nn as nn

import config


def train_one_epoch(model, loader, loss_fn, optimizer):
    """Satu epoch = satu putaran melihat seluruh data latih, batch demi batch."""
    model.train()
    total_loss = 0.0
    for inputs, targets in loader:
        outputs = model(inputs)             # 1. forward
        loss = loss_fn(outputs, targets)    # 2. hitung loss
        optimizer.zero_grad()               # 3. hapus gradien lama
        loss.backward()                     # 4. backpropagation
        optimizer.step()                    # 5. update bobot
        total_loss += loss.item() * len(inputs)
    return total_loss / len(loader.dataset)


def validate(model, loader, loss_fn):
    """Hitung loss di data validasi (tanpa mengubah bobot)."""
    model.eval()
    total_loss = 0.0
    with torch.no_grad():  # tidak perlu gradien -> lebih cepat
        for inputs, targets in loader:
            outputs = model(inputs)
            total_loss += loss_fn(outputs, targets).item() * len(inputs)
    return total_loss / len(loader.dataset)


def train_model(model, train_loader, val_loader):
    """Latih model beberapa epoch dan simpan bobot dengan val loss terbaik."""
    loss_fn = nn.BCEWithLogitsLoss()  # sigmoid + binary cross-entropy
    optimizer = torch.optim.Adam(model.parameters(), lr=config.LEARNING_RATE)

    history = {"train": [], "val": []}
    best_val_loss = float("inf")
    best_weights = None
    epochs_without_improvement = 0

    print(f"Iterasi per epoch: {len(train_loader)}")
    for epoch in range(1, config.EPOCHS + 1):
        train_loss = train_one_epoch(model, train_loader, loss_fn, optimizer)
        val_loss = validate(model, val_loader, loss_fn)
        history["train"].append(train_loss)
        history["val"].append(val_loss)

        mark = ""
        if val_loss < best_val_loss:
            # model membaik -> simpan salinan bobotnya
            best_val_loss = val_loss
            best_weights = copy.deepcopy(model.state_dict())
            epochs_without_improvement = 0
            mark = " *"
        else:
            epochs_without_improvement += 1

        print(f"Epoch {epoch:2d}/{config.EPOCHS} | train loss {train_loss:.4f} | val loss {val_loss:.4f}{mark}")

        # early stopping: berhenti jika sudah lama tidak membaik (mencegah overfitting)
        if epochs_without_improvement == config.PATIENCE:
            print(f"Early stopping: val loss tidak membaik selama {config.PATIENCE} epoch")
            break

    model.load_state_dict(best_weights)  # kembalikan ke bobot terbaik
    return history
