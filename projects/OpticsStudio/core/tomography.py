from __future__ import annotations

import numpy as np
from scipy import ndimage

from .common import centered_grid, normalize_array


def make_phantom_slice(n: int, kind: str = "shepp_logan") -> np.ndarray:
    x, y = centered_grid(n, 1.0)
    key = str(kind).lower()
    phantom = np.zeros_like(x)
    if "disk" in key:
        phantom[np.hypot(x, y) < 0.62] = 1.0
    elif "bar" in key:
        phantom[(np.abs(x) < 0.18) & (np.abs(y) < 0.75)] = 1.0
        phantom[(np.abs(y) < 0.10) & (np.abs(x) < 0.75)] += 0.5
    else:
        ellipses = [
            (1.0, 0.0, 0.0, 0.69, 0.92, 0.0),
            (-0.8, 0.0, -0.0184, 0.6624, 0.874, 0.0),
            (-0.2, 0.22, 0.0, 0.11, 0.31, -18.0),
            (-0.2, -0.22, 0.0, 0.16, 0.41, 18.0),
            (0.1, 0.0, 0.35, 0.21, 0.25, 0.0),
            (0.1, 0.0, 0.1, 0.046, 0.046, 0.0),
        ]
        for amp, x0, y0, a, b, angle in ellipses:
            th = np.deg2rad(angle)
            xr = (x - x0) * np.cos(th) + (y - y0) * np.sin(th)
            yr = -(x - x0) * np.sin(th) + (y - y0) * np.cos(th)
            phantom[(xr / a) ** 2 + (yr / b) ** 2 <= 1.0] += amp
    return normalize_array(phantom)


def parallel_radon_transform(image: np.ndarray, angles: int | np.ndarray = 90, detector_bins: int | None = None):
    if np.isscalar(angles):
        theta = np.linspace(0.0, 180.0, int(angles), endpoint=False)
    else:
        theta = np.asarray(angles, dtype=float)
    n = image.shape[0]
    if detector_bins is None:
        detector_bins = n
    sinogram = np.zeros((int(detector_bins), len(theta)), dtype=float)
    for i, angle in enumerate(theta):
        rotated = ndimage.rotate(image, float(angle), reshape=False, order=1, mode="constant", cval=0.0)
        proj = rotated.sum(axis=0)
        coords = np.linspace(0, proj.size - 1, int(detector_bins))
        sinogram[:, i] = np.interp(coords, np.arange(proj.size), proj)
    return sinogram, theta


def filtered_backprojection(sinogram: np.ndarray, theta: np.ndarray, output_size: int, filter_name: str = "ram_lak") -> np.ndarray:
    n_det, n_theta = sinogram.shape
    freqs = np.fft.fftfreq(n_det).reshape(-1, 1)
    filt = np.abs(freqs)
    key = str(filter_name).lower()
    if "hann" in key:
        filt *= 0.5 + 0.5 * np.cos(2 * np.pi * freqs)
    elif "none" in key:
        filt[:] = 1.0
    filtered = np.real(np.fft.ifft(np.fft.fft(sinogram, axis=0) * filt, axis=0))
    recon = np.zeros((int(output_size), int(output_size)), dtype=float)
    x = np.linspace(-(n_det - 1) / 2, (n_det - 1) / 2, int(output_size))
    xx, yy = np.meshgrid(x, x)
    det_axis = np.linspace(-(n_det - 1) / 2, (n_det - 1) / 2, n_det)
    for i, angle in enumerate(theta):
        t = xx * np.cos(np.deg2rad(angle)) + yy * np.sin(np.deg2rad(angle))
        recon += np.interp(t.ravel(), det_axis, filtered[:, i], left=0.0, right=0.0).reshape(recon.shape)
    recon *= np.pi / max(2 * n_theta, 1)
    return normalize_array(recon)


def run_tomography(params: dict) -> dict:
    n = int(np.clip(float(params.get("resolution", 128)), 32, 512))
    phantom = make_phantom_slice(n, str(params.get("phantom", "shepp_logan")))
    sinogram, theta = parallel_radon_transform(phantom, int(float(params.get("angles", 90))), int(float(params.get("detector_bins", n))))
    recon = filtered_backprojection(sinogram, theta, n, str(params.get("filter", "ram_lak")))
    return {"phantom": phantom, "sinogram": normalize_array(sinogram), "reconstruction": recon}
