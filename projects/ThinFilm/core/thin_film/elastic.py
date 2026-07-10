from __future__ import annotations

import numpy as np

from .common import casin, clean_tree, cot, csqrt


def make_elastic_medium(lam: float, mu: float, eta: float, kx: float, omega: float) -> dict:
    kP = omega * csqrt(eta / (lam + 2 * mu))
    kS = omega * csqrt(eta / mu)
    thetaP = casin(kx / kP)
    thetaS = casin(kx / kS)
    cP = csqrt((lam + 2 * mu) / eta)
    cS = csqrt(mu / eta)
    return {
        "lambda": lam,
        "mu": mu,
        "eta": eta,
        "kP": kP,
        "kS": kS,
        "cP": cP,
        "cS": cS,
        "kappa": mu / (lam + 2 * mu),
        "thetaP": thetaP,
        "thetaS": thetaS,
        "zeta": eta * cS,
        "h": 0.0,
        "phiP": 0.0,
        "phiS": 0.0,
    }


def psv_transfer(med: dict) -> np.ndarray:
    thp = med["thetaP"]
    ths = med["thetaS"]
    eta = med["eta"]
    kappa = med["kappa"]
    phiP = med["phiP"]
    phiS = med["phiS"]
    A1 = np.array(
        [
            [1, 1, -cot(ths), cot(ths)],
            [cot(thp), -cot(thp), 1, 1],
            [eta * kappa * np.sin(2 * thp), -eta * kappa * np.sin(2 * thp), -eta * np.cos(2 * ths), -eta * np.cos(2 * ths)],
            [eta * np.cos(2 * ths), eta * np.cos(2 * ths), eta * np.sin(2 * ths), -eta * np.sin(2 * ths)],
        ],
        dtype=complex,
    )
    A2 = np.array(
        [
            [np.exp(1j * phiP), np.exp(-1j * phiP), -cot(ths) * np.exp(1j * phiS), cot(ths) * np.exp(-1j * phiS)],
            [cot(thp) * np.exp(1j * phiP), -cot(thp) * np.exp(-1j * phiP), np.exp(1j * phiS), np.exp(-1j * phiS)],
            [
                eta * kappa * np.sin(2 * thp) * np.exp(1j * phiP),
                -eta * kappa * np.sin(2 * thp) * np.exp(-1j * phiP),
                -eta * np.cos(2 * ths) * np.exp(1j * phiS),
                -eta * np.cos(2 * ths) * np.exp(-1j * phiS),
            ],
            [
                eta * np.cos(2 * ths) * np.exp(1j * phiP),
                eta * np.cos(2 * ths) * np.exp(-1j * phiP),
                eta * np.sin(2 * ths) * np.exp(1j * phiS),
                -eta * np.sin(2 * ths) * np.exp(-1j * phiS),
            ],
        ],
        dtype=complex,
    )
    return A1 @ np.linalg.inv(A2)


def sh_transfer(med: dict) -> np.ndarray:
    phiS = med["phiS"]
    zeta = med["zeta"]
    cts = np.cos(med["thetaS"])
    return np.array(
        [
            [np.cos(phiS), -1j * np.sin(phiS) / (zeta * cts)],
            [-1j * zeta * cts * np.sin(phiS), np.cos(phiS)],
        ],
        dtype=complex,
    )


def solve_elastic_film(data: dict) -> dict:
    omega = float(data["omega"])
    kx = float(data["kx"])
    a = make_elastic_medium(data["a"]["lambda"], data["a"]["mu"], data["a"]["eta"], kx, omega)
    g = make_elastic_medium(data["g"]["lambda"], data["g"]["mu"], data["g"]["eta"], kx, omega)
    Ptot = np.eye(4, dtype=complex)
    Psh = np.eye(2, dtype=complex)
    layers = []
    for layer in data.get("layers", []):
        med = make_elastic_medium(layer["lambda"], layer["mu"], layer["eta"], kx, omega)
        med["h"] = layer["h"]
        med["phiP"] = med["kP"] * med["h"] * np.cos(med["thetaP"])
        med["phiS"] = med["kS"] * med["h"] * np.cos(med["thetaS"])
        layers.append(med)
        Ptot = Ptot @ psv_transfer(med)
        Psh = Psh @ sh_transfer(med)

    c1 = np.array([-1, cot(a["thetaP"]), a["eta"] * a["kappa"] * np.sin(2 * a["thetaP"]), -a["eta"] * np.cos(2 * a["thetaS"])], dtype=complex)
    c2 = np.array([-cot(a["thetaS"]), -1, a["eta"] * np.cos(2 * a["thetaS"]), a["eta"] * np.sin(2 * a["thetaS"])], dtype=complex)
    c3 = Ptot @ np.array([1, cot(g["thetaP"]), g["eta"] * g["kappa"] * np.sin(2 * g["thetaP"]), g["eta"] * np.cos(2 * g["thetaS"])], dtype=complex)
    c4 = Ptot @ np.array([-cot(g["thetaS"]), 1, -g["eta"] * np.cos(2 * g["thetaS"]), g["eta"] * np.sin(2 * g["thetaS"])], dtype=complex)
    matrix = np.column_stack([c1, c2, c3, c4])

    rhs_p = np.array([1, cot(a["thetaP"]), a["eta"] * a["kappa"] * np.sin(2 * a["thetaP"]), a["eta"] * np.cos(2 * a["thetaS"])], dtype=complex) * data["phii"]
    rhs_sv = np.array([-cot(a["thetaS"]), 1, -a["eta"] * np.cos(2 * a["thetaS"]), a["eta"] * np.sin(2 * a["thetaS"])], dtype=complex) * data["psii"]
    sol_p = np.linalg.solve(matrix, rhs_p)
    sol_sv = np.linalg.solve(matrix, rhs_sv)
    result = {"a": a, "g": g, "layers": layers, "Ptot": Ptot, "Psh": Psh}
    result.update({
        "phi_r_P": sol_p[0], "psi_r_P": sol_p[1], "phi_t_P": sol_p[2], "psi_t_P": sol_p[3],
        "phi_r_SV": sol_sv[0], "psi_r_SV": sol_sv[1], "phi_t_SV": sol_sv[2], "psi_t_SV": sol_sv[3],
    })

    if abs(data["phii"]) < np.finfo(float).eps:
        result.update({"rP_P": 0, "RP_P": 0, "rSV_P": 0, "RSV_P": 0, "tP_P": 0, "TP_P": 0, "tSV_P": 0, "TSV_P": 0, "EP": 0})
    else:
        result["rP_P"] = result["phi_r_P"] / data["phii"]
        result["RP_P"] = abs(result["rP_P"]) ** 2
        result["rSV_P"] = result["psi_r_P"] / data["phii"]
        result["RSV_P"] = (a["cP"] * np.cos(a["thetaS"])) / (a["cS"] * np.cos(a["thetaP"])) * abs(result["rSV_P"]) ** 2
        result["tP_P"] = result["phi_t_P"] / data["phii"]
        result["TP_P"] = (g["eta"] * a["cP"] * np.cos(g["thetaP"])) / (a["eta"] * g["cP"] * np.cos(a["thetaP"])) * abs(result["tP_P"]) ** 2
        result["tSV_P"] = result["psi_t_P"] / data["phii"]
        result["TSV_P"] = (g["eta"] * a["cP"] * np.cos(g["thetaS"])) / (a["eta"] * g["cS"] * np.cos(a["thetaP"])) * abs(result["tSV_P"]) ** 2
        result["EP"] = result["RP_P"] + result["RSV_P"] + result["TP_P"] + result["TSV_P"]

    if abs(data["psii"]) < np.finfo(float).eps:
        result.update({"rP_SV": 0, "RP_SV": 0, "rSV_SV": 0, "RSV_SV": 0, "tP_SV": 0, "TP_SV": 0, "tSV_SV": 0, "TSV_SV": 0, "ESV": 0})
    else:
        result["rP_SV"] = result["phi_r_SV"] / data["psii"]
        result["RP_SV"] = (a["cS"] * np.cos(a["thetaP"])) / (a["cP"] * np.cos(a["thetaS"])) * abs(result["rP_SV"]) ** 2
        result["rSV_SV"] = result["psi_r_SV"] / data["psii"]
        result["RSV_SV"] = abs(result["rSV_SV"]) ** 2
        result["tP_SV"] = result["phi_t_SV"] / data["psii"]
        result["TP_SV"] = (g["eta"] * a["cS"] * np.cos(g["thetaP"])) / (a["eta"] * g["cP"] * np.cos(a["thetaS"])) * abs(result["tP_SV"]) ** 2
        result["tSV_SV"] = result["psi_t_SV"] / data["psii"]
        result["TSV_SV"] = (g["eta"] * a["cS"] * np.cos(g["thetaS"])) / (a["eta"] * g["cS"] * np.cos(a["thetaS"])) * abs(result["tSV_SV"]) ** 2
        result["ESV"] = result["RP_SV"] + result["RSV_SV"] + result["TP_SV"] + result["TSV_SV"]

    den_sh = a["zeta"] * np.cos(a["thetaS"]) * (Psh[0, 0] + Psh[0, 1] * g["zeta"] * np.cos(g["thetaS"])) + (
        Psh[1, 0] + Psh[1, 1] * g["zeta"] * np.cos(g["thetaS"])
    )
    num_sh = a["zeta"] * np.cos(a["thetaS"]) * (Psh[0, 0] + Psh[0, 1] * g["zeta"] * np.cos(g["thetaS"])) - (
        Psh[1, 0] + Psh[1, 1] * g["zeta"] * np.cos(g["thetaS"])
    )
    result["rSH"] = num_sh / den_sh
    result["RSH"] = abs(result["rSH"]) ** 2
    result["tSH"] = (a["kS"] / g["kS"]) * (2 * a["zeta"] * np.cos(a["thetaS"])) / den_sh
    result["TSH"] = (g["zeta"] * np.cos(g["thetaS"])) / (a["zeta"] * np.cos(a["thetaS"])) * abs((g["kS"] / a["kS"]) * result["tSH"]) ** 2
    result["ESH"] = result["RSH"] + result["TSH"]
    return clean_tree(result)
