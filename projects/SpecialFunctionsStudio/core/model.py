import numpy as np

from .catalog import get_family, get_variant
from .history import PreviewRef, RunHistory, is_history_payload, normalize_run_params
from .rendering import render_curves, render_surfaces
from .special_functions import compute_1d_curves, compute_spherical_items
from .tuple_parser import parse_tuple_scan

TITLE = "Special Functions Studio"
DESCRIPTION = "Curves, surfaces, and vector-style special-function plots."
DEFAULTS = {}
FORMULAS = "Bessel, Airy, elliptic, hypergeometric, and spherical harmonics."

CURVE_LABELS = {
    "j": ("Bessel function $J_n(x)$", "$x$", "$f(x)$"),
    "y": ("Bessel function $Y_n(x)$", "$x$", "$f(x)$"),
    "i": ("Modified Bessel function $I_n(x)$", "$x$", "$f(x)$"),
    "k": ("Modified Bessel function $K_n(x)$", "$x$", "$f(x)$"),
    "spherical_j": ("Spherical Bessel function $j_n(x)$", "$x$", "$f(x)$"),
    "spherical_y": ("Spherical Bessel function $y_n(x)$", "$x$", "$f(x)$"),
    "ai": ("Airy function $Ai(x)$", "$x$", "$f(x)$"),
    "bi": ("Airy function $Bi(x)$", "$x$", "$f(x)$"),
    "aip": ("Derivative $Ai'(x)$", "$x$", "$f(x)$"),
    "bip": ("Derivative $Bi'(x)$", "$x$", "$f(x)$"),
    "lane_emden": ("Lane--Emden solutions $\\theta_n(\\xi)$", "$\\xi$", "$\\theta(\\xi)$"),
    "ellipk": ("Complete elliptic integral $K(m)$", "$m$", "$K(m)$"),
    "ellipe": ("Complete elliptic integral $E(m)$", "$m$", "$E(m)$"),
    "ellipf_inc": ("Incomplete elliptic integral $F(\\phi|m)$", "$\\phi$", "$F(\\phi|m)$"),
    "ellipe_inc": ("Incomplete elliptic integral $E(\\phi|m)$", "$\\phi$", "$E(\\phi|m)$"),
    "ellippi_inc": ("Incomplete elliptic integral $\\Pi(n;\\phi|m)$", "$\\phi$", "$\\Pi(n;\\phi|m)$"),
    "sn": ("Jacobi elliptic function $sn(u|m)$", "$u$", "$f(u)$"),
    "cn": ("Jacobi elliptic function $cn(u|m)$", "$u$", "$f(u)$"),
    "dn": ("Jacobi elliptic function $dn(u|m)$", "$u$", "$f(u)$"),
    "hyp2f1": ("Gauss hypergeometric function ${}_2F_1(a,b;c;z)$", "$z$", "$f(z)$"),
}


def render(params):
    if is_history_payload(params):
        return _render_history(params)
    return _render_single(normalize_run_params(params))


def _render_single(params):
    family = get_family(params.get("family", "Bessel"))
    variant = get_variant(family.key, params.get("variant", None))
    if variant.plot_kind == "3d":
        args = parse_tuple_scan(str(params.get("tuple_scan", variant.default_tuple)), expected_cols=2)
        return render_surfaces(variant, compute_spherical_items(variant.key, args))

    xmin, xmax = _x_range(params, family.default_xrange)
    x = np.linspace(xmin, xmax, 1400)
    expected = max(len(variant.param_labels), 1)
    default_scan = variant.default_tuple if variant.param_defaults else "0"
    args = parse_tuple_scan(str(params.get("tuple_scan", default_scan)), expected_cols=expected)
    if not variant.param_labels:
        args = np.zeros((1, 0))
    curves = compute_1d_curves(variant.key, x, args)
    title, xlabel, ylabel = CURVE_LABELS.get(variant.key, (variant.name, "$x$", "$f(x)$"))
    crop = params.get("crop", {})
    y_range = crop.get("y_range") if crop.get("mode") == "yrange" else None
    render_options = params.get("render_options", {})
    return render_curves(title, curves, xlabel, ylabel, y_range=y_range,
                         legend_location=render_options.get("legend_location", "northwest"))


def _render_history(params):
    history = RunHistory.from_payload(params)
    bundles = [_render_single(snapshot.params) for snapshot in history.runs]
    raw_refs = params.get("history_selection", ())
    if not raw_refs and isinstance(params.get("export"), dict):
        raw_refs = params["export"].get("selected_refs", ())
    if raw_refs:
        refs = tuple(PreviewRef.from_value(ref) for ref in raw_refs)
    else:
        refs = tuple(
            PreviewRef(run_index, item_index)
            for run_index, bundle in enumerate(bundles, start=1)
            for item_index in range(1, len(bundle.figures) + 1)
        )
    figures = []
    for ref in refs:
        if ref.run_index > len(bundles) or ref.item_index > len(bundles[ref.run_index - 1].figures):
            raise ValueError(f"History preview reference {ref.to_dict()} does not exist.")
        figures.append(bundles[ref.run_index - 1].figures[ref.item_index - 1])
    report = f"Special Functions history: {len(figures)} selected preview(s) from {len(history.runs)} run(s)"
    from utils.render_result import RenderBundle
    return RenderBundle("SpecialFunctionsStudio", figures, report=report)


def _x_range(params: dict, fallback: tuple[float, float]) -> tuple[float, float]:
    raw = str(params.get("x_range", "")).replace(",", " ").strip()
    if raw:
        pieces = [float(piece) for piece in raw.split()[:2]]
        if len(pieces) == 2 and pieces[1] > pieces[0]:
            return pieces[0], pieces[1]
    return fallback
