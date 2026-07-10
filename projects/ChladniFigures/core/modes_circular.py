from __future__ import annotations

from functools import lru_cache
from dataclasses import dataclass

import numpy as np
from scipy import optimize, special


@dataclass
class CircularMode:
    x: np.ndarray
    y: np.ndarray
    u: np.ndarray
    lam_disp: float
    tag: str
    boundary: str
    mask: np.ndarray
    beta: float
    coeffs: np.ndarray


def _normalize(data: np.ndarray, mask: np.ndarray) -> np.ndarray:
    out = np.array(data, dtype=float)
    out[~mask] = np.nan
    amp = np.nanmax(np.abs(out))
    if np.isfinite(amp) and amp > 0:
        out = out / amp
    return out


def _parse_boundary(boundary: str, annulus: bool) -> str:
    text = str(boundary).strip().lower()
    if annulus:
        aliases = {"clamped-free": "cf", "free-clamped": "fc", "free": "ff", "clamped": "cc", "simply": "ss"}
        tag = aliases.get(text, text)
        if tag not in {"cc", "cs", "cf", "sc", "ss", "sf", "fc", "fs", "ff"}:
            raise ValueError(f"Unknown annulus boundary condition: {boundary!r}.")
        return tag
    aliases = {"clamped": "c", "simply": "s", "free": "f"}
    tag = aliases.get(text, text[:1])
    if tag not in {"c", "s", "f"}:
        raise ValueError(f"Unknown disk boundary condition: {boundary!r}.")
    return tag


def _besselj_pair(m: int, x: float) -> tuple[float, float]:
    j = special.jv(m, x)
    jd = -special.jv(1, x) if m == 0 else 0.5 * (special.jv(m - 1, x) - special.jv(m + 1, x))
    return float(j), float(jd)


def _bessely_pair(m: int, x: float) -> tuple[float, float]:
    y = special.yv(m, x)
    yd = -special.yv(1, x) if m == 0 else 0.5 * (special.yv(m - 1, x) - special.yv(m + 1, x))
    return float(y), float(yd)


def _besseli_scaled_pair(m: int, x: float, beta: float) -> tuple[float, float]:
    i_scaled = special.ive(m, x)
    if m == 0:
        id_scaled = special.ive(1, x)
    else:
        id_scaled = 0.5 * (special.ive(m - 1, x) + special.ive(m + 1, x))
    factor = np.exp(x - beta)
    return float(factor * i_scaled), float(factor * id_scaled)


def _besselk_scaled_pair(m: int, x: float, lam: float) -> tuple[float, float]:
    k_scaled = special.kve(m, x)
    if m == 0:
        kd_scaled = -special.kve(1, x)
    else:
        kd_scaled = -0.5 * (special.kve(m - 1, x) + special.kve(m + 1, x))
    factor = np.exp(lam - x)
    return float(factor * k_scaled), float(factor * kd_scaled)


def _disk_rows(edge: str, x: float, m: int, nu: float) -> np.ndarray:
    j, jd = _besselj_pair(m, x)
    iv, ivd = _besseli_scaled_pair(m, x, x)
    c0 = np.array([j, iv], dtype=float)
    c1 = np.array([x * jd, x * ivd], dtype=float)
    mom = np.array([
        x**2 * j + (1 - nu) * (x * jd - m**2 * j),
        -x**2 * iv + (1 - nu) * (x * ivd - m**2 * iv),
    ])
    shear = np.array([
        x**3 * jd + m**2 * (1 - nu) * (x * jd - j),
        -x**3 * ivd + m**2 * (1 - nu) * (x * ivd - iv),
    ])
    return {"c": np.vstack([c0, c1]), "s": np.vstack([c0, mom]), "f": np.vstack([mom, shear])}[edge]


def _annulus_rows(edge: str, x: float, beta: float, lam: float, m: int, nu: float) -> np.ndarray:
    j, jd = _besselj_pair(m, x)
    y, yd = _bessely_pair(m, x)
    iv, ivd = _besseli_scaled_pair(m, x, beta)
    kv, kvd = _besselk_scaled_pair(m, x, lam)
    c0 = np.array([j, y, iv, kv], dtype=float)
    c1 = np.array([x * jd, x * yd, x * ivd, x * kvd], dtype=float)
    mom = np.array([
        x**2 * j + (1 - nu) * (x * jd - m**2 * j),
        x**2 * y + (1 - nu) * (x * yd - m**2 * y),
        -x**2 * iv + (1 - nu) * (x * ivd - m**2 * iv),
        -x**2 * kv + (1 - nu) * (x * kvd - m**2 * kv),
    ])
    shear = np.array([
        x**3 * jd + m**2 * (1 - nu) * (x * jd - j),
        x**3 * yd + m**2 * (1 - nu) * (x * yd - y),
        -x**3 * ivd + m**2 * (1 - nu) * (x * ivd - iv),
        -x**3 * kvd + m**2 * (1 - nu) * (x * kvd - kv),
    ])
    return {"c": np.vstack([c0, c1]), "s": np.vstack([c0, mom]), "f": np.vstack([mom, shear])}[edge]


def _mode_matrix(beta: float, m: int, nu: float, boundary: str, xi0: float) -> np.ndarray:
    if xi0 > 0:
        lam = beta * xi0
        return np.vstack([
            _annulus_rows(boundary[0], beta, beta, lam, m, nu),
            _annulus_rows(boundary[1], lam, beta, lam, m, nu),
        ])
    return _disk_rows(boundary, beta, m, nu)


def _balance_matrix(matrix: np.ndarray) -> tuple[np.ndarray, np.ndarray]:
    row_scale = np.max(np.abs(matrix), axis=1)
    row_scale[row_scale < 1] = 1
    row_balanced = matrix / row_scale[:, None]
    col_scale = np.max(np.abs(row_balanced), axis=0)
    col_scale[col_scale < 1] = 1
    return row_balanced / col_scale[None, :], col_scale


def _sigma_min(beta: float, m: int, nu: float, boundary: str, xi0: float) -> float:
    if not np.isfinite(beta) or beta <= 0:
        return np.inf
    try:
        balanced, _ = _balance_matrix(_mode_matrix(beta, m, nu, boundary, xi0))
        return float(np.linalg.svd(balanced, compute_uv=False)[-1])
    except (FloatingPointError, ValueError):
        return np.inf


def _det_balanced(beta: float, m: int, nu: float, boundary: str, xi0: float) -> float:
    if not np.isfinite(beta) or beta <= 0:
        return np.nan
    try:
        balanced, _ = _balance_matrix(_mode_matrix(beta, m, nu, boundary, xi0))
        return float(np.real(np.linalg.det(balanced)))
    except (FloatingPointError, ValueError):
        return np.nan


def _merge_roots(values: list[float], tol: float = 1e-7) -> list[float]:
    out: list[float] = []
    for value in sorted(v for v in values if np.isfinite(v)):
        if not out or abs(value - out[-1]) > tol * max(1.0, abs(out[-1])):
            out.append(float(value))
    return out


def _find_roots(m: int, radial_count: int, nu: float, boundary: str, xi0: float) -> list[float]:
    annulus = xi0 > 0
    beta_max = max(34.0, 16.0 + 9.0 * np.sqrt(radial_count + m + 1.0) + 1.5 * m)
    beta_min = max(0.18, 0.5 * m) if annulus else 1e-4
    step = 0.04 if annulus else 0.035
    sigma_tol = 2e-7 if annulus else 2e-8
    roots: list[float] = []
    for _ in range(5):
        grid = np.arange(beta_min, beta_max + step, step)
        sig = np.array([_sigma_min(v, m, nu, boundary, xi0) for v in grid])
        det = np.array([_det_balanced(v, m, nu, boundary, xi0) for v in grid])
        intervals: list[tuple[float, float]] = []
        for idx in range(len(grid) - 1):
            dl, dr = det[idx], det[idx + 1]
            if np.isfinite(dl) and np.isfinite(dr) and (dl == 0 or dr == 0 or np.sign(dl) != np.sign(dr)):
                intervals.append((float(grid[idx]), float(grid[idx + 1])))
        for idx in range(1, len(grid) - 1):
            if np.isfinite(sig[idx - 1]) and np.isfinite(sig[idx]) and np.isfinite(sig[idx + 1]):
                if sig[idx] <= sig[idx - 1] and sig[idx] <= sig[idx + 1]:
                    intervals.append((float(grid[idx - 1]), float(grid[idx + 1])))
        for left, right in intervals:
            root = np.nan
            dl, dr = _det_balanced(left, m, nu, boundary, xi0), _det_balanced(right, m, nu, boundary, xi0)
            if np.isfinite(dl) and np.isfinite(dr) and (dl == 0 or dr == 0 or np.sign(dl) != np.sign(dr)):
                try:
                    root = optimize.brentq(lambda z: _det_balanced(z, m, nu, boundary, xi0), left, right, xtol=1e-11)
                except ValueError:
                    root = np.nan
            if not np.isfinite(root):
                res = optimize.minimize_scalar(lambda z: _sigma_min(z, m, nu, boundary, xi0), bounds=(left, right), method="bounded", options={"xatol": 1e-11})
                if res.success:
                    root = float(res.x)
            if np.isfinite(root) and _sigma_min(root, m, nu, boundary, xi0) <= sigma_tol:
                roots.append(float(root))
        roots = _merge_roots(roots)
        if len(roots) >= radial_count:
            return roots[:radial_count]
        beta_max *= 1.45
    return roots[:radial_count]


@lru_cache(maxsize=512)
def _cached_root_and_coeffs(m: int, s: int, nu_key: float, boundary: str, xi0_key: float) -> tuple[float, tuple[float, ...]]:
    nu = float(nu_key)
    xi0 = float(xi0_key)
    roots = _find_roots(m, s, nu, boundary, xi0)
    if len(roots) < s:
        raise ValueError(f"Only found {len(roots)} circular roots for m={m}; requested s={s}.")
    beta = roots[s - 1]
    matrix = _mode_matrix(beta, m, nu, boundary, xi0)
    balanced, col_scale = _balance_matrix(matrix)
    _, _, vh = np.linalg.svd(balanced)
    coeffs = np.real(vh[-1, :] / col_scale)
    coeffs = coeffs / max(float(np.max(np.abs(coeffs))), np.finfo(float).eps)
    pivot = int(np.argmax(np.abs(coeffs)))
    if coeffs[pivot] < 0:
        coeffs = -coeffs
    return float(beta), tuple(float(v) for v in coeffs)


def _radial_values(x: np.ndarray, beta: float, m: int, coeffs: np.ndarray, xi0: float) -> np.ndarray:
    vals = np.asarray(x, dtype=float).ravel()
    if xi0 > 0:
        lam = beta * xi0
        columns = np.column_stack([
            special.jv(m, vals),
            special.yv(m, vals),
            np.exp(vals - beta) * special.ive(m, vals),
            np.exp(lam - vals) * special.kve(m, vals),
        ])
    else:
        columns = np.column_stack([
            special.jv(m, vals),
            np.exp(vals - beta) * special.ive(m, vals),
        ])
    return np.real(columns @ coeffs).reshape(np.shape(x))


def compute_circular_mode(
    azimuthal_order: int,
    radial_order: int,
    *,
    boundary: str = "C",
    nu: float = 0.225,
    xi0: float = 0.0,
    grid_n: int = 240,
    radius: float = 1.0,
    phase: str = "cos",
) -> CircularMode:
    x = np.linspace(-radius, radius, int(grid_n))
    y = np.linspace(-radius, radius, int(grid_n))
    X, Y = np.meshgrid(x, y)
    R = np.hypot(X, Y)
    theta = np.arctan2(Y, X)
    inner = max(0.0, min(float(xi0), 0.92)) * radius
    mask = (R <= radius) & (R >= inner)
    m = int(azimuthal_order)
    s = max(1, int(radial_order))
    angular = np.cos(m * theta) if phase == "cos" else np.sin(m * theta)
    if m == 0:
        angular = np.ones_like(theta)
    tag_boundary = _parse_boundary(boundary, inner > 0)
    beta, coeff_tuple = _cached_root_and_coeffs(m, s, round(float(nu), 12), tag_boundary, round(inner / radius, 12))
    coeffs = np.asarray(coeff_tuple, dtype=float)
    radial = _radial_values(beta * R / radius, beta, m, coeffs, inner / radius)
    u = _normalize(radial * angular, mask)
    lam = (beta / radius) ** 2
    prefix = "annulus" if inner > 0 else "disk"
    tag = f"{prefix}_{tag_boundary.upper()}_m{m}_s{s}"
    return CircularMode(x=x, y=y, u=u, lam_disp=float(lam), tag=tag, boundary=tag_boundary.upper(), mask=mask, beta=beta, coeffs=coeffs)


def compute_annulus_sequence(
    sequence: list[tuple[int, int]],
    *,
    boundary: str = "FC",
    nu: float = 0.225,
    xi0: float = 0.2,
    grid_n: int = 240,
) -> list[CircularMode]:
    return [
        compute_circular_mode(m, s, boundary=boundary, nu=nu, xi0=xi0, grid_n=grid_n)
        for m, s in sequence
    ]
