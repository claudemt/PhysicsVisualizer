from __future__ import annotations

from dataclasses import dataclass
from functools import lru_cache

import numpy as np
from scipy.optimize import brentq
from scipy.special import jv, jvp, yv, yvp

C0 = 299_792_458.0


def _latex_mode_label(mode_type: str, m: int | None = None, n: int | None = None) -> str:
    mode = mode_type.upper()
    if mode == "TEM" or m is None or n is None:
        return rf"\mathrm{{{mode}}}"
    return rf"\mathrm{{{mode}}}_{{{int(m)},{int(n)}}}"


def _dispersion_label(mode_type: str, m: int | None, n: int | None, fc_ghz: float) -> str:
    return "$" + _latex_mode_label(mode_type, m, n) + rf"\,(f_{{\mathrm{{c}}}}={fc_ghz:.3g}\,\mathrm{{GHz}})$"


def _field_title(mode_type: str, m: int | None, n: int | None, fc_ghz: float, xi0: float) -> str:
    return "$" + _latex_mode_label(mode_type, m, n) + rf",\ f_{{\mathrm{{c}}}}={fc_ghz:.4g}\ \mathrm{{GHz}},\ \xi_0={xi0:.4g}$"


@dataclass(frozen=True)
class MetalCurve:
    m: int
    n: int
    fc_ghz: float
    f_ghz: np.ndarray
    beta: np.ndarray
    vg_over_c: np.ndarray
    label: str


def rectangular_metal_dispersion(
    mode_type: str,
    a: float,
    b: float,
    max_order: int,
    f_min_ghz: float = 0.0,
    f_max_ghz: float = 10.0,
    samples: int = 420,
) -> dict:
    """PEC rectangular-guide dispersion matching the MATLAB formulas."""
    if f_max_ghz <= f_min_ghz:
        raise ValueError("f max must be greater than f min.")
    mode_type = mode_type.upper()
    f_ghz = np.linspace(f_min_ghz, f_max_ghz, int(samples))
    f_hz = f_ghz * 1e9
    curves: list[MetalCurve] = []
    for m in range(max_order + 1):
        for n in range(max_order + 1):
            if m == 0 and n == 0:
                continue
            if mode_type == "TM" and (m == 0 or n == 0):
                continue
            fc = 0.5 * C0 * np.sqrt((m / a) ** 2 + (n / b) ** 2)
            mask = f_hz > fc
            if np.count_nonzero(mask) < 4:
                continue
            ff = f_hz[mask]
            beta = (2 * np.pi / C0) * np.sqrt(ff**2 - fc**2)
            vg_over_c = np.sqrt(1.0 - (fc / ff) ** 2)
            curves.append(
                MetalCurve(
                    m=m,
                    n=n,
                    fc_ghz=fc / 1e9,
                    f_ghz=f_ghz[mask],
                    beta=beta,
                    vg_over_c=vg_over_c,
                    label=_dispersion_label(mode_type, m, n, fc / 1e9),
                )
            )
    if not curves:
        raise ValueError("No propagating modes below f max.")
    return {
        "mode_type": mode_type,
        "a": a,
        "b": b,
        "f_min_ghz": f_min_ghz,
        "f_max_ghz": f_max_ghz,
        "curves": curves,
        "title": (
            f"Rectangular PEC $\\mathrm{{{mode_type}}}$ dispersion: "
            f"$a={a:.3g}\\ \\mathrm{{m}}$, $b={b:.3g}\\ \\mathrm{{m}}$, "
            f"$f_{{\\max}}={f_max_ghz:.3g}\\ \\mathrm{{GHz}}$"
        ),
    }


def rectangular_metal_field(
    mode_type: str,
    m: int,
    n: int,
    a: float,
    xi0: float,
    grid_n: int = 220,
) -> dict:
    """Scalar longitudinal field for a centered rectangular PEC guide.

    As in MATLAB, ``a`` is the half-width and ``b = a * xi0`` is the
    half-height. Coordinates returned are normalized by ``a``.
    """
    mode_type = mode_type.upper()
    b = a * xi0
    x = np.linspace(-a, a, int(grid_n))
    y = np.linspace(-b, b, int(grid_n))
    x_grid, y_grid = np.meshgrid(x, y)
    xp = x_grid + a
    yp = y_grid + b
    if mode_type == "TE":
        field = np.cos(m * np.pi * xp / (2 * a)) * np.cos(n * np.pi * yp / (2 * b))
        cb_label = "$H_z$"
    else:
        field = np.sin(m * np.pi * xp / (2 * a)) * np.sin(n * np.pi * yp / (2 * b))
        cb_label = "$E_z$"
    field = field / (np.nanmax(np.abs(field)) + np.finfo(float).eps)
    fc_ghz = C0 / 4 * np.sqrt((m / a) ** 2 + (n / b) ** 2) / 1e9
    return {
        "x": x_grid / a,
        "y": y_grid / a,
        "field": field,
        "xi0": xi0,
        "mode_label": "$" + _latex_mode_label(mode_type, m, n) + "$",
        "cb_label": cb_label,
        "fc_ghz": fc_ghz,
        "title": _field_title(mode_type, m, n, fc_ghz, xi0),
    }


def rectangular_cutoff_map(mode_type: str, a: float, b: float, max_order: int) -> dict:
    """Cutoff-frequency matrix for a rectangular PEC guide."""
    mode_type = mode_type.upper()
    m_list = np.arange(max_order + 1)
    n_list = np.arange(max_order + 1)
    fc_ghz = np.full((len(m_list), len(n_list)), np.nan, dtype=float)
    for ii, m in enumerate(m_list):
        for jj, n in enumerate(n_list):
            if m == 0 and n == 0:
                continue
            if mode_type == "TM" and (m == 0 or n == 0):
                continue
            fc_ghz[ii, jj] = 0.5 * C0 * np.sqrt((m / a) ** 2 + (n / b) ** 2) / 1e9
    return {
        "m_list": m_list,
        "n_list": n_list,
        "fc_ghz": fc_ghz,
        "title": (
            f"Rectangular PEC $\\mathrm{{{mode_type}}}$ cutoff map: "
            f"$a={a:.3g}\\ \\mathrm{{m}}$, $b={b:.3g}\\ \\mathrm{{m}}$"
        ),
    }


def circular_metal_dispersion(
    mode_type: str,
    radius: float,
    max_order: int,
    f_min_ghz: float = 0.0,
    f_max_ghz: float = 10.0,
    samples: int = 420,
    xi0: float = 0.0,
    guide: str = "circular",
) -> dict:
    """Dispersion for circular and annular PEC guides.

    Circular modes use roots of J_m or J_m'. Annular modes use the
    two-conductor J_m/Y_m determinant at both PEC radii. An annular TEM
    request returns its zero-cutoff branch.
    """
    if f_max_ghz <= f_min_ghz:
        raise ValueError("f max must be greater than f min.")
    mode_type = mode_type.upper()
    if mode_type not in {"TE", "TM", "TEM"}:
        raise ValueError("Metal mode type must be TE, TM, or TEM.")
    is_annular = _is_annular(guide, xi0)
    if mode_type == "TEM" and not is_annular:
        raise ValueError("TEM propagation requires an annular two-conductor guide.")
    if is_annular:
        _validate_xi0(xi0)
    guide_label = _guide_label(guide, xi0)
    f_ghz = np.linspace(f_min_ghz, f_max_ghz, int(samples))
    f_hz = f_ghz * 1e9
    curves: list[MetalCurve] = []
    if mode_type == "TEM":
        mask = f_hz > 0
        curves.append(
            MetalCurve(
                m=0,
                n=0,
                fc_ghz=0.0,
                f_ghz=f_ghz[mask],
                beta=2 * np.pi * f_hz[mask] / C0,
                vg_over_c=np.ones(np.count_nonzero(mask)),
                label=_dispersion_label("TEM", None, None, 0.0),
            )
        )
    else:
        for m in range(max_order + 1):
            roots = (
                annular_mode_roots(mode_type, m, max_order, xi0)
                if is_annular
                else np.array([bessel_roots(m, n)[1 if mode_type == "TE" else 0] for n in range(1, max_order + 1)])
            )
            for n, root in enumerate(roots, start=1):
                fc = C0 * root / (2 * np.pi * radius)
                mask = f_hz > fc
                if np.count_nonzero(mask) < 4:
                    continue
                ff = f_hz[mask]
                beta = (2 * np.pi / C0) * np.sqrt(ff**2 - fc**2)
                vg_over_c = np.sqrt(1.0 - (fc / ff) ** 2)
                curves.append(
                    MetalCurve(
                        m=m,
                        n=n,
                        fc_ghz=fc / 1e9,
                        f_ghz=f_ghz[mask],
                        beta=beta,
                        vg_over_c=vg_over_c,
                        label=_dispersion_label(mode_type, m, n, fc / 1e9),
                    )
                )
    if not curves:
        raise ValueError("No propagating modes below f max.")
    return {
        "mode_type": mode_type,
        "guide": guide_label,
        "radius": radius,
        "xi0": xi0,
        "f_min_ghz": f_min_ghz,
        "f_max_ghz": f_max_ghz,
        "curves": curves,
        "title": (
            f"{guide_label} PEC $\\mathrm{{{mode_type}}}$ dispersion: "
            f"$r={radius:.3g}\\ \\mathrm{{m}}$, $f_{{\\max}}={f_max_ghz:.3g}\\ \\mathrm{{GHz}}$"
        ),
    }


def circular_cutoff_map(
    mode_type: str,
    radius: float,
    max_order: int,
    xi0: float = 0.0,
    guide: str = "circular",
) -> dict:
    """Cutoff-frequency matrix for circular/annular PEC guides."""
    mode_type = mode_type.upper()
    if mode_type not in {"TE", "TM", "TEM"}:
        raise ValueError("Metal mode type must be TE, TM, or TEM.")
    is_annular = _is_annular(guide, xi0)
    if mode_type == "TEM":
        if not is_annular:
            raise ValueError("TEM propagation requires an annular two-conductor guide.")
        _validate_xi0(xi0)
        return {
            "m_list": np.array([0]),
            "n_list": np.array([0]),
            "fc_ghz": np.array([[0.0]]),
            "title": "Annular PEC $\\mathrm{TEM}$ cutoff map",
        }
    if is_annular:
        _validate_xi0(xi0)
    m_list = np.arange(max_order + 1)
    n_list = np.arange(1, max_order + 1)
    fc_ghz = np.full((len(m_list), len(n_list)), np.nan, dtype=float)
    for ii, m in enumerate(m_list):
        roots = (
            annular_mode_roots(mode_type, int(m), max_order, xi0)
            if is_annular
            else np.array([bessel_roots(int(m), int(n))[1 if mode_type == "TE" else 0] for n in n_list])
        )
        for jj, root in enumerate(roots):
            fc_ghz[ii, jj] = C0 * root / (2 * np.pi * radius) / 1e9
    guide_label = _guide_label(guide, xi0)
    return {
        "m_list": m_list,
        "n_list": n_list,
        "fc_ghz": fc_ghz,
        "title": f"{guide_label} PEC $\\mathrm{{{mode_type}}}$ cutoff map: $r={radius:.3g}\\ \\mathrm{{m}}$",
    }


def _guide_label(guide: str, xi0: float) -> str:
    guide = str(guide).lower()
    if guide in {"annulus", "annular"} or xi0 > 0:
        return "Annular"
    return "Circular"


def _is_annular(guide: str, xi0: float) -> bool:
    return str(guide).lower() in {"annulus", "annular"} or xi0 > 0


def _validate_xi0(xi0: float) -> None:
    if not 0.0 < float(xi0) < 1.0:
        raise ValueError("Annular guides require 0 < xi0 = R_in/R_out < 1.")


def annular_characteristic(mode_type: str, m: int, x: np.ndarray | float, xi0: float) -> np.ndarray:
    """Two-PEC-boundary characteristic determinant for an annular guide."""
    _validate_xi0(xi0)
    mode_type = mode_type.upper()
    if mode_type not in {"TE", "TM"}:
        raise ValueError("Annular characteristic roots are defined for TE or TM modes.")
    x_arr = np.asarray(x, dtype=float)
    inner = xi0 * x_arr
    if mode_type == "TM":
        value = jv(m, inner) * yv(m, x_arr) - yv(m, inner) * jv(m, x_arr)
    else:
        value = jvp(m, inner) * yvp(m, x_arr) - yvp(m, inner) * jvp(m, x_arr)
    return np.asarray(value)


@lru_cache(maxsize=256)
def _annular_mode_roots_cached(mode_type: str, m: int, count: int, xi0: float) -> tuple[float, ...]:
    mode_type = mode_type.upper()
    _validate_xi0(xi0)
    if m < 0 or count < 1:
        raise ValueError("Annular roots require m >= 0 and count >= 1.")
    spacing = np.pi / (1.0 - xi0)
    scan_max = max(40.0, (count + m / 2 + 4) * spacing)
    step = min(0.05, spacing / 100.0)

    def scalar(value: float) -> float:
        return float(annular_characteristic(mode_type, m, value, xi0))

    roots: list[float] = []
    while len(roots) < count:
        grid = np.arange(1e-5, scan_max + step, step)
        values = annular_characteristic(mode_type, m, grid, xi0)
        for left, right, f_left, f_right in zip(grid[:-1], grid[1:], values[:-1], values[1:]):
            if not (np.isfinite(f_left) and np.isfinite(f_right)) or f_left * f_right >= 0:
                continue
            root = float(brentq(scalar, float(left), float(right), xtol=1e-12, rtol=1e-12, maxiter=100))
            if root > 1e-7 and (not roots or abs(root - roots[-1]) > 1e-6):
                roots.append(root)
                if len(roots) == count:
                    break
        if len(roots) < count:
            scan_max *= 1.6
            if scan_max > 2e4:
                raise ValueError(f"Failed to find {count} annular {mode_type} roots for m={m}.")
    return tuple(roots)


def annular_mode_roots(mode_type: str, m: int, count: int, xi0: float) -> np.ndarray:
    """Return positive annular TE/TM transverse eigenvalues x = k_c R_out."""
    return np.asarray(_annular_mode_roots_cached(mode_type.upper(), int(m), int(count), round(float(xi0), 12)))


def bessel_roots(m: int, n: int) -> tuple[float, float]:
    """Return the nth positive roots of J_m and J_m' as in the MATLAB core."""
    if m < 0 or n < 1:
        raise ValueError("Bessel roots require m >= 0 and n >= 1.")
    return _nth_bessel_root(m, n, derivative=False), _nth_bessel_root(m, n, derivative=True)


def _nth_bessel_root(m: int, n: int, derivative: bool) -> float:
    fun = (lambda x: jvp(m, x, 1)) if derivative else (lambda x: jv(m, x))
    roots: list[float] = []
    step = 0.035
    scan_max = max(60.0, (n + m / 2 + 10) * np.pi)
    x_prev = 1e-8
    y_prev = float(fun(x_prev))
    x = step
    while x <= scan_max:
        y = float(fun(x))
        if np.isfinite(y_prev) and np.isfinite(y) and y_prev * y < 0:
            root = brentq(fun, x - step, x, xtol=1e-12, rtol=1e-12, maxiter=100)
            if root > 1e-7 and (not roots or abs(root - roots[-1]) > 1e-6):
                roots.append(float(root))
                if len(roots) >= n:
                    return roots[n - 1]
        x_prev, y_prev = x, y
        x += step
    label = "J_m prime" if derivative else "J_m"
    raise ValueError(f"Failed to find root {n} of {label} for m={m}.")


def circular_metal_field(
    mode_type: str,
    m: int,
    n: int,
    radius: float,
    grid_n: int = 220,
    xi0: float = 0.0,
) -> dict:
    """Longitudinal TE/TM field or transverse TEM field in a circular/annular guide."""
    mode_type = mode_type.upper()
    if mode_type not in {"TE", "TM", "TEM"}:
        raise ValueError("Metal mode type must be TE, TM, or TEM.")
    is_annular = xi0 > 0
    if is_annular:
        _validate_xi0(xi0)
    if mode_type == "TEM" and not is_annular:
        raise ValueError("TEM propagation requires an annular two-conductor guide.")
    x = np.linspace(-radius, radius, int(grid_n))
    y = np.linspace(-radius, radius, int(grid_n))
    x_grid, y_grid = np.meshgrid(x, y)
    rho = np.hypot(x_grid, y_grid)
    phi = np.arctan2(y_grid, x_grid)
    rho_norm = rho / radius
    if mode_type == "TEM":
        root = 0.0
        with np.errstate(divide="ignore", invalid="ignore"):
            field = xi0 / rho_norm
            field_x = field * np.cos(phi)
            field_y = field * np.sin(phi)
        cb_label = "$|E_t|$ (normalized)"
        mode_label = "$\\mathrm{TEM}$"
    else:
        if is_annular:
            root = float(annular_mode_roots(mode_type, int(m), int(n), xi0)[int(n) - 1])
            if mode_type == "TM":
                radial = jv(int(m), root * rho_norm) * yv(int(m), root * xi0) - yv(int(m), root * rho_norm) * jv(int(m), root * xi0)
            else:
                radial = jv(int(m), root * rho_norm) * yvp(int(m), root * xi0) - yv(int(m), root * rho_norm) * jvp(int(m), root * xi0)
        else:
            tm_root, te_root = bessel_roots(int(m), int(n))
            root = te_root if mode_type == "TE" else tm_root
            radial = jv(int(m), root * rho_norm)
        field = radial * np.cos(int(m) * phi)
        field_x = None
        field_y = None
        cb_label = "$H_z$" if mode_type == "TE" else "$E_z$"
        mode_label = "$" + _latex_mode_label(mode_type, m, n) + "$"
    outside = rho > radius
    inside_conductor = rho < xi0 * radius if is_annular else np.zeros_like(rho, dtype=bool)
    field[outside | inside_conductor] = np.nan
    if field_x is not None:
        field_x[outside | inside_conductor] = np.nan
        field_y[outside | inside_conductor] = np.nan
    field = field / (np.nanmax(np.abs(field)) + np.finfo(float).eps)
    fc_ghz = C0 * root / (2 * np.pi * radius) / 1e9
    result = {
        "x": x_grid / radius,
        "y": y_grid / radius,
        "field": field,
        "xi0": xi0,
        "mode_label": mode_label,
        "cb_label": cb_label,
        "fc_ghz": fc_ghz,
        "title": _field_title(mode_type, None if mode_type == "TEM" else m, None if mode_type == "TEM" else n, fc_ghz, xi0),
        "boundary_radii": [xi0, 1.0] if xi0 > 0 else [1.0],
    }
    if field_x is not None:
        scale = np.nanmax(np.hypot(field_x, field_y)) + np.finfo(float).eps
        result["field_x"] = field_x / scale
        result["field_y"] = field_y / scale
    return result
