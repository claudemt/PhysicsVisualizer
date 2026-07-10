from __future__ import annotations

from dataclasses import dataclass

import numpy as np
from scipy import optimize
from scipy.special import jv, jvp, kv, kve, kvp


@dataclass(frozen=True)
class CylindricalCurve:
    order: int
    phi: np.ndarray
    family: str = "HE/EH"


@dataclass(frozen=True)
class CylindricalBranch:
    family: str
    order: int
    radial_index: int
    v: np.ndarray
    u: np.ndarray
    b_norm: np.ndarray
    neff: np.ndarray

    @property
    def label(self) -> str:
        return f"$\\mathrm{{{self.family}}}_{{{self.order},{self.radial_index}}}$"


@dataclass(frozen=True)
class CylindricalRoot:
    order: int
    radial_index: int
    u: float
    w: float
    v: float
    b_norm: float
    neff: float
    family: str = "HE/EH"
    ez_amplitude: float = 1.0
    hz_amplitude: float = 0.0


def _normalize_family(family: str | None, order: int) -> str:
    value = str(family or "hybrid").strip().upper().replace(" ", "")
    aliases = {"HE/EH": "HYBRID", "HEEH": "HYBRID", "ALL": "HYBRID", "LP": "HYBRID"}
    value = aliases.get(value, value)
    if value == "HYBRID" and int(order) == 0:
        return "TE"
    if value not in {"HYBRID", "HE", "EH", "TE", "TM"}:
        raise ValueError("Cylindrical mode family must be HE, EH, TE, or TM.")
    if value in {"TE", "TM"} and int(order) != 0:
        raise ValueError(f"{value} modes of a circular step-index guide require azimuthal order m=0.")
    if value in {"HE", "EH", "HYBRID"} and int(order) < 1:
        raise ValueError("HE/EH modes require azimuthal order m >= 1.")
    return value


def _fg_terms(order: int, u: np.ndarray | float, v: np.ndarray | float) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    u_arr = np.asarray(u, dtype=float)
    v_arr = np.asarray(v, dtype=float)
    ue = np.where(u_arr == 0, 1e-12, u_arr)
    w2 = v_arr * v_arr - ue * ue
    w = np.sqrt(np.where(w2 <= 0, np.nan, w2))
    we = np.where(w == 0, 1e-12, w)
    jm = jv(order, ue)
    km = kve(order, we)
    with np.errstate(divide="ignore", invalid="ignore", over="ignore"):
        f = jvp(order, ue) / (ue * jm)
        g = (-kve(order - 1, we) / km - order / we) / we
    bad = (ue < 1e-9) | (we < 1e-9) | (np.abs(jm) < 1e-7) | (np.abs(km) < 1e-300)
    return np.where(bad, np.nan, f), np.where(bad, np.nan, g), w


def cylindrical_characteristic(
    order: int,
    u: np.ndarray | float,
    v: float,
    n1: float,
    n2: float,
    family: str | None = None,
) -> np.ndarray:
    """Exact vector characteristic equation for a circular step-index guide.

    For m=0 the two factors are exposed independently as TE and TM. For
    m>=1 the hybrid determinant contains both HE and EH roots; the family is
    classified from the longitudinal-field eigenvector after root finding.
    """
    if n1 <= n2:
        raise ValueError("Cylindrical dielectric guidance requires n1 > n2.")
    order = int(order)
    resolved = _normalize_family(family, order)
    u_arr = np.asarray(u, dtype=float)
    f, g, w = _fg_terms(order, u_arr, v)
    eta = (n2 / n1) ** 2
    if resolved == "TE":
        phi = f + g
    elif resolved == "TM":
        phi = f + eta * g
    else:
        ue = np.where(u_arr == 0, 1e-12, u_arr)
        we = np.where(w == 0, 1e-12, w)
        rhs = order**2 * (1 / ue**2 + 1 / we**2) * (1 / ue**2 + eta / we**2)
        phi = (f + g) * (f + eta * g) - rhs
    return np.asarray(phi)


def _boundary_matrix(order: int, u: float, v: float, n1: float, n2: float) -> np.ndarray:
    """Tangential E_phi/H_phi continuity matrix for [E_z(a), H_z(a)]."""
    w = float(np.sqrt(max(v * v - u * u, 0.0)))
    k0 = v / np.sqrt(n1 * n1 - n2 * n2)
    beta = float(np.sqrt(max((n1 * k0) ** 2 - u * u, 0.0)))
    d_core = u * jvp(order, u) / jv(order, u)
    d_clad = w * kvp(order, w) / kv(order, w)
    gamma_core = u * u
    gamma_clad = -(w * w)
    cross = beta * order * (1.0 / gamma_core - 1.0 / gamma_clad)
    return np.array(
        [
            [cross, k0 * (d_core / gamma_core - d_clad / gamma_clad)],
            [-k0 * (n1 * n1 * d_core / gamma_core - n2 * n2 * d_clad / gamma_clad), -cross],
        ],
        dtype=float,
    )


def _longitudinal_amplitudes(family: str, order: int, u: float, v: float, n1: float, n2: float) -> tuple[float, float, str]:
    if family == "TE":
        return 0.0, 1.0, "TE"
    if family == "TM":
        return 1.0, 0.0, "TM"
    matrix = _boundary_matrix(order, u, v, n1, n2)
    _, _, vh = np.linalg.svd(matrix)
    ez, hz = (float(value) for value in vh[-1])
    scale = np.hypot(n1 * ez, hz)
    if scale > 0:
        ez, hz = ez / scale, hz / scale
    resolved = "HE" if ez * hz >= 0 else "EH"
    return ez, hz, resolved


def _candidate_roots(n1: float, n2: float, v_number: float, order: int, family: str, samples: int) -> list[float]:
    u_grid = np.linspace(1e-5, float(v_number) - 1e-5, max(400, int(samples)))
    phi = cylindrical_characteristic(order, u_grid, v_number, n1, n2, family)

    def scalar(value: float) -> float:
        return float(cylindrical_characteristic(order, value, v_number, n1, n2, family))

    roots: list[float] = []
    for left, right, f_left, f_right in zip(u_grid[:-1], u_grid[1:], phi[:-1], phi[1:]):
        if not (np.isfinite(f_left) and np.isfinite(f_right)):
            continue
        if abs(f_left) > 1e7 or abs(f_right) > 1e7 or f_left * f_right > 0:
            continue
        try:
            candidate = float(left) if f_left == 0 else float(optimize.brentq(scalar, float(left), float(right), maxiter=100))
        except (ValueError, RuntimeError):
            continue
        residual = scalar(candidate)
        if not np.isfinite(residual) or abs(residual) > 1e-4:
            continue
        if candidate <= 0 or candidate >= v_number:
            continue
        if roots and min(abs(candidate - root) for root in roots) < 5e-4:
            continue
        roots.append(candidate)
    return roots


def cylindrical_mode_roots(
    n1: float,
    n2: float,
    v_number: float,
    order: int,
    max_roots: int = 4,
    samples: int = 2400,
    family: str | None = None,
) -> list[CylindricalRoot]:
    """Find and classify guided vector roots U for a fixed V."""
    if v_number <= 0:
        raise ValueError("v_number must be positive.")
    requested = _normalize_family(family, int(order))
    equation_family = requested if requested in {"TE", "TM"} else "HYBRID"
    candidates = _candidate_roots(n1, n2, float(v_number), int(order), equation_family, samples)
    found: list[tuple[float, float, float, str]] = []
    for candidate in candidates:
        ez, hz, resolved = _longitudinal_amplitudes(equation_family, int(order), candidate, float(v_number), n1, n2)
        if requested in {"HE", "EH"} and resolved != requested:
            continue
        found.append((candidate, ez, hz, resolved))

    results: list[CylindricalRoot] = []
    family_counts: dict[str, int] = {}
    for global_index, (root, ez, hz, resolved) in enumerate(found, start=1):
        if len(results) >= max_roots:
            break
        family_counts[resolved] = family_counts.get(resolved, 0) + 1
        radial_index = global_index if requested == "HYBRID" else family_counts[resolved]
        w = float(np.sqrt(max(v_number * v_number - root * root, 0.0)))
        b_norm = (w / v_number) ** 2
        neff = float(np.sqrt(n2 * n2 + b_norm * (n1 * n1 - n2 * n2)))
        results.append(
            CylindricalRoot(
                int(order), radial_index, float(root), w, float(v_number), b_norm, neff, resolved, ez, hz
            )
        )
    return results


def _radial_profiles(order: int, root: CylindricalRoot, rho: np.ndarray, radius: float) -> tuple[np.ndarray, np.ndarray]:
    core = rho <= radius
    profile = np.empty_like(rho)
    derivative = np.empty_like(rho)
    core_den = jv(order, root.u)
    clad_den = kv(order, root.w)
    profile[core] = jv(order, root.u * rho[core] / radius) / core_den
    derivative[core] = (root.u / radius) * jvp(order, root.u * rho[core] / radius) / core_den
    profile[~core] = kv(order, root.w * rho[~core] / radius) / clad_den
    derivative[~core] = (root.w / radius) * kvp(order, root.w * rho[~core] / radius) / clad_den
    return profile, derivative


def cylindrical_dielectric_field(
    order: int,
    radial_index: int,
    n1: float,
    n2: float,
    v_number: float,
    radius: float = 1.0,
    grid_n: int = 220,
    phase: str = "cos",
    family: str = "HE",
    field_quantity: str = "electric magnitude",
) -> dict:
    """Reconstruct all six vector-field components of one guided mode."""
    requested = _normalize_family(family, int(order))
    if requested == "HYBRID":
        requested = "HE"
    roots = cylindrical_mode_roots(
        n1, n2, v_number, order, max_roots=max(radial_index, 1), samples=2600, family=requested
    )
    if len(roots) < radial_index:
        raise ValueError(f"The selected {requested}_{order},{radial_index} mode is not guided at this V-number.")
    root = roots[radial_index - 1]
    axis = np.linspace(-1.5 * radius, 1.5 * radius, int(grid_n))
    x, y = np.meshgrid(axis, axis)
    rho = np.hypot(x, y)
    phi = np.arctan2(y, x)
    profile, derivative = _radial_profiles(order, root, rho, radius)
    shifted_phi = phi + (np.pi / (2 * max(order, 1)) if phase.lower().startswith("sin") and order > 0 else 0.0)
    cos_m = np.cos(order * shifted_phi)
    sin_m = np.sin(order * shifted_phi)

    ez = root.ez_amplitude * profile * cos_m
    dez_dr = root.ez_amplitude * derivative * cos_m
    dez_dphi = -order * root.ez_amplitude * profile * sin_m
    if order == 0:
        hz = root.hz_amplitude * profile
        dhz_dr = root.hz_amplitude * derivative
        dhz_dphi = np.zeros_like(profile)
    else:
        hz = root.hz_amplitude * profile * sin_m
        dhz_dr = root.hz_amplitude * derivative * sin_m
        dhz_dphi = order * root.hz_amplitude * profile * cos_m

    delta_n2 = n1 * n1 - n2 * n2
    k0 = v_number / (radius * np.sqrt(delta_n2))
    beta = np.sqrt((n1 * k0) ** 2 - (root.u / radius) ** 2)
    core = rho <= radius
    epsilon = np.where(core, n1 * n1, n2 * n2)
    gamma2 = np.where(core, (root.u / radius) ** 2, -(root.w / radius) ** 2)
    rho_safe = np.where(rho > radius * 1e-10, rho, radius * 1e-10)
    with np.errstate(divide="ignore", invalid="ignore", over="ignore"):
        er = -1j * (beta * dez_dr + k0 * dhz_dphi / rho_safe) / gamma2
        ephi = -1j * (beta * dez_dphi / rho_safe - k0 * dhz_dr) / gamma2
        hr = -1j * (beta * dhz_dr - k0 * epsilon * dez_dphi / rho_safe) / gamma2
        hphi = -1j * (beta * dhz_dphi / rho_safe + k0 * epsilon * dez_dr) / gamma2

    e_scale = np.nanmax(np.sqrt(np.abs(er) ** 2 + np.abs(ephi) ** 2 + np.abs(ez) ** 2)) + np.finfo(float).eps
    h_scale = np.nanmax(np.sqrt(np.abs(hr) ** 2 + np.abs(hphi) ** 2 + np.abs(hz) ** 2)) + np.finfo(float).eps
    components = {
        "Er": er / e_scale,
        "Ephi": ephi / e_scale,
        "Ez": ez / e_scale,
        "Hr": hr / h_scale,
        "Hphi": hphi / h_scale,
        "Hz": hz / h_scale,
    }
    electric_magnitude = np.sqrt(sum(np.abs(components[key]) ** 2 for key in ("Er", "Ephi", "Ez")))
    magnetic_magnitude = np.sqrt(sum(np.abs(components[key]) ** 2 for key in ("Hr", "Hphi", "Hz")))
    quantity = field_quantity.strip().lower().replace("_", " ")
    if quantity in {"electric", "electric field", "electric magnitude", "|e|"}:
        field, cb_label = electric_magnitude, "$|E|$ (normalized)"
    elif quantity in {"magnetic", "magnetic field", "magnetic magnitude", "|h|"}:
        field, cb_label = magnetic_magnitude, "$|H|$ (normalized)"
    elif quantity == "ez":
        field, cb_label = np.real(components["Ez"]), "$E_z$ (normalized)"
    elif quantity == "hz":
        field, cb_label = np.real(components["Hz"]), "$H_z$ (normalized)"
    else:
        raise ValueError("field quantity must be electric magnitude, magnetic magnitude, Ez, or Hz.")
    field = field / (np.nanmax(np.abs(field)) + np.finfo(float).eps)
    mode_label = f"$\\mathrm{{{root.family}}}_{{{order},{radial_index}}}$"
    return {
        "x": axis / radius,
        "y": axis / radius,
        "field": field,
        "components": components,
        "mode_label": mode_label,
        "family": root.family,
        "cb_label": cb_label,
        "boundary_radii": [1.0],
        "u": root.u,
        "w": root.w,
        "v": root.v,
        "b": root.b_norm,
        "neff": root.neff,
        "beta": float(beta),
        "title": (
            f"$\\mathrm{{{root.family}}}_{{{order},{radial_index}}},\\ "
            f"V={v_number:.4g},\\ n_{{\\mathrm{{eff}}}}={root.neff:.5g}$"
        ),
    }


def _trace_vector_branches(n1: float, n2: float, vmax: float, max_order: int, samples: int) -> list[CylindricalBranch]:
    trace_v = np.linspace(max(0.35, vmax / max(samples, 1)), vmax, max(48, min(96, samples // 3)))
    points: dict[tuple[str, int, int], list[tuple[float, float, float, float]]] = {}
    radial_limit = max(1, min(4, int(max_order)))
    for value in trace_v:
        for family in ("TE", "TM"):
            for root in cylindrical_mode_roots(n1, n2, value, 0, radial_limit, 520, family):
                points.setdefault((family, 0, root.radial_index), []).append((value, root.u, root.b_norm, root.neff))
        for order in range(1, int(max_order) + 1):
            family_counts: dict[str, int] = {}
            roots = cylindrical_mode_roots(n1, n2, value, order, 2 * radial_limit, 520)
            for root in roots:
                family_counts[root.family] = family_counts.get(root.family, 0) + 1
                radial_index = family_counts[root.family]
                if radial_index <= radial_limit:
                    points.setdefault((root.family, order, radial_index), []).append((value, root.u, root.b_norm, root.neff))
    branches: list[CylindricalBranch] = []
    for (family, order, radial_index), rows in sorted(points.items()):
        if len(rows) < 3:
            continue
        data = np.asarray(rows)
        branches.append(CylindricalBranch(family, order, radial_index, data[:, 0], data[:, 1], data[:, 2], data[:, 3]))
    return branches


def cylindrical_dielectric_dispersion(
    n1: float,
    n2: float,
    vmax: float,
    umax: float | None = None,
    max_order: int = 5,
    samples: int = 260,
) -> dict:
    """Exact TE/TM/HE/EH normalized dispersion for a step-index cylinder."""
    if n1 <= n2:
        raise ValueError("Cylindrical dielectric guidance requires n1 > n2.")
    if vmax <= 0:
        raise ValueError("vmax must be positive.")
    umax = vmax if umax is None else float(umax)
    n = max(160, min(int(samples), 900))
    v = np.linspace(0.0, float(vmax), n)
    u = np.linspace(0.0, float(umax), n)
    vg, ug = np.meshgrid(v, u)
    curves = [CylindricalCurve(0, cylindrical_characteristic(0, ug, vg, n1, n2, "TE"), "TE")]
    curves.extend(CylindricalCurve(order, cylindrical_characteristic(order, ug, vg, n1, n2), "HE/EH") for order in range(1, int(max_order) + 1))
    branches = _trace_vector_branches(n1, n2, float(vmax), int(max_order), n)
    return {
        "n1": n1,
        "n2": n2,
        "V": vg,
        "U": ug,
        "vmax": float(vmax),
        "umax": float(umax),
        "curves": curves,
        "branches": branches,
        "title": (
            "Cylindrical dielectric vector dispersion: "
            f"$n_{{\\mathrm{{co}}}}={n1:.3g}$, $n_{{\\mathrm{{cl}}}}={n2:.3g}$"
        ),
    }
