import numpy as np

from utils import render_result as rr
from utils import style

from .thin_film import (
    elastic_defaults,
    optical_angle_sweep,
    optical_defaults,
    optical_sweep_report,
    optical_thickness_sweep,
    render_report,
    resolve_optical_layer_h,
)

TITLE = "Thin Film"
DESCRIPTION = "Optical and elastic layered transfer-matrix visualization."
DEFAULTS = {
    "film_kind": "optical",
    "omega": 1.0,
    "theta_a": 0.524,
    "scan_mode": "single",
    "sweep_samples": 181,
}
FORMULAS = "Layer transfer matrices for reflection and transmission."


def _numbers(text: object) -> list[float]:
    return [float(item) for item in str(text).replace(",", " ").split()]


def _parse_elastic(params: dict) -> dict:
    data = elastic_defaults()
    data["omega"] = float(params.get("omega", data["omega"]))
    data["kx"] = float(params.get("k_x", params.get("kx", data["kx"])))
    data["phii"] = float(params.get("phi_i", params.get("phii", data["phii"])))
    data["psii"] = float(params.get("psi_i", params.get("psii", data["psii"])))
    a_vals = _numbers(params.get("medium_a", "1.3 1 1"))
    g_vals = _numbers(params.get("medium_g", "1.3 5.2 1.9"))
    if len(a_vals) != 3 or len(g_vals) != 3:
        raise ValueError("Elastic boundary media must each contain: lambda mu eta")
    data["a"] = {"lambda": a_vals[0], "mu": a_vals[1], "eta": a_vals[2]}
    data["g"] = {"lambda": g_vals[0], "mu": g_vals[1], "eta": g_vals[2]}
    layers = []
    for line in str(params.get("layers", "4 1.5 4.4 9.8")).splitlines():
        if not line.strip():
            continue
        vals = _numbers(line)
        if len(vals) != 4:
            raise ValueError("Elastic film layers must use rows: lambda mu eta h")
        layers.append({"lambda": vals[0], "mu": vals[1], "eta": vals[2], "h": vals[3]})
    data["layers"] = layers
    data["N"] = len(layers)
    return data


def _parse_optical(params: dict) -> dict:
    data = optical_defaults()
    data["omega"] = float(params.get("omega", data["omega"]))
    data["theta_a"] = float(params.get("theta_a", data["theta_a"]))
    a_vals = _numbers(params.get("medium_a", "1 1"))
    g_vals = _numbers(params.get("medium_g", "2.25 1"))
    if len(a_vals) != 2 or len(g_vals) != 2:
        raise ValueError("Optical boundary media must each contain: eps mu")
    data["a"] = {"eps": a_vals[0], "mu": a_vals[1]}
    data["g"] = {"eps": g_vals[0], "mu": g_vals[1]}
    layers = []
    for line in str(params.get("layers", "2.25 1 0.25*lambda")).splitlines():
        if not line.strip():
            continue
        pieces = line.replace(",", " ").split()
        if len(pieces) != 3:
            raise ValueError("Optical film layers must use rows: eps mu h")
        eps = float(pieces[0])
        mu = float(pieces[1])
        h = resolve_optical_layer_h(
            pieces[2], data["omega"], data["theta_a"],
            data["a"]["eps"], data["a"]["mu"], eps, mu,
        )
        layers.append({"eps": eps, "mu": mu, "h": h})
    data["layers"] = layers
    data["N"] = len(layers)
    return data


def _summary_figure(kind: str, result: dict):
    fig, axes = rr.new_figure(f"ThinFilm {kind} transfer summary", 1, 1, (7.2, 4.8))
    ax = axes[0, 0]
    if kind == "optical":
        labels = ["R_s", "T_s", "R_p", "T_p"]
        values = [result["Rs"], result["Ts"], result["Rp"], result["Tp"]]
    else:
        labels = ["P refl", "P trans", "SV refl", "SV trans", "SH refl", "SH trans"]
        values = [
            result["RP_P"] + result["RSV_P"],
            result["TP_P"] + result["TSV_P"],
            result["RP_SV"] + result["RSV_SV"],
            result["TP_SV"] + result["TSV_SV"],
            result["RSH"],
            result["TSH"],
        ]
    ax.bar(labels, [float(abs(v)) for v in values], color=style.tokens().primary)
    rr.set_axis_text(ax, title="Energy coefficients", ylabel="coefficient", grid=True)
    ax.tick_params(axis="x", rotation=25)
    rr.finish_figure(fig)
    return fig


def _scan_values(start: object, stop: object, samples: object) -> np.ndarray:
    first = float(start)
    last = float(stop)
    count = int(samples)
    if not np.isfinite(first) or not np.isfinite(last):
        raise ValueError("Sweep endpoints must be finite.")
    if count < 2 or count > 5001:
        raise ValueError("Sweep samples must be between 2 and 5001.")
    return np.linspace(first, last, count)


def _real_series(rows: list[dict], key: str) -> np.ndarray:
    return np.asarray([float(np.real(row[key])) for row in rows], dtype=float)


def _optical_sweep_figure(mode: str, rows: list[dict], layer_index: int | None = None):
    x_key = "theta_a" if mode == "angle sweep" else "h"
    x = _real_series(rows, x_key)
    xlabel = "theta_a (rad)" if x_key == "theta_a" else f"layer {layer_index} thickness"
    fig, axes = rr.new_figure(f"ThinFilm optical {mode}", 1, 2, (11, 5))
    for ax, pol, primary_key, secondary_key in (
        (axes[0, 0], "s", "Rs", "Ts"),
        (axes[0, 1], "p", "Rp", "Tp"),
    ):
        rr.curve(
            ax,
            x,
            _real_series(rows, primary_key),
            f"{pol} polarization",
            xlabel,
            "power coefficient",
            label=f"R_{pol}",
            color=style.tokens().primary,
        )
        rr.curve(
            ax, x, _real_series(rows, secondary_key),
            label=f"T_{pol}", color=style.tokens().accent,
        )
        energy_error = np.abs(_real_series(rows, f"E{pol}") - 1.0)
        rr.curve(ax, x, energy_error, label=f"|E_{pol}-1|", color=style.tokens().error)
    rr.finish_figure(fig)
    return fig


def render(params):
    params = dict(params)
    kind = str(params.get("film_kind", "optical")).lower()
    if kind == "elastic":
        data = _parse_elastic(params)
        result, text = render_report("elastic", data)
    else:
        kind = "optical"
        data = _parse_optical(params)
        result, text = render_report("optical", data)
        scan_mode = str(params.get("scan_mode", "single")).strip().lower()
        if scan_mode == "angle sweep":
            values = _scan_values(
                params.get("angle_start", 0.0),
                params.get("angle_stop", 1.4),
                params.get("sweep_samples", 181),
            )
            rows = optical_angle_sweep(data, values)
            text += optical_sweep_report(scan_mode, rows)
            figures = [_optical_sweep_figure(scan_mode, rows), _summary_figure(kind, result)]
            return rr.RenderBundle("ThinFilm optical angle sweep", figures, text)
        if scan_mode == "thickness sweep":
            layer_index = int(params.get("layer_index", 1))
            if layer_index < 1 or layer_index > len(data["layers"]):
                raise ValueError(f"layer index must be between 1 and {len(data['layers'])}.")
            values = _scan_values(
                params.get("thickness_start", 0.0),
                params.get("thickness_stop", 2.0),
                params.get("sweep_samples", 181),
            )
            rows = optical_thickness_sweep(data, layer_index - 1, values)
            text += optical_sweep_report(scan_mode, rows, layer_index)
            figures = [_optical_sweep_figure(scan_mode, rows, layer_index), _summary_figure(kind, result)]
            return rr.RenderBundle("ThinFilm optical thickness sweep", figures, text)
        if scan_mode != "single":
            raise ValueError(f"Unknown optical render mode: {scan_mode}")
    return rr.RenderBundle(f"ThinFilm {kind}", [_summary_figure(kind, result)], text)
