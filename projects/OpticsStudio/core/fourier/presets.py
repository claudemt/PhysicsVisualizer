from __future__ import annotations

from copy import deepcopy


_DEFAULT = {
    "wavelength_nm": 632.8,
    "focal_length_mm": 250.0,
    "window_mm": 4.0,
    "n_samples": 1536,
    "object_scale_mm": 0.55,
    "secondary_scale_mm": 0.30,
    "phase_radius_mm": 1.00,
    "zernike_coeff_waves": 0.30,
    "filter_scale_ratio": 0.18,
    "topological_charge": 1,
    "auto_adjust_plot_range": True,
    "object_plot_half_range_mm": 1.20,
    "fourier_plot_half_range_mm": 8.00,
    "object_name": "Double slit",
    "phase_name": "No phase",
    "filter_name": "Circular low-pass",
    "display_scaling": "fixed",
}


def _preset(name: str, **updates) -> dict:
    values = {**_DEFAULT, **updates}
    values["name"] = name
    return values


_PRESETS = (
    _preset("HeNe classroom preview"),
    _preset(
        "Rich 4f low-pass demo",
        object_name="Hex lattice circles",
        object_scale_mm=0.22,
        secondary_scale_mm=0.38,
        filter_scale_ratio=0.12,
        fourier_plot_half_range_mm=6.0,
    ),
    _preset(
        "Coma plus ring filter",
        object_name="Star aperture",
        phase_name="Zernike coma x",
        filter_name="Ring band-pass",
        zernike_coeff_waves=0.45,
        filter_scale_ratio=0.34,
        fourier_plot_half_range_mm=16.0,
    ),
    _preset(
        "Astigmatic slit selection",
        object_name="Rectangular aperture",
        phase_name="Zernike astigmatism 0 deg",
        filter_name="Horizontal slit",
        zernike_coeff_waves=0.32,
        object_scale_mm=0.60,
        secondary_scale_mm=0.22,
        filter_scale_ratio=0.12,
        fourier_plot_half_range_mm=10.0,
    ),
    _preset(
        "Thin lens focusing",
        object_name="Circular aperture",
        phase_name="Thin lens",
        filter_name="No filter",
        phase_radius_mm=1.10,
        object_scale_mm=1.00,
        fourier_plot_half_range_mm=12.0,
    ),
    _preset(
        "Vortex and mesh",
        object_name="Cross aperture",
        phase_name="Vortex charge 1",
        filter_name="Mesh",
        filter_scale_ratio=0.22,
        object_scale_mm=1.25,
        fourier_plot_half_range_mm=10.0,
    ),
    _preset(
        "Five-slit directional filtering",
        object_name="Five slits",
        filter_name="Vertical double slit",
        object_scale_mm=0.45,
        secondary_scale_mm=0.18,
        fourier_plot_half_range_mm=10.0,
    ),
    _preset(
        "Tilted lattice selection",
        object_name="Finite 2D grating",
        phase_name="Zernike tilt x",
        filter_name="Diagonal slit",
        zernike_coeff_waves=0.18,
        secondary_scale_mm=0.20,
        filter_scale_ratio=0.16,
        fourier_plot_half_range_mm=10.0,
    ),
    _preset(
        "Dual-circle astigmatic focus",
        object_name="Two circular apertures",
        phase_name="Zernike astigmatism 45 deg",
        filter_name="No filter",
        zernike_coeff_waves=0.28,
        object_scale_mm=0.28,
        secondary_scale_mm=0.38,
        phase_radius_mm=1.20,
        fourier_plot_half_range_mm=12.0,
    ),
)

FOURIER_PRESET_NAMES = tuple(item["name"] for item in _PRESETS)


def get_fourier_preset(name: str | None) -> dict | None:
    key = str(name or "").strip().casefold()
    if not key or key in {"custom", "custom / manual", "manual"}:
        return None
    for preset in _PRESETS:
        if preset["name"].casefold() == key:
            return deepcopy(preset)
    raise ValueError(f"Unknown Fourier preset: {name}")
