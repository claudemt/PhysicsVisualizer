from __future__ import annotations

import re

import numpy as np

from .common import clean_tree, csqrt


def make_optical_medium(eps: complex, mu: complex, omega: float, k_x: complex) -> dict:
    n_sq = eps * mu
    n = csqrt(n_sq)
    k_z = csqrt(omega**2 * n_sq - k_x**2)
    return {
        "eps": eps,
        "mu": mu,
        "omega": omega,
        "k_x": k_x,
        "k_z": k_z,
        "sin_theta": k_x / (omega * n),
        "cos_theta": k_z / (omega * n),
        "zeta": csqrt(eps / mu),
        "h": 0.0,
        "phi": 0.0,
    }


def layer_matrix_p(med: dict) -> np.ndarray:
    phase = med["phi"]
    zeta = med["zeta"]
    cos_theta = med["cos_theta"]
    return np.array(
        [
            [np.cos(phase), -1j / zeta * np.sin(phase) / cos_theta],
            [-1j * zeta * cos_theta * np.sin(phase), np.cos(phase)],
        ],
        dtype=complex,
    )


def layer_matrix_q(med: dict) -> np.ndarray:
    phase = med["phi"]
    zeta = med["zeta"]
    cos_theta = med["cos_theta"]
    return np.array(
        [
            [np.cos(phase), -1j * zeta * np.sin(phase) / cos_theta],
            [-1j / zeta * cos_theta * np.sin(phase), np.cos(phase)],
        ],
        dtype=complex,
    )


def resolve_optical_layer_h(
    spec: object,
    omega: float,
    theta_a: float,
    eps_a: complex,
    mu_a: complex,
    eps_m: complex,
    mu_m: complex,
) -> float:
    """Parse numeric h or MATLAB's ``coeff*lambda`` optical-thickness syntax."""
    text = str(spec).strip().lower()
    match = re.fullmatch(r"([+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:e[+-]?\d+)?)\s*\*\s*lambda", text)
    if match:
        alpha = float(match.group(1))
        n_a = csqrt(eps_a * mu_a)
        lambda_a = 2 * np.pi / (omega * max(float(np.real(n_a)), np.finfo(float).tiny))
        k_x = omega * n_a * np.sin(theta_a)
        k_z_m = csqrt(omega**2 * eps_m * mu_m - k_x**2)
        nm_cos = max(float(np.real(k_z_m / omega)), np.finfo(float).tiny)
        return float(alpha * lambda_a / nm_cos)
    try:
        return float(text)
    except ValueError as exc:
        raise ValueError(f"Layer thickness must be numeric or coeff*lambda, got {spec!r}.") from exc


def apply_quarter_wave_thicknesses(data: dict) -> dict:
    out = {
        **data,
        "a": dict(data["a"]),
        "g": dict(data["g"]),
        "layers": [dict(layer) for layer in data.get("layers", [])],
    }
    omega = float(out["omega"])
    theta_a = float(out["theta_a"])
    k_x = omega * csqrt(out["a"]["eps"] * out["a"]["mu"]) * np.sin(theta_a)
    for layer in out["layers"]:
        med = make_optical_medium(layer["eps"], layer["mu"], omega, k_x)
        layer["h"] = round(float(np.pi / (2 * max(float(np.real(med["k_z"])), np.finfo(float).tiny))), 4)
    return out


def alternating_quarter_wave_stack(params: dict) -> dict:
    data = {
        "N": int(params.get("N", 8)),
        "omega": float(params.get("omega", 1.0)),
        "theta_a": float(params.get("theta_a", 0.0)),
        "a": dict(params.get("a", {"eps": 1.0, "mu": 1.0})),
        "g": dict(params.get("g", {"eps": 1.0, "mu": 1.0})),
        "layers": [],
    }
    first_high = bool(params.get("first_high", True))
    for idx in range(data["N"]):
        use_high = (idx % 2 == 0) if first_high else (idx % 2 == 1)
        data["layers"].append({
            "eps": params.get("eps_hi", 2.25) if use_high else params.get("eps_lo", 1.44),
            "mu": params.get("mu_hi", 1.0) if use_high else params.get("mu_lo", 1.0),
            "h": 0.0,
        })
    return apply_quarter_wave_thicknesses(data)


def optical_angle_sweep(data: dict, angles: np.ndarray) -> list[dict]:
    rows = []
    for angle in np.asarray(angles, dtype=float).ravel():
        case = {**data, "a": dict(data["a"]), "g": dict(data["g"]), "layers": [dict(layer) for layer in data.get("layers", [])], "theta_a": float(angle)}
        rows.append({"theta_a": float(angle), **solve_optical_film(case)})
    return rows


def optical_thickness_sweep(data: dict, layer_index: int, thicknesses: np.ndarray) -> list[dict]:
    rows = []
    idx = int(layer_index)
    for h in np.asarray(thicknesses, dtype=float).ravel():
        case = {**data, "a": dict(data["a"]), "g": dict(data["g"]), "layers": [dict(layer) for layer in data.get("layers", [])]}
        case["layers"][idx]["h"] = float(h)
        rows.append({"h": float(h), **solve_optical_film(case)})
    return rows


def solve_optical_film(data: dict) -> dict:
    omega = float(data["omega"])
    theta_a = float(data["theta_a"])
    k_x = omega * np.sqrt(data["a"]["eps"] * data["a"]["mu"]) * np.sin(theta_a)
    a = make_optical_medium(data["a"]["eps"], data["a"]["mu"], omega, k_x)
    g = make_optical_medium(data["g"]["eps"], data["g"]["mu"], omega, k_x)
    Ptot = np.eye(2, dtype=complex)
    Qtot = np.eye(2, dtype=complex)
    layers = []
    for layer in data.get("layers", []):
        med = make_optical_medium(layer["eps"], layer["mu"], omega, k_x)
        med["h"] = layer["h"]
        med["phi"] = med["k_z"] * med["h"]
        layers.append(med)
        Ptot = Ptot @ layer_matrix_p(med)
        Qtot = Qtot @ layer_matrix_q(med)

    zeta_a = a["zeta"]
    zeta_g = g["zeta"]
    ca = a["cos_theta"]
    cg = g["cos_theta"]

    combo_p = Ptot[0, 0] + zeta_g * cg * Ptot[0, 1]
    combo_p21 = Ptot[1, 0] + zeta_g * cg * Ptot[1, 1]
    den_s = zeta_a * ca * combo_p + combo_p21
    rs = (zeta_a * ca * combo_p - combo_p21) / den_s
    ts = (2 * zeta_a * ca) / den_s

    combo_q1 = Qtot[0, 0] * zeta_g + Qtot[0, 1] * cg
    combo_q2 = Qtot[1, 0] * zeta_g + Qtot[1, 1] * cg
    den_p = ca * combo_q1 + zeta_a * combo_q2
    rp = (ca * combo_q1 - zeta_a * combo_q2) / den_p
    tp = (2 * zeta_a * ca) / den_p

    result = {
        "rs": rs,
        "ts": ts,
        "rp": rp,
        "tp": tp,
        "Rs": abs(rs) ** 2,
        "Rp": abs(rp) ** 2,
        "Ts": (zeta_g * cg) / (zeta_a * ca) * abs(ts) ** 2,
        "Tp": (zeta_g * cg) / (zeta_a * ca) * abs(tp) ** 2,
        "a": a,
        "g": g,
        "layers": layers,
        "P": Ptot,
        "Q": Qtot,
        "k_x": k_x,
    }
    result["Es"] = result["Rs"] + result["Ts"]
    result["Ep"] = result["Rp"] + result["Tp"]
    return clean_tree(result)
