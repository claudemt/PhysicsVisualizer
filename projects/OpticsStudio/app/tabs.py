from __future__ import annotations

from utils.control_schema import c, section, tab
from ..core.fourier.presets import FOURIER_PRESET_NAMES, get_fourier_preset


_PRESET_KEY_MAP = {
    "n_samples": "resolution",
    "zernike_coeff_waves": "zernike_waves",
    "filter_scale_ratio": "filter_scale",
    "object_plot_half_range_mm": "object_half_range_mm",
    "fourier_plot_half_range_mm": "fourier_half_range_mm",
    "object_name": "object",
    "phase_name": "phase",
    "filter_name": "filter",
    "display_scaling": "image_scaling",
}


def _fourier_preset_values() -> dict[str, dict[str, object]]:
    result = {}
    for name in FOURIER_PRESET_NAMES:
        preset = get_fourier_preset(name) or {}
        values = {
            _PRESET_KEY_MAP.get(key, key): value
            for key, value in preset.items()
            if key not in {"name", "auto_adjust_plot_range"}
        }
        values["plot_range"] = "auto" if preset.get("auto_adjust_plot_range", True) else "fixed"
        for selector in ("object", "phase", "filter"):
            values[selector] = str(values[selector]).lower().replace("-", " ")
        result[name] = values
    return result


FOURIER_PRESET_VALUES = _fourier_preset_values()


def get_tabs():
    fourier_objects = (
        "circular aperture",
        "cross aperture",
        "double slit",
        "finite 2d grating",
        "five slits",
        "hex lattice circles",
        "rectangular aperture",
        "star aperture",
        "three slits",
        "two circular apertures",
    )
    fourier_phases = (
        "no phase",
        "thin lens",
        "vortex charge 1",
        "vortex charge 2",
        "zernike astigmatism 0 deg",
        "zernike astigmatism 45 deg",
        "zernike coma x",
        "zernike coma y",
        "zernike defocus",
        "zernike spherical",
        "zernike tilt x",
    )
    fourier_filters = (
        "no filter",
        "circular low pass",
        "circular high pass",
        "diagonal slit",
        "horizontal double slit",
        "horizontal slit",
        "mesh",
        "ring band pass",
        "vertical double slit",
        "vertical slit",
    )
    return [
        tab(
            "fourier_studio",
            "fourier studio",
            section(
                "setup",
                c(
                    "preset", "preset", "combo", "HeNe classroom preview",
                    (*FOURIER_PRESET_NAMES, "custom / manual"),
                    preset_values=FOURIER_PRESET_VALUES,
                ),
                c("object", "object", "combo", "double slit", fourier_objects),
                c("phase", "phase plane", "combo", "no phase", fourier_phases),
                c("filter", "filter plane", "combo", "circular low pass", fourier_filters),
            ),
            section(
                "basic",
                c("wavelength_nm", "wavelength (nm)", default=632.8),
                c("focal_length_mm", "focal length (mm)", default=250),
                c("window_mm", "window (mm)", default=4.0),
                c("resolution", "samples", default=1536),
            ),
            section(
                "advanced",
                c("object_scale_mm", "object scale (mm)", default=0.55),
                c("secondary_scale_mm", "secondary scale (mm)", default=0.30),
                c(
                    "phase_radius_mm", "phase radius (mm)", default=1.0,
                    visible_when={"phase": tuple(item for item in fourier_phases if item != "no phase")},
                ),
                c(
                    "zernike_waves", "zernike waves", default=0.30,
                    visible_when={"phase": tuple(item for item in fourier_phases if item.startswith("zernike"))},
                ),
                c(
                    "filter_scale", "filter scale", default=0.18,
                    visible_when={"filter": tuple(item for item in fourier_filters if item != "no filter")},
                ),
                c(
                    "topological_charge", "topological charge", default=1,
                    visible_when={"phase": ("vortex charge 1", "vortex charge 2")},
                ),
                c("plot_range", "plot range", "combo", "auto", ("auto", "fixed")),
                c(
                    "object_half_range_mm", "object half range (mm)", default=1.2,
                    enabled_when={"plot_range": ("fixed",)},
                ),
                c(
                    "fourier_half_range_mm", "Fourier half range (mm)", default=8.0,
                    enabled_when={"plot_range": ("fixed",)},
                ),
                c("image_scaling", "image scaling", "combo", "fixed", ("fixed", "auto")),
            ),
            section("actions"),
            preview="axesgrid",
            initial_message="run to fill the six-panel Fourier preview",
            module="fourier",
        ),
        tab(
            "wave_optics",
            "wave optics",
            section(
                "physical parameters",
                c("mode", "mode", "combo", "free_space", ("free_space", "4f_filtering")),
                c("object", "object", "combo", "bars", ("bars", "mesh", "double_slit", "aperture", "gaussian_lattice")),
                c(
                    "filter", "filter", "combo", "pinhole",
                    ("none", "pinhole", "ring", "horizontal_single", "horizontal_double", "vertical_single", "vertical_double"),
                    depends_on="mode",
                    options_by={
                        "free_space": ("none",),
                        "4f_filtering": ("none", "pinhole", "ring", "horizontal_single", "horizontal_double", "vertical_single", "vertical_double"),
                    },
                    visible_when={"mode": ("4f_filtering",)},
                ),
                c("filter_scale", "filter scale", default=0.16, visible_when={"mode": ("4f_filtering",)}),
                c("pixel_size_um", "pixel size (um)", default=6.5, visible_when={"mode": ("free_space",)}),
                c("wavelength_nm", "wavelength (nm)", default=532, visible_when={"mode": ("free_space",)}),
                c("distance_mm", "distance (mm)", default=20, visible_when={"mode": ("free_space",)}),
                c("resolution", "grid", default=256),
                c("band_limit", "band-limit", "bool", True, visible_when={"mode": ("free_space",)}),
                c("image_scaling", "image scaling", "combo", "fixed", ("fixed", "auto")),
            ),
            section("actions"),
            preview="axesgrid",
            initial_message="run to generate wave optics panels",
            module="wave",
        ),
        tab(
            "imaging",
            "imaging and aberrations",
            section(
                "physical parameters",
                c("mode", "mode", "combo", "widefield", ("widefield", "confocal", "sted")),
                c("aberration", "aberration", "combo", "defocus", ("none", "tilt_x", "defocus", "astigmatism", "coma", "spherical")),
                c("coefficient_waves", "coefficient (waves)", default=0.35),
                c("pinhole", "pinhole", default=0.60, visible_when={"mode": ("confocal",)}),
                c("sted", "STED", default=4.0, visible_when={"mode": ("sted",)}),
                c("resolution", "grid", default=256),
            ),
            section("actions"),
            preview="axesgrid",
            initial_message="run to generate imaging panels",
            module="imaging",
        ),
        tab(
            "interference",
            "interference and phase",
            section(
                "physical parameters",
                c("mode", "mode", "combo", "moire", ("moire", "shearing", "gs_phase")),
                c("freq1", "freq1", default=18, visible_when={"mode": ("moire",)}),
                c("freq2", "freq2", default=19.2, visible_when={"mode": ("moire",)}),
                c("angle_deg", "angle deg", default=2.5, visible_when={"mode": ("moire",)}),
                c("aberration", "aberration", "combo", "coma", ("none", "coma", "defocus", "astigmatism", "spherical"), visible_when={"mode": ("shearing",)}),
                c("coefficient", "coefficient", default=0.45, visible_when={"mode": ("shearing",)}),
                c("shear_px", "shear px", default=10, visible_when={"mode": ("shearing",)}),
                c("carrier", "carrier", default=8, visible_when={"mode": ("shearing",)}),
                c("iterations", "GS iterations", default=80, visible_when={"mode": ("gs_phase",)}),
                c("alpha", "alpha", default=0.85, visible_when={"mode": ("gs_phase",)}),
                c("spot_count", "GS spot count", default=3, visible_when={"mode": ("gs_phase",)}),
                c("separation_px", "GS separation (px)", default=46.08, visible_when={"mode": ("gs_phase",)}),
                c("resolution", "grid", default=256),
            ),
            section("actions"),
            preview="axesgrid",
            initial_message="run to generate interference panels",
            module="interference",
        ),
        tab(
            "geometric_optics",
            "geometric optics",
            section(
                "physical parameters",
                c("mode", "mode", "combo", "thin_lens", ("thin_lens", "spherical_interface")),
                c("object_distance_mm", "object distance (mm)", default=120, visible_when={"mode": ("thin_lens",)}),
                c("focal_length_mm", "focal length (mm)", default=60, visible_when={"mode": ("thin_lens",)}),
                c("height_mm", "height (mm)", default=10, visible_when={"mode": ("thin_lens",)}),
                c("n1", "n1", default=1.0, visible_when={"mode": ("spherical_interface",)}),
                c("n2", "n2", default=1.5, visible_when={"mode": ("spherical_interface",)}),
                c("radius_mm", "radius (mm)", default=40, visible_when={"mode": ("spherical_interface",)}),
                c("screen_z_mm", "screen z (mm)", default=100, visible_when={"mode": ("spherical_interface",)}),
                c("aperture_mm", "aperture (mm)", default=12),
                c("ray_count", "ray count", default=13),
            ),
            section("actions"),
            preview="axesgrid",
            initial_message="run to generate ray-tracing panels",
            module="ray",
        ),
        tab(
            "tomography",
            "tomography",
            section(
                "physical parameters",
                c("phantom", "phantom", "combo", "shepp_logan", ("shepp_logan", "disk", "bars")),
                c("filter", "filter", "combo", "ram_lak", ("ram_lak", "hann", "none")),
                c("resolution", "image size", default=128),
                c("angles", "angles", default=90),
                c("detector_bins", "detector bins", default=128),
            ),
            section("actions"),
            preview="axesgrid",
            initial_message="run to generate tomography panels",
            module="tomography",
        ),
    ]


def build_tab():
    return get_tabs()[0]


