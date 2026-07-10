from utils import render_result as rr
from utils import style

import numpy as np

from .fourier import fourier_4f_model, fourier_params_from_gui
from .imaging import run_imaging
from .interference import run_interference
from .ray import fresnel_coefficients, trace_spherical_interface_bundle, trace_thin_lens_bundle
from .tomography import run_tomography
from .wave import run_wave_optics

TITLE = "Optics Studio"
DESCRIPTION = "Fourier optics, imaging, wave, ray, interference, and tomography modules."
DEFAULTS = {}
FORMULAS = "Fourier propagation, PSF/OTF, ray transfer, and interferometry."


def render(params):
    module = str(params.get("module", "fourier")).lower()
    if "wave" in module:
        return _render_wave(params)
    if "imag" in module:
        return _render_imaging(params)
    if "inter" in module:
        return _render_interference(params)
    if "ray" in module or "geometric" in module:
        return _render_ray(params)
    if "tomo" in module:
        return _render_tomography(params)
    return _render_fourier(params)


def _render_fourier(params):
    result = fourier_4f_model(params)
    display = fourier_params_from_gui(params)
    fig, axes = rr.new_figure("OpticsStudio - Fourier Studio", 2, 3, (13, 8))
    panels = [
        (result.object_amp, result.x_mm, result.y_mm, result.object_amp > 0.05, "object", "$\\mathrm{object\\ plane}$", "gray", False, "$x\\,(\\mathrm{mm})$", "$y\\,(\\mathrm{mm})$"),
        (result.phase_wrapped, result.x_mm, result.y_mm, result.phase_support > 0.5, "phase", "$\\mathrm{phase\\ plane}$", None, True, "$x\\,(\\mathrm{mm})$", "$y\\,(\\mathrm{mm})$"),
        (result.after_phase_amp, result.x_mm, result.y_mm, result.after_phase_amp > 0.02, "amplitude", "$\\mathrm{after\\ phase}$", "gray", False, "$x\\,(\\mathrm{mm})$", "$y\\,(\\mathrm{mm})$"),
        (result.spectrum_intensity, result.xf_mm, result.yf_mm, result.spectrum_intensity > 0.02, "spectrum", "$\\mathrm{fourier\\ intensity}$", None, True, "$x_f\\,(\\mathrm{mm})$", "$y_f\\,(\\mathrm{mm})$"),
        (result.filter_amp, result.xf_mm, result.yf_mm, result.filter_amp > 0.02, "filter", "$\\mathrm{filter\\ plane}$", "gray", False, "$x_f\\,(\\mathrm{mm})$", "$y_f\\,(\\mathrm{mm})$"),
        (result.output_intensity, result.x_mm, result.y_mm, result.output_intensity > 0.02, "intensity", "$\\mathrm{image\\ plane}$", None, True, "$x\\,(\\mathrm{mm})$", "$y\\,(\\mathrm{mm})$"),
    ]
    for ax, panel in zip(axes.ravel(), panels):
        _render_fourier_map(ax, panel, display)
    rr.finish_figure(fig)
    return rr.RenderBundle("OpticsStudio", [fig], report=result.summary)


def _render_fourier_map(ax, panel, display):
    data, x_grid, y_grid, support, role, title, cmap, colorbar, xlabel, ylabel = panel
    shown, expanded_support = _prepare_display_map(data, role, support)
    x_vec = np.asarray(x_grid)[0, :]
    y_vec = np.asarray(y_grid)[:, 0]
    image = rr.image(
        ax,
        shown,
        title,
        cmap,
        extent=(x_vec[0], x_vec[-1], y_vec[0], y_vec[-1]),
        colorbar=colorbar,
        aspect="equal",
    )
    if display["display_scaling"] == "fixed":
        image.set_clim((-np.pi, np.pi) if role == "phase" else (0.0, 1.0))
    if display["auto_adjust_plot_range"]:
        x_limits, y_limits = _auto_plot_limits(x_vec, y_vec, expanded_support)
    else:
        half_range = display[
            "fourier_plot_half_range_mm" if role in {"spectrum", "filter"} else "object_plot_half_range_mm"
        ]
        x_limits = y_limits = (-half_range, half_range)
    ax.set_xlim(*x_limits)
    ax.set_ylim(*y_limits)
    rr.set_axis_text(ax, title=title, xlabel=xlabel, ylabel=ylabel, aspect="equal")


def _prepare_display_map(data, role, support):
    shown = np.asarray(data, dtype=float).copy()
    mask = np.asarray(support, dtype=bool).copy()
    eps = np.finfo(float).eps
    if role in {"spectrum", "intensity"}:
        shown = np.maximum(shown, 0.0)
        shown /= max(float(np.max(shown)), eps)
        shown = np.log1p(72.0 * shown) / np.log(73.0)
        raw = np.abs(np.asarray(data, dtype=float))
        raw /= max(float(np.max(raw)), eps)
        mask |= raw > 0.012
    elif role in {"object", "filter", "amplitude"}:
        shown = np.maximum(shown, 0.0)
        shown /= max(float(np.max(shown)), eps)
        mask |= shown > 0.01
    for _ in range(2):
        mask |= np.roll(mask, 1, axis=0) | np.roll(mask, -1, axis=0)
        mask |= np.roll(mask, 1, axis=1) | np.roll(mask, -1, axis=1)
    return shown, mask


def _auto_plot_limits(x_vec, y_vec, support):
    rows = np.flatnonzero(np.any(support, axis=1))
    cols = np.flatnonzero(np.any(support, axis=0))
    if not rows.size or not cols.size:
        return (float(np.min(x_vec)), float(np.max(x_vec))), (float(np.min(y_vec)), float(np.max(y_vec)))
    radius = max(
        abs(float(x_vec[cols[0]])), abs(float(x_vec[cols[-1]])),
        abs(float(y_vec[rows[0]])), abs(float(y_vec[rows[-1]])),
    )
    radius = max(1.18 * radius, np.finfo(float).eps)
    return (-radius, radius), (-radius, radius)


def _render_wave(params):
    data = run_wave_optics(params)
    if data["mode"] == "free_space":
        panels = (
            (data["object"], "$\\mathrm{input\\ amplitude}$", "gray", False),
            (data["input_spectrum"], "$\\mathrm{input\\ spectrum}$", "gray", False),
            (data["transfer_real"], "$\\Re\\{H(f_x,f_y)\\}$", None, True),
            (data["propagated"], "$\\mathrm{output\\ intensity}$", None, True),
        )
    else:
        panels = (
            (data["object"], "$\\mathrm{input\\ object}$", "gray", False),
            (data["input_spectrum"], "$|\\mathcal{F}\\{U_0\\}|$", "gray", False),
            (data["filter"], "$\\mathrm{filter\\ mask}$", "gray", False),
            (data["filtered"], "$\\mathrm{filtered\\ image}$", None, True),
        )
    bundle = rr.render_many(
        "OpticsStudio - Wave Optics",
        [
            lambda ax, panel=panel: rr.image(
                ax, panel[0], panel[1], panel[2], colorbar=panel[3]
            )
            for panel in panels
        ],
        cols=2,
        size=(11, 8),
    )
    if str(params.get("image_scaling", "fixed")).strip().lower() == "fixed":
        plot_axes = [ax for ax in bundle.figures[0].axes if ax.get_label() != "<colorbar>"]
        for ax, panel in zip(plot_axes, panels):
            if ax.images:
                ax.images[0].set_clim((-1.0, 1.0) if "Re\\{" in panel[1] else (0.0, 1.0))
    return bundle


def _render_imaging(params):
    data = run_imaging(params)
    fig, axes = rr.new_figure("OpticsStudio - Imaging", 2, 2, (11, 8))
    rr.image(axes[0, 0], data["pupil_phase"], "$\\mathrm{pupil\\ phase}$", None, colorbar=True)
    mode = str(params.get("mode", "widefield")).strip().lower().replace("_", "\\_")
    rr.image(axes[0, 1], data["effective"], f"$\\mathrm{{{mode}\\ PSF}}$", None, colorbar=True)
    rr.image(axes[1, 0], data["otf"], "$|\\mathrm{OTF}|$", None, colorbar=True)
    profile_ax = axes[1, 1]
    rr.curve(
        profile_ax, data["profile_x"], data["widefield_profile"],
        "$\\mathrm{central\\ profile}$", "$x\\ \\mathrm{(pixel)}$", "$I/I_{\\max}$",
        label="$\\mathrm{widefield}$", color=style.tokens().primary,
    )
    rr.curve(
        profile_ax, data["profile_x"], data["effective_profile"],
        "$\\mathrm{central\\ profile}$", "$x\\ \\mathrm{(pixel)}$", "$I/I_{\\max}$",
        label="$\\mathrm{effective}$", color=style.tokens().accent,
    )
    rr.finish_figure(fig)
    return rr.RenderBundle("OpticsStudio", [fig])


def _render_interference(params):
    data = run_interference(params)
    fig, axes = rr.new_figure("OpticsStudio - Interference", 2, 2, (11, 8))
    flat = axes.ravel()
    if data["mode"] == "gs_phase":
        rr.image(flat[0], data["target_amplitude"], "$\\mathrm{target\\ amplitude}$", "gray", colorbar=False)
        rr.image(flat[1], data["final_phase"], "$\\mathrm{recovered\\ phase}$", None, colorbar=True)
        rr.image(flat[2], data["final_intensity"], "$\\mathrm{focal\\ intensity}$", None, colorbar=True)
        k = np.arange(1, len(data["efficiency"]) + 1)
        rr.curve(flat[3], k, data["efficiency"], "$\\mathrm{GS\\ convergence}$", "$k$", "$\\mathrm{metric}$", label="$\\eta$", color=style.tokens().primary)
        rr.curve(flat[3], k, data["uniformity"], "$\\mathrm{GS\\ convergence}$", "$k$", "$\\mathrm{metric}$", label="$u$", color=style.tokens().accent)
    elif data["mode"] == "shearing":
        rr.image(flat[0], data["wavefront"], "$\\mathrm{wavefront}$", None, colorbar=True)
        rr.image(flat[1], data["delta_phase"], "$\\Delta\\phi$", None, colorbar=True)
        rr.image(flat[2], data["interferogram"], "$\\mathrm{interferogram}$", "gray", colorbar=False)
        spectrum = np.log1p(np.abs(np.fft.fftshift(np.fft.fft2(np.fft.ifftshift(data["interferogram"])))))
        rr.image(flat[3], _normalize(spectrum), "$\\mathrm{interferogram\\ spectrum}$", None, colorbar=True)
    else:
        rr.image(flat[0], data["grating_a"], "$\\mathrm{grating\\ 1}$", "gray", colorbar=False)
        rr.image(flat[1], data["grating_b"], "$\\mathrm{grating\\ 2}$", "gray", colorbar=False)
        rr.image(flat[2], data["moire"], "$\\mathrm{moire\\ product}$", "gray", colorbar=False)
        rr.image(flat[3], data["spectrum"], "$\\mathrm{moire\\ spectrum}$", None, colorbar=True)
    rr.finish_figure(fig)
    return rr.RenderBundle("OpticsStudio", [fig])


def _normalize(data):
    data = np.asarray(data, dtype=float)
    lo = float(np.min(data))
    span = float(np.max(data)) - lo
    return np.zeros_like(data) if span <= 0 else (data - lo) / span


def _render_ray(params):
    mode = str(params.get("mode", "thin_lens")).lower()
    fig, axes = rr.new_figure("OpticsStudio - Geometric Optics", 1, 2, (12, 4.8))
    if "spher" in mode:
        bundle = trace_spherical_interface_bundle(
            float(params.get("n1", 1.0)),
            float(params.get("n2", 1.5)),
            float(params.get("radius_mm", 40.0)),
            float(params.get("aperture_mm", 12.0)),
            float(params.get("screen_z_mm", 100.0)),
            int(float(params.get("ray_count", 13))),
        )
        title = "$\\mathrm{single\\ spherical\\ interface}$"
    else:
        bundle = trace_thin_lens_bundle(
            float(params.get("object_distance_mm", 120.0)),
            float(params.get("focal_length_mm", 60.0)),
            float(params.get("height_mm", 10.0)),
            float(params.get("aperture_mm", 12.0)),
            int(float(params.get("ray_count", 13))),
        )
        title = "$\\mathrm{thin\\ lens\\ ray\\ diagram}$"
    ax = axes[0, 0]
    for ray in bundle["rays"]:
        rr.curve(ax, ray[:, 0], ray[:, 1], color=style.tokens().primary)
    rr.set_axis_text(ax, title=title, xlabel="$z\\ \\mathrm{(mm)}$", ylabel="$y\\ \\mathrm{(mm)}$", grid=True)
    ax2 = axes[0, 1]
    if "image_distance" in bundle:
        focal_length = float(params.get("focal_length_mm", 60.0))
        distance = float(params.get("object_distance_mm", 120.0))
        curve_x = np.linspace(1.1 * focal_length, 4.0 * focal_length, 200)
        curve_y = -focal_length / np.maximum(curve_x - focal_length, np.finfo(float).eps)
        rr.curve(ax2, curve_x, curve_y, "$\\mathrm{magnification\\ vs.\\ object\\ distance}$", "$s\\ \\mathrm{(mm)}$", "$m$", label="$m(s)$", color=style.tokens().primary)
        rr.curve(ax2, [distance], [bundle["magnification"]], "$\\mathrm{magnification\\ vs.\\ object\\ distance}$", "$s\\ \\mathrm{(mm)}$", "$m$", label="$m_{\\mathrm{current}}$", color=style.tokens().error, marker="o", linestyle="none")
    else:
        radius = float(params.get("radius_mm", 40.0))
        aperture = min(abs(radius), abs(float(params.get("aperture_mm", 12.0))))
        surface_y = np.linspace(-aperture, aperture, 400)
        surface_z = radius - np.sign(radius) * np.sqrt(np.maximum(radius**2 - surface_y**2, 0.0))
        rr.curve(ax, surface_z, surface_y, color=style.tokens().text)
        ax.axvline(float(params.get("screen_z_mm", 100.0)), color=style.tokens().muted_text, linestyle="--", linewidth=style.tokens().line_width)
        theta = np.linspace(0.0, np.pi / 2 - 1e-3, 300)
        coeff = fresnel_coefficients(theta, float(params.get("n1", 1.0)), float(params.get("n2", 1.5)))
        theta_deg = np.rad2deg(theta)
        rr.curve(ax2, theta_deg, coeff["Rs"], "$\\mathrm{Fresnel\\ reflectance}$", "$\\theta_i\\ \\mathrm{(deg)}$", "$R$", label="$R_s$", color=style.tokens().primary)
        rr.curve(ax2, theta_deg, coeff["Rp"], "$\\mathrm{Fresnel\\ reflectance}$", "$\\theta_i\\ \\mathrm{(deg)}$", "$R$", label="$R_p$", color=style.tokens().accent)
    rr.set_axis_text(ax, title=title, xlabel="$z\\ \\mathrm{(mm)}$", ylabel="$y\\ \\mathrm{(mm)}$", grid=True)
    rr.finish_figure(fig)
    return rr.RenderBundle("OpticsStudio", [fig])


def _render_tomography(params):
    data = run_tomography(params)
    filter_name = str(params.get("filter", "ram_lak")).strip().replace("_", r"\_")
    return rr.render_many("OpticsStudio - Tomography", [
        lambda ax: rr.image(ax, data["phantom"], "$\\mathrm{phantom}$", "gray", colorbar=True),
        lambda ax: (rr.image(ax, data["sinogram"], "$\\mathrm{sinogram}$", None, colorbar=True, aspect="auto"), rr.set_axis_text(ax, xlabel="$\\theta\\ \\mathrm{(deg)}$", ylabel="$s$")),
        lambda ax: rr.image(ax, data["reconstruction"], f"$\\mathrm{{reconstruction}}\\;(\\mathrm{{{filter_name}}})$", "gray", colorbar=True),
        lambda ax: rr.image(ax, abs(data["phantom"] - data["reconstruction"]), "$\\mathrm{error\\ map}$", None, colorbar=True),
    ], cols=2, size=(11, 8))
