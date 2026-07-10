from __future__ import annotations

import numpy as np

from .common import normalize_array


def make_circular_pupil(n: int):
    axis = np.linspace(-1.0, 1.0, int(n), endpoint=False)
    x, y = np.meshgrid(axis, axis)
    rho = np.hypot(x, y)
    phi = np.arctan2(y, x)
    return (rho <= 1.0).astype(float), rho, phi


def zernike_wavefront(name: str, rho: np.ndarray, phi: np.ndarray) -> np.ndarray:
    key = str(name).lower()
    if "tilt" in key:
        z = rho * np.cos(phi)
    elif "defocus" in key:
        z = 2 * rho**2 - 1
    elif "astig" in key:
        z = rho**2 * np.cos(2 * phi)
    elif "coma" in key:
        z = (3 * rho**3 - 2 * rho) * np.cos(phi)
    elif "spherical" in key:
        z = 6 * rho**4 - 6 * rho**2 + 1
    else:
        z = np.zeros_like(rho)
    return np.where(rho <= 1.0, z, 0.0)


def compute_psf_2d(n: int, aberration_name: str = "defocus", coefficient_waves: float = 0.35, extra_phase=0.0):
    pupil, rho, phi = make_circular_pupil(n)
    wavefront = zernike_wavefront(aberration_name, rho, phi)
    pupil_field = pupil * np.exp(1j * (2 * np.pi * float(coefficient_waves) * wavefront + extra_phase))
    field = np.fft.fftshift(np.fft.fft2(np.fft.ifftshift(pupil_field)))
    psf = normalize_array(np.abs(field) ** 2, clip_negative=True)
    return psf, pupil_field, wavefront


def compute_otf(psf: np.ndarray) -> np.ndarray:
    otf = np.fft.fftshift(np.fft.fft2(np.fft.ifftshift(psf)))
    mag = np.abs(otf)
    peak = max(float(np.max(mag)), np.finfo(float).eps)
    return otf / peak


def run_imaging(params: dict) -> dict:
    n = int(np.clip(float(params.get("resolution", 256)), 64, 1024))
    psf, pupil_field, wavefront = compute_psf_2d(
        n,
        str(params.get("aberration", "defocus")),
        float(params.get("coefficient_waves", 0.35)),
    )
    mode = str(params.get("mode", "widefield")).lower()
    effective = psf.copy()
    if "confocal" in mode:
        pinhole_factor = max(float(params.get("pinhole", params.get("pinhole_factor", 0.60))), 0.05)
        detector_psf = normalize_array(psf ** (1.0 / pinhole_factor))
        effective = normalize_array(psf * detector_psf)
    elif "sted" in mode:
        sted = float(params.get("sted", 4.0))
        _, _, phi = make_circular_pupil(n)
        depletion_psf, _, _ = compute_psf_2d(
            n,
            str(params.get("aberration", "defocus")),
            float(params.get("coefficient_waves", 0.35)),
            extra_phase=phi,
        )
        effective = normalize_array(psf * np.exp(-max(sted, 0.0) * depletion_psf))
    effective_otf = compute_otf(effective)
    pupil_phase = np.angle(pupil_field) * (np.abs(pupil_field) > 0)
    center = n // 2
    return {
        "pupil": pupil_phase,
        "pupil_phase": pupil_phase,
        "wavefront": wavefront,
        "psf": effective,
        "widefield_psf": psf,
        "otf": normalize_array(np.abs(effective_otf)),
        "effective": effective,
        "profile_x": np.arange(1, n + 1),
        "widefield_profile": psf[center, :],
        "effective_profile": effective[center, :],
    }
