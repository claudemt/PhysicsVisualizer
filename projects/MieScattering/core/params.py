from __future__ import annotations

import ast
import re


FIELD_LABELS = {
    "sca Re Ex": "sca_rex",
    "sca Re Ey": "sca_rey",
    "sca Re Ez": "sca_rez",
    "sca |Ex|": "sca_aex",
    "sca |Ey|": "sca_aey",
    "sca |Ez|": "sca_aez",
    "sca Emag": "sca_emag",
    "tot Re Ex": "tot_rex",
    "tot Re Ey": "tot_rey",
    "tot Re Ez": "tot_rez",
    "tot |Ex|": "tot_aex",
    "tot |Ey|": "tot_aey",
    "tot |Ez|": "tot_aez",
    "tot Emag": "tot_emag",
}


def parse_complex(value: object, default: complex = 1 + 0j) -> complex:
    if isinstance(value, complex):
        return value
    if isinstance(value, (int, float)):
        return complex(value)
    text = str(value).strip().lower().replace("i", "j")
    text = re.sub(r"(?<=\d)j", "j", text)
    try:
        parsed = ast.literal_eval(text)
    except Exception as exc:  # noqa: BLE001
        raise ValueError(f"Could not parse complex scalar: {value!r}") from exc
    try:
        return complex(parsed)
    except Exception as exc:  # noqa: BLE001
        raise ValueError(f"Could not parse complex scalar: {value!r}") from exc


def selected_field_codes(value: object) -> list[str]:
    if value is None:
        return ["sca_rex", "sca_rey", "sca_rez", "sca_aex", "sca_aey", "sca_aez", "sca_emag"]
    if isinstance(value, (list, tuple, set)):
        pieces = [str(item) for item in value]
    else:
        pieces = str(value).replace(";", ",").split(",")
    codes: list[str] = []
    reverse = {v: v for v in FIELD_LABELS.values()}
    reverse.update(FIELD_LABELS)
    for item in pieces:
        label = item.strip()
        if not label:
            continue
        label = label.strip("'\"[]() ")
        code = reverse.get(label, label.lower().replace(" ", "_").replace("|", "a"))
        if code in FIELD_LABELS.values() and code not in codes:
            codes.append(code)
    return codes or ["sca_emag"]


def normalize_params(params: dict) -> dict:
    geometry = str(params.get("geometry", "sphere")).lower()
    slice_type = str(params.get("slice", params.get("sliceType", "xz" if geometry == "sphere" else "xy"))).lower()
    return {
        "eps1": parse_complex(params.get("epsilon_r", params.get("eps1", "2+0.1i"))),
        "mu1": parse_complex(params.get("mu_r", params.get("mu1", "0.8+0.05i"))),
        "radius": float(params.get("radius", params.get("R_over_lambda", 0.5))),
        "nu": float(params.get("nu", 1.1)),
        "psi": float(params.get("psi", 0.2)),
        "geometry": "cylinder" if geometry.startswith("cyl") else "sphere",
        "slice": slice_type if slice_type in {"xy", "xz", "yz"} else "xz",
        "slice_position": float(params.get("slice_position", params.get("slicePos_over_lambda", 0.0))),
        "grid_half_width": float(params.get("gridHalfWidth", params.get("grid_half_width", 2.5))),
        "resolution": int(params.get("resolution", params.get("N", 260))),
        "nmax_extra": int(params.get("nmaxExtra", params.get("nmax_extra", 10))),
        "mask_inside": bool(params.get("mask_inside", params.get("maskInside", True))),
        "fields": selected_field_codes(params.get("fields", params.get("customSelection"))),
    }
