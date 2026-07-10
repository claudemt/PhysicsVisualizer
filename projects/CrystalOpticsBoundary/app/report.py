from __future__ import annotations

import numpy as np


def _fmt(value: complex | float) -> str:
    if abs(value) < 1e-10:
        return "0"
    if abs(np.imag(value)) < 1e-10:
        return f"{float(np.real(value)):.5f}"
    sign = "+" if np.imag(value) >= 0 else ""
    return f"{np.real(value):.5f}{sign}{np.imag(value):.5f}i"


def _vec(value) -> str:
    arr = np.asarray(value).ravel()
    return "[" + ", ".join(_fmt(v) for v in arr) + "]"


def _dir(value) -> str:
    arr = np.asarray(value).ravel()
    if np.all(np.isfinite(arr)) and np.linalg.norm(arr) > 0:
        return _vec(arr)
    return "elliptical"


def render_crystal_report(result: dict[str, object]) -> str:
    common = result["common"]
    single = result["single"]
    lines: list[str] = []
    add = lines.append

    add("")
    add("==============================================================================")
    add("                    CRYSTAL BOUNDARY OPTICS RESULTS")
    add("==============================================================================")
    add("")
    add("--- Crystal ---")
    add(f"type            : {common['crystal_type']}")
    add(f"eps_principal   : {_vec(common['eps_principal'])}")
    add("principal_axes_lab:")
    for row in np.asarray(common["principal_axes_lab"]):
        add(f"  {_vec(row)}")
    optic_axes = np.asarray(common["optic_axes_lab"])
    if optic_axes.size:
        add("optic_axes_lab:")
        for row in np.atleast_2d(optic_axes):
            add(f"  {_vec(row)}")

    add("")
    add("--- Incident Geometry ---")
    add(f"k_inc_hat       : {_vec(common['k_inc_hat'])}")
    add(f"q_inc           : {_vec(common['q_inc'])}")
    add(f"sHat            : {_vec(common['sHat'])}")
    add(f"pHatInc         : {_vec(common['pHatInc'])}")
    add(f"pHatRef         : {_vec(common['pHatRef'])}")

    inc = single["incident"]
    ref = single["reflection"]
    add("")
    add("--- Incident Wave ---")
    add(f"n_inc           : {_fmt(common['n_inc'])}")
    add(f"E_inc direction : {_dir(inc['E_linear_dir'])}")
    add(f"S_inc direction : {_vec(inc['S_hat'])}")
    add(f"|S_inc|         : {_fmt(np.linalg.norm(inc['S']))}")
    add(f"P_inc,z         : {_fmt(inc['power_z_in'])}")

    add("")
    add("--- Reflected Wave ---")
    add(f"q_ref hat       : {_vec(ref['q_hat'])}")
    add(f"Jones [r_s;r_p] : [{_fmt(ref['jones_sp'][0])}, {_fmt(ref['jones_sp'][1])}]")
    add(f"E_ref direction : {_dir(ref['E_linear_dir'])}")
    add(f"S_ref direction : {_vec(ref['S_hat'])}")
    add(f"|S_ref|         : {_fmt(np.linalg.norm(ref['S']))}")
    add(f"R               : {_fmt(ref['power_ratio'])}")
    add(f"|S_ref|/|S_inc| : {_fmt(np.linalg.norm(ref['S']) / max(np.linalg.norm(inc['S']), 1e-14))}")

    add("")
    add("--- Transmitted Wave(s) ---")
    transmission = single["transmission"]
    branches = transmission["branch"]
    if isinstance(branches, dict):
        branches = [branches]
        add("Degenerate branch:")
    for index, branch in enumerate(branches, start=1):
        if len(branches) > 1:
            add(f"Branch {index}:")
        add(f"q               : {_vec(branch['q'])}")
        add(f"E direction     : {_dir(branch['E_linear_dir'])}")
        add(f"S direction     : {_vec(branch['S_hat']) if np.all(np.isfinite(branch['S_hat'])) else 'evanescent'}")
        add(f"|S|/|S_inc|     : {_fmt(np.linalg.norm(branch['S']) / max(np.linalg.norm(inc['S']), 1e-14))}")
        add(f"power ratio     : {_fmt(branch['power_ratio'])}")

    energy = single["energy"]
    add("")
    add("--- Energy Balance ---")
    add(f"R               : {_fmt(energy['R'])}")
    add(f"T_total         : {_fmt(energy['T_total'])}")
    add(f"R + T - 1       : {_fmt(energy['balance'])}")
    if result.get("case_type") == "sweep" and "sweep" in result:
        add("")
        add("--- Polarization Sweep ---")
        alpha = np.asarray(result["sweep"].get("alpha_deg", []), dtype=float)
        samples = result["sweep"].get("sample", [])
        add(f"samples         : {len(samples)}")
        if alpha.size:
            add(f"alpha_deg       : {_vec(alpha)}")
        for index, sample in enumerate(samples, start=1):
            sample_energy = sample["energy"]
            label = _fmt(alpha[index - 1]) if index - 1 < alpha.size else str(index)
            add(
                f"  alpha={label}: R={_fmt(sample_energy['R'])}, "
                f"T_total={_fmt(sample_energy['T_total'])}, "
                f"R+T-1={_fmt(sample_energy['balance'])}"
            )
    add("==============================================================================")
    add("")
    return "\n".join(lines) + "\n\n"
