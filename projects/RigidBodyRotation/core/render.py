from __future__ import annotations

import matplotlib.pyplot as plt
import numpy as np

from utils import render_result as rr
from utils import style
from utils.render_result import report

from .solver import RigidCompareResult, default_input, solve


PLOT_TITLES = (
    "$\\omega$ in lab frame",
    "$\\omega$ in lab frame",
    "$\\omega$ in body frame",
    "$\\omega$ in body frame",
    "$L$ in body frame",
    "$\\omega$ and $L$ in body frame",
    "axis tips in lab frame",
)


def _legend_location(value: object) -> str:
    return {
        "northeast": "upper right",
        "northwest": "upper left",
        "best": "best",
    }.get(str(value).strip().casefold(), "upper right")


def _fig(index: int, projection=None):
    style.apply_matplotlib_defaults()
    title = PLOT_TITLES[index - 1]
    fig = plt.figure(figsize=(6.8, 5.3))
    rr.set_figure_title(fig, f"{index:02d} {title}")
    return fig, fig.add_subplot(111, projection=projection), title


def _finish_2d(ax):
    rr.set_axis_text(ax, grid=True)
    ax.axhline(0, color="black", linestyle=":", linewidth=0.8, label="_nolegend_")
    ax.axvline(0, color="black", linestyle=":", linewidth=0.8, label="_nolegend_")


def _finish_3d(ax, points, legend_location: str | None = None):
    rr.set_axis_text(ax, grid=True)
    data = np.asarray(points, dtype=float).reshape(-1, 3)
    data = data[np.all(np.isfinite(data), axis=1)]
    if not len(data):
        data = np.array([[-1.0, -1.0, -1.0], [1.0, 1.0, 1.0]])
    mins, maxs = data.min(axis=0), data.max(axis=0)
    spans = maxs - mins
    max_span = max(float(spans.max()), 1.0)
    spans = np.maximum(spans, 0.10 * max_span)
    centers = (mins + maxs) / 2
    half_ranges = 0.58 * spans
    ax.set_xlim(centers[0] - half_ranges[0], centers[0] + half_ranges[0])
    ax.set_ylim(centers[1] - half_ranges[1], centers[1] + half_ranges[1])
    ax.set_zlim(centers[2] - half_ranges[2], centers[2] + half_ranges[2])
    ax.set_box_aspect((1, 1, 1))
    ax.set_proj_type("ortho")
    xl, yl, zl = ax.get_xlim(), ax.get_ylim(), ax.get_zlim()
    ax.plot3D(xl, (0, 0), (0, 0), color="black", linestyle=":", linewidth=0.8, label="_nolegend_")
    ax.plot3D((0, 0), yl, (0, 0), color="black", linestyle=":", linewidth=0.8, label="_nolegend_")
    ax.plot3D((0, 0), (0, 0), zl, color="black", linestyle=":", linewidth=0.8, label="_nolegend_")
    if legend_location is not None:
        handles, labels = ax.get_legend_handles_labels()
        if any(not label.startswith("_") for label in labels):
            rr.apply_legend(ax.legend(loc=_legend_location(legend_location)))


def _start_end(ax, values, color=None):
    data = np.asarray(values)
    kwargs = {"color": color} if color else {}
    if data.shape[1] == 2:
        ax.plot(data[0, 0], data[0, 1], "o", markersize=4, label="_nolegend_", **kwargs)
        ax.plot(data[-1, 0], data[-1, 1], "s", markersize=4, label="_nolegend_", **kwargs)
    else:
        ax.plot3D(*data[0], "o", markersize=4, label="_nolegend_", **kwargs)
        ax.plot3D(*data[-1], "s", markersize=4, label="_nolegend_", **kwargs)


def _w3_scale(w_body: np.ndarray) -> tuple[float, str]:
    reference = max(float(np.max(np.abs(w_body[:, :2]))), 1e-12)
    if float(np.max(np.abs(w_body[:, 2]))) > 3.5 * reference:
        return 10.0, "$\\omega_3/10$"
    return 1.0, "$\\omega_3$"


def _case_colors(count: int):
    return plt.rcParams["axes.prop_cycle"].by_key()["color"][:count]


def _finalize(figures):
    for fig in figures:
        rr.finish_figure(fig)


def render(params: dict) -> rr.RenderBundle:
    input_data = default_input(params)
    result = solve(input_data)
    if isinstance(result, RigidCompareResult):
        return render_compare(result)

    figures = []
    t, wb, wl, lb, tips = result.t, result.w_body, result.w_lab, result.l_body, result.axis_tips
    legend_2d, legend_3d = input_data["legend_2d"], input_data["legend_3d"]
    w3_scale, w3_label = _w3_scale(wb)

    fig, ax, title = _fig(1)
    for index, label in enumerate(("$\\omega_x$", "$\\omega_y$")):
        ax.plot(t, wl[:, index], linewidth=0.95, label=label)
    rr.set_axis_text(ax, title=title, xlabel="$t$", ylabel="$\\omega$", grid=True)
    _finish_2d(ax)
    rr.apply_legend(ax.legend(loc=_legend_location(legend_2d)))
    figures.append(fig)

    fig, ax, title = _fig(2, "3d" if result.mode == "fixed" else None)
    if result.mode == "fixed":
        line = ax.plot3D(wl[:, 0], wl[:, 1], wl[:, 2], linewidth=0.90)[0]
        _start_end(ax, wl, line.get_color())
        rr.set_axis_text(ax, title=title, xlabel="$\\omega_x$", ylabel="$\\omega_y$", zlabel="$\\omega_z$", grid=True)
        _finish_3d(ax, wl)
    else:
        line = ax.plot(wl[:, 0], wl[:, 1], linewidth=0.90)[0]
        _start_end(ax, wl[:, :2], line.get_color())
        rr.set_axis_text(ax, title=title, xlabel="$\\omega_x$", ylabel="$\\omega_y$", grid=True)
        _finish_2d(ax)
    figures.append(fig)

    fig, ax, title = _fig(3)
    for index, label, values in ((0, "$\\omega_1$", wb[:, 0]), (1, "$\\omega_2$", wb[:, 1]), (2, w3_label, wb[:, 2] / w3_scale)):
        ax.plot(t, values, linewidth=0.95, label=label)
    rr.set_axis_text(ax, title=title, xlabel="$t$", ylabel="$\\omega$", grid=True)
    _finish_2d(ax)
    rr.apply_legend(ax.legend(loc=_legend_location(legend_2d)))
    figures.append(fig)

    fig, ax, title = _fig(4, "3d")
    line = ax.plot3D(wb[:, 0], wb[:, 1], wb[:, 2], linewidth=0.90)[0]
    _start_end(ax, wb, line.get_color())
    rr.set_axis_text(ax, title=title, xlabel="$\\omega_1$", ylabel="$\\omega_2$", zlabel="$\\omega_3$", grid=True)
    _finish_3d(ax, wb)
    figures.append(fig)

    fig, ax, title = _fig(5, "3d")
    line = ax.plot3D(lb[:, 0], lb[:, 1], lb[:, 2], linewidth=0.90)[0]
    _start_end(ax, lb, line.get_color())
    rr.set_axis_text(ax, title=title, xlabel="$L_1$", ylabel="$L_2$", zlabel="$L_3$", grid=True)
    _finish_3d(ax, lb)
    figures.append(fig)

    fig, ax, title = _fig(6, "3d")
    omega = ax.plot3D(wb[:, 0], wb[:, 1], wb[:, 2], linewidth=0.90, label="$\\omega$")[0]
    momentum = ax.plot3D(lb[:, 0], lb[:, 1], lb[:, 2], linewidth=0.90, label="$L$")[0]
    _start_end(ax, wb, omega.get_color())
    _start_end(ax, lb, momentum.get_color())
    rr.set_axis_text(ax, title=title, xlabel="$e_1$", ylabel="$e_2$", zlabel="$e_3$", grid=True)
    _finish_3d(ax, np.vstack((wb, lb)), legend_3d)
    figures.append(fig)

    fig, ax, title = _fig(7, "3d")
    for index, label in enumerate(("$\\hat e_1$", "$\\hat e_2$", "$\\hat e_3$")):
        values = tips[:, :, index]
        line = ax.plot3D(values[:, 0], values[:, 1], values[:, 2], linewidth=0.90, label=label)[0]
        _start_end(ax, values, line.get_color())
    rr.set_axis_text(ax, title=title, xlabel="$x$", ylabel="$y$", zlabel="$z$", grid=True)
    _finish_3d(ax, np.vstack((tips[:, :, 0], tips[:, :, 1], tips[:, :, 2])), legend_3d)
    figures.append(fig)

    _finalize(figures)
    drift = float((np.nanmax(result.energy) - np.nanmin(result.energy)) / max(abs(np.nanmean(result.energy)), 1e-12))
    return rr.RenderBundle("Rigid body rotation previews", figures, report("RigidBodyRotation", [
        f"Mode: {result.mode}",
        "Generated the seven MATLAB static preview plots.",
        f"Relative energy drift in integration output: {drift:.3e}",
        "Single-case exports can write the attitude MP4 animation.",
    ]))


def render_compare(result: RigidCompareResult) -> rr.RenderBundle:
    figures, cases, labels = [], result.cases, result.labels
    colors = _case_colors(len(cases))

    fig, ax, title = _fig(1)
    for case, color in zip(cases, colors):
        ax.plot(case.t, case.w_lab[:, 0], color=color, linewidth=0.85)
        ax.plot(case.t, case.w_lab[:, 1], color=color, linestyle="--", linewidth=0.85)
    rr.set_axis_text(ax, title=title, xlabel="$t$", ylabel="$\\omega$", grid=True)
    _finish_2d(ax)
    _add_case_legend(ax, colors, labels, result.legend_2d, False)
    figures.append(fig)

    fig, ax, title = _fig(2, "3d" if result.base_mode == "fixed" else None)
    if result.base_mode == "free":
        for case, color in zip(cases, colors):
            ax.plot(case.w_lab[:, 0], case.w_lab[:, 1], color=color, linewidth=0.90)
            _start_end(ax, case.w_lab[:, :2], color)
        rr.set_axis_text(ax, title=title, xlabel="$\\omega_x$", ylabel="$\\omega_y$", grid=True)
        _finish_2d(ax)
        _add_case_legend(ax, colors, labels, result.legend_2d, False)
    else:
        for case, color in zip(cases, colors):
            ax.plot3D(case.w_lab[:, 0], case.w_lab[:, 1], case.w_lab[:, 2], color=color, linewidth=0.90)
            _start_end(ax, case.w_lab, color)
        rr.set_axis_text(ax, title=title, xlabel="$\\omega_x$", ylabel="$\\omega_y$", zlabel="$\\omega_z$", grid=True)
        _finish_3d(ax, np.vstack([case.w_lab for case in cases]))
        _add_case_legend(ax, colors, labels, result.legend_3d, True)
    figures.append(fig)

    all_wb = np.vstack([case.w_body for case in cases])
    w3_scale, _ = _w3_scale(all_wb)
    fig, ax, title = _fig(3)
    for case, color in zip(cases, colors):
        ax.plot(case.t, case.w_body[:, 0], color=color, linewidth=0.85)
        ax.plot(case.t, case.w_body[:, 1], color=color, linestyle="--", linewidth=0.85)
        ax.plot(case.t, case.w_body[:, 2] / w3_scale, color=color, linestyle="-.", linewidth=0.85)
    rr.set_axis_text(ax, title=title, xlabel="$t$", ylabel="$\\omega$", grid=True)
    _finish_2d(ax)
    _add_case_legend(ax, colors, labels, result.legend_2d, False)
    figures.append(fig)

    for index, values, labels_xyz, title in (
        (4, [case.w_body for case in cases], ("$\\omega_1$", "$\\omega_2$", "$\\omega_3$"), PLOT_TITLES[3]),
        (5, [case.l_body for case in cases], ("$L_1$", "$L_2$", "$L_3$"), PLOT_TITLES[4]),
    ):
        fig, ax, _ = _fig(index, "3d")
        for value, color in zip(values, colors):
            ax.plot3D(value[:, 0], value[:, 1], value[:, 2], color=color, linewidth=0.90)
            _start_end(ax, value, color)
        rr.set_axis_text(ax, title=title, xlabel=labels_xyz[0], ylabel=labels_xyz[1], zlabel=labels_xyz[2], grid=True)
        _finish_3d(ax, np.vstack(values))
        _add_case_legend(ax, colors, labels, result.legend_3d, True)
        figures.append(fig)

    fig, ax, title = _fig(6, "3d")
    points = []
    for case, color in zip(cases, colors):
        ax.plot3D(case.w_body[:, 0], case.w_body[:, 1], case.w_body[:, 2], color=color, linewidth=0.90)
        ax.plot3D(case.l_body[:, 0], case.l_body[:, 1], case.l_body[:, 2], color=color, linestyle="--", linewidth=0.85)
        _start_end(ax, case.w_body, color)
        _start_end(ax, case.l_body, color)
        points.extend((case.w_body, case.l_body))
    rr.set_axis_text(ax, title=title, xlabel="$c_1$", ylabel="$c_2$", zlabel="$c_3$", grid=True)
    _finish_3d(ax, np.vstack(points))
    _add_case_legend(ax, colors, labels, result.legend_3d, True)
    figures.append(fig)

    fig, ax, title = _fig(7, "3d")
    points = []
    for case, color in zip(cases, colors):
        for axis, linestyle in enumerate(("-", "--", "-.")):
            values = case.axis_tips[:, :, axis]
            ax.plot3D(values[:, 0], values[:, 1], values[:, 2], color=color, linestyle=linestyle, linewidth=0.85)
            _start_end(ax, values, color)
            points.append(values)
    rr.set_axis_text(ax, title=title, xlabel="$x$", ylabel="$y$", zlabel="$z$", grid=True)
    _finish_3d(ax, np.vstack(points))
    _add_case_legend(ax, colors, labels, result.legend_3d, True)
    figures.append(fig)

    _finalize(figures)
    return rr.RenderBundle("Rigid body multi-IC comparison", figures, report("RigidBodyRotation", [
        f"Mode: {result.mode}",
        f"Compared {len(cases)} initial-condition rows across seven previews.",
        "Video export is disabled for multi-IC comparison.",
    ]))


def _add_case_legend(ax, colors, labels, location: str, use_3d: bool):
    handles = []
    for color in colors:
        if use_3d:
            handle = ax.plot3D((np.nan,), (np.nan,), (np.nan,), color=color, linewidth=1.0)[0]
        else:
            handle = ax.plot((np.nan,), (np.nan,), color=color, linewidth=1.0)[0]
        handles.append(handle)
    rr.apply_legend(ax.legend(handles, labels, loc=_legend_location(location)))
