from __future__ import annotations

import numpy as np

from utils import render_result as rr
from utils import style


def field_figure(result: dict, title: str):
    fig, axes = rr.new_figure(title, 1, 1, (7.5, 6.0))
    ax = axes[0, 0]
    x = result.get("x")
    y = result.get("y", result.get("z"))
    extent = None
    if x is not None and y is not None:
        extent = [float(np.nanmin(x)), float(np.nanmax(x)), float(np.nanmin(y)), float(np.nanmax(y))]
    rr.image(
        ax,
        result["field"],
        result["title"],
        style.visible_colormap(),
        extent=extent,
        label=result.get("cb_label", "field"),
        aspect="auto",
    )
    rr.set_axis_text(ax, xlabel="$x/a$" if "y" in result else "$x/d$", ylabel="$y/a$" if "y" in result else "$z/d$")
    theta = np.linspace(0.0, 2.0 * np.pi, 361)
    for radius in result.get("boundary_radii", []):
        rr.curve(
            ax,
            radius * np.cos(theta),
            radius * np.sin(theta),
            color=style.tokens().primary_text,
            alpha=0.9,
            grid=False,
        )
    if result.get("boundary_radii"):
        ax.set_aspect("equal", adjustable="box")
    rr.finish_figure(fig)
    return fig


def metal_dispersion_figure(result: dict):
    fig, axes = rr.new_figure(result["title"], 1, 1, (8.2, 5.8))
    rr.set_figure_title(fig, result["title"], visible=False)
    ax = axes[0, 0]
    velocity_ax = ax.twinx()
    curves = sorted(result["curves"], key=lambda curve: curve.fc_ghz)[:6]
    beta_lines = []
    for curve in curves:
        beta_line = rr.curve(
            ax, curve.f_ghz, curve.beta, "", "$f\\;(\\mathrm{GHz})$",
            "$\\beta\\;(\\mathrm{rad/m})$", curve.label,
        )
        beta_lines.append(beta_line)
        rr.curve(
            velocity_ax, curve.f_ghz, curve.vg_over_c, "", "$f\\;(\\mathrm{GHz})$",
            "$v_{\\mathrm{g}}/c$", color=beta_line.get_color(), linestyle="--",
        )
    rr.set_axis_text(ax, title=result["title"], xlabel="$f\\;(\\mathrm{GHz})$", ylabel="$\\beta\\;(\\mathrm{rad/m})$", grid=True)
    rr.set_axis_text(velocity_ax, ylabel="$v_{\\mathrm{g}}/c$")
    rr.apply_legend(ax.legend(beta_lines, [line.get_label() for line in beta_lines], loc="best"))
    rr.finish_figure(fig)
    return fig


def cutoff_map_figure(result: dict):
    fig, axes = rr.new_figure(result["title"], 1, 1, (7.5, 6.0))
    ax = axes[0, 0]
    rr.image(
        ax,
        result["fc_ghz"],
        result["title"],
        style.visible_colormap(),
        extent=[result["n_list"][0] - 0.5, result["n_list"][-1] + 0.5, result["m_list"][0] - 0.5, result["m_list"][-1] + 0.5],
        label="$f_{\\mathrm{c}}\\;(\\mathrm{GHz})$",
    )
    rr.set_axis_text(ax, xlabel="$n$", ylabel="$m$")
    rr.finish_figure(fig)
    return fig


def planar_dispersion_figure(result: dict):
    title = (
        f"Planar slab $\\mathrm{{{result['mode_type']}}}$ normalized dispersion: "
        f"$n_{{\\mathrm{{co}}}}={result['n1']:.4g}$, $n_{{\\mathrm{{cl}}}}={result['n2']:.4g}$"
    )
    fig, axes = rr.new_figure(title, 1, 1, (8.2, 5.8))
    ax = axes[0, 0]
    for curve in result["curves"]:
        rr.curve(ax, curve.V, curve.b, "", "$V$", "$b=(n_{\\mathrm{eff}}^2-n_{\\mathrm{cl}}^2)/(n_{\\mathrm{co}}^2-n_{\\mathrm{cl}}^2)$", f"{result['mode_type']}_{curve.order}")
    ax.set_xlim(0, result["Vmax"])
    ax.set_ylim(0, 1)
    rr.set_axis_text(ax, title=title, xlabel="$V$", ylabel="$b=(n_{\\mathrm{eff}}^2-n_{\\mathrm{cl}}^2)/(n_{\\mathrm{co}}^2-n_{\\mathrm{cl}}^2)$", grid=True)
    rr.apply_legend(ax.legend(loc="best"))
    rr.finish_figure(fig)
    return fig


def planar_existence_figure(result: dict):
    title = (
        f"Planar mode existence: $\\mathrm{{{result['mode_type']}}}$, "
        f"$V_{{\\mathrm{{max}}}}={result['Vmax']:.4g}$"
    )
    fig, axes = rr.new_figure(title, 1, 1, (8.2, 5.2))
    ax = axes[0, 0]
    for order, cutoff in zip(result["orders"], result["cutoffV"]):
        rr.curve(ax, [cutoff, result["Vmax"]], [order, order], "", "$V$", "$\\mathrm{mode\\ order}$", f"$\\mathrm{{{result['mode_type']}}}_{{{order}}}$")
    ax.set_xlim(0, result["Vmax"])
    ax.set_ylim(-0.6, max(result["orders"], default=0) + 0.6)
    rr.set_axis_text(ax, title=title, xlabel="$V$", ylabel="$\\mathrm{mode\\ order}$", grid=True)
    rr.apply_legend(ax.legend(loc="best"))
    rr.finish_figure(fig)
    return fig


def planar_sweep_figure(result: dict):
    title = (
        f"Planar thickness sweep: $\\mathrm{{{result['mode_type']}}}$, "
        f"$f={result['freqGHz']:.4g}\\ \\mathrm{{GHz}}$, "
        f"$n_{{\\mathrm{{co}}}}={result['n1']:.4g}$, $n_{{\\mathrm{{cl}}}}={result['n2']:.4g}$"
    )
    fig, axes = rr.new_figure(title, 1, 1, (8.2, 5.8))
    rr.set_figure_title(fig, title, visible=False)
    ax = axes[0, 0]
    neff_ax = ax.twinx()
    count_line = rr.curve(
        ax,
        result["dValues"],
        result["modeCount"],
        "",
        "$d\\;(\\mathrm{m})$",
        "$\\mathrm{guided\\ mode\\ count}$",
        "$\\mathrm{guided\\ modes}$",
        color=style.tokens().accent,
        drawstyle="steps-mid",
    )
    for branch in result["branches"]:
        rr.curve(
            neff_ax,
            result["dValues"],
            branch["neff"],
            "",
            "$d\\,(\\mathrm{m})$",
            "$n_{\\mathrm{eff}}$",
            f"$n_{{\\mathrm{{eff}}}},\\ {result['mode_type']}_{{{branch['order']}}}$",
            linestyle="--",
        )
    rr.set_axis_text(ax, xlabel="$d\\;(\\mathrm{m})$", ylabel="$\\mathrm{guided\\ mode\\ count}$", title=title, grid=True)
    rr.set_axis_text(neff_ax, ylabel="$n_{\\mathrm{eff}}$")
    lines = [count_line, *neff_ax.get_lines()]
    rr.apply_legend(ax.legend(lines, [line.get_label() for line in lines], loc="best"))
    rr.finish_figure(fig)
    return fig


def cylindrical_dispersion_figure(result: dict):
    fig, axes = rr.new_figure(result["title"], 1, 1, (7.4, 6.2))
    ax = axes[0, 0]
    for branch in result["branches"]:
        rr.curve(ax, branch.v, branch.u, "", "$V$", "$U$", branch.label)
    rr.curve(
        ax,
        [0, result["vmax"]],
        [0, min(result["vmax"], result["umax"])],
        "",
        "$V$",
        "$U$",
        "$U=V$",
        color=style.tokens().muted_text,
        linestyle="--",
    )
    ax.set_xlim(0, result["vmax"])
    ax.set_ylim(0, result["umax"])
    ax.set_aspect("equal", adjustable="box")
    rr.set_axis_text(ax, title=result["title"], xlabel="$V$", ylabel="$U$", grid=True, box=True)
    rr.apply_legend(ax.legend(loc="best"))
    rr.finish_figure(fig)
    return fig
