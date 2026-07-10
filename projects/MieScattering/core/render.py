from __future__ import annotations

import numpy as np

from utils.render_result import report
from utils import render_result as rr

from .fields import compute_fields, evaluate_field
from .params import normalize_params


def _slice_axis_labels(slice_type: str) -> tuple[str, str]:
    if slice_type == "yz":
        return "$y/\\lambda$", "$z/\\lambda$"
    if slice_type == "xz":
        return "$x/\\lambda$", "$z/\\lambda$"
    return "$x/\\lambda$", "$y/\\lambda$"


def _draw_boundary(ax, cfg: dict):
    radius = cfg["radius"]
    pos = abs(cfg["slice_position"])
    if cfg["geometry"] == "sphere":
        effective = np.sqrt(max(radius * radius - pos * pos, 0.0))
        if effective <= 1e-12:
            return
        circle = __import__("matplotlib.patches").patches.Circle((0, 0), effective, fill=False, color="black", linewidth=1.0)
        ax.add_patch(circle)
    elif cfg["slice"] == "xy":
        circle = __import__("matplotlib.patches").patches.Circle((0, 0), radius, fill=False, color="black", linewidth=1.0)
        ax.add_patch(circle)
    elif cfg["slice"] in {"xz", "yz"}:
        half_width = np.sqrt(max(radius * radius - pos * pos, 0.0))
        if half_width > 1e-12:
            ax.axvline(half_width, color="black", linewidth=0.8)
            ax.axvline(-half_width, color="black", linewidth=0.8)


def render(params: dict) -> rr.RenderBundle:
    cfg = normalize_params(params)
    fields = compute_fields(cfg)
    extent = [fields["U"].min(), fields["U"].max(), fields["V"].min(), fields["V"].max()]
    xlabel, ylabel = _slice_axis_labels(cfg["slice"])
    figures = []
    for idx, code in enumerate(cfg["fields"], start=1):
        data, label, symmetric = evaluate_field(code, fields)
        fig, axes = rr.new_figure(f"{idx:02d} Mie {code}", 1, 1, (6.6, 5.6))
        ax = axes[0, 0]
        im = rr.image(
            ax,
            data,
            f"{cfg['geometry']} {label}",
            None,
            extent=extent,
            label=label,
            aspect="equal",
        )
        rr.set_axis_text(ax, xlabel=xlabel, ylabel=ylabel, aspect="equal")
        if symmetric:
            vmax = np.nanpercentile(np.abs(data), 99)
            if np.isfinite(vmax) and vmax > 0:
                im.set_clim(-vmax, vmax)
        _draw_boundary(ax, cfg)
        rr.finish_figure(fig)
        figures.append(fig)
    bundle = rr.RenderBundle("Mie scattering field bundle", figures)
    bundle.report = report("MieScattering", [
        f"Geometry: {cfg['geometry']}, slice: {cfg['slice']}, radius/lambda: {cfg['radius']:.4g}",
        f"Rendered fields: {', '.join(cfg['fields'])}",
        "Sphere and cylinder baselines use Mie coefficient series and preserve scattered/total field selections.",
    ])
    return bundle


