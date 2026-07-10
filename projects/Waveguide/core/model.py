from utils.render_result import report
from utils import render_result as rr

from .display import (
    cutoff_map_figure,
    cylindrical_dispersion_figure,
    field_figure,
    metal_dispersion_figure,
    planar_dispersion_figure,
    planar_existence_figure,
    planar_sweep_figure,
)
from .metal import (
    circular_cutoff_map,
    circular_metal_dispersion,
    circular_metal_field,
    rectangular_cutoff_map,
    rectangular_metal_dispersion,
    rectangular_metal_field,
)
from .planar import planar_dispersion, planar_existence, planar_field, planar_thickness_sweep
from .cylindrical import cylindrical_dielectric_dispersion, cylindrical_dielectric_field

TITLE = "Waveguide"
DESCRIPTION = "Metallic and dielectric waveguide modes, cutoff, and dispersion."
DEFAULTS = {"a": 0.03, "b": 0.015, "xi0": 0.5, "fmax_ghz": 10.0, "max_order": 5}
FORMULAS = "Metal and dielectric waveguide mode equations."


def _parse_int_ranges(text: object, cols: int) -> list[tuple[int, ...]]:
    value = str(text).strip() or "(1:3,0:3)"
    pieces = value.split(";") if ";" in value else [value]
    rows: list[tuple[int, ...]] = []
    for piece in pieces:
        piece = piece.strip().removeprefix("(").removesuffix(")")
        if not piece:
            continue
        dimensions: list[list[int]] = []
        for part in [p.strip() for p in piece.split(",") if p.strip()]:
            if ":" in part:
                lo, hi = [int(float(item)) for item in part.split(":", 1)]
                step = 1 if hi >= lo else -1
                dimensions.append(list(range(lo, hi + step, step)))
            else:
                dimensions.append([int(float(part))])
        if len(dimensions) != cols:
            continue
        product = [()]
        for dimension in dimensions:
            product = [prefix + (item,) for prefix in product for item in dimension]
        rows.extend(product)
    if not rows:
        raise ValueError(f"Could not parse {cols}-column integer tuples from {value!r}.")
    return rows


def _float(params: dict, key: str, default: float) -> float:
    return float(params.get(key, default))


def _int(params: dict, key: str, default: int) -> int:
    return int(float(params.get(key, default)))


def _render_metal(params: dict):
    action = str(params.get("action", "mode field")).lower()
    guide = str(params.get("guide", "rectangular")).lower()
    mode_type = str(params.get("polarization", params.get("mode_type", "TE"))).upper()
    a = _float(params, "a", 0.03)
    b = _float(params, "b", a * _float(params, "xi0", 0.5))
    xi0 = b / a if guide == "rectangular" else _float(params, "xi0", 0.5)
    max_order = _int(params, "max_order", 5)
    fmax_ghz = _float(params, "fmax_ghz", 10.0)
    figures = []
    if action == "mode field":
        mode_rows = _parse_int_ranges(params.get("modes", "(1:3,0:3)"), 2)
        if mode_type == "TEM":
            mode_rows = [(0, 0)]
        for index, (m, n) in enumerate(mode_rows, start=1):
            if guide == "rectangular" and ((mode_type == "TM" and (m == 0 or n == 0)) or (mode_type == "TE" and m == 0 and n == 0)):
                continue
            if guide in {"annulus", "annular", "circular"} and mode_type in {"TE", "TM"} and n < 1:
                continue
            if guide in {"annulus", "annular", "circular"}:
                radius = _float(params, "radius", 0.03)
                result = circular_metal_field(mode_type, m, n, radius, _int(params, "grid_n", 220), xi0 if guide != "circular" else 0.0)
            else:
                result = rectangular_metal_field(mode_type, m, n, a, xi0, _int(params, "grid_n", 220))
            figures.append(field_figure(result, f"{index:02d} {result['mode_label']}"))
    elif action in {"dispersion", "dispersion curves"}:
        if guide in {"annulus", "annular", "circular"}:
            radius = _float(params, "radius", 0.03)
            result = circular_metal_dispersion(
                mode_type,
                radius,
                max_order,
                0.0,
                fmax_ghz,
                _int(params, "samples", 420),
                xi0 if guide != "circular" else 0.0,
                guide,
            )
        else:
            result = rectangular_metal_dispersion(mode_type, a, b, max_order, 0.0, fmax_ghz, _int(params, "samples", 420))
        figures.append(metal_dispersion_figure(result))
    elif action == "cutoff map":
        if guide in {"annulus", "annular", "circular"}:
            radius = _float(params, "radius", 0.03)
            result = circular_cutoff_map(mode_type, radius, max_order, xi0 if guide != "circular" else 0.0, guide)
        else:
            result = rectangular_cutoff_map(mode_type, a, b, max_order)
        figures.append(cutoff_map_figure(result))
    else:
        raise ValueError(f"Unsupported metal guide action: {action}")
    return rr.RenderBundle("Waveguide metal guides", figures, report("Waveguide metal guides", [
        "Circular PEC modes use J_m/J_m' roots; annular PEC modes satisfy both conductor boundaries.",
        "The annular TEM branch has zero cutoff and a radial 1/r transverse electric field.",
    ]))


def _render_planar(params: dict):
    action = str(params.get("action", "mode field")).lower()
    mode_type = str(params.get("polarization", params.get("mode_type", "TE"))).upper()
    n1 = _float(params, "nco", _float(params, "n1", 1.50))
    n2 = _float(params, "ncl", _float(params, "n2", 1.45))
    d = _float(params, "d", 0.10)
    freq_ghz = _float(params, "frequency_ghz", _float(params, "freq_ghz", 4.0))
    max_order = _int(params, "max_order", 5)
    Vmax = _float(params, "vmax", 10.0)
    figures = []
    skipped: list[int] = []
    if action == "mode field":
        orders = [row[0] for row in _parse_int_ranges(params.get("orders", "(0:3)"), 1)]
        for index, order in enumerate(orders, start=1):
            try:
                result = planar_field(mode_type, order, freq_ghz, n1, n2, d, _float(params, "z_length", 8.0), _int(params, "grid_n", 220))
            except ValueError:
                skipped.append(order)
                continue
            figures.append(field_figure(result, f"{index:02d} {mode_type}_{order}"))
        if not figures:
            raise ValueError("None of the selected planar orders is guided at this frequency.")
    elif action in {"dispersion", "dispersion curve"}:
        figures.append(planar_dispersion_figure(planar_dispersion(mode_type, n1, n2, Vmax, max_order, _int(params, "samples", 260))))
    elif action in {"existence", "mode existence"}:
        figures.append(planar_existence_figure(planar_existence(mode_type, Vmax, max_order)))
    elif action == "thickness sweep":
        figures.append(planar_sweep_figure(planar_thickness_sweep(mode_type, n1, n2, d, freq_ghz, max_order, _int(params, "samples", 180))))
    else:
        raise ValueError(f"Unsupported planar action: {action}")
    lines = [
        "Symmetric slab eigenvalue equation uses the MATLAB TE/TM branch logic.",
        "Mode-field, dispersion, existence, and thickness-sweep actions are distinct render workflows.",
    ]
    if skipped:
        lines.append("Skipped unguided planar orders: " + ", ".join(str(order) for order in skipped))
    return rr.RenderBundle("Waveguide planar dielectric", figures, report("Waveguide planar dielectric", lines))


def _render_cylindrical(params: dict):
    action = str(params.get("action", "dispersion")).lower()
    radius = _float(params, "radius", 0.03)
    nco = _float(params, "nco", 2.5)
    ncl = _float(params, "ncl", 1.5)
    max_order = _int(params, "max_order", 5)
    vmax = _float(params, "vmax", 18.0)
    umax = _float(params, "umax", vmax)
    figures = []
    if action in {"dispersion", "dispersion curves"}:
        result = cylindrical_dielectric_dispersion(nco, ncl, vmax, umax, max_order, _int(params, "samples", 260))
        figures.append(cylindrical_dispersion_figure(result))
    elif action == "mode field":
        configured_family = params.get("mode_family", params.get("polarization"))
        if configured_family in {"HE/EH", "hybrid"}:
            configured_family = "HE"
        if configured_family in {"TE", "TM"} and "radial_orders" in params:
            mode_rows = [(0, row[0]) for row in _parse_int_ranges(params["radial_orders"], 1)]
        else:
            modes_text = params.get("modes", params.get("orders", "(1:2,1:2)"))
            mode_rows = _parse_int_ranges(modes_text, 2)
        for index, (order, radial_index) in enumerate(mode_rows, start=1):
            family = configured_family or ("TE" if order == 0 else "HE")
            result = cylindrical_dielectric_field(
                order,
                radial_index,
                nco,
                ncl,
                _float(params, "v_number", vmax),
                radius,
                _int(params, "grid_n", 220),
                str(params.get("phase", "cos")),
                str(family),
                str(params.get("field_quantity", "electric magnitude")),
            )
            figures.append(field_figure(result, f"{index:02d} {result['mode_label']}"))
        if not figures:
            raise ValueError("None of the selected cylindrical modes is guided at this V-number.")
    else:
        raise ValueError(f"Unsupported cylindrical dielectric action: {action}")
    return rr.RenderBundle("Waveguide cylindrical dielectric", figures, report("Waveguide cylindrical dielectric", [
        f"Step-index fiber: radius={radius:g}, nco={nco:g}, ncl={ncl:g}.",
        "TE/TM/HE/EH branches use exact Phi(V,U)=0 vector boundary equations.",
        "Mode fields reconstruct Er, Ephi, Ez, Hr, Hphi, and Hz across the dielectric interface.",
    ]))


def render(params):
    params = dict(params)
    workflow = str(params.get("waveguide_kind", "")).lower()
    if workflow == "planar":
        return _render_planar(params)
    if workflow == "cylindrical":
        return _render_cylindrical(params)
    if "orders" in params and "nco" in params and "ncl" in params:
        return _render_planar(params)
    return _render_metal(params)


