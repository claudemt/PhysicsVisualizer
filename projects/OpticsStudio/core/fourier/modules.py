from __future__ import annotations

import math
from dataclasses import dataclass

import numpy as np

from ..common import normalize_array


@dataclass(frozen=True)
class FourierModuleInfo:
    """Metadata for one selectable Fourier-plane module."""

    function_name: str
    display_name: str
    description: str


_MODULES = {
    "object": (
        FourierModuleInfo("object_circular_aperture", "Circular aperture", "Circular amplitude pupil useful for Airy-like patterns and thin-lens focusing."),
        FourierModuleInfo("object_cross_aperture", "Cross aperture", "Orthogonal cross aperture with strong horizontal and vertical spatial frequencies."),
        FourierModuleInfo("object_double_slit", "Double slit", "Classic two-slit amplitude transmission for interference and 4f filtering demos."),
        FourierModuleInfo("object_finite_2d_grating", "Finite 2D grating", "Finite orthogonal line grating for spatial-frequency lattice views."),
        FourierModuleInfo("object_five_slits", "Five slits", "Five equally spaced slits for richer diffraction orders and comb-like spectra."),
        FourierModuleInfo("object_hex_lattice_circles", "Hex lattice circles", "Finite hexagonal array of circular micro-apertures for rich lattice spectra."),
        FourierModuleInfo("object_rectangular_aperture", "Rectangular aperture", "Binary rectangular opening with rigorously defined Cartesian edges."),
        FourierModuleInfo("object_star_aperture", "Star aperture", "Five-point star polygon, useful for showing angular spectral content."),
        FourierModuleInfo("object_three_slits", "Three slits", "Three parallel amplitude slits with controllable pitch for Fourier-order demonstrations."),
        FourierModuleInfo("object_two_circular_apertures", "Two circular apertures", "Two equal circular holes for comparison with the double-slit case."),
    ),
    "phase": (
        FourierModuleInfo("phase_no_phase", "No phase", "Uniform zero phase across the active phase plane."),
        FourierModuleInfo("phase_thin_lens", "Thin lens", "Paraxial quadratic phase of a thin positive lens."),
        FourierModuleInfo("phase_vortex_charge_1", "Vortex charge 1", "Azimuthal phase ramp with unit topological charge."),
        FourierModuleInfo("phase_vortex_charge_2", "Vortex charge 2", "Azimuthal phase ramp with charge two."),
        FourierModuleInfo("phase_zernike_astigmatism_0_deg", "Zernike astigmatism 0 deg", "Zernike astigmatism aligned with Cartesian axes."),
        FourierModuleInfo("phase_zernike_astigmatism_45_deg", "Zernike astigmatism 45 deg", "Zernike astigmatism rotated by 45 degrees."),
        FourierModuleInfo("phase_zernike_coma_x", "Zernike coma x", "Zernike coma along the x axis."),
        FourierModuleInfo("phase_zernike_coma_y", "Zernike coma y", "Zernike coma along the y axis."),
        FourierModuleInfo("phase_zernike_defocus", "Zernike defocus", "Quadratic Zernike defocus phase."),
        FourierModuleInfo("phase_zernike_spherical", "Zernike spherical", "Fourth-order spherical Zernike phase."),
        FourierModuleInfo("phase_zernike_tilt_x", "Zernike tilt x", "Linear Zernike tilt along the x axis."),
    ),
    "filter": (
        FourierModuleInfo("filter_circular_high_pass", "Circular high-pass", "Blocks the Fourier-plane origin and transmits high spatial frequencies."),
        FourierModuleInfo("filter_circular_low_pass", "Circular low-pass", "Circular Fourier-plane low-pass aperture."),
        FourierModuleInfo("filter_diagonal_slit", "Diagonal slit", "Diagonal spatial-frequency slit."),
        FourierModuleInfo("filter_horizontal_double_slit", "Horizontal double slit", "Two horizontal Fourier-plane pass bands."),
        FourierModuleInfo("filter_horizontal_slit", "Horizontal slit", "Horizontal Fourier-plane pass band."),
        FourierModuleInfo("filter_mesh", "Mesh", "Orthogonal mesh of Fourier-plane pass bands."),
        FourierModuleInfo("filter_no_filter", "No filter", "Unity transmission across the Fourier plane."),
        FourierModuleInfo("filter_ring_band_pass", "Ring band-pass", "Annular spatial-frequency band-pass filter."),
        FourierModuleInfo("filter_vertical_double_slit", "Vertical double slit", "Two vertical Fourier-plane pass bands."),
        FourierModuleInfo("filter_vertical_slit", "Vertical slit", "Vertical Fourier-plane pass band."),
    ),
}


def discover_fourier_modules() -> dict[str, tuple[FourierModuleInfo, ...]]:
    """Return MATLAB-style object, phase, and filter module descriptors.

    MATLAB discovers plane files and asks each for metadata. The Python port
    keeps their dispatch in this module; this stable result offers equivalent
    runtime-independent discovery for callers and tests.
    """

    return {
        plane: tuple(sorted(entries, key=lambda item: item.display_name.casefold()))
        for plane, entries in _MODULES.items()
    }


def _module_key(name: str, prefix: str) -> str:
    key = str(name).strip().lower().replace("-", " ").replace("_", " ")
    return key[len(prefix):] if key.startswith(prefix) else key


def object_module(name: str, x: np.ndarray, y: np.ndarray, params: dict) -> np.ndarray:
    """Return a legacy-equivalent object-plane amplitude transmission."""

    key = _module_key(name, "object ")
    scale = max(float(params.get("object_scale_m", 0.55e-3)), np.finfo(float).eps)
    secondary = max(float(params.get("secondary_scale_m", 0.30e-3)), np.finfo(float).eps)
    if key in {"circular aperture", "circle", "disk"}:
        return (x**2 + y**2 <= (0.5 * scale) ** 2).astype(float)
    if key in {"cross aperture", "cross"}:
        width, length = max(0.12e-3, 0.22 * scale), max(0.50e-3, scale)
        return ((np.abs(x) <= width / 2) & (np.abs(y) <= length / 2) | (np.abs(y) <= width / 2) & (np.abs(x) <= length / 2)).astype(float)
    if key in {"double slit", "two slits"}:
        width, height = max(10e-6, 0.06 * scale), max(0.20e-3, scale)
        separation = max(2.5 * width, 0.45 * secondary)
        return ((np.abs(x - separation / 2) <= width / 2) & (np.abs(y) <= height / 2) | (np.abs(x + separation / 2) <= width / 2) & (np.abs(y) <= height / 2)).astype(float)
    if key in {"finite 2d grating", "grating"}:
        length, pitch = 3.2 * scale, max(40e-6, 0.55 * secondary)
        half, width = length / 2, 0.28 * pitch
        lines = (np.abs(np.mod(x + half, pitch) - pitch / 2) <= width / 2) | (np.abs(np.mod(y + half, pitch) - pitch / 2) <= width / 2)
        return (lines & (np.abs(x) <= half) & (np.abs(y) <= half)).astype(float)
    if key in {"five slits", "five slit"}:
        width, height = max(10e-6, 0.045 * scale), max(0.22e-3, 1.1 * scale)
        separation = max(2.8 * width, 0.42 * secondary)
        transmission = np.zeros_like(x, dtype=bool)
        for index in range(-2, 3):
            transmission |= (np.abs(x - index * separation) <= width / 2) & (np.abs(y) <= height / 2)
        return transmission.astype(float)
    if key in {"hex lattice circles", "hex lattice", "hexagonal lattice"}:
        radius, pitch = max(20e-6, 0.5 * scale), max(2.2 * max(20e-6, 0.5 * scale), secondary)
        transmission = np.zeros_like(x, dtype=bool)
        for row in range(-3, 4):
            for column in range(-3, 4):
                center_x, center_y = (column + 0.5 * (row % 2)) * pitch, row * np.sqrt(3.0) * pitch / 2
                transmission |= (x - center_x) ** 2 + (y - center_y) ** 2 <= radius**2
        return transmission.astype(float)
    if key in {"rectangular aperture", "rectangle"}:
        height = max(0.18e-3, 0.45 * secondary)
        return ((np.abs(x) <= scale / 2) & (np.abs(y) <= height / 2)).astype(float)
    if key in {"star aperture", "star"}:
        outer_radius = 0.55 * scale
        radii = np.where(np.arange(10) % 2 == 0, outer_radius, 0.42 * outer_radius)
        angles = np.pi / 2 + np.arange(10) * np.pi / 5
        return _inside_polygon(x, y, np.column_stack((radii * np.cos(angles), radii * np.sin(angles)))).astype(float)
    if key in {"three slits", "triple slit"}:
        width, height = max(10e-6, 0.05 * scale), max(0.20e-3, scale)
        separation = max(2.6 * width, 0.55 * secondary)
        return ((np.abs(x + separation) <= width / 2) & (np.abs(y) <= height / 2) | (np.abs(x) <= width / 2) & (np.abs(y) <= height / 2) | (np.abs(x - separation) <= width / 2) & (np.abs(y) <= height / 2)).astype(float)
    if key in {"two circular apertures", "double circular aperture", "two pinholes"}:
        radius = max(18e-6, 0.42 * scale)
        separation = max(2.4 * radius, 0.70 * secondary)
        return (((x - separation / 2) ** 2 + y**2 <= radius**2) | ((x + separation / 2) ** 2 + y**2 <= radius**2)).astype(float)
    raise ValueError(f"Unknown Fourier object module: {name}")


def _inside_polygon(x: np.ndarray, y: np.ndarray, vertices: np.ndarray) -> np.ndarray:
    inside = np.zeros_like(x, dtype=bool)
    previous_x, previous_y = vertices[-1]
    for current_x, current_y in vertices:
        crosses = (current_y > y) != (previous_y > y)
        x_intersection = (previous_x - current_x) * (y - current_y) / (previous_y - current_y) + current_x
        inside ^= crosses & (x < x_intersection)
        previous_x, previous_y = current_x, current_y
    return inside


def zernike_nm(n: int, m: int, rho: np.ndarray, theta: np.ndarray) -> np.ndarray:
    m_abs = abs(int(m))
    if (n - m_abs) % 2:
        return np.zeros_like(rho)
    radial = np.zeros_like(rho, dtype=float)
    for k in range((n - m_abs) // 2 + 1):
        coeff = (-1) ** k * math.factorial(n - k)
        coeff /= (
            math.factorial(k)
            * math.factorial((n + m_abs) // 2 - k)
            * math.factorial((n - m_abs) // 2 - k)
        )
        radial += coeff * rho ** (n - 2 * k)
    if m >= 0:
        return radial * np.cos(m_abs * theta)
    return radial * np.sin(m_abs * theta)


def phase_module(name: str, x: np.ndarray, y: np.ndarray, params: dict) -> np.ndarray:
    key = _module_key(name, "phase ")
    radius = max(float(params.get("phase_radius_m", 1.0e-3)), np.finfo(float).eps)
    rho = np.hypot(x, y) / radius
    theta = np.arctan2(y, x)
    support = rho <= 1.0
    phase = np.zeros_like(x, dtype=float)
    waves = float(params.get("zernike_coeff_waves", 0.30))
    if "thin lens" in key:
        wavelength = float(params.get("lambda_m", 632.8e-9))
        focal = float(params.get("f_m", 250e-3))
        phase = -np.pi * (x**2 + y**2) / max(wavelength * focal, np.finfo(float).eps)
    elif "vortex" in key:
        charge = int(params.get("topological_charge", 1))
        if "charge 2" in key:
            charge = max(2, abs(charge))
        phase = charge * theta
    elif "defocus" in key:
        phase = 2 * np.pi * waves * zernike_nm(2, 0, rho, theta)
    elif "astigmatism" in key:
        phase = 2 * np.pi * waves * zernike_nm(2, 2 if "45" not in key else -2, rho, theta)
    elif "coma" in key:
        phase = 2 * np.pi * waves * zernike_nm(3, 1 if "y" not in key else -1, rho, theta)
    elif "spherical" in key:
        phase = 2 * np.pi * waves * zernike_nm(4, 0, rho, theta)
    elif "tilt" in key:
        phase = 2 * np.pi * waves * zernike_nm(1, 1, rho, theta)
    phase = np.where(support | ("no phase" in key), phase, 0.0)
    return phase


def filter_module(name: str, xf: np.ndarray, yf: np.ndarray, params: dict) -> np.ndarray:
    key = _module_key(name, "filter ")
    radius = np.hypot(xf, yf)
    max_radius = max(float(np.max(radius)), np.finfo(float).eps)
    scale = float(params.get("filter_scale_ratio", params.get("filter_scale", 0.18)))
    cutoff = np.clip(scale, 0.02, 1.0) * max_radius
    if "no filter" in key or key == "none":
        filt = np.ones_like(radius)
    elif "high" in key:
        filt = radius >= cutoff
    elif "ring" in key or "band" in key:
        filt = (radius >= 0.65 * cutoff) & (radius <= 1.45 * cutoff)
    elif "horizontal double" in key:
        filt = (np.abs(yf - cutoff * 0.55) < 0.18 * cutoff) | (np.abs(yf + cutoff * 0.55) < 0.18 * cutoff)
    elif "vertical double" in key:
        filt = (np.abs(xf - cutoff * 0.55) < 0.18 * cutoff) | (np.abs(xf + cutoff * 0.55) < 0.18 * cutoff)
    elif "horizontal" in key or "slit" in key and "vertical" not in key:
        filt = np.abs(yf) < 0.25 * cutoff
    elif "vertical" in key:
        filt = np.abs(xf) < 0.25 * cutoff
    elif "mesh" in key:
        filt = ((np.abs(np.sin(np.pi * xf / cutoff)) < 0.22) |
                (np.abs(np.sin(np.pi * yf / cutoff)) < 0.22))
    elif "diagonal" in key:
        filt = np.abs(xf - yf) < 0.25 * cutoff
    else:
        filt = radius <= cutoff
    return normalize_array(np.asarray(filt, dtype=float), clip_negative=True)
