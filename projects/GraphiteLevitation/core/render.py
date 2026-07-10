from __future__ import annotations

from math import ceil

import matplotlib.patches as patches
import numpy as np

from utils import render_result as rr
from utils.render_result import report

from .metrics import compute_visualization_maps
from .params import _numbers, normalize_scan_params


def _norm_positive(values: np.ndarray) -> np.ndarray:
    finite = values[np.isfinite(values)]
    if finite.size == 0:
        return values
    maximum = float(np.max(finite))
    return values if not np.isfinite(maximum) or abs(maximum) < 1e-15 else values / maximum


def _norm_signed(values: np.ndarray) -> np.ndarray:
    finite = values[np.isfinite(values)]
    if finite.size == 0:
        return values
    maximum = float(np.max(np.abs(finite)))
    return values if not np.isfinite(maximum) or maximum < 1e-15 else values / maximum


def _scan_layout(params: dict, case_count: int) -> tuple[int, int]:
    """Mirror the MATLAB scan layout: the last scanned input spans columns."""
    values = (
        _numbers(params.get("d", 6), (6,)),
        _numbers(params.get("W_um", 40), (40,)),
        _numbers(params.get("chi", 3.05), (3.05,)),
        _numbers(params.get("P", 0.35), (0.35,)),
    )
    scanned = [items for items in values if len(items) > 1]
    columns = len(scanned[-1]) if scanned else 1
    return max(1, ceil(case_count / columns)), max(1, columns)


def _figure(title: str, rows: int, columns: int, blocks: int, *, maps: bool):
    width = max(6.6, 3.65 * columns + (0.65 if maps else 0.0))
    height = max(4.6, 2.85 * rows * blocks + 0.45)
    return rr.new_figure(title, rows * blocks, columns, (width, height), visible_title=True)


def _case_axis(axes, block: int, case_index: int, rows: int, columns: int):
    return axes[block * rows + case_index // columns, case_index % columns]


def _case_title(label: str) -> str:
    return "" if label == "single run" else label


def _add_colorbar(fig, ax, image, case_index: int, columns: int) -> None:
    # MATLAB places the normalized-map colorbar on the right edge of every row.
    if case_index % columns == columns - 1:
        rr.apply_colorbar(fig.colorbar(image, ax=ax, fraction=0.040, pad=0.035))


def _map(ax, values, data, title: str, ylabel: str, *, signed: bool,
         x_label: str = "$x\\,[\\mathrm{mm}]$", overlay_magnets: bool = True,
         marker: tuple[float, float, str, str] | None = None):
    image = rr.image(
        ax,
        values,
        title="",
        cmap=None,
        extent=[data["x"].min() * 1e3, data["x"].max() * 1e3, data["y"].min() * 1e3, data["y"].max() * 1e3],
        colorbar=False,
        aspect="equal",
    )
    image.set_clim((-1, 1) if signed else (0, 1))
    if overlay_magnets:
        _overlay_magnets(ax, data)
    if marker is not None:
        x, y, color, symbol = marker
        ax.plot(x * 1e3, y * 1e3, symbol, color=color, markerfacecolor="none", markersize=5, markeredgewidth=1.0)
    rr.set_axis_text(ax, title=title, xlabel=x_label, ylabel=ylabel, aspect="equal")
    return image


def _overlay_magnets(ax, data) -> None:
    magnets = data["magnets"]
    for x, y in zip(magnets.x, magnets.y):
        ax.add_patch(patches.Rectangle(
            ((x - magnets.a / 2) * 1e3, (y - magnets.b / 2) * 1e3),
            magnets.a * 1e3,
            magnets.b * 1e3,
            fill=False,
            edgecolor="0.15",
            linewidth=0.5,
        ))


def _graphite_outline(ax, params, x_center: float = 0.0, y_center: float = 0.0,
                      *, color: str = "black", linestyle: str = "-", linewidth: float = 1.0) -> None:
    if params.shape == "circle":
        theta = np.linspace(0, 2 * np.pi, 240)
        x = params.radius * np.cos(theta)
        y = params.radius * np.sin(theta)
    else:
        half_side = params.side / 2
        points = np.array([
            [-half_side, -half_side], [half_side, -half_side], [half_side, half_side],
            [-half_side, half_side], [-half_side, -half_side],
        ])
        angle = np.deg2rad(params.rotation_deg)
        rotation = np.array([[np.cos(angle), -np.sin(angle)], [np.sin(angle), np.cos(angle)]])
        x, y = (rotation @ points.T)
    ax.plot((x + x_center) * 1e3, (y + y_center) * 1e3, color=color, linestyle=linestyle, linewidth=linewidth)


def _projected_width(params, axis: str) -> float:
    if params.shape == "circle":
        return 2 * params.radius
    half_side = params.side / 2
    points = np.array([[-half_side, -half_side], [half_side, -half_side], [half_side, half_side], [-half_side, half_side]])
    angle = np.deg2rad(params.rotation_deg)
    rotation = np.array([[np.cos(angle), -np.sin(angle)], [np.sin(angle), np.cos(angle)]])
    values = (rotation @ points.T)[0 if axis == "x" else 1]
    return float(values.max() - values.min())


def _draw_magnet_projection(ax, data, axis: str) -> None:
    magnets = data["magnets"]
    width = magnets.a if axis == "x" else magnets.b
    centers = np.unique(magnets.x if axis == "x" else magnets.y)
    for center in centers:
        ax.add_patch(patches.Rectangle(
            ((center - width / 2) * 1e3, -magnets.c * 1e3),
            width * 1e3,
            magnets.c * 1e3,
            facecolor="0.85",
            edgecolor="0.35",
            linewidth=0.5,
        ))


def _draw_system_top(ax, base, active) -> None:
    _overlay_magnets(ax, active)
    base_metrics = base["metrics"]
    active_metrics = active["metrics"]
    _graphite_outline(ax, base["params"], base_metrics["x_min"], base_metrics["y_min"], color="0.35", linestyle="--", linewidth=1.2)
    _graphite_outline(ax, active["params"], active_metrics["x_min"], active_metrics["y_min"], color="#b82727", linewidth=1.2)
    ax.plot(base_metrics["x_min"] * 1e3, base_metrics["y_min"] * 1e3, "o", color="0.35", markerfacecolor="none", markersize=5)
    ax.plot(active_metrics["x_min"] * 1e3, active_metrics["y_min"] * 1e3, "+", color="#b82727", markersize=7, markeredgewidth=1.2)
    params = active["params"]
    if params.laser_enabled:
        angle = np.deg2rad(params.rotation_deg)
        spot_x = np.cos(angle) * params.spot_x - np.sin(angle) * params.spot_y
        spot_y = np.sin(angle) * params.spot_x + np.cos(angle) * params.spot_y
        ax.plot((active_metrics["x_min"] + spot_x) * 1e3, (active_metrics["y_min"] + spot_y) * 1e3,
                "ko", markerfacecolor="yellow", markersize=4)


def _draw_system_side(ax, base, active, axis: str) -> None:
    _draw_magnet_projection(ax, active, axis)
    coordinate = "x_min" if axis == "x" else "y_min"
    width = _projected_width(active["params"], axis)
    u = np.linspace(-width / 2, width / 2, 120)
    base_metrics = base["metrics"]
    active_metrics = active["metrics"]
    # A rotation around y appears as slope in x-z; a rotation around x has
    # the opposite visual sign in y-z. This matches the small-angle pose model.
    active_theta = active_metrics["theta_y"] if axis == "x" else -active_metrics["theta_x"]
    z_ref = active_metrics.get("z_eq_off", base_metrics["z_balance"])
    ax.plot((base_metrics[coordinate] + u) * 1e3, np.full_like(u, z_ref) * 1e3,
            color="0.45", linestyle="--", linewidth=1.6)
    ax.plot((active_metrics[coordinate] + u) * 1e3, (z_ref + active_theta * u) * 1e3,
            color="#b82727", linewidth=1.6)


def _case_maps(params):
    active = compute_visualization_maps(params)
    return active["base"], active


def _b2_figure(cases, rows: int, columns: int):
    fig, axes = _figure("01 $B^2$", rows, columns, 1, maps=True)
    for index, (base, active, label) in enumerate(cases):
        ax = _case_axis(axes, 0, index, rows, columns)
        image = _map(ax, _norm_positive(active["B2"]), active, _case_title(label), "$y\\,[\\mathrm{mm}]$", signed=False)
        _add_colorbar(fig, ax, image, index, columns)
    rr.finish_figure(fig, hspace=0.48, wspace=0.36, right=0.88)
    return fig


def _compare_figure(cases, rows: int, columns: int, *, title: str, field: str,
                    signed: bool = False, show_stable: bool = True):
    fig, axes = _figure(title, rows, columns, 3, maps=True)
    for index, (base, active, label) in enumerate(cases):
        values = (base[field], active[field])
        display = (_norm_signed(values[0]), _norm_signed(values[1])) if signed else (_norm_positive(values[0]), _norm_positive(values[1]))
        difference = _norm_signed(display[1] - display[0])
        base_metric = base["metrics"]
        active_metric = active["metrics"]
        panels = (
            (display[0], base, "$\\mathrm{no\\,laser}$", signed, (base_metric["x_min"], base_metric["y_min"], "white", "o") if show_stable else None),
            (display[1], active, "$\\mathrm{with\\,laser}$", signed, (active_metric["x_min"], active_metric["y_min"], "white", "o") if show_stable else None),
            (difference, active, "$\\mathrm{diff}$", True, None),
        )
        for block, (values_to_draw, data, ylabel, panel_signed, marker) in enumerate(panels):
            ax = _case_axis(axes, block, index, rows, columns)
            image = _map(ax, values_to_draw, data, _case_title(label), ylabel, signed=panel_signed, marker=marker)
            if block == 2 and show_stable:
                ax.plot(base_metric["x_min"] * 1e3, base_metric["y_min"] * 1e3, "o", color="0.2", markerfacecolor="none", markersize=5)
                ax.plot(active_metric["x_min"] * 1e3, active_metric["y_min"] * 1e3, "+", color="white", markersize=7, markeredgewidth=1.2)
            _add_colorbar(fig, ax, image, index, columns)
    rr.finish_figure(fig, hspace=0.58, wspace=0.36, right=0.88)
    return fig


def _chi_figure(cases, rows: int, columns: int):
    fig, axes = _figure("03 $|\\chi|/|\\chi_0|$", rows, columns, 3, maps=True)
    for index, (base, active, label) in enumerate(cases):
        base_weight = base["chi"]["weight"]
        active_weight = active["chi"]["weight"]
        base_display = _norm_positive(base_weight)
        active_display = _norm_positive(active_weight)
        panels = (
            (base_display, base, "$\\mathrm{no\\,laser}\\; y_s\\,[\\mathrm{mm}]$", False),
            (active_display, active, "$\\mathrm{with\\,laser}\\; y_s\\,[\\mathrm{mm}]$", False),
            (_norm_signed(active_display - base_display), active, "$\\mathrm{diff}\\; y_s\\,[\\mathrm{mm}]$", True),
        )
        for block, (values, data, ylabel, signed) in enumerate(panels):
            ax = _case_axis(axes, block, index, rows, columns)
            image = _map(
                ax, values, {**data, "x": data["chi"]["x"], "y": data["chi"]["y"]},
                _case_title(label), ylabel, signed=signed,
                x_label="$x_s\\,[\\mathrm{mm}]$", overlay_magnets=False,
            )
            _graphite_outline(ax, data["params"], linewidth=0.8)
            if block > 0 and data["params"].laser_enabled:
                params = data["params"]
                ax.plot(params.spot_x * 1e3, params.spot_y * 1e3, "ko", markerfacecolor="white", markersize=4)
            _add_colorbar(fig, ax, image, index, columns)
    rr.finish_figure(fig, hspace=0.58, wspace=0.36, right=0.88)
    return fig


def _system_figure(cases, rows: int, columns: int):
    fig, axes = _figure("04 system views", rows, columns, 3, maps=False)
    labels = (("top", "$x\\,[\\mathrm{mm}]$", "$\\mathrm{top\\,view}$"),
              ("x", "$x\\,[\\mathrm{mm}]$", "$\\mathrm{side\\,x-z}$"),
              ("y", "$y\\,[\\mathrm{mm}]$", "$\\mathrm{side\\,y-z}$"))
    for index, (base, active, label) in enumerate(cases):
        for block, (view, xlabel, ylabel) in enumerate(labels):
            ax = _case_axis(axes, block, index, rows, columns)
            if view == "top":
                _draw_system_top(ax, base, active)
                rr.set_axis_text(ax, title=_case_title(label), xlabel=xlabel, ylabel=ylabel, aspect="equal")
            else:
                _draw_system_side(ax, base, active, view)
                rr.set_axis_text(ax, title=_case_title(label), xlabel=xlabel, ylabel=ylabel, aspect="equal")
    rr.finish_figure(fig, hspace=0.58, wspace=0.36, right=0.95)
    return fig


def _force_figure(cases, rows: int, columns: int, field: str, title: str):
    return _compare_figure(cases, rows, columns, title=title, field=field, signed=True, show_stable=False)


def render(params: dict) -> rr.RenderBundle:
    expanded = normalize_scan_params(params)
    cases = []
    report_lines = []
    for case_params, label, _suffix in expanded:
        base, active = _case_maps(case_params)
        cases.append((base, active, label))
        metrics = active["metrics"]
        report_lines.extend(_case_report_lines(label, base["metrics"], metrics))
    rows, columns = _scan_layout(params, len(cases))
    figures = [
        _b2_figure(cases, rows, columns),
        _compare_figure(cases, rows, columns, title="02 $U(X,Y)$", field="U"),
        _chi_figure(cases, rows, columns),
        _system_figure(cases, rows, columns),
        _force_figure(cases, rows, columns, "Fx", "05 $F_x$"),
        _force_figure(cases, rows, columns, "Fy", "06 $F_y$"),
        _force_figure(cases, rows, columns, "Fz", "07 $F_z$"),
    ]
    first = expanded[0][0]
    bundle = rr.RenderBundle("Graphite levitation seven-figure bundle", figures)
    bundle.report = report("GraphiteLevitation", [
        f"Checkerboard array: {first.array_nx} x {first.array_ny}, Br={first.br:.3g} T",
        f"Cartesian scan cases: {len(cases)}; layout: {rows} x {columns}.",
        *report_lines,
        "Each case follows the MATLAB order: B2, potential, chi, system, Fx, Fy, Fz.",
        "Stable poses are grid-resolved local minima; their count and coordinates vary with map resolution. The current softened dipole-field model and finite force quadrature cannot reproduce the legacy finite-magnet maps pixel-for-pixel.",
    ])
    return bundle


def _case_report_lines(label: str, base_metrics: dict, active_metrics: dict) -> list[str]:
    """Keep the scan report auditable: record every grid-resolved stable pose."""
    prefix = label if label != "single run" else "single run"
    lines = [
        f"{prefix}: no-laser x={base_metrics['x_min'] * 1e3:.6g} mm, y={base_metrics['y_min'] * 1e3:.6g} mm, "
        f"z={base_metrics['z_balance'] * 1e3:.6g} mm, Fz/W={base_metrics['force_over_weight']:.6g}; "
        f"with-laser x={active_metrics['x_min'] * 1e3:.6g} mm, y={active_metrics['y_min'] * 1e3:.6g} mm, "
        f"z diagnostic={active_metrics['z_eq_on'] * 1e3:.6g} mm, Fz/W={active_metrics['force_over_weight']:.6g}.",
        f"{prefix}: displacement dx={active_metrics['dx_laser'] * 1e3:.6g} mm, dy={active_metrics['dy_laser'] * 1e3:.6g} mm, "
        f"|d|={active_metrics['displacement'] * 1e3:.6g} mm; thetaX={active_metrics['theta_x'] * 1e3:.6g} mrad, "
        f"thetaY={active_metrics['theta_y'] * 1e3:.6g} mrad, thetaMag={active_metrics['theta_mag'] * 1e3:.6g} mrad.",
    ]
    for state, poses in (("no-laser", active_metrics["poses_off"]), ("with-laser", active_metrics["poses_on"])):
        lines.append(f"{prefix}: {state} stable-count={poses['count']}.")
        for index in range(poses["count"]):
            lines.append(
                f"{prefix}: {state} pose #{index + 1}: x={poses['x'][index] * 1e3:.6g} mm, "
                f"y={poses['y'][index] * 1e3:.6g} mm, z={poses['z'][index] * 1e3:.6g} mm, "
                f"thetaX={poses['theta_x'][index] * 1e3:.6g} mrad, thetaY={poses['theta_y'][index] * 1e3:.6g} mrad, "
                f"thetaMag={poses['theta_mag'][index] * 1e3:.6g} mrad, U={poses['U'][index]:.12g}."
            )
    return lines
