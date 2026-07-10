from __future__ import annotations

from dataclasses import dataclass

import numpy as np

from .static_rect import evaluate_custom_load, parse_sources, static_load_label


@dataclass
class StaticCircularResult:
    x: np.ndarray
    y: np.ndarray
    u: np.ndarray
    q: np.ndarray
    mask: np.ndarray
    domain: str
    boundary: str
    method: str
    load_projection: str
    load_label: str
    nu: float
    xi0: float


def compute_static_circular_response(
    *,
    domain: str = "disk",
    xi0: float = 0.0,
    nu: float = 0.30,
    boundary: str = "C",
    grid_n: int = 220,
    sources: object = None,
    q0: float = 0.0,
    load_type: str = "points",
    custom_load: object = None,
    mmax: int = 36,
    d_rigidity: float = 1.0,
    radius: float = 1.0,
    distribution_samples: int | None = None,
) -> StaticCircularResult:
    if not (0 < float(nu) < 0.5):
        raise ValueError("nu must be in (0, 0.5).")
    if float(d_rigidity) <= 0 or float(radius) <= 0:
        raise ValueError("d_rigidity and radius must be positive.")
    x = np.linspace(-radius, radius, int(grid_n))
    y = np.linspace(-radius, radius, int(grid_n))
    X, Y = np.meshgrid(x, y)
    R = np.hypot(X, Y)
    inner = max(0.0, min(float(xi0), 0.92)) * radius if str(domain).lower().startswith("ann") else 0.0
    mask = (R <= radius) & (R >= inner)
    q = np.zeros_like(X)
    u = np.zeros_like(X, dtype=float)
    xi = R / radius
    theta = np.arctan2(Y, X)
    xi_vec = xi[mask]
    theta_vec = theta[mask]
    outer, inner_edge = _parse_boundary(boundary, inner > 0)
    if (inner == 0 and outer == "F") or (inner > 0 and outer == "F" and inner_edge == "F"):
        raise ValueError("Free circular static plates require a balancing gauge; use C/S boundary for a unique Green response.")
    load_key = _load_key(load_type)
    src = parse_sources(sources) if load_key in {"points", "mixed"} else np.empty((0, 4))
    _validate_source_geometry(src, inner / radius, radius)
    dx = abs(x[1] - x[0]) if x.size > 1 else 1.0
    if load_key in {"uniform", "mixed"}:
        q[mask] += float(q0)
    if load_key in {"custom", "mixed"}:
        q[mask] += evaluate_custom_load(custom_load, X, Y)[mask]
    point_sources = src if load_key in {"points", "mixed"} else np.empty((0, 4))
    smooth_sources: list[np.ndarray] = []
    for xs, ys, amp, sigma in point_sources:
        sig = float(sigma)
        visual_sigma = sig if sig > 0 else 2.5 * dx
        visual = np.exp(-((X - xs) ** 2 + (Y - ys) ** 2) / (2 * visual_sigma * visual_sigma))
        visual_total = np.trapezoid(np.trapezoid(np.where(mask, visual, 0.0), x, axis=1), y)
        if visual_total > 0:
            q[mask] += amp * visual[mask] / visual_total
        if sig > 0:
            if visual_total > 0:
                smooth_sources.append(np.array([xs, ys, amp / visual_total, sig], dtype=float))
            continue
        eta = float(np.hypot(xs, ys) / radius)
        if eta <= inner / radius + 1e-8 or eta >= 1 - 1e-8:
            continue
        theta0 = float(np.arctan2(ys, xs))
        add = np.zeros_like(xi_vec)
        for order in range(max(0, int(mmax)) + 1):
            gm = _radial_green(xi_vec, eta, order, float(nu), outer, inner_edge, inner / radius)
            if order == 0:
                add += gm / (2 * np.pi)
            else:
                add += np.cos(order * (theta_vec - theta0)) * gm / np.pi
        u[mask] += amp * radius**2 * add / max(float(d_rigidity), np.finfo(float).eps)
    if load_key in {"uniform", "custom", "mixed"} or smooth_sources:
        shells = _distributed_shells(
            inner / radius, int(mmax), distribution_samples, load_key, float(q0), custom_load, smooth_sources,
        )
        u[mask] += radius**2 * _shell_green_sum(
            xi_vec, theta_vec, shells, int(mmax), float(nu), outer, inner_edge, inner / radius,
        ) / max(float(d_rigidity), np.finfo(float).eps)
    q[~mask] = np.nan
    u[~mask] = np.nan
    amp = np.nanmax(np.abs(u))
    if np.isfinite(amp) and amp > 0:
        u = u / amp
    return StaticCircularResult(
        x=x, y=y, u=u, q=q, mask=mask, domain=str(domain), boundary=(outer + inner_edge if inner else outer),
        method="polar biharmonic Green function",
        load_projection="shell Fourier moments for distributed and finite-width loads",
        load_label=static_load_label(load_type), nu=float(nu), xi0=float(inner / radius),
    )


def _load_key(load_type: str) -> str:
    aliases = {"point": "points", "source": "points", "sources": "points", "distributed": "custom"}
    key = aliases.get(str(load_type).strip().lower(), str(load_type).strip().lower())
    if key not in {"points", "uniform", "custom", "mixed"}:
        raise ValueError("load_type must be points, uniform, custom, or mixed.")
    return key


def _validate_source_geometry(sources: np.ndarray, inner_ratio: float, radius: float) -> None:
    if sources.size == 0:
        return
    radial = np.hypot(sources[:, 0], sources[:, 1]) / radius
    tolerance = 1e-10
    inside = (radial < 1 - tolerance) & (radial > inner_ratio + tolerance)
    if not np.all(inside):
        domain = "annulus" if inner_ratio > 0 else "disk"
        raise ValueError(f"All point-source centers must lie strictly inside the {domain} material.")


def _distributed_shells(
    xi0: float,
    mmax: int,
    samples: int | None,
    load_type: str,
    q0: float,
    custom_load: object,
    smooth_sources: list[np.ndarray],
) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    radial_count = max(8, int(samples) if samples is not None else 18)
    theta_count = max(48, 2 * max(1, mmax) + 3, 3 * radial_count)
    edges = np.linspace(xi0, 1.0, radial_count + 1)
    eta = np.sqrt((edges[:-1] ** 2 + edges[1:] ** 2) / 2)
    theta = (np.arange(theta_count) + 0.5) * (2 * np.pi / theta_count)
    weights = np.zeros((radial_count, theta_count), dtype=float)
    use_uniform = load_type in {"uniform", "mixed"}
    use_custom = load_type in {"custom", "mixed"}
    dtheta = 2 * np.pi / theta_count
    for index, radius in enumerate(eta):
        xx = radius * np.cos(theta)
        yy = radius * np.sin(theta)
        values = np.full(theta_count, q0 if use_uniform else 0.0)
        if use_custom:
            values += evaluate_custom_load(custom_load, xx, yy)
        for xs, ys, amp, sigma in smooth_sources:
            values += amp * np.exp(-((xx - xs) ** 2 + (yy - ys) ** 2) / (2 * sigma * sigma))
        area = 0.5 * (edges[index + 1] ** 2 - edges[index] ** 2) * dtheta
        weights[index] = values * area
    return eta, theta, weights


def _shell_green_sum(
    xi: np.ndarray,
    theta: np.ndarray,
    shells: tuple[np.ndarray, np.ndarray, np.ndarray],
    mmax: int,
    nu: float,
    outer: str,
    inner: str,
    xi0: float,
) -> np.ndarray:
    eta_values, source_theta, weights = shells
    out = np.zeros_like(xi, dtype=float)
    for eta, shell_weights in zip(eta_values, weights):
        if not np.any(shell_weights):
            continue
        for order in range(max(0, mmax) + 1):
            radial = _radial_green(xi, float(eta), order, nu, outer, inner, xi0)
            if order == 0:
                out += np.sum(shell_weights) * radial / (2 * np.pi)
            else:
                cosine = float(np.sum(shell_weights * np.cos(order * source_theta)))
                sine = float(np.sum(shell_weights * np.sin(order * source_theta)))
                out += radial * (cosine * np.cos(order * theta) + sine * np.sin(order * theta)) / np.pi
    return out


def _parse_boundary(boundary: str, annulus: bool) -> tuple[str, str]:
    text = str(boundary).strip().upper()
    aliases = {"CLAMPED": "C", "SIMPLY": "S", "FREE": "F"}
    if annulus:
        tag = aliases.get(text, text)
        if len(tag) == 1:
            tag = tag + "C"
        if len(tag) != 2 or any(ch not in "CSF" for ch in tag):
            raise ValueError("Annulus boundary must be a two-letter code over C/S/F.")
        return tag[0], tag[1]
    tag = aliases.get(text, text[:1])
    if tag not in "CSF":
        raise ValueError("Disk boundary must be C, S, or F.")
    return tag, "R"


def _terms(order: int, regular_only: bool) -> tuple[np.ndarray, np.ndarray]:
    if regular_only:
        if order == 0:
            return np.array([0.0, 2.0]), np.array([False, False])
        if order == 1:
            return np.array([1.0, 3.0]), np.array([False, False])
        return np.array([float(order), float(order + 2)]), np.array([False, False])
    if order == 0:
        return np.array([0.0, 0.0, 2.0, 2.0]), np.array([False, True, False, True])
    if order == 1:
        return np.array([1.0, -1.0, 3.0, 1.0]), np.array([False, False, False, True])
    return np.array([float(order), float(-order), float(order + 2), float(2 - order)]), np.array([False, False, False, False])


def _eval_terms(xi: np.ndarray, powers: np.ndarray, logs: np.ndarray) -> tuple[np.ndarray, np.ndarray, np.ndarray, np.ndarray]:
    r = np.asarray(xi, dtype=float).reshape(-1)
    r = np.maximum(r, 1e-10)
    f = np.zeros((r.size, powers.size))
    d1 = np.zeros_like(f)
    d2 = np.zeros_like(f)
    d3 = np.zeros_like(f)
    for idx, (p, use_log) in enumerate(zip(powers, logs)):
        if use_log:
            log_r = np.log(r)
            rp = r**p
            f[:, idx] = rp * log_r
            d1[:, idx] = p * r ** (p - 1) * log_r + r ** (p - 1)
            d2[:, idx] = p * (p - 1) * r ** (p - 2) * log_r + (2 * p - 1) * r ** (p - 2)
            d3[:, idx] = p * (p - 1) * (p - 2) * r ** (p - 3) * log_r + (3 * p * p - 6 * p + 2) * r ** (p - 3)
        else:
            f[:, idx] = r**p
            d1[:, idx] = p * r ** (p - 1)
            d2[:, idx] = p * (p - 1) * r ** (p - 2)
            d3[:, idx] = p * (p - 1) * (p - 2) * r ** (p - 3)
    return f, d1, d2, d3


def _all_rows(xi: float | np.ndarray, order: int, nu: float, powers: np.ndarray, logs: np.ndarray) -> tuple[np.ndarray, np.ndarray, np.ndarray, np.ndarray]:
    r = np.asarray(xi, dtype=float).reshape(-1)
    w, t, d2, d3 = _eval_terms(r, powers, logs)
    rr = np.maximum(r[:, None], 1e-10)
    delta_prime = d3 + d2 / rr - (1 + order * order) * t / rr**2 + 2 * order * order * w / rr**3
    moment = d2 + nu * (t / rr - order * order * w / rr**2)
    shear = delta_prime - (1 - nu) * order * order * (t - w / rr) / rr**2
    return w, t, moment, shear


def _boundary_rows(edge: str, xi: float, order: int, nu: float, powers: np.ndarray, logs: np.ndarray) -> np.ndarray:
    w, t, moment, shear = _all_rows(xi, order, nu, powers, logs)
    return {"C": np.vstack([w, t]), "S": np.vstack([w, moment]), "F": np.vstack([moment, shear])}[edge]


def _nullspace(matrix: np.ndarray) -> np.ndarray:
    scale = np.max(np.abs(matrix), axis=1)
    scale[scale < 1] = 1
    balanced = matrix / scale[:, None]
    _, s, vh = np.linalg.svd(balanced)
    threshold = 1e-10 * max(1.0, s[0] if s.size else 1.0)
    rank = int(np.count_nonzero(s > threshold))
    basis = vh[rank:].T
    return basis if basis.size else vh[-2:].T


def _radial_green(xi: np.ndarray, eta: float, order: int, nu: float, outer: str, inner: str, xi0: float) -> np.ndarray:
    full_p, full_l = _terms(order, False)
    if xi0 > 0:
        a_basis = _nullspace(_boundary_rows(inner, xi0, order, nu, full_p, full_l))
        inner_p, inner_l = full_p, full_l
    else:
        inner_p, inner_l = _terms(order, True)
        a_basis = np.eye(inner_p.size)
    b_basis = _nullspace(_boundary_rows(outer, 1.0, order, nu, full_p, full_l))
    if a_basis.shape[1] != 2 or b_basis.shape[1] != 2:
        return np.zeros_like(xi)
    ui = np.vstack(_all_rows(eta, order, nu, inner_p, inner_l)) @ a_basis
    vo = np.vstack(_all_rows(eta, order, nu, full_p, full_l)) @ b_basis
    system = np.column_stack([-ui, vo])
    rhs = np.array([0.0, 0.0, 0.0, 1.0 / max(eta, 1e-10)])
    coeff = np.linalg.pinv(system) @ rhs if np.linalg.cond(system) > 1e12 else np.linalg.solve(system, rhs)
    alpha = coeff[:2]
    beta = coeff[2:]
    out = np.zeros_like(xi, dtype=float)
    left = xi <= eta
    if np.any(left):
        w, *_ = _all_rows(xi[left], order, nu, inner_p, inner_l)
        out[left] = (w @ a_basis) @ alpha
    if np.any(~left):
        w, *_ = _all_rows(xi[~left], order, nu, full_p, full_l)
        out[~left] = (w @ b_basis) @ beta
    return out
