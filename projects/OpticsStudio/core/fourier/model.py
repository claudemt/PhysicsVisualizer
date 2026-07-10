from __future__ import annotations

from dataclasses import dataclass

import numpy as np

from ..common import normalize_array
from .modules import filter_module, object_module, phase_module
from .presets import get_fourier_preset


@dataclass(frozen=True)
class FourierResult:
    x_mm: np.ndarray
    y_mm: np.ndarray
    xf_mm: np.ndarray
    yf_mm: np.ndarray
    object_amp: np.ndarray
    phase_wrapped: np.ndarray
    phase_support: np.ndarray
    after_phase_amp: np.ndarray
    spectrum_intensity: np.ndarray
    filter_amp: np.ndarray
    output_intensity: np.ndarray
    field_after_phase: np.ndarray
    field_fourier: np.ndarray
    field_image: np.ndarray
    summary: str


def fourier_params_from_gui(params: dict) -> dict:
    preset = get_fourier_preset(params.get("preset"))
    values = preset or {}
    aliases = {
        "n_samples": "resolution",
        "zernike_coeff_waves": "zernike_waves",
        "filter_scale_ratio": "filter_scale",
        "object_name": "object",
        "phase_name": "phase",
        "filter_name": "filter",
        "auto_adjust_plot_range": "plot_range",
        "object_plot_half_range_mm": "object_half_range_mm",
        "fourier_plot_half_range_mm": "fourier_half_range_mm",
        "display_scaling": "image_scaling",
    }
    gui_defaults = {
        "wavelength_nm": 632.8,
        "focal_length_mm": 250.0,
        "window_mm": 4.0,
        "resolution": 256,
        "object_scale_mm": 0.55,
        "secondary_scale_mm": 0.30,
        "phase_radius_mm": 1.0,
        "zernike_waves": 0.30,
        "filter_scale": 0.18,
        "topological_charge": 1,
        "object": "double slit",
        "phase": "no phase",
        "filter": "circular low pass",
        "plot_range": "auto",
        "object_half_range_mm": 1.2,
        "fourier_half_range_mm": 8.0,
        "image_scaling": "fixed",
    }
    for target in (
        "wavelength_nm", "focal_length_mm", "window_mm", "n_samples",
        "object_scale_mm", "secondary_scale_mm", "phase_radius_mm",
        "zernike_coeff_waves", "filter_scale_ratio", "topological_charge",
        "object_name", "phase_name", "filter_name", "auto_adjust_plot_range",
        "object_plot_half_range_mm", "fourier_plot_half_range_mm", "display_scaling",
    ):
        source = aliases.get(target, target)
        provided_key = source if source in params else target if target in params else None
        if provided_key is None:
            continue
        value = params[provided_key]
        if preset is None or provided_key == target or value != gui_defaults.get(source):
            values[target] = value

    plot_range = values.get("auto_adjust_plot_range", True)
    if isinstance(plot_range, str):
        plot_range = plot_range.strip().lower() == "auto"
    n = int(float(values.get("n_samples", params.get("n_samples", 256))))
    n = int(np.clip(n, 64, 2048))
    out = {
        "preset_name": str(values.get("name", "custom / manual")),
        "wavelength_nm": float(values.get("wavelength_nm", 632.8)),
        "focal_length_mm": float(values.get("focal_length_mm", 250.0)),
        "window_mm": float(values.get("window_mm", 4.0)),
        "n_samples": n,
        "object_scale_mm": float(values.get("object_scale_mm", 0.55)),
        "secondary_scale_mm": float(values.get("secondary_scale_mm", 0.30)),
        "phase_radius_mm": float(values.get("phase_radius_mm", 1.0)),
        "zernike_coeff_waves": float(values.get("zernike_coeff_waves", 0.30)),
        "filter_scale_ratio": float(values.get("filter_scale_ratio", 0.18)),
        "topological_charge": int(float(values.get("topological_charge", 1))),
        "object_name": str(values.get("object_name", "cross aperture")),
        "phase_name": str(values.get("phase_name", "no phase")),
        "filter_name": str(values.get("filter_name", "circular low pass")),
        "auto_adjust_plot_range": bool(plot_range),
        "object_plot_half_range_mm": max(float(values.get("object_plot_half_range_mm", 1.2)), 1e-6),
        "fourier_plot_half_range_mm": max(float(values.get("fourier_plot_half_range_mm", 8.0)), 1e-6),
        "display_scaling": str(values.get("display_scaling", "fixed")).strip().lower(),
    }
    out["lambda_m"] = out["wavelength_nm"] * 1e-9
    out["f_m"] = out["focal_length_mm"] * 1e-3
    out["window_m"] = out["window_mm"] * 1e-3
    out["object_scale_m"] = out["object_scale_mm"] * 1e-3
    out["secondary_scale_m"] = out["secondary_scale_mm"] * 1e-3
    out["phase_radius_m"] = out["phase_radius_mm"] * 1e-3
    return out


def fourier_4f_model(params: dict) -> FourierResult:
    p = fourier_params_from_gui(params)
    n = p["n_samples"]
    length = p["window_m"]
    dx = length / n
    axis = (np.arange(n) - n // 2) * dx
    x, y = np.meshgrid(axis, axis)
    freq = (np.arange(n) - n // 2) / (n * dx)
    fx, fy = np.meshgrid(freq, freq)
    xf = p["lambda_m"] * p["f_m"] * fx
    yf = p["lambda_m"] * p["f_m"] * fy

    obj = np.asarray(object_module(p["object_name"], x, y, p), dtype=float)
    phase = np.asarray(phase_module(p["phase_name"], x, y, p), dtype=float)
    filt = np.asarray(filter_module(p["filter_name"], xf, yf, p), dtype=float)
    support = np.ones_like(obj) if p["phase_name"].lower() == "no phase" else (np.hypot(x, y) <= p["phase_radius_m"]).astype(float)

    field_after_phase = obj * support * np.exp(1j * phase)
    field_fourier = np.fft.fftshift(np.fft.fft2(np.fft.ifftshift(field_after_phase)))
    field_image = np.fft.fftshift(np.fft.ifft2(np.fft.ifftshift(field_fourier * filt)))

    return FourierResult(
        x_mm=x * 1e3,
        y_mm=y * 1e3,
        xf_mm=xf * 1e3,
        yf_mm=yf * 1e3,
        object_amp=normalize_array(obj, clip_negative=True),
        phase_wrapped=np.angle(np.exp(1j * phase)) * support,
        phase_support=support,
        after_phase_amp=normalize_array(np.abs(field_after_phase), clip_negative=True),
        spectrum_intensity=normalize_array(np.abs(field_fourier) ** 2, clip_negative=True),
        filter_amp=normalize_array(filt, clip_negative=True),
        output_intensity=normalize_array(np.abs(field_image) ** 2, clip_negative=True),
        field_after_phase=field_after_phase,
        field_fourier=field_fourier,
        field_image=field_image,
        summary=f"{p['object_name']} + {p['phase_name']} + {p['filter_name']} | "
        f"lambda={p['wavelength_nm']:.1f} nm | f={p['focal_length_mm']:.1f} mm | N={n}",
    )
