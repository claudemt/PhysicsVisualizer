from __future__ import annotations

from dataclasses import dataclass

import numpy as np
from scipy import integrate

from .kinematics import euler313_to_quat, normalize_quat_array, omega_matrix, quat_to_rotm, rotation_map, rotm_to_quat, axis_angle
from .presets import FIXED_PRESETS, FREE_PRESETS, fixed_compare_rows, free_compare_rows


@dataclass
class RigidResult:
    mode: str
    t: np.ndarray
    w_body: np.ndarray
    w_lab: np.ndarray
    l_body: np.ndarray
    axis_tips: np.ndarray
    energy: np.ndarray
    lmag: np.ndarray


@dataclass
class RigidCompareResult:
    mode: str
    base_mode: str
    cases: list[RigidResult]
    labels: list[str]
    legend_2d: str = "northeast"
    legend_3d: str = "northeast"


def parse_vector(value: object, n: int, default: tuple[float, ...] | None = None, name: str = "vector") -> np.ndarray:
    if value is None:
        if default is None:
            raise ValueError(f"{name} requires {n} finite numbers")
        return np.array(default, dtype=float)
    text = str(value).strip().strip("[]")
    try:
        parts = [float(part) for part in text.replace(",", " ").split()]
    except ValueError as exc:
        raise ValueError(f"Invalid vector for {name}; expected {n} finite numbers") from exc
    if len(parts) != n or not np.all(np.isfinite(parts)):
        raise ValueError(f"Invalid vector for {name}; expected {n} finite numbers")
    return np.array(parts, dtype=float)


def _mode(value: object) -> str:
    text = str(value or "free rotation").strip().casefold()
    if text in {"free", "free rotation"}:
        return "free"
    if text in {"fixed", "fixed point"}:
        return "fixed"
    raise ValueError("mode must be 'free rotation' or 'fixed point'")


def _as_bool(value: object) -> bool:
    if isinstance(value, str):
        return value.strip().casefold() in {"1", "true", "yes", "on"}
    return bool(value)


def _finite_scalar(value: object, name: str) -> float:
    try:
        result = float(value)
    except (TypeError, ValueError) as exc:
        raise ValueError(f"Invalid scalar for {name}") from exc
    if not np.isfinite(result):
        raise ValueError(f"Invalid scalar for {name}")
    return result


def _preset(params: dict, mode: str) -> dict:
    choices = FREE_PRESETS if mode == "free" else FIXED_PRESETS
    key = "free_preset" if mode == "free" else "fixed_preset"
    selected = str(params.get(key, next(iter(choices)))).strip().casefold()
    return next((dict(values) for name, values in choices.items() if name.casefold() == selected), dict(next(iter(choices.values()))))


def _input_value(params: dict, preset: dict, key: str, *aliases: str):
    for candidate in (key, *aliases):
        if candidate not in params:
            continue
        value = params[candidate]
        if value is not None and (not isinstance(value, str) or value.strip()):
            return value
    return preset[key]


def default_input(params: dict) -> dict:
    mode = _mode(params.get("mode", "free rotation"))
    preset = _preset(params, mode)
    compare = _as_bool(params.get("compare", False))
    if mode == "fixed":
        data = {
            "mode": "fixed",
            "I": parse_vector(_input_value(params, preset, "I"), 3, name="I"),
            "aBody": parse_vector(_input_value(params, preset, "aBody"), 3, name="aBody"),
            "mass": _finite_scalar(_input_value(params, preset, "mass"), "mass"),
            "g": _finite_scalar(_input_value(params, preset, "g"), "g"),
            "euler0": parse_vector(_input_value(params, preset, "Euler0", "euler0"), 3, name="Euler0"),
            "w0": parse_vector(_input_value(params, preset, "w0"), 3, name="w0"),
            "tEnd": _finite_scalar(_input_value(params, preset, "tEnd"), "tEnd"),
            "nSamples": int(round(_finite_scalar(_input_value(params, preset, "nSamples"), "nSamples"))),
        }
    else:
        data = {
            "mode": "free",
            "I": parse_vector(_input_value(params, preset, "I"), 3, name="I"),
            "w0": parse_vector(_input_value(params, preset, "w0"), 3, name="w0"),
            "phi0": _finite_scalar(_input_value(params, preset, "phi0"), "phi0"),
            "tEnd": _finite_scalar(_input_value(params, preset, "tEnd"), "tEnd"),
            "nSamples": int(round(_finite_scalar(_input_value(params, preset, "nSamples"), "nSamples"))),
        }
    if np.any(data["I"] <= 0):
        raise ValueError("I must contain positive principal moments")
    if data["tEnd"] <= 0:
        raise ValueError("tEnd must be positive")
    if data["nSamples"] < 200:
        raise ValueError("nSamples must be at least 200")
    if mode == "fixed" and (data["mass"] <= 0 or data["g"] < 0):
        raise ValueError("mass must be positive and g must be non-negative")
    data["legend_2d"] = str(params.get("legend_2d", "northeast"))
    data["legend_3d"] = str(params.get("legend_3d", "northeast"))
    if compare:
        data["compare"] = True
        rows = str(params.get("compare_rows", "")).strip()
        data["compare_rows"] = rows or (
            free_compare_rows(data["w0"], data["phi0"])
            if mode == "free"
            else fixed_compare_rows(data["euler0"], data["w0"])
        )
    return data


def solve(input_data: dict) -> RigidResult:
    if input_data.get("compare"):
        return solve_compare(input_data)
    if input_data["mode"] == "fixed":
        return solve_fixed(input_data)
    return solve_free(input_data)


def parse_compare_rows(text: str, mode: str) -> list[dict]:
    cases: list[dict] = []
    for line_number, raw in enumerate(str(text).replace("\r", "").replace(";", "\n").splitlines(), start=1):
        line = raw.strip()
        if not line:
            continue
        if "|" in line:
            left, right = [part.strip() for part in line.split("|", 1)]
            if mode == "free":
                # Accept the early Python-port syntax while emitting/parsing legacy rows.
                parse_vector(left, 3, name=f"compare row {line_number}")
                cases.append({"w0": parse_vector(right, 3, name=f"compare row {line_number}"), "phi0": 0.0})
            else:
                cases.append({"euler0": parse_vector(left, 3, name=f"compare row {line_number}"), "w0": parse_vector(right, 3, name=f"compare row {line_number}")})
        else:
            try:
                nums = [float(part) for part in line.strip("[]").replace(",", " ").split()]
            except ValueError as exc:
                raise ValueError(f"Invalid comparison row {line_number}") from exc
            expected = 4 if mode == "free" else 6
            if len(nums) != expected or not np.all(np.isfinite(nums)):
                label = "[w1 w2 w3 phi0]" if mode == "free" else "[phi theta psi w1 w2 w3]"
                raise ValueError(f"Invalid comparison row {line_number}; expected {label}")
            if mode == "free":
                cases.append({"w0": np.array(nums[:3]), "phi0": nums[3]})
            else:
                cases.append({"euler0": np.array(nums[:3]), "w0": np.array(nums[3:])})
    if not cases:
        raise ValueError("At least one comparison row is required")
    if len(cases) > 5:
        raise ValueError("At most five comparison rows are allowed")
    return cases


def solve_compare(input_data: dict) -> RigidCompareResult:
    mode = str(input_data["mode"])
    rows = parse_compare_rows(str(input_data.get("compare_rows", "")), mode)
    results: list[RigidResult] = []
    labels: list[str] = []
    for idx, row in enumerate(rows, start=1):
        data = dict(input_data)
        data.pop("compare", None)
        data.pop("compare_rows", None)
        data.update(row)
        results.append(solve_fixed(data) if mode == "fixed" else solve_free(data))
        labels.append(f"p.{idx}")
    return RigidCompareResult(
        mode=f"{mode}_multi",
        base_mode=mode,
        cases=results,
        labels=labels,
        legend_2d=str(input_data.get("legend_2d", "northeast")),
        legend_3d=str(input_data.get("legend_3d", "northeast")),
    )


def solve_free(input_data: dict) -> RigidResult:
    I = np.asarray(input_data["I"], dtype=float)
    Ib = np.diag(I)
    w0 = np.asarray(input_data["w0"], dtype=float)
    L0 = Ib @ w0
    Lmag = max(np.linalg.norm(L0), 1e-12)
    Ralign = rotation_map(L0 / Lmag, np.array([0, 0, 1.0]))
    R0 = axis_angle([0, 0, 1], float(input_data.get("phi0", 0))) @ Ralign
    q0 = rotm_to_quat(R0)
    return _integrate(input_data, np.r_[w0, q0], lambda _t, wb, _q: np.array([
        ((I[1] - I[2]) / I[0]) * wb[1] * wb[2],
        ((I[2] - I[0]) / I[1]) * wb[2] * wb[0],
        ((I[0] - I[1]) / I[2]) * wb[0] * wb[1],
    ]), gravity=None)


def solve_fixed(input_data: dict) -> RigidResult:
    I = np.asarray(input_data["I"], dtype=float)
    Ib = np.diag(I)
    invIb = np.diag(1 / I)
    a_body = np.asarray(input_data["aBody"], dtype=float)
    mass = float(input_data["mass"])
    grav = float(input_data["g"])
    q0 = euler313_to_quat(input_data["euler0"])
    y0 = np.r_[np.asarray(input_data["w0"], dtype=float), q0]

    def torque_rhs(_t, wb, q):
        R = quat_to_rotm(q)
        F_body = R.T @ np.array([0, 0, -mass * grav])
        tau = np.cross(a_body, F_body)
        return invIb @ (tau - np.cross(wb, Ib @ wb))

    return _integrate(input_data, y0, torque_rhs, gravity=(mass, grav, a_body))


def _integrate(input_data, y0, rhs_w, gravity):
    I = np.asarray(input_data["I"], dtype=float)
    Ib = np.diag(I)
    t_eval = np.linspace(0, float(input_data["tEnd"]), int(input_data["nSamples"]))

    def rhs(t, y):
        wb = y[:3]
        q = y[3:7]
        return np.r_[rhs_w(t, wb, q), 0.5 * omega_matrix(wb) @ q]

    sol = integrate.solve_ivp(
        rhs, (t_eval[0], t_eval[-1]), y0, t_eval=t_eval,
        method="DOP853", rtol=1e-9, atol=1e-10,
        max_step=max(t_eval[-1] / 500, 1e-3),
    )
    Wb = sol.y[:3].T
    Q = normalize_quat_array(sol.y[3:7].T)
    n = len(sol.t)
    Wlab = np.zeros((n, 3))
    Lb = np.zeros((n, 3))
    tips = np.zeros((n, 3, 3))
    zcom = np.zeros(n)
    for idx in range(n):
        R = quat_to_rotm(Q[idx])
        wb = Wb[idx]
        lb = Ib @ wb
        Wlab[idx] = R @ wb
        Lb[idx] = lb
        tips[idx, :, 0] = R[:, 0]
        tips[idx, :, 1] = R[:, 1]
        tips[idx, :, 2] = R[:, 2]
        if gravity is not None:
            zcom[idx] = (R @ gravity[2])[2]
    energy = 0.5 * np.sum(Wb * (Wb @ Ib), axis=1)
    mode = str(input_data["mode"])
    if gravity is not None:
        energy = energy + gravity[0] * gravity[1] * zcom
    return RigidResult(mode=mode, t=sol.t, w_body=Wb, w_lab=Wlab, l_body=Lb, axis_tips=tips, energy=energy, lmag=np.linalg.norm(Lb, axis=1))
