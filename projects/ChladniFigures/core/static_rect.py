from __future__ import annotations

from dataclasses import dataclass

import numpy as np

from .boundaries import rect_boundary_meta
from .modes_rect import compute_rect_modes


@dataclass
class StaticRectResult:
    x: np.ndarray
    y: np.ndarray
    u: np.ndarray
    q: np.ndarray
    modal_weights: np.ndarray
    boundary: str
    method: str
    domain: str
    load_label: str
    nu: float
    xi0: float


def parse_sources(raw: object) -> np.ndarray:
    if raw is None:
        return np.array([[0.0, 0.0, 1.0, 0.0]])
    if isinstance(raw, np.ndarray) or (isinstance(raw, (list, tuple)) and raw and not isinstance(raw[0], str)):
        data = np.asarray(raw, dtype=float)
        if data.size == 0:
            return np.empty((0, 4), dtype=float)
        if data.ndim == 1:
            data = data[None, :]
        if data.ndim != 2:
            raise ValueError("sources must be an N-by-2, N-by-3, or N-by-4 array [x y P sigma].")
        if data.shape[1] == 2:
            data = np.column_stack((data, np.ones(data.shape[0]), np.zeros(data.shape[0])))
        elif data.shape[1] == 3:
            data = np.column_stack((data, np.zeros(data.shape[0])))
        elif data.shape[1] != 4:
            raise ValueError("sources must be an N-by-2, N-by-3, or N-by-4 array [x y P sigma].")
        if not np.isfinite(data).all() or np.any(data[:, 3] < 0):
            raise ValueError("sources must be finite and use nonnegative sigma values.")
        return data
    rows = []
    for line in str(raw).replace(";", "\n").splitlines():
        text = line.strip().strip("[]")
        if not text:
            continue
        parts = [float(p) for p in text.replace(",", " ").split()]
        if len(parts) == 2:
            parts.extend((1.0, 0.0))
        elif len(parts) == 3:
            parts.append(0.0)
        if len(parts) >= 4:
            rows.append(parts[:4])
    result = np.array(rows or [[0.0, 0.0, 1.0, 0.0]], dtype=float)
    if not np.isfinite(result).all() or np.any(result[:, 3] < 0):
        raise ValueError("sources must be finite and use nonnegative sigma values.")
    return result


def evaluate_custom_load(expression: object, xg: np.ndarray, yg: np.ndarray) -> np.ndarray:
    text = str(expression or "0").strip().replace(".^", "**").replace(".*", "*").replace("./", "/")
    allowed = {
        "x": xg, "y": yg, "X": xg, "Y": yg, "pi": np.pi,
        "sin": np.sin, "cos": np.cos, "tan": np.tan, "exp": np.exp,
        "sqrt": np.sqrt, "abs": np.abs, "log": np.log,
    }
    try:
        value = eval(text, {"__builtins__": {}}, allowed)  # noqa: S307 - restricted numerical namespace.
    except Exception as exc:
        raise ValueError(f"Invalid custom load expression: {expression!r}") from exc
    out = np.asarray(value, dtype=float)
    return np.broadcast_to(out, xg.shape).copy()


def distributed_load(x: np.ndarray, y: np.ndarray, load_type: str, q0: float, sources: np.ndarray,
                     custom_load: object = None) -> np.ndarray:
    xg, yg = np.meshgrid(x, y)
    q = np.zeros_like(xg)
    lt = str(load_type).lower()
    if lt in {"uniform", "mixed"}:
        q += float(q0)
    if lt in {"points", "mixed"}:
        dx = abs(x[1] - x[0]) if x.size > 1 else 1.0
        sigma_default = 2.5 * dx
        for xs, ys, amp, sigma in sources:
            sig = float(sigma) if sigma > 0 else sigma_default
            g = np.exp(-((xg - xs) ** 2 + (yg - ys) ** 2) / (2 * sig * sig))
            total = np.trapezoid(np.trapezoid(g, x, axis=1), y)
            if total > 0:
                q += amp * g / total
    if lt in {"custom", "mixed"}:
        q += evaluate_custom_load(custom_load, xg, yg)
    return q


def static_load_label(load_type: str) -> str:
    key = str(load_type).strip().lower()
    return {
        "points": "point sources",
        "point": "point sources",
        "uniform": "uniform self-weight",
        "custom": "custom distributed load",
        "mixed": "mixed load",
    }.get(key, key or "load")


def compute_static_rect_modal(
    boundary: str = "SSSS",
    nu: float = 0.30,
    grid_n: int = 220,
    truncation: int = 60,
    d_rigidity: float = 1.0,
    load_type: str = "points",
    q0: float = 1.0,
    sources: object = None,
    custom_load: object = None,
    a: float = 2.0,
    b: float = 1.0,
    solver: str = "auto",
) -> StaticRectResult:
    meta = rect_boundary_meta(boundary)
    # MATLAB static modal summation used Navier only for SSSS and retained the
    # general Ritz basis otherwise. Keep that default while exposing all routes.
    selected_solver = "navier" if meta.is_all_simply else "ritz" if str(solver).strip().lower() == "auto" else solver
    modes = compute_rect_modes(meta.code, nu, int(truncation), int(grid_n), a, b, solver=selected_solver)
    x = modes[0].x
    y = modes[0].y
    src = parse_sources(sources)
    q = distributed_load(x, y, load_type, q0, src, custom_load)
    _validate_source_geometry(src, a, b)
    if meta.is_all_free:
        _require_free_compatibility(q, x, y, src, load_type)
    u = np.zeros_like(q)
    weights = np.zeros(len(modes))
    for idx, mode in enumerate(modes):
        phi = mode.u
        norm = np.trapezoid(np.trapezoid(phi * phi, x, axis=1), y)
        proj = np.trapezoid(np.trapezoid(q * phi, x, axis=1), y)
        lam = max(mode.lam_disp**2, 1e-10)
        weights[idx] = proj / (float(d_rigidity) * lam * max(norm, 1e-12))
        u += weights[idx] * phi
    amp = np.nanmax(np.abs(u))
    if amp > 0:
        u = u / amp
    return StaticRectResult(
        x=x, y=y, u=u, q=q, modal_weights=weights, boundary=meta.code,
        method="rectangular modal static summation", domain="rect", load_label=static_load_label(load_type),
        nu=float(nu), xi0=float(b) / float(a),
    )


def _validate_source_geometry(sources: np.ndarray, a: float, b: float) -> None:
    if sources.size == 0:
        return
    tol = 1e-10 * max(1.0, float(a), float(b))
    inside = (
        (sources[:, 0] >= -a / 2 - tol) & (sources[:, 0] <= a / 2 + tol)
        & (sources[:, 1] >= -b / 2 - tol) & (sources[:, 1] <= b / 2 + tol)
    )
    if not np.all(inside):
        raise ValueError("All rectangular source positions must lie within the plate.")


def _require_free_compatibility(q: np.ndarray, x: np.ndarray, y: np.ndarray, sources: np.ndarray, load_type: str) -> None:
    xg, yg = np.meshgrid(x, y)
    resultant = float(np.trapezoid(np.trapezoid(q, x, axis=1), y))
    moment_x = float(np.trapezoid(np.trapezoid(q * yg, x, axis=1), y))
    moment_y = float(np.trapezoid(np.trapezoid(q * xg, x, axis=1), y))
    scale = max(1.0, float(np.trapezoid(np.trapezoid(np.abs(q), x, axis=1), y)))
    if max(abs(resultant), abs(moment_x), abs(moment_y)) > 1e-8 * scale:
        raise ValueError(
            "FFFF static response requires zero resultant force and first moments; "
            "supply a self-equilibrated load or use a constrained boundary."
        )
