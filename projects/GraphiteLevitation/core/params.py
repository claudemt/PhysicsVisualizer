from __future__ import annotations

from dataclasses import dataclass
from dataclasses import replace
from itertools import product
import re

import numpy as np


@dataclass
class GraphiteParams:
    shape: str = "circle"
    radius: float = 6.0e-3
    side: float = 10.0e-3
    rotation_deg: float = 0.0
    thickness: float = 40e-6
    z0: float = 1.05e-3
    chi_abs: float = 3.05e-4
    rho: float = 2200.0
    array_nx: int = 6
    array_ny: int = 6
    magnet_a: float = 10e-3
    magnet_b: float = 10e-3
    magnet_c: float = 10e-3
    br: float = 1.46
    laser_enabled: bool = True
    spot_x: float = 3e-3
    spot_y: float = 0.0
    laser_alpha: float = 0.35
    spot_diameter: float = 3e-3
    grid_n: int = 160
    chi_grid_n: int = 180
    force_kernel_n: int = 55
    force_dz: float = 0.035e-3
    torsional_stiffness: float = 3.0e-6
    mu0: float = 4 * np.pi * 1e-7


def _numbers(value: object, default: tuple[float, ...]) -> list[float]:
    if isinstance(value, (list, tuple, np.ndarray)):
        try:
            parts = [float(item) for item in np.asarray(value).ravel()]
            return parts or list(default)
        except (TypeError, ValueError):
            return list(default)
    raw = str(value).strip()
    try:
        match = re.fullmatch(r"linspace\s*\(\s*([^,]+),\s*([^,]+),\s*([^,]+)\s*\)", raw, re.I)
        if match:
            start, stop, count = (float(part) for part in match.groups())
            return np.linspace(start, stop, max(1, int(round(count)))).tolist()
        if len(raw) >= 2 and (raw[0], raw[-1]) in {("(", ")"), ("[", "]")}:
            raw = raw[1:-1].strip()
        if ":" in raw and not re.search(r"[,;\s]", raw):
            pieces = [float(part) for part in raw.split(":")]
            if len(pieces) in {2, 3}:
                start, step, stop = (pieces[0], 1.0, pieces[1]) if len(pieces) == 2 else pieces
                if step == 0:
                    return list(default)
                count = int(np.floor((stop - start) / step + 1e-12)) + 1
                return (start + step * np.arange(max(0, count))).tolist() or list(default)
        parts = [float(p) for p in re.split(r"[,;\s*]+", raw) if p]
        return parts or list(default)
    except (TypeError, ValueError):
        return list(default)


def normalize_params(params: dict) -> GraphiteParams:
    d_mm = _numbers(params.get("d", 6), (6,))[0]
    w_um = _numbers(params.get("W_um", 40), (40,))[0]
    array = _numbers(params.get("array_size", "6 6"), (6, 6))
    magnet = _numbers(params.get("magnet_size_mm", "10 10 10"), (10, 10, 10))
    spot = _numbers(params.get("spot_mm", "3 0"), (3, 0))
    shape = str(params.get("shape", "circle")).lower()
    return GraphiteParams(
        shape="square" if shape in {"square", "rectangle"} else "circle",
        radius=d_mm * 1e-3,
        side=d_mm * 1e-3,
        rotation_deg=float(params.get("rotation_deg", 0)),
        thickness=w_um * 1e-6,
        chi_abs=_chi_si(_numbers(params.get("chi", 3.05), (3.05,))[0]),
        array_nx=max(1, int(array[0])),
        array_ny=max(1, int(array[1] if len(array) > 1 else array[0])),
        magnet_a=magnet[0] * 1e-3,
        magnet_b=(magnet[1] if len(magnet) > 1 else magnet[0]) * 1e-3,
        magnet_c=(magnet[2] if len(magnet) > 2 else magnet[0]) * 1e-3,
        br=float(params.get("Br", 1.46)),
        laser_enabled=_numbers(params.get("P", 0.35), (0.35,))[0] != 0,
        spot_x=spot[0] * 1e-3,
        spot_y=(spot[1] if len(spot) > 1 else 0) * 1e-3,
        laser_alpha=_numbers(params.get("P", 0.35), (0.35,))[0],
        grid_n=int(params.get("resolution", params.get("gridN", 160))),
    )


def _chi_si(value: float) -> float:
    """Accept MATLAB GUI units (1e-4) and legacy Python SI values."""
    return abs(value) if abs(value) < 0.01 else abs(value) * 1e-4


def normalize_scan_params(params: dict) -> list[tuple[GraphiteParams, str, str]]:
    """Expand MATLAB-compatible d/W/chi/P inputs as a Cartesian product."""
    base = normalize_params(params)
    values = {
        "d": _numbers(params.get("d", 6), (6,)),
        "W": _numbers(params.get("W_um", 40), (40,)),
        "chi": _numbers(params.get("chi", 3.05), (3.05,)),
        "P": _numbers(params.get("P", 0.35), (0.35,)),
    }
    scanned = [key for key, items in values.items() if len(items) > 1]
    cases: list[tuple[GraphiteParams, str, str]] = []
    for d_mm, w_um, chi, laser_p in product(values["d"], values["W"], values["chi"], values["P"]):
        radius = d_mm * 1e-3 if base.shape == "circle" else base.radius
        side = d_mm * 1e-3 if base.shape == "square" else base.side
        case = replace(
            base,
            radius=radius,
            side=side,
            thickness=w_um * 1e-6,
            chi_abs=_chi_si(chi),
            laser_enabled=laser_p > 0,
            laser_alpha=laser_p,
        )
        raw = {"d": d_mm, "W": w_um, "chi": chi, "P": laser_p}
        label = ", ".join(f"{key}={raw[key]:.12g}" for key in scanned) or "single run"
        suffix = "_" + "_".join(f"{key}{raw[key]:.12g}" for key in scanned) if scanned else ""
        cases.append((case, label, suffix))
    return cases
