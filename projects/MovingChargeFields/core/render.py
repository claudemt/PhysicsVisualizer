from __future__ import annotations

import numpy as np
from matplotlib.collections import LineCollection
from matplotlib.colors import Normalize

from utils.render_result import report
from utils import render_result as rr
from utils import style

from .fields import compute_payload, field_payload, field_text, process_display_field, selected_fields, slice_metadata


def _compose_title(title_core: str, motion: str, part: str) -> str:
    motion_token = "circ" if motion.lower().startswith("circ") else "harm"
    return f"$\\mathrm{{{motion_token}}} - \\mathrm{{{part}}} \\; {title_core.strip('$')}$"


def _project_to_slice(point, slice_type: str) -> tuple[float, float]:
    if slice_type == "xz":
        return float(point[0]), float(point[2])
    if slice_type == "yz":
        return float(point[1]), float(point[2])
    return float(point[0]), float(point[1])


def _draw_trajectory(ax, motion: str, slice_type: str, a_over_lambda: float) -> None:
    phase = np.linspace(0.0, 2.0 * np.pi, 800)
    if motion.lower().startswith("circ"):
        x = a_over_lambda * np.cos(phase)
        y = a_over_lambda * np.sin(phase)
        z = np.zeros_like(phase)
    else:
        x = np.zeros_like(phase)
        y = np.zeros_like(phase)
        z = a_over_lambda * np.cos(phase)
    if slice_type == "xz":
        u, v = x, z
    elif slice_type == "yz":
        u, v = y, z
    else:
        u, v = x, y
    ax.plot(u, v, color="black", linewidth=1.5)


def _draw_charge_marker(ax, payload: dict) -> None:
    u0, v0 = _project_to_slice(payload["rq_now"], payload["slice"])
    ax.plot(u0, v0, "ko", markerfacecolor="black", markersize=6)


def _draw_colored_streamlines(ax, payload: dict, uu, vv, color_values,
                              colorbar_label: str, motion: str, field: str,
                              stream_density: float) -> None:
    u0 = np.nan_to_num(np.real(uu), nan=0.0, posinf=0.0, neginf=0.0)
    v0 = np.nan_to_num(np.real(vv), nan=0.0, posinf=0.0, neginf=0.0)
    magnitude = np.hypot(u0, v0)
    finite_mag = magnitude[np.isfinite(magnitude)]
    mag_ref = np.nan
    if finite_mag.size:
        mag_ref = float(np.nanpercentile(finite_mag, 98.0))
        if not np.isfinite(mag_ref) or mag_ref <= 0:
            mag_ref = float(np.nanmax(finite_mag))
    if np.isfinite(mag_ref) and mag_ref > 0:
        denominator = np.maximum(magnitude, mag_ref * 0.02)
        u_plot = u0 / denominator
        v_plot = v0 / denominator
    else:
        u_plot, v_plot = u0, v0

    charge_u, charge_v = _project_to_slice(payload["rq_now"], payload["slice"])
    a_over_lambda = max(0.0, float(payload.get("a_over_lambda", 1.2)))
    base_seed_count = 72 if field == "S_stream" else 60
    seed_count = max(16, int(round(base_seed_count * max(0.25, stream_density))))
    seed_radius = (0.30 if field == "S_stream" else 0.18) * a_over_lambda + (0.08 if field == "S_stream" else 0.04)
    theta = np.linspace(0.0, 2.0 * np.pi, seed_count, endpoint=False)
    seeds = np.column_stack((charge_u + seed_radius * np.cos(theta), charge_v + seed_radius * np.sin(theta)))

    colors = np.real(np.asarray(color_values, dtype=float)).copy()
    colors[~np.isfinite(colors)] = np.nan
    finite = colors[np.isfinite(colors)]
    vmin, vmax = 0.0, 1.0
    if finite.size:
        vmin = float(np.nanmin(finite))
        vmax = float(np.nanmax(finite))
        if not np.isfinite(vmin) or not np.isfinite(vmax) or vmin == vmax:
            vmin, vmax = 0.0, 1.0

    collection = _seeded_streamline_collection(
        payload["u"], payload["v"], u_plot, v_plot, colors, seeds,
        vmin, vmax, density=stream_density,
    )
    ax.add_collection(collection)
    rr.apply_colorbar(ax.figure.colorbar(collection, ax=ax, fraction=0.038, pad=0.035), colorbar_label)
    _draw_trajectory(ax, motion, payload["slice"], a_over_lambda)
    _draw_charge_marker(ax, payload)
    ax.set_facecolor("white")


def _sample_grid(x_values: np.ndarray, y_values: np.ndarray, grid: np.ndarray,
                 x: float, y: float) -> float:
    if x < x_values[0] or x > x_values[-1] or y < y_values[0] or y > y_values[-1]:
        return np.nan
    ix = int(np.searchsorted(x_values, x) - 1)
    iy = int(np.searchsorted(y_values, y) - 1)
    ix = max(0, min(ix, len(x_values) - 2))
    iy = max(0, min(iy, len(y_values) - 2))
    x0, x1 = float(x_values[ix]), float(x_values[ix + 1])
    y0, y1 = float(y_values[iy]), float(y_values[iy + 1])
    tx = 0.0 if x1 == x0 else (x - x0) / (x1 - x0)
    ty = 0.0 if y1 == y0 else (y - y0) / (y1 - y0)
    block = grid[iy:iy + 2, ix:ix + 2]
    if not np.all(np.isfinite(block)):
        return np.nan
    return float(
        (1 - tx) * (1 - ty) * block[0, 0]
        + tx * (1 - ty) * block[0, 1]
        + (1 - tx) * ty * block[1, 0]
        + tx * ty * block[1, 1]
    )


def _seeded_streamline_collection(x_values: np.ndarray, y_values: np.ndarray,
                                  u_field: np.ndarray, v_field: np.ndarray,
                                  colors: np.ndarray, seeds: np.ndarray,
                                  vmin: float, vmax: float, *,
                                  density: float) -> LineCollection:
    segments: list[np.ndarray] = []
    segment_values: list[float] = []
    dx = float(x_values[-1] - x_values[0])
    dy = float(y_values[-1] - y_values[0])
    step_size = 0.018 * max(dx, dy)
    steps = max(18, int(round(74 * max(0.25, min(1.0, density)))))
    for seed in seeds:
        for direction in (-1.0, 1.0):
            point = np.asarray(seed, dtype=float)
            path = [point.copy()]
            values = []
            for _ in range(steps):
                ux = _sample_grid(x_values, y_values, u_field, float(point[0]), float(point[1]))
                vy = _sample_grid(x_values, y_values, v_field, float(point[0]), float(point[1]))
                value = _sample_grid(x_values, y_values, colors, float(point[0]), float(point[1]))
                if not (np.isfinite(ux) and np.isfinite(vy) and np.isfinite(value)):
                    break
                vector_norm = max(float(np.hypot(ux, vy)), 1e-12)
                point = point + direction * step_size * np.array([ux, vy]) / vector_norm
                if point[0] < x_values[0] or point[0] > x_values[-1] or point[1] < y_values[0] or point[1] > y_values[-1]:
                    break
                path.append(point.copy())
                values.append(value)
            if len(path) < 2:
                continue
            arr = np.asarray(path)
            for start, end, value in zip(arr[:-1], arr[1:], values):
                segments.append(np.vstack([start, end]))
                segment_values.append(value)
    collection = LineCollection(segments, cmap=style.visible_cmap_name(), norm=Normalize(vmin=vmin, vmax=vmax))
    collection.set_array(np.asarray(segment_values, dtype=float))
    collection.set_linewidth(1.25)
    return collection


def draw_field(ax, payload: dict, field: str, part: str, motion: str, stream_density: float = 1.0):
    """Draw one legacy-equivalent field view on an existing axes."""
    scalar, uu, vv, colorbar_label, signed = field_payload(payload, field, part)
    title_core, _ = field_text(field, payload["slice"])
    xlabel, ylabel, _, _ = slice_metadata(payload["slice"])
    extent = [payload["u"].min(), payload["u"].max(), payload["v"].min(), payload["v"].max()]
    display = process_display_field(scalar, signed)
    if uu is not None and vv is not None:
        _draw_colored_streamlines(ax, payload, uu, vv, display, colorbar_label, motion, field, stream_density)
        rr.set_axis_text(ax, title=_compose_title(title_core, motion, part), xlabel=xlabel, ylabel=ylabel, aspect="equal")
        ax.set_xlim(extent[0], extent[1])
        ax.set_ylim(extent[2], extent[3])
        return ax
    im = rr.image(
        ax,
        display,
        _compose_title(title_core, motion, part),
        None,
        extent=extent,
        label=colorbar_label,
        aspect="equal",
    )
    _draw_trajectory(ax, motion, payload["slice"], float(payload.get("a_over_lambda", 1.2)))
    _draw_charge_marker(ax, payload)
    rr.set_axis_text(ax, xlabel=xlabel, ylabel=ylabel, aspect="equal")
    if signed:
        vmax = np.nanpercentile(np.abs(display), 99)
        if np.isfinite(vmax) and vmax > 0:
            im.set_clim(-vmax, vmax)
    return im


def render(params: dict) -> rr.RenderBundle:
    payload = compute_payload(params)
    part = str(params.get("field_part", params.get("partType", "tot"))).lower()
    if part not in {"tot", "vel", "rad"}:
        part = "tot"
    fields = selected_fields(params.get("fields", params.get("selectedFields", params.get("customFields"))))
    figures = []
    for idx, field in enumerate(fields, start=1):
        fig, axes = rr.new_figure(f"{idx:02d} moving charge field", 1, 1, (6.8, 5.8))
        ax = axes[0, 0]
        draw_field(ax, payload, field, part, str(params.get("motion", params.get("motionType", "circular"))))
        rr.finish_figure(fig)
        figures.append(fig)
    bundle = rr.RenderBundle("Moving charge field bundle", figures)
    bundle.report = report("MovingChargeFields", [
        f"Motion: {params.get('motion', params.get('motionType', 'circular'))}, slice: {payload['slice']}, part: {part}",
        f"Rendered fields: {', '.join(fields)}",
        "Retarded time is solved by Picard iterations followed by Newton corrections, matching the MATLAB backend structure.",
        "Project reproduction entries use the shared output layer and the legacy phase-sweep MP4 contract.",
    ])
    return bundle


