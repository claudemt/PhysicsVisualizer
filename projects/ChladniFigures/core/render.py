from __future__ import annotations

import numpy as np

from utils.render_result import report
from utils import render_result as rr

from .modes_rect import RectMode, compute_rect_modes
from .modes_circular import CircularMode, compute_circular_mode
from .static_circular import StaticCircularResult, compute_static_circular_response
from .static_rect import StaticRectResult, compute_static_rect_modal


def _mode_figure(mode: RectMode | CircularMode, index: int):
    fig, axes = rr.new_figure(f"{index:02d} Chladni {mode.boundary} {mode.tag}", 1, 1, (6.8, 5.8))
    ax = axes[0, 0]
    rr.image(
        ax,
        mode.u,
        f"$\\mathrm{{{mode.boundary}}}\\ {mode.tag},\\ \\Lambda={mode.lam_disp:.4g}$",
        None,
        extent=[mode.x.min(), mode.x.max(), mode.y.min(), mode.y.max()],
        label="$w/w_{max}$",
        aspect="equal",
    )
    rr.set_axis_text(ax, xlabel="$x$", ylabel="$y$", aspect="equal")
    ax.contour(mode.x, mode.y, mode.u, levels=[0], colors="k", linewidths=0.7)
    rr.finish_figure(fig)
    return fig


def _static_figure(result: StaticRectResult | StaticCircularResult):
    fig, axes = rr.new_figure("Chladni static source response", 1, 1, (6.8, 5.8))
    load_label = result.load_label.replace(" ", r"\ ")
    title = (
        f"$\\mathrm{{{result.domain}}}\\quad\\mathrm{{{load_label}}}"
        f"\\quad\\nu={result.nu:.4g}\\quad\\xi_0={result.xi0:.4g}\\quad\\mathrm{{{result.boundary}}}$"
    )
    rr.image(
        axes[0, 0],
        result.u,
        title,
        None,
        extent=[result.x.min(), result.x.max(), result.y.min(), result.y.max()],
        label="$w/w_{max}$",
        aspect="equal",
    )
    rr.set_axis_text(axes[0, 0], xlabel="$x$", ylabel="$y$", aspect="equal")
    axes[0, 0].contour(result.x, result.y, result.u, levels=[0], colors="k", linewidths=0.7)
    rr.finish_figure(fig)
    return fig


def render(params: dict) -> rr.RenderBundle:
    study = str(params.get("study", "modes")).lower()
    domain = str(params.get("domain", params.get("type", "rect"))).lower()
    if domain == "disk":
        domain = "circ"
    grid_n = int(params.get("resolution", params.get("grid_size", 240)))
    xi0 = float(params.get("xi0", 0.45))
    a = 2.0
    b = max(0.15, 2.0 * xi0)
    if study == "static":
        if domain == "rect":
            result = compute_static_rect_modal(
                boundary=str(params.get("rect_boundary", "SSSS")),
                nu=float(params.get("nu", 0.30)),
                grid_n=grid_n,
                truncation=int(params.get("truncation", 60)),
                d_rigidity=float(params.get("D", params.get("d_rigidity", 1.0))),
                load_type=str(params.get("load_type", "points")),
                q0=float(params.get("q0", 1.0)),
                sources=params.get("sources"),
                custom_load=params.get("custom_load"),
                a=a,
                b=b,
                solver=str(params.get("rect_solver", "auto")),
            )
        else:
            boundary = str(params.get("circ_boundary", params.get("boundary", "C"))).upper()
            if domain == "annulus" and len(boundary) == 1:
                boundary += "C"
            result = compute_static_circular_response(
                domain="annulus" if domain == "annulus" else "disk",
                xi0=xi0 if domain == "annulus" else 0.0,
                nu=float(params.get("nu", 0.30)),
                boundary=boundary,
                grid_n=grid_n,
                sources=params.get("sources"),
                load_type=str(params.get("load_type", "points")),
                q0=float(params.get("q0", 1.0)),
                custom_load=params.get("custom_load"),
                mmax=int(params.get("truncation", 36)),
                d_rigidity=float(params.get("D", params.get("d_rigidity", 1.0))),
                distribution_samples=int(params.get("distribution_samples", max(10, min(30, round(np.sqrt(grid_n)))))),
            )
        bundle = rr.RenderBundle("Chladni static sources", [_static_figure(result)])
        modal_terms = getattr(result, "modal_weights", np.empty(0)).size
        bundle.report = report("ChladniFigures static sources", [
            result.method,
            f"Domain: {domain}; boundary: {getattr(result, 'boundary', str(params.get('circ_boundary', 'C')))}",
            f"Modal terms: {modal_terms if modal_terms else int(params.get('truncation', 36))}",
            getattr(result, "load_projection", "Point and distributed loads are projected on the same rectangular modal basis as the mode viewer."),
        ])
        return bundle

    count = int(params.get("mode_count", params.get("k", 10)))
    if domain == "rect":
        modes = compute_rect_modes(
            boundary=str(params.get("rect_boundary", params.get("boundary", "FFFF"))),
            nu=float(params.get("nu", 0.225)),
            count=count,
            grid_n=grid_n,
            a=a,
            b=b,
            solver=str(params.get("rect_solver", "auto")),
        )
    else:
        boundary = str(params.get("circ_boundary", params.get("boundary", "C"))).upper()
        if domain == "annulus" and len(boundary) == 1:
            boundary += "C"
        candidates = []
        radial_max = max(2, int(np.ceil(count / max(4, int(np.sqrt(count)) + 2))))
        for m in range(max(4, count // 2 + 1)):
            for s in range(1, radial_max + 1):
                candidates.append(compute_circular_mode(
                    m, s, boundary=boundary, nu=float(params.get("nu", 0.225)),
                    xi0=xi0 if domain == "annulus" else 0.0, grid_n=grid_n,
                ))
        modes = sorted(candidates, key=lambda mode: mode.lam_disp)[:count]
    figures = [_mode_figure(mode, idx) for idx, mode in enumerate(modes, start=1)]
    bundle = rr.RenderBundle("Chladni plate modes", figures)
    bundle.report = report("ChladniFigures modes", [
        f"Generated {len(modes)} rectangular mode previews.",
        "Auto routing uses Navier (SSSS), clamped FD (CCCC), Levy (?S?S), free Ritz (FFFF), or general Ritz.",
        "Each preview includes the zero nodal contour used by the MATLAB Chladni renderer.",
    ])
    return bundle


