import numpy as np

from projects.CrystalOpticsBoundary.app.params import params_to_config
from projects.CrystalOpticsBoundary.app.report import render_crystal_report
from projects.CrystalOpticsBoundary.core.formula import crystal_boundary_formula
from utils import render_result as rr
from utils import style

TITLE = "Crystal Optics Boundary"
DESCRIPTION = "Reflection and transmission at dielectric boundaries."
DEFAULTS = {
    "n_incident": 1.0,
    "eps_diag": "2.25 2.56 3.24",
    "k_inc": "0.60 0.64 -0.48",
    "pol_type": "angle",
    "alpha_deg": 0.0,
    "pol_vector": "1 0 0",
    "num_samples": 181,
}
FORMULAS = "Boundary matching of electromagnetic fields."


def _single_figure(result: dict):
    energy = result["single"]["energy"]
    branches = result["single"]["transmission"]["branch"]
    fig, axes = rr.new_figure("Crystal boundary solution", 1, 2, (11, 5))
    components = ["R", "T", "|R+T-1|"]
    axes[0, 0].bar(
        components,
        [energy["R"], energy["T_total"], abs(energy["balance"])],
        color=[style.tokens().primary, style.tokens().accent, style.tokens().error],
    )
    rr.set_axis_text(axes[0, 0], title="energy balance", xlabel="component", ylabel="power ratio", grid=True)
    power = [float(branch["power_ratio"]) for branch in branches]
    branch_ids = np.arange(1, len(branches) + 1)
    colors = [style.tokens().primary, style.tokens().accent][:len(branches)]
    axes[0, 1].bar(branch_ids, power, color=colors)
    axes[0, 1].set_xticks(branch_ids)
    rr.set_axis_text(
        axes[0, 1], title="transmitted branch power",
        xlabel="branch", ylabel="power ratio", grid=True,
    )
    rr.finish_figure(fig)
    return fig


def _sweep_figure(result: dict):
    alpha = np.asarray(result["sweep"]["alpha_deg"], dtype=float)
    samples = result["sweep"]["sample"]
    reflectance = np.asarray([sample["energy"]["R"] for sample in samples], dtype=float)
    transmittance = np.asarray([sample["energy"]["T_total"] for sample in samples], dtype=float)
    balance = np.asarray([sample["energy"]["balance"] for sample in samples], dtype=float)
    branch_count = max(len(sample["transmission"]["branch"]) for sample in samples)

    fig, axes = rr.new_figure("Crystal polarization sweep", 1, 2, (11, 5))
    rr.curve(
        axes[0, 0], alpha, reflectance,
        "total energy coefficients", "alpha (deg)", "power ratio",
        label="R", color=style.tokens().primary,
    )
    rr.curve(
        axes[0, 0], alpha, transmittance,
        label="T total", color=style.tokens().accent,
    )
    rr.curve(
        axes[0, 0], alpha, np.abs(balance),
        label="|R+T-1|", color=style.tokens().error,
    )

    branch_colors = [style.tokens().primary, style.tokens().accent]
    for index in range(branch_count):
        power = [
            sample["transmission"]["branch"][index]["power_ratio"]
            if index < len(sample["transmission"]["branch"]) else np.nan
            for sample in samples
        ]
        rr.curve(
            axes[0, 1],
            alpha,
            power,
            "transmitted branch power",
            "alpha (deg)",
            "power ratio",
            label=f"branch {index + 1}",
            color=branch_colors[index % len(branch_colors)],
        )
    rr.finish_figure(fig)
    return fig


def render(params):
    result = crystal_boundary_formula(params_to_config(params))
    text = render_crystal_report(result)
    figures = [_single_figure(result)]
    if result["case_type"] == "sweep":
        figures.insert(0, _sweep_figure(result))
    return rr.RenderBundle("CrystalOpticsBoundary", figures, text)
