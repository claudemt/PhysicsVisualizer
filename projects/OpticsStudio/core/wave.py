from __future__ import annotations

import numpy as np

from .common import make_coordinate_grid, normalize_array


def angular_spectrum_propagation(u0: np.ndarray, dx: float, wavelength: float, z: float, use_bandlimit: bool = True):
    nx, ny = u0.shape
    _, _, fx, fy = make_coordinate_grid(nx, ny, dx, dx)
    argument = 1.0 - (wavelength * fx) ** 2 - (wavelength * fy) ** 2
    transfer = np.exp(1j * 2 * np.pi * z / wavelength * np.sqrt(argument.astype(complex)))
    if use_bandlimit:
        lx = ny * dx
        ly = nx * dx
        fx_limit = 1.0 / (wavelength * np.sqrt(1.0 + (2.0 * z / lx) ** 2))
        fy_limit = 1.0 / (wavelength * np.sqrt(1.0 + (2.0 * z / ly) ** 2))
        transfer[(np.abs(fx) > fx_limit) | (np.abs(fy) > fy_limit)] = 0.0
    u0_hat = np.fft.fftshift(np.fft.fft2(np.fft.ifftshift(u0)))
    u1 = np.fft.fftshift(np.fft.ifft2(np.fft.ifftshift(u0_hat * transfer)))
    return u1, transfer


def make_fourier_filter(kind: str, fx: np.ndarray, fy: np.ndarray, scale: float) -> np.ndarray:
    key = str(kind).strip().lower()
    fmax = max(float(np.max(np.abs(fx))), np.finfo(float).eps)
    fxn = fx / fmax
    fyn = fy / fmax
    radius = np.hypot(fxn, fyn)
    width = max(0.03, float(scale))
    separation = np.clip(2.2 * float(scale), 0.15, 0.6)
    if key == "none":
        mask = np.ones_like(radius)
    elif key == "pinhole":
        mask = radius < float(scale)
    elif key == "ring":
        mask = np.abs(radius - 0.45) < width / 2.0
    elif key == "horizontal_single":
        mask = np.abs(fyn) < width
    elif key == "horizontal_double":
        mask = (np.abs(fyn - separation) < width) | (np.abs(fyn + separation) < width)
    elif key == "vertical_single":
        mask = np.abs(fxn) < width
    elif key == "vertical_double":
        mask = (np.abs(fxn - separation) < width) | (np.abs(fxn + separation) < width)
    else:
        mask = np.ones_like(radius)
    return np.asarray(mask, dtype=float)


def make_wave_object(kind: str, n: int) -> np.ndarray:
    axis = np.linspace(-1.0, 1.0, int(n))
    x, y = np.meshgrid(axis, axis)
    key = str(kind).strip().lower()
    if key == "mesh":
        mesh_x = np.abs(np.mod(8.0 * x + 1.0, 0.5)) < 0.06
        mesh_y = np.abs(np.mod(8.0 * y + 1.0, 0.5)) < 0.06
        field = mesh_x | mesh_y
    elif key in {"double_slit", "double slit"}:
        field = ((np.abs(x) < 0.04) & (np.abs(y - 0.18) < 0.25)).astype(float)
        field += ((np.abs(x) < 0.04) & (np.abs(y + 0.18) < 0.25)).astype(float)
    elif key == "aperture":
        radius = np.hypot(x, y)
        field = np.maximum((radius < 0.55).astype(float) - 0.6 * (radius < 0.22), 0.0)
    elif key == "gaussian_lattice":
        field = np.zeros_like(x)
        for cx in (-0.45, 0.0, 0.45):
            for cy in (-0.45, 0.0, 0.45):
                field += np.exp(-((x - cx) ** 2 + (y - cy) ** 2) / (2 * 0.08**2))
    else:
        bars = (np.abs(y) < 0.06).astype(float)
        bars += ((np.abs(x - 0.32) < 0.04) & (np.abs(y) < 0.6)).astype(float)
        bars += ((np.abs(x + 0.32) < 0.04) & (np.abs(y) < 0.6)).astype(float)
        bars += ((np.abs(y - 0.35) < 0.05) & (np.abs(x) < 0.35)).astype(float)
        field = 0.8 * bars + 0.7 * np.exp(-(x**2 + y**2) / (2 * 0.15**2))
    return normalize_array(np.maximum(field, 0.0))


def run_wave_optics(params: dict) -> dict:
    n = int(np.clip(float(params.get("resolution", 256)), 64, 1024))
    pixel = float(params.get("pixel_size_um", 6.5)) * 1e-6
    wavelength = float(params.get("wavelength_nm", 532.0)) * 1e-9
    z = float(params.get("distance_mm", 20.0)) * 1e-3
    x, y, fx, fy = make_coordinate_grid(n, n, pixel, pixel)
    obj = make_wave_object(str(params.get("object", "bars")), n)
    filt = make_fourier_filter(str(params.get("filter", "pinhole")), fx, fy, float(params.get("filter_scale", 0.16)))
    field0 = obj.astype(complex)
    propagated, transfer = angular_spectrum_propagation(field0, pixel, wavelength, z, bool(params.get("band_limit", True)))
    spectrum = np.fft.fftshift(np.fft.fft2(np.fft.ifftshift(field0)))
    filtered = np.fft.fftshift(np.fft.ifft2(np.fft.ifftshift(spectrum * filt)))
    input_spectrum = normalize_array(np.log1p(np.abs(spectrum)))
    return {
        "mode": str(params.get("mode", "free_space")).strip().lower(),
        "object": normalize_array(obj),
        "input_spectrum": input_spectrum,
        "transfer_real": np.real(transfer),
        "transfer_phase": np.real(transfer),
        "filter": normalize_array(filt),
        "propagated": normalize_array(np.abs(propagated) ** 2),
        "filtered": normalize_array(np.abs(filtered) ** 2),
    }
