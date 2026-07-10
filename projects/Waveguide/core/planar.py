from __future__ import annotations

from dataclasses import dataclass

import numpy as np
from scipy.optimize import brentq, minimize_scalar

from .metal import C0


@dataclass(frozen=True)
class PlanarCurve:
    order: int
    V: np.ndarray
    b: np.ndarray
    neff: np.ndarray
    u: np.ndarray


def _cot(x):
    return 1.0 / np.tan(x)


def _safe_eval(fun, value: float) -> float:
    try:
        y = float(fun(value))
    except (ValueError, FloatingPointError, ZeroDivisionError, OverflowError):
        return np.nan
    return y if np.isfinite(y) else np.nan


def planar_solve_u(mode_type: str, order: int, V: float, n1: float, n2: float) -> tuple[float, float, float, bool]:
    """Solve the symmetric slab eigenvalue equation for normalized u."""
    if V <= 0 or order < 0 or n1 <= n2:
        return np.nan, np.nan, np.nan, False
    lower = order * np.pi / 2
    upper = (order + 1) * np.pi / 2
    if V <= lower:
        return np.nan, np.nan, np.nan, False
    eps_u = 1e-8
    left = lower + eps_u
    right = min(upper - eps_u, V - eps_u)
    if right <= left:
        return np.nan, np.nan, np.nan, False
    ratio = 1.0 if mode_type.upper() == "TE" else (n2 / n1) ** 2
    if order % 2 == 0:
        fun = lambda x: np.sqrt(max(V**2 - x**2, 0.0)) - ratio * x * np.tan(x)
    else:
        fun = lambda x: np.sqrt(max(V**2 - x**2, 0.0)) + ratio * x * _cot(x)

    xs = np.linspace(left, right, 100)
    ys = np.array([_safe_eval(fun, x) for x in xs])
    good = np.isfinite(ys)
    bracket = None
    for idx in range(len(xs) - 1):
        if good[idx] and good[idx + 1] and ys[idx] * ys[idx + 1] <= 0:
            bracket = (xs[idx], xs[idx + 1])
            break
    try:
        if bracket is not None:
            u = brentq(fun, bracket[0], bracket[1], xtol=1e-12, rtol=1e-12, maxiter=80)
        else:
            finite_x = xs[good]
            if finite_x.size == 0:
                return np.nan, np.nan, np.nan, False
            center = finite_x[np.nanargmin(np.abs(ys[good]))]
            span = (right - left) / 100
            lo = max(left, center - span)
            hi = min(right, center + span)
            result = minimize_scalar(lambda x: abs(_safe_eval(fun, x)), bounds=(lo, hi), method="bounded")
            if not result.success:
                return np.nan, np.nan, np.nan, False
            u = float(result.x)
        if not (np.isfinite(u) and lower < u < min(upper, V)):
            return np.nan, np.nan, np.nan, False
        w = np.sqrt(max(V**2 - u**2, 0.0))
        b_norm = (w / V) ** 2
        ok = np.isfinite(b_norm) and -1e-8 <= b_norm <= 1 + 1e-8
        return u, w, min(max(b_norm, 0.0), 1.0), bool(ok)
    except (ValueError, FloatingPointError, RuntimeError):
        return np.nan, np.nan, np.nan, False


def planar_dispersion(
    mode_type: str,
    n1: float,
    n2: float,
    Vmax: float,
    max_order: int,
    samples: int = 260,
) -> dict:
    if n1 <= n2:
        raise ValueError("Planar dispersion requires n1 > n2.")
    if Vmax <= 0:
        raise ValueError("V max must be positive.")
    V_values = np.linspace(1e-4, Vmax, max(160, int(samples)))
    curves: list[PlanarCurve] = []
    for order in range(max_order + 1):
        vv: list[float] = []
        bb: list[float] = []
        nn: list[float] = []
        uu: list[float] = []
        for value in V_values:
            u, _w, b_norm, ok = planar_solve_u(mode_type, order, float(value), n1, n2)
            if ok:
                vv.append(float(value))
                bb.append(float(b_norm))
                nn.append(float(np.sqrt(n2**2 + b_norm * (n1**2 - n2**2))))
                uu.append(float(u))
        if len(vv) >= 5:
            curves.append(PlanarCurve(order, np.array(vv), np.array(bb), np.array(nn), np.array(uu)))
    if not curves:
        raise ValueError("No guided planar branches were found.")
    return {"mode_type": mode_type.upper(), "n1": n1, "n2": n2, "Vmax": Vmax, "curves": curves}


def planar_field(
    mode_type: str,
    order: int,
    freq_ghz: float,
    n1: float,
    n2: float,
    d: float,
    z_length: float = 8.0,
    grid_n: int = 220,
) -> dict:
    if n1 <= n2:
        raise ValueError("Planar guidance requires nco > ncl.")
    k0 = 2 * np.pi * freq_ghz * 1e9 / C0
    V = k0 * d * np.sqrt(n1**2 - n2**2) / 2
    u, w, b_norm, ok = planar_solve_u(mode_type, order, V, n1, n2)
    if not ok:
        raise ValueError("The selected planar mode is not guided at this frequency.")
    neff = np.sqrt(n2**2 + b_norm * (n1**2 - n2**2))
    beta = k0 * neff
    kx = 2 * u / d
    gamma = 2 * w / d
    x_span = max(1.25 * d, d / 2 + 4 / max(gamma, 1e-12))
    x = np.linspace(-x_span, x_span, int(grid_n))
    z = np.linspace(0, z_length, int(grid_n))
    x_grid, z_grid = np.meshgrid(x, z)
    x_abs = np.abs(x_grid)
    inside = x_abs <= d / 2
    profile = np.zeros_like(x_grid)
    if order % 2 == 0:
        core = np.cos(kx * x_grid)
        boundary = np.cos(u)
        clad = boundary * np.exp(-gamma * (x_abs - d / 2))
    else:
        core = np.sin(kx * x_grid)
        boundary = np.sin(u)
        clad = np.sign(x_grid) * boundary * np.exp(-gamma * (x_abs - d / 2))
    profile[inside] = core[inside]
    profile[~inside] = clad[~inside]
    field = profile * np.cos(beta * z_grid)
    field = field / (np.nanmax(np.abs(field)) + np.finfo(float).eps)
    cutoff_ghz = order * C0 / (2 * d * np.sqrt(n1**2 - n2**2)) / 1e9
    cb_label = "$E_y$" if mode_type.upper() == "TE" else "$H_y$"
    return {
        "x": x_grid / d,
        "z": z_grid / d,
        "field": field,
        "V": V,
        "u": u,
        "w": w,
        "b": b_norm,
        "neff": neff,
        "cb_label": cb_label,
        "cutoffV": order * np.pi / 2,
        "title": (
            f"$\\mathrm{{{mode_type.upper()}}}_{{{order}}},\\ "
            f"f={freq_ghz:.4g}\\ \\mathrm{{GHz}},\\ "
            f"f_{{\\mathrm{{c}}}}={cutoff_ghz:.4g}\\ \\mathrm{{GHz}}$"
        ),
    }


def planar_existence(mode_type: str, Vmax: float, max_order: int) -> dict:
    orders = np.arange(max_order + 1)
    cutoff_v = orders * np.pi / 2
    keep = cutoff_v <= Vmax
    return {"mode_type": mode_type.upper(), "orders": orders[keep], "cutoffV": cutoff_v[keep], "Vmax": Vmax}


def planar_thickness_sweep(
    mode_type: str,
    n1: float,
    n2: float,
    d0: float,
    freq_ghz: float,
    max_order: int,
    samples: int = 180,
) -> dict:
    if n1 <= n2:
        raise ValueError("Planar sweep requires n1 > n2.")
    d_values = np.linspace(max(d0 * 0.15, np.finfo(float).eps), d0 * 2.5, int(samples))
    mode_count = np.zeros_like(d_values)
    branches = [{"order": order, "neff": np.full_like(d_values, np.nan)} for order in range(max_order + 1)]
    k0 = 2 * np.pi * freq_ghz * 1e9 / C0
    for idx, d in enumerate(d_values):
        V = k0 * d * np.sqrt(n1**2 - n2**2) / 2
        count = 0
        for order in range(max_order + 1):
            _u, _w, b_norm, ok = planar_solve_u(mode_type, order, float(V), n1, n2)
            if ok:
                count += 1
                branches[order]["neff"][idx] = np.sqrt(n2**2 + b_norm * (n1**2 - n2**2))
        mode_count[idx] = count
    return {
        "mode_type": mode_type.upper(),
        "n1": n1,
        "n2": n2,
        "dValues": d_values,
        "freqGHz": freq_ghz,
        "modeCount": mode_count,
        "branches": branches,
    }
