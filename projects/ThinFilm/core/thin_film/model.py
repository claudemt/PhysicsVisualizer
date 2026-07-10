from __future__ import annotations

import numpy as np

from .common import fmt
from .elastic import solve_elastic_film
from .optical import resolve_optical_layer_h, solve_optical_film


def elastic_defaults() -> dict:
    return {
        "N": 1,
        "omega": 1.0,
        "kx": 0.1,
        "phii": 1.0,
        "psii": 1.0,
        "a": {"lambda": 1.3, "mu": 1.0, "eta": 1.0},
        "g": {"lambda": 1.3, "mu": 5.2, "eta": 1.9},
        "layers": [{"lambda": 4.0, "mu": 1.5, "eta": 4.4, "h": 9.8}],
    }


def optical_defaults() -> dict:
    data = {
        "N": 1,
        "omega": 1.0,
        "theta_a": round(np.pi / 6, 3),
        "a": {"eps": 1.0, "mu": 1.0},
        "g": {"eps": 2.25, "mu": 1.0},
        "layers": [{"eps": 2.25, "mu": 1.0, "h": 0.0}],
    }
    data["layers"][0]["h"] = resolve_optical_layer_h("0.25*lambda", data["omega"], data["theta_a"], data["a"]["eps"], data["a"]["mu"], 2.25, 1.0)
    return data


def optical_report(data: dict, result: dict) -> str:
    lines = [
        "Optical multilayer result",
        "========================",
        "",
        f"N = {len(data['layers'])}",
        f"omega = {fmt(data['omega'])}",
        f"theta_a (rad, from normal in medium a) = {fmt(data['theta_a'])}",
        f"k_x = {fmt(result['k_x'])}",
        "",
        "Medium a (incident)",
        f"eps_a = {fmt(data['a']['eps'])}",
        f"mu_a = {fmt(data['a']['mu'])}",
        f"zeta_a = {fmt(result['a']['zeta'])}",
        f"cos_theta_a = {fmt(result['a']['cos_theta'])}",
        "",
        "Medium g (substrate)",
        f"eps_g = {fmt(data['g']['eps'])}",
        f"mu_g = {fmt(data['g']['mu'])}",
        f"zeta_g = {fmt(result['g']['zeta'])}",
        f"cos_theta_g = {fmt(result['g']['cos_theta'])}",
        "",
    ]
    for index, layer in enumerate(data["layers"], start=1):
        lines.extend([
            f"Layer {index}",
            f"eps_{index} = {fmt(layer['eps'])}",
            f"mu_{index} = {fmt(layer['mu'])}",
            f"h_{index} = {fmt(layer['h'])}",
            f"phase_{index} = {fmt(result['layers'][index - 1]['phi'])}",
            f"cos_theta_{index} = {fmt(result['layers'][index - 1]['cos_theta'])}",
            "",
        ])
    lines.extend([
        "s polarization",
        f"r_s = {fmt(result['rs'])}",
        f"R_s = {fmt(result['Rs'])}",
        f"t_s = {fmt(result['ts'])}",
        f"T_s = {fmt(result['Ts'])}",
        f"Energy sum s = {fmt(result['Es'])}",
        "",
        "p polarization",
        f"r_p = {fmt(result['rp'])}",
        f"R_p = {fmt(result['Rp'])}",
        f"t_p = {fmt(result['tp'])}",
        f"T_p = {fmt(result['Tp'])}",
        f"Energy sum p = {fmt(result['Ep'])}",
    ])
    return "\n".join(lines) + "\n\n"


def elastic_report(data: dict, result: dict) -> str:
    lines = [
        "Elastic film result",
        "===================",
        "",
        f"N = {len(data['layers'])}",
        f"omega = {fmt(data['omega'])}",
        f"k_x = {fmt(data['kx'])}",
        f"phi_i = {fmt(data['phii'])}",
        f"psi_i = {fmt(data['psii'])}",
        "",
        "Incident side a",
        f"lambda_a = {fmt(data['a']['lambda'])}",
        f"mu_a = {fmt(data['a']['mu'])}",
        f"eta_a = {fmt(data['a']['eta'])}",
        "",
        "Substrate side g",
        f"lambda_g = {fmt(data['g']['lambda'])}",
        f"mu_g = {fmt(data['g']['mu'])}",
        f"eta_g = {fmt(data['g']['eta'])}",
        "",
    ]
    for index, layer in enumerate(data["layers"], start=1):
        lines.extend([
            f"Layer {index}",
            f"lambda_{index} = {fmt(layer['lambda'])}",
            f"mu_{index} = {fmt(layer['mu'])}",
            f"eta_{index} = {fmt(layer['eta'])}",
            f"h_{index} = {fmt(layer['h'])}",
            "",
        ])
    lines.extend([
        "P incidence",
        f"r_P = {fmt(result['rP_P'])}",
        f"R_P = {fmt(result['RP_P'])}",
        f"r_SV = {fmt(result['rSV_P'])}",
        f"R_SV = {fmt(result['RSV_P'])}",
        f"t_P = {fmt(result['tP_P'])}",
        f"T_P = {fmt(result['TP_P'])}",
        f"t_SV = {fmt(result['tSV_P'])}",
        f"T_SV = {fmt(result['TSV_P'])}",
        f"Energy sum = {fmt(result['EP'])}",
        "",
        "SV incidence",
        f"r_P = {fmt(result['rP_SV'])}",
        f"R_P = {fmt(result['RP_SV'])}",
        f"r_SV = {fmt(result['rSV_SV'])}",
        f"R_SV = {fmt(result['RSV_SV'])}",
        f"t_P = {fmt(result['tP_SV'])}",
        f"T_P = {fmt(result['TP_SV'])}",
        f"t_SV = {fmt(result['tSV_SV'])}",
        f"T_SV = {fmt(result['TSV_SV'])}",
        f"Energy sum = {fmt(result['ESV'])}",
        "",
        "SH incidence",
        f"r_SH = {fmt(result['rSH'])}",
        f"R_SH = {fmt(result['RSH'])}",
        f"t_SH = {fmt(result['tSH'])}",
        f"T_SH = {fmt(result['TSH'])}",
        f"Energy sum = {fmt(result['ESH'])}",
    ])
    return "\n".join(lines) + "\n\n"


def optical_sweep_report(mode: str, rows: list[dict], layer_index: int | None = None) -> str:
    key = "theta_a" if mode == "angle sweep" else "h"
    label = "theta_a (rad)" if key == "theta_a" else f"layer {layer_index} thickness"
    lines = [
        "",
        "Optical sweep",
        "=============",
        f"mode = {mode}",
        f"samples = {len(rows)}",
    ]
    if layer_index is not None:
        lines.append(f"layer_index = {layer_index}")
    header = (
        f"{label:>20}  {'R_s':>14}  {'T_s':>14}  {'R_p':>14}  "
        f"{'T_p':>14}  {'E_s-1':>14}  {'E_p-1':>14}"
    )
    lines.extend(["", header])
    for row in rows:
        lines.append(
            f"{fmt(row[key]):>20}  {fmt(row['Rs']):>14}  {fmt(row['Ts']):>14}  "
            f"{fmt(row['Rp']):>14}  {fmt(row['Tp']):>14}  "
            f"{fmt(row['Es'] - 1):>14}  {fmt(row['Ep'] - 1):>14}"
        )
    return "\n".join(lines) + "\n"


def render_report(kind: str, data: dict) -> tuple[dict, str]:
    if kind == "optical":
        result = solve_optical_film(data)
        return result, optical_report(data, result)
    result = solve_elastic_film(data)
    return result, elastic_report(data, result)
