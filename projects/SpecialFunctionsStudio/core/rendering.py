from __future__ import annotations

import numpy as np

from utils import render_result as rr
from utils import style

from .catalog import Variant


def render_curves(title: str, curves: list[dict], x_label: str = "$x$", y_label: str = "$f(x)$",
                  *, y_range=None, legend_location: str = "northwest"):
    fig, axes = rr.new_figure("SpecialFunctionsStudio", 1, 1, (10, 6))
    ax = axes[0, 0]
    for curve in curves:
        y = np.asarray(curve["y"], dtype=float)
        y = np.where(np.isfinite(y), y, np.nan)
        rr.curve(ax, curve["x"], y, title, x_label, y_label, curve.get("label"))
    if y_range and len(y_range) == 2:
        ax.set_ylim(float(y_range[0]), float(y_range[1]))
    location = {"northwest": "upper left", "northeast": "upper right"}.get(str(legend_location).lower(), "best")
    if str(legend_location).lower() != "none":
        rr.apply_legend(ax.legend(loc=location))
    rr.finish_figure(fig)
    return rr.RenderBundle("SpecialFunctionsStudio", [fig], report=f"{title}: {len(curves)} curve(s)")


def render_surfaces(variant: Variant, items: list[dict]):
    figures = []
    for item in items:
        fig, axes = rr.new_figure(f"{variant.name} {item['title']}", 1, 1, (7.4, 6.4))
        fig.delaxes(axes[0, 0])
        rr.set_figure_title(fig, f"{variant.name} {item['title']}", visible=False)
        ax = fig.add_subplot(111, projection="3d")
        if item.get("kind") == "vectorfield":
            _draw_vectorfield(ax, item)
        else:
            _draw_surface(ax, item)
        rr.set_axis_text(ax, title=item["title"], xlabel="", ylabel="", zlabel="", grid=True, box=True)
        ax.view_init(elev=24, azim=-37.5)
        _style_3d_axes(ax)
        _set_equal_3d(ax, item["x"], item["y"], item["z"])
        fig._physics_filename = item.get("filename", "")  # type: ignore[attr-defined]
        fig.subplots_adjust(left=0.02, right=0.98, bottom=0.02, top=0.93)
        figures.append(fig)
    return rr.RenderBundle("SpecialFunctionsStudio", figures, report=f"{variant.name}: {len(items)} surface(s)")


def _draw_surface(ax, item: dict) -> None:
    cmap = rr.plt.get_cmap(style.matlab_parula_cmap_name())
    colors = _lit_facecolors(item["c"], item["z"], cmap)
    ax.plot_surface(
        item["x"],
        item["y"],
        item["z"],
        facecolors=colors,
        linewidth=0,
        antialiased=True,
        shade=False,
        rcount=120,
        ccount=120,
    )


def _draw_vectorfield(ax, item: dict) -> None:
    cmap = rr.plt.get_cmap("turbo")
    colors = _lit_facecolors(item["c"], item["sphere_z"], cmap, alpha=0.88)
    ax.plot_surface(
        item["sphere_x"],
        item["sphere_y"],
        item["sphere_z"],
        facecolors=colors,
        linewidth=0,
        antialiased=True,
        shade=False,
        rcount=80,
        ccount=80,
    )
    uq, vq, wq = _scaled_quiver(item["uq"], item["vq"], item["wq"])
    ax.quiver(
        item["xq"],
        item["yq"],
        item["zq"],
        uq,
        vq,
        wq,
        color=(0.10, 0.10, 0.10, 0.82),
        linewidth=0.8,
        arrow_length_ratio=0.28,
        normalize=False,
    )


def _normalize(values):
    arr = np.asarray(values, dtype=float)
    lo = float(np.nanmin(arr))
    hi = float(np.nanmax(arr))
    if hi <= lo:
        return np.zeros_like(arr)
    return (arr - lo) / (hi - lo)


def _lit_facecolors(values, elevation, cmap, alpha: float = 1.0):
    rgb = cmap(_normalize(values))
    shade = 0.78 + 0.22 * _normalize(elevation)
    shaded = np.clip(rgb[..., :3] * shade[..., None] + 0.06 * (1.0 - shade[..., None]), 0.0, 1.0)
    out = np.empty((*shaded.shape[:2], 4), dtype=float)
    out[..., :3] = shaded
    out[..., 3] = alpha
    return out


def _scaled_quiver(u, v, w):
    uu = np.asarray(u, dtype=float)
    vv = np.asarray(v, dtype=float)
    ww = np.asarray(w, dtype=float)
    mag = np.sqrt(uu ** 2 + vv ** 2 + ww ** 2)
    scale = 0.34 / max(float(np.nanmax(mag)), np.finfo(float).eps)
    return uu * scale, vv * scale, ww * scale


def _style_3d_axes(ax) -> None:
    ax.grid(True)
    for axis in (ax.xaxis, ax.yaxis, ax.zaxis):
        axis.pane.set_facecolor((1.0, 1.0, 1.0, 0.0))
        axis.pane.set_edgecolor("#cfd7e3")
        axis.line.set_color("#566275")
        axis.line.set_linewidth(0.8)
    ax.tick_params(colors=style.tokens().muted_text, labelsize=style.tokens().axes_font_size - 2, pad=0)


def _set_equal_3d(ax, x, y, z):
    mins = np.array([np.min(x), np.min(y), np.min(z)], dtype=float)
    maxs = np.array([np.max(x), np.max(y), np.max(z)], dtype=float)
    center = (mins + maxs) / 2
    radius = max(float(np.max(maxs - mins)) / 2, 1e-6)
    ax.set_xlim(center[0] - radius, center[0] + radius)
    ax.set_ylim(center[1] - radius, center[1] + radius)
    ax.set_zlim(center[2] - radius, center[2] + radius)
