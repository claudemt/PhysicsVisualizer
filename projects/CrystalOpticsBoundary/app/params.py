from __future__ import annotations

import re
from typing import Iterable

import numpy as np


def parse_vector(value: object, default: Iterable[float], length: int = 3) -> np.ndarray:
    if value is None or str(value).strip() == "":
        data = list(default)
    elif isinstance(value, np.ndarray):
        data = value.astype(float).ravel().tolist()
    elif isinstance(value, (list, tuple)):
        data = [float(v) for v in value]
    else:
        text = str(value).replace(";", " ").replace(",", " ")
        data = [float(part) for part in text.split()]
    if len(data) != length:
        raise ValueError(f"Expected {length} values, got {len(data)}.")
    return np.asarray(data, dtype=float)


def parse_number_list(value: object) -> np.ndarray:
    if value is None:
        return np.empty(0, dtype=float)
    if isinstance(value, np.ndarray):
        return value.astype(float).ravel()
    if isinstance(value, (list, tuple)):
        return np.asarray(value, dtype=float).ravel()
    text = str(value).strip().replace(";", " ").replace(",", " ")
    if not text:
        return np.empty(0, dtype=float)
    return np.asarray([float(part) for part in text.split()], dtype=float)


def parse_matrix(value: object, default: Iterable[Iterable[float]], shape: tuple[int, int] = (3, 3)) -> np.ndarray:
    if value is None or str(value).strip() == "":
        matrix = np.asarray(default, dtype=float)
    elif isinstance(value, np.ndarray):
        matrix = value.astype(float)
    else:
        rows = [row for row in re.split(r"[\n;]+", str(value).strip()) if row.strip()]
        matrix = np.asarray([[float(part) for part in row.replace(",", " ").split()] for row in rows], dtype=float)
    if matrix.shape != shape:
        raise ValueError(f"Expected matrix shape {shape}, got {matrix.shape}.")
    return matrix


def params_to_config(params: dict[str, object]) -> dict[str, object]:
    material_input = str(params.get("material_input", "principal + orientation")).lower()
    eps_diag = parse_vector(params.get("eps_diag"), [2.25, 2.56, 3.24])
    cfg: dict[str, object] = {
        "n_inc": float(params.get("n_incident", params.get("n_inc", 1.0))),
        "k_inc": parse_vector(params.get("k_inc"), [0.60, 0.64, -0.48]),
        "pol": {
            "type": params.get("pol_type", params.get("polarization_type", "angle")),
            "angle_deg": float(params.get("alpha_deg", 0.0)),
            "vector": parse_vector(params.get("pol_vector"), [1.0, 0.0, 0.0]),
            "num_samples": int(params.get("num_samples", 181)),
        },
        "orientation": {
            "mode": str(params.get("orientation", "none")),
            "optic_axis": parse_vector(params.get("optic_axis"), [0.0, 0.0, 1.0]),
            "euler_deg": parse_vector(params.get("euler_zyx"), [0.0, 0.0, 0.0]),
        },
        "eps_diag": eps_diag,
    }
    if str(cfg["orientation"]["mode"]).lower().strip() == "matrix":
        cfg["orientation"]["R"] = parse_matrix(
            params.get("orientation_R", params.get("orientation.R")),
            np.eye(3),
        )
    angle_list = parse_number_list(params.get("angle_list_deg"))
    if angle_list.size:
        cfg["pol"]["angle_list_deg"] = angle_list
    if material_input.startswith("direct"):
        cfg["eps_lab"] = parse_matrix(params.get("eps_lab"), np.diag(eps_diag))
    return cfg
