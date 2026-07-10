from __future__ import annotations

import numpy as np

from .formula import moving_charge_formula


FIELD_LABELS = {
    "E_in": "electric in-plane field",
    "E_n": "electric normal field",
    "E_mag": "electric field magnitude",
    "B_in": "magnetic in-plane field",
    "B_n": "magnetic normal field",
    "B_mag": "magnetic field magnitude",
    "S_stream": "Poynting streamlines",
    "tau": "retardation time",
    "E_stream": "electric streamlines",
    "B_stream": "magnetic streamlines",
}


def slice_metadata(slice_type: str) -> tuple[str, str, str, str]:
    """Return the plotted axes plus the physical plane and normal component."""
    if slice_type == "xz":
        return "$x/\\lambda$", "$z/\\lambda$", "xz", "y"
    if slice_type == "yz":
        return "$y/\\lambda$", "$z/\\lambda$", "yz", "x"
    return "$x/\\lambda$", "$y/\\lambda$", "xy", "z"


def field_text(field: str, slice_type: str) -> tuple[str, str]:
    """MATLAB-equivalent title core and colorbar label for a selected field."""
    _, _, plane, normal = slice_metadata(slice_type)
    if field in {"E_in", "E_stream"}:
        return f"$E_{{{plane}}}$", f"$|E_{{{plane}}}|$"
    if field == "E_n":
        return f"$E_{{{normal}}}$", f"$E_{{{normal}}}$"
    if field == "E_mag":
        return "$E$", "$|E|$"
    if field in {"B_in", "B_stream"}:
        return f"$B_{{{plane}}}$", f"$|B_{{{plane}}}|$"
    if field == "B_n":
        return f"$B_{{{normal}}}$", f"$B_{{{normal}}}$"
    if field == "B_mag":
        return "$B$", "$|B|$"
    if field == "S_stream":
        return f"$S_{{{plane}}}$", f"$|S_{{{plane}}}|$"
    return "$\\tau$", "$\\tau=t-t_r$"


def selected_fields(value: object) -> list[str]:
    if value is None:
        return ["E_mag", "B_mag", "E_stream", "S_stream"]
    if isinstance(value, (list, tuple, set)):
        fields = [str(part).strip() for part in value if str(part).strip()]
    else:
        fields = [part.strip() for part in str(value).replace(";", ",").split(",") if part.strip()]
    return [field for field in fields if field in FIELD_LABELS] or ["E_mag"]


def make_slice_grid(n: int, span: float, slice_type: str, pos: float):
    u = np.linspace(-span, span, int(n))
    v = np.linspace(-span, span, int(n))
    U, V = np.meshgrid(u, v)
    if slice_type == "xz":
        return u, v, U, np.full_like(U, pos), V
    if slice_type == "yz":
        return u, v, np.full_like(U, pos), U, V
    return u, v, U, V, np.full_like(U, pos)


def plane_components(block: dict, slice_type: str, prefix: str):
    Fx, Fy, Fz = block[f"{prefix}x"], block[f"{prefix}y"], block[f"{prefix}z"]
    if slice_type == "xz":
        return Fx, Fz, Fy
    if slice_type == "yz":
        return Fy, Fz, Fx
    return Fx, Fy, Fz


def compute_payload(params: dict) -> dict:
    a_over_lambda = float(params.get("a_over_lambda", 1.2))
    beta = float(params.get("beta", params.get("beta_max", 0.6)))
    a = a_over_lambda
    omega = beta / max(a, 1e-9)
    phase = float(params.get("phase", params.get("phase_over_T", 0.0)))
    t_obs = phase * 2 * np.pi / omega
    slice_type = str(params.get("slice", params.get("sliceType", "xy"))).lower()
    pos = float(params.get("slice_position", params.get("slicePos_over_lambda", 0.0)))
    span = max(2.5, 2.4 * a_over_lambda + abs(pos) + 0.5)
    u, v, X, Y, Z = make_slice_grid(int(params.get("resolution", 180)), span, slice_type, pos)
    motion = str(params.get("motion", params.get("motionType", "circular")))
    data, rq_now = moving_charge_formula(X, Y, Z, t_obs, motion, a, omega)
    return {
        "u": u, "v": v, "X": X, "Y": Y, "Z": Z,
        "data": data, "rq_now": rq_now, "slice": slice_type,
        "t_obs": t_obs, "a_over_lambda": a_over_lambda,
    }


def field_payload(payload: dict, field: str, part: str):
    block = payload["data"][part]
    Eu, Ev, En = plane_components(block, payload["slice"], "E")
    Bu, Bv, Bn = plane_components(block, payload["slice"], "B")
    Emag = np.sqrt(block["Ex"] ** 2 + block["Ey"] ** 2 + block["Ez"] ** 2)
    Bmag = np.sqrt(block["Bx"] ** 2 + block["By"] ** 2 + block["Bz"] ** 2)
    Sx = block["Ey"] * block["Bz"] - block["Ez"] * block["By"]
    Sy = block["Ez"] * block["Bx"] - block["Ex"] * block["Bz"]
    Sz = block["Ex"] * block["By"] - block["Ey"] * block["Bx"]
    Su, Sv, _ = plane_components({"Sx": Sx, "Sy": Sy, "Sz": Sz}, payload["slice"], "S")
    rad = payload["data"]["rad"]
    Srx = rad["Ey"] * rad["Bz"] - rad["Ez"] * rad["By"]
    Sry = rad["Ez"] * rad["Bx"] - rad["Ex"] * rad["Bz"]
    Srz = rad["Ex"] * rad["By"] - rad["Ey"] * rad["Bx"]
    Sru, Srv, _ = plane_components({"Sx": Srx, "Sy": Sry, "Sz": Srz}, payload["slice"], "S")
    _, label = field_text(field, payload["slice"])
    if field == "E_in":
        return np.hypot(Eu, Ev), None, None, label, False
    if field == "E_n":
        return En, None, None, label, True
    if field == "E_mag":
        return Emag, None, None, label, False
    if field == "B_in":
        return np.hypot(Bu, Bv), None, None, label, False
    if field == "B_n":
        return Bn, None, None, label, True
    if field == "B_mag":
        return Bmag, None, None, label, False
    if field == "S_stream":
        return np.hypot(Sru, Srv), Sru, Srv, label, False
    if field == "tau":
        return payload["t_obs"] - payload["data"]["tr"], None, None, label, False
    if field == "E_stream":
        return np.hypot(Eu, Ev), Eu, Ev, label, False
    if field == "B_stream":
        return np.hypot(Bu, Bv), Bu, Bv, label, False
    raise ValueError(f"Unknown field: {field}")


def process_display_field(values: np.ndarray, signed: bool) -> np.ndarray:
    """Apply the legacy log display mapping without changing physical data."""
    display = np.real(np.asarray(values, dtype=float)).copy()
    display[~np.isfinite(display)] = np.nan
    if not signed:
        display[display < 0] = 0.0
    magnitudes = np.abs(display) if signed else display
    finite = np.sort(magnitudes[np.isfinite(magnitudes)])
    if finite.size == 0:
        return display
    index = max(0, min(finite.size - 1, int(np.floor(0.998 * finite.size + 0.5)) - 1))
    reference = finite[index]
    if not np.isfinite(reference) or reference <= 0:
        reference = finite[-1]
    if not np.isfinite(reference) or reference <= 0:
        return display
    scaled = np.log1p(40.0 * np.minimum(magnitudes, reference) / reference) / np.log1p(40.0)
    return np.sign(display) * scaled if signed else scaled
