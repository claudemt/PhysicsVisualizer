from __future__ import annotations

import numpy as np


def normalize_array(values: np.ndarray, clip_negative: bool = False) -> np.ndarray:
    data = np.asarray(values, dtype=float)
    if clip_negative:
        data = np.maximum(data, 0.0)
    finite = np.isfinite(data)
    if not finite.any():
        return np.zeros_like(data, dtype=float)
    lo = float(np.nanmin(data[finite]))
    hi = float(np.nanmax(data[finite]))
    if hi <= lo:
        return np.zeros_like(data, dtype=float)
    return np.clip((data - lo) / (hi - lo), 0.0, 1.0)


def make_coordinate_grid(nx: int, ny: int | None = None, dx: float = 1.0, dy: float | None = None):
    if ny is None:
        ny = nx
    if dy is None:
        dy = dx
    x_vec = (np.arange(ny) - ny // 2) * dx
    y_vec = (np.arange(nx) - nx // 2) * dy
    x, y = np.meshgrid(x_vec, y_vec)
    fx_vec = (np.arange(ny) - ny // 2) / (ny * dx)
    fy_vec = (np.arange(nx) - nx // 2) / (nx * dy)
    fx, fy = np.meshgrid(fx_vec, fy_vec)
    return x, y, fx, fy


def centered_grid(n: int, half_width: float = 1.0):
    axis = np.linspace(-half_width, half_width, int(n), endpoint=False)
    x, y = np.meshgrid(axis, axis)
    return x, y


def make_demo_object(name: str, x: np.ndarray, y: np.ndarray, scale: float = 0.35) -> np.ndarray:
    key = str(name).strip().lower().replace("-", " ").replace("_", " ")
    sx = max(float(scale), np.finfo(float).eps)
    sy = sx
    if key in {"bars", "bar target"}:
        return ((np.abs(x) < 0.16 * sx) | ((np.abs(x) < 0.42 * sx) & (np.abs(y) < 0.10 * sy))).astype(float)
    if key in {"disk", "circle", "circular aperture"}:
        return (np.hypot(x, y) <= 0.45 * sx).astype(float)
    if key in {"rectangle", "rectangular aperture"}:
        return ((np.abs(x) <= 0.48 * sx) & (np.abs(y) <= 0.28 * sy)).astype(float)
    if key in {"double slit", "two slits"}:
        slit = np.abs(y) <= 0.45 * sy
        return (((np.abs(x - 0.22 * sx) < 0.055 * sx) | (np.abs(x + 0.22 * sx) < 0.055 * sx)) & slit).astype(float)
    if key in {"three slits", "triple slit"}:
        slit = np.abs(y) <= 0.45 * sy
        centers = (-0.26 * sx, 0.0, 0.26 * sx)
        mask = np.zeros_like(x, dtype=bool)
        for center in centers:
            mask |= np.abs(x - center) < 0.045 * sx
        return (mask & slit).astype(float)
    if key in {"five slits", "five slit"}:
        slit = np.abs(y) <= 0.45 * sy
        centers = np.linspace(-0.36 * sx, 0.36 * sx, 5)
        mask = np.zeros_like(x, dtype=bool)
        for center in centers:
            mask |= np.abs(x - center) < 0.032 * sx
        return (mask & slit).astype(float)
    if key in {"two circular apertures", "double circular aperture", "two pinholes"}:
        radius = 0.12 * sx
        return (((x - 0.24 * sx) ** 2 + y**2 <= radius**2) |
                ((x + 0.24 * sx) ** 2 + y**2 <= radius**2)).astype(float)
    if key in {"cross aperture", "cross"}:
        return ((np.abs(x) < 0.08 * sx) & (np.abs(y) < 0.50 * sy) |
                (np.abs(y) < 0.08 * sy) & (np.abs(x) < 0.50 * sx)).astype(float)
    if key in {"star aperture", "star"}:
        theta = np.arctan2(y, x)
        radius = np.hypot(x, y)
        boundary = 0.33 * sx * (1.0 + 0.28 * np.cos(5 * theta))
        return (radius <= boundary).astype(float)
    if key in {"finite 2d grating", "grating"}:
        pitch = 0.18 * sx
        dots = (np.mod(x + 3 * pitch, pitch) < 0.055 * sx) & (np.mod(y + 3 * pitch, pitch) < 0.055 * sy)
        window = (np.abs(x) <= 0.65 * sx) & (np.abs(y) <= 0.65 * sy)
        return (dots & window).astype(float)
    if key in {"hex lattice circles", "hex lattice", "hexagonal lattice"}:
        pitch = 0.20 * sx
        radius = 0.045 * sx
        mask = np.zeros_like(x, dtype=bool)
        for row in range(-3, 4):
            for col in range(-3, 4):
                cx = (col + 0.5 * (row % 2)) * pitch
                cy = row * pitch * np.sqrt(3.0) / 2.0
                if cx**2 + cy**2 <= (0.62 * sx) ** 2:
                    mask |= (x - cx) ** 2 + (y - cy) ** 2 <= radius**2
        return mask.astype(float)
    if key in {"pinhole", "aperture"}:
        return (np.hypot(x, y) <= 0.22 * sx).astype(float)
    return (((np.abs(x) < 0.08 * sx) & (np.abs(y) < 0.5 * sy)) |
            ((x - 0.32 * sx) ** 2 + y ** 2 < (0.13 * sx) ** 2) |
            ((x + 0.32 * sx) ** 2 + y ** 2 < (0.13 * sx) ** 2)).astype(float)
