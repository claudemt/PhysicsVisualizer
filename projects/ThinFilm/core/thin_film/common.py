from __future__ import annotations

import cmath

import numpy as np


def cot(x):
    return 1.0 / np.tan(x)


def csqrt(x):
    return np.sqrt(np.asarray(x, dtype=complex)).item()


def casin(x):
    return np.arcsin(np.asarray(x, dtype=complex)).item()


def clean_scalar(value):
    if isinstance(value, (complex, np.complexfloating)):
        if abs(value.imag) < 1e-12 * max(1.0, abs(value.real)):
            return float(value.real)
        return complex(value)
    if isinstance(value, np.generic):
        return value.item()
    return value


def clean_tree(value):
    if isinstance(value, dict):
        return {key: clean_tree(item) for key, item in value.items()}
    if isinstance(value, list):
        return [clean_tree(item) for item in value]
    if isinstance(value, tuple):
        return tuple(clean_tree(item) for item in value)
    if isinstance(value, np.ndarray):
        return value
    return clean_scalar(value)


def fmt(value) -> str:
    value = clean_scalar(value)
    if isinstance(value, complex):
        return f"{value.real:.12g}{value.imag:+.12g}i"
    if isinstance(value, float):
        return f"{value:.12g}"
    if isinstance(value, np.ndarray):
        return np.array2string(value, precision=8)
    return str(value)


def phase_unwrap(value):
    return cmath.phase(complex(value))
