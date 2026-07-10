from __future__ import annotations

import numpy as np
from scipy import ndimage

from .common import centered_grid, normalize_array
from .imaging import make_circular_pupil, zernike_wavefront


def make_grating(x: np.ndarray, y: np.ndarray, frequency: float, angle_deg: float = 0.0, phase: float = 0.0):
    angle = np.deg2rad(float(angle_deg))
    coord = x * np.cos(angle) + y * np.sin(angle)
    return 0.5 + 0.5 * np.cos(2 * np.pi * float(frequency) * coord + phase)


def shearing_interferogram(
    n: int,
    aberration_name: str = "coma",
    coefficient_waves: float = 0.45,
    shear_px: float = 10.0,
    carrier_frequency: float = 8.0,
) -> dict:
    pupil, rho, phi = make_circular_pupil(int(n))
    wavefront = zernike_wavefront(aberration_name, rho, phi)
    phase = 2 * np.pi * float(coefficient_waves) * wavefront
    shift = (0.0, float(shear_px))
    phase_shifted = ndimage.shift(phase, shift, order=1, mode="constant", cval=0.0, prefilter=False)
    pupil_shifted = ndimage.shift(pupil, shift, order=1, mode="constant", cval=0.0, prefilter=False)
    common_mask = (pupil > 0.5) & (pupil_shifted > 0.5)
    x_norm = np.linspace(-1.0, 1.0, int(n))[None, :]
    carrier = 2 * np.pi * float(carrier_frequency) * x_norm
    delta_phase = (phase_shifted - phase) * common_mask
    interferogram = common_mask * (1.0 + np.cos(delta_phase + carrier))
    return {
        "wavefront": wavefront * pupil,
        "delta_phase": delta_phase,
        "interferogram": normalize_array(interferogram),
        "mask": common_mask.astype(float),
    }


def gerchberg_saxton_phase(
    n: int,
    spot_count: int = 3,
    separation_px: float | None = None,
    iterations: int = 80,
    alpha: float = 0.85,
) -> dict:
    n = int(np.clip(n, 64, 1024))
    count = int(np.clip(spot_count, 1, 9))
    separation = float(separation_px if separation_px is not None else 0.18 * n)
    n_iter = int(np.clip(iterations, 1, 500))
    damping = float(np.clip(alpha, 0.0, 1.0))
    pupil, _, _ = make_circular_pupil(n)

    offsets = np.linspace(-(count - 1) / 2, (count - 1) / 2, count) * separation
    xp, yp = np.meshgrid(np.arange(n), np.arange(n))
    center = (n - 1) / 2
    sigma = max(1.5, 0.05 * separation + 1.0)
    target_amplitude = np.zeros((n, n), dtype=float)
    for cx in offsets:
        for cy in offsets:
            target_amplitude += np.exp(
                -((xp - (center + cx)) ** 2 + (yp - (center + cy)) ** 2) / (2 * sigma**2)
            )
    target_amplitude = normalize_array(target_amplitude)
    signal_mask = target_amplitude > 0.15

    rng = np.random.default_rng(7)
    pupil_field = pupil * np.exp(1j * rng.uniform(0.0, 2 * np.pi, (n, n)))
    efficiency = np.zeros(n_iter, dtype=float)
    uniformity = np.zeros(n_iter, dtype=float)
    eps = np.finfo(float).eps
    for k in range(n_iter):
        image_field = np.fft.fftshift(np.fft.fft2(np.fft.ifftshift(pupil_field)))
        image_intensity = np.abs(image_field) ** 2
        signal_values = image_intensity[signal_mask]
        efficiency[k] = float(np.sum(signal_values) / max(float(np.sum(image_intensity)), eps))
        if signal_values.size:
            peak_max = float(np.max(signal_values))
            peak_min = float(np.min(signal_values))
            uniformity[k] = 1.0 - (peak_max - peak_min) / (peak_max + peak_min + eps)
        constrained = target_amplitude * np.exp(1j * np.angle(image_field))
        back_field = np.fft.fftshift(np.fft.ifft2(np.fft.ifftshift(constrained)))
        phase_only_update = pupil * np.exp(1j * np.angle(back_field))
        pupil_field = (1.0 - damping) * pupil_field + damping * phase_only_update

    final_image = np.fft.fftshift(np.fft.fft2(np.fft.ifftshift(pupil_field)))
    return {
        "target_amplitude": target_amplitude,
        "final_intensity": normalize_array(np.abs(final_image) ** 2),
        "final_phase": np.angle(pupil_field) * pupil,
        "efficiency": efficiency,
        "uniformity": uniformity,
    }


def run_interference(params: dict) -> dict:
    n = int(np.clip(float(params.get("resolution", 256)), 64, 1024))
    mode = str(params.get("mode", "moire")).strip().lower()
    if "gs" in mode or "gerchberg" in mode:
        return {
            "mode": "gs_phase",
            **gerchberg_saxton_phase(
                n,
                int(float(params.get("spot_count", 3))),
                float(params.get("separation_px", 0.18 * n)),
                int(float(params.get("iterations", 80))),
                float(params.get("alpha", 0.85)),
            ),
        }
    if "shear" in mode:
        return {
            "mode": "shearing",
            **shearing_interferogram(
                n,
                str(params.get("aberration", "coma")),
                float(params.get("coefficient", params.get("coefficient_waves", 0.45))),
                float(params.get("shear_px", 10)),
                float(params.get("carrier", params.get("carrier_frequency", 8))),
            ),
        }

    x, y = centered_grid(n, 0.5)
    grating_a = make_grating(x, y, float(params.get("freq1", 18)), 0.0)
    grating_b = make_grating(x, y, float(params.get("freq2", 19.2)), float(params.get("angle_deg", 2.5)))
    moire = normalize_array(grating_a * grating_b)
    spectrum = normalize_array(np.log1p(np.abs(np.fft.fftshift(np.fft.fft2(np.fft.ifftshift(moire))))))
    return {
        "mode": "moire",
        "grating_a": grating_a,
        "grating_b": grating_b,
        "moire": moire,
        "spectrum": spectrum,
    }
