"""Arsitektur ANN (Multi-Layer Perceptron)."""

import torch.nn as nn

import config


def build_model(n_features):
    """MLP: input -> hidden 1 (ReLU) -> hidden 2 (ReLU) -> 1 output."""
    model = nn.Sequential(
        nn.Linear(n_features, config.HIDDEN_1),
        nn.ReLU(),
        nn.Linear(config.HIDDEN_1, config.HIDDEN_2),
        nn.ReLU(),
        nn.Linear(config.HIDDEN_2, 1),
        # tanpa sigmoid di sini: sudah termasuk di dalam BCEWithLogitsLoss
    )
    return model


def count_parameters(model):
    """Jumlah seluruh bobot + bias yang dipelajari model."""
    return sum(p.numel() for p in model.parameters())
