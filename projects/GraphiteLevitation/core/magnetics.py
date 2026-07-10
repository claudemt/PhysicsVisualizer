from __future__ import annotations

from dataclasses import dataclass

import numpy as np

from .params import GraphiteParams


@dataclass
class Magnets:
    x: np.ndarray
    y: np.ndarray
    z: np.ndarray
    sign: np.ndarray
    a: float
    b: float
    c: float
    br: float


def build_compact_checkerboard_magnets(params: GraphiteParams) -> Magnets:
    xs = (np.arange(1, params.array_nx + 1) - (params.array_nx + 1) / 2) * params.magnet_a
    ys = (np.arange(1, params.array_ny + 1) - (params.array_ny + 1) / 2) * params.magnet_b
    X, Y = np.meshgrid(xs, ys)
    S = np.fromfunction(lambda iy, ix: (-1.0) ** (ix + iy), X.shape)
    return Magnets(
        x=X.ravel(),
        y=Y.ravel(),
        z=np.full(X.size, -params.magnet_c / 2),
        sign=S.ravel(),
        a=params.magnet_a,
        b=params.magnet_b,
        c=params.magnet_c,
        br=params.br,
    )


def evaluate_dipole_field_map(X, Y, z: float, magnets: Magnets, params: GraphiteParams):
    Bx = np.zeros_like(X, dtype=float)
    By = np.zeros_like(X, dtype=float)
    Bz = np.zeros_like(X, dtype=float)
    volume = magnets.a * magnets.b * magnets.c
    m0 = magnets.br / params.mu0 * volume
    soft = 0.25 * min(magnets.a, magnets.b, magnets.c)
    for x0, y0, z0, sign in zip(magnets.x, magnets.y, magnets.z, magnets.sign):
        rx = X - x0
        ry = Y - y0
        rz = z - z0
        r2 = rx * rx + ry * ry + rz * rz + soft * soft
        r = np.sqrt(r2)
        m = sign * m0
        mdotr = m * rz
        coef = params.mu0 / (4 * np.pi)
        Bx += coef * (3 * rx * mdotr / r**5)
        By += coef * (3 * ry * mdotr / r**5)
        Bz += coef * (3 * rz * mdotr / r**5 - m / r**3)
    return {"Bx": Bx, "By": By, "Bz": Bz}
