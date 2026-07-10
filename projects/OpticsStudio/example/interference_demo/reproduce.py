from __future__ import annotations

import sys
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np

ROOT = Path(__file__).resolve().parents[4]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from projects.OpticsStudio.core.interference import run_interference
from utils import render_result as rr
from utils.image_output import compose_grid, ensure_dir, save_figure, write_manifest


PANEL_NAMES = ("panel_1.png", "panel_2.png", "panel_3.png", "panel_4.png")


def legacy_parameters(samples_n: int | None = None) -> dict:
    """Return the MATLAB tab's default interference export parameters."""

    return {
        "mode": "moire",
        "freq1": 18.0,
        "freq2": 19.2,
        "angle_deg": 2.5,
        "aberration": "coma",
        "coefficient": 0.45,
        "shear_px": 10.0,
        "carrier": 8.0,
        "iterations": 80,
        "alpha": 0.85,
        "spot_count": 3,
        "separation_px": None,
        "resolution": int(samples_n or 256),
        "image_scaling": "fixed",
    }


def main(output_dir: str | Path | None = None, samples_n: int | None = None) -> list[Path]:
    out = ensure_dir(output_dir or Path(__file__).resolve().parent / "generated")
    params = legacy_parameters(samples_n)
    result = run_interference(params)

    exported: list[Path] = []
    for name, (kind, data, title, cmap, colorbar) in zip(PANEL_NAMES, _panels_for(result)):
        fig, axes = rr.new_figure(f"Interference - {title}", 1, 1, (7.2, 5.6))
        ax = axes[0, 0]
        if kind == "curve":
            iteration, efficiency, uniformity = data
            rr.curve(ax, iteration, efficiency, title, "$k$", "$\\mathrm{metric}$", label="$\\eta$")
            rr.curve(ax, iteration, uniformity, title, "$k$", "$\\mathrm{metric}$", label="$u$")
        else:
            rr.image(ax, data, title, cmap, colorbar=colorbar)
        rr.finish_figure(fig)
        exported.append(save_figure(fig, out, name, title_band=None))
        plt.close(fig)

    exported.append(compose_grid(exported, out / "composite.png", columns=2))
    parameters_path = out / "parameters.txt"
    reproduce_code_path = out / "reproduce_code.py"
    reproduce_path = out / "reproduce.py"
    _write_parameters(parameters_path, params, result)
    _write_reproduce_code(reproduce_code_path)
    _write_reproduce_code(reproduce_path)
    write_manifest(
        out,
        "OpticsStudio",
        "interference_demo",
        [params],
        [*exported, parameters_path, reproduce_code_path, reproduce_path],
        "Interference and phase demo reproduction using the MATLAB tab's default moire setup.",
    )
    return exported


def _panels_for(result: dict) -> tuple[tuple[str, object, str, str | None, bool], ...]:
    if result["mode"] == "gs_phase":
        iteration = np.arange(1, len(result["efficiency"]) + 1)
        return (
            ("image", result["target_amplitude"], "Target amplitude", "gray", False),
            ("image", result["final_phase"], "Recovered phase", None, True),
            ("image", result["final_intensity"], "Focal intensity", None, True),
            ("curve", (iteration, result["efficiency"], result["uniformity"]), "GS convergence", None, False),
        )
    if result["mode"] == "shearing":
        spectrum = np.log1p(np.abs(np.fft.fftshift(np.fft.fft2(np.fft.ifftshift(result["interferogram"])))))
        spectrum /= max(float(np.max(spectrum)), np.finfo(float).eps)
        return (
            ("image", result["wavefront"], "Wavefront", None, True),
            ("image", result["delta_phase"], "Delta phase", None, True),
            ("image", result["interferogram"], "Interferogram", "gray", False),
            ("image", spectrum, "Interferogram spectrum", None, True),
        )
    return (
        ("image", result["grating_a"], "Grating 1", "gray", False),
        ("image", result["grating_b"], "Grating 2", "gray", False),
        ("image", result["moire"], "Moire product", "gray", False),
        ("image", result["spectrum"], "Moire spectrum", None, True),
    )


def _write_parameters(path: Path, params: dict, result: dict) -> None:
    lines = [
        f"mode = {params['mode']}",
        f"grating_1_frequency = {params['freq1']:.6f}",
        f"grating_2_frequency = {params['freq2']:.6f}",
        f"grating_2_angle_deg = {params['angle_deg']:.6f}",
        f"aberration = {params['aberration']}",
        f"coefficient_waves = {params['coefficient']:.6f}",
        f"shear_px = {params['shear_px']:.6f}",
        f"carrier_frequency = {params['carrier']:.6f}",
        f"grid_size = {params['resolution']}",
        f"gs_iterations = {params['iterations']}",
        f"gs_damping = {params['alpha']:.6f}",
        f"image_scaling = {params['image_scaling']}",
        f"status = mode: {result['mode']}",
    ]
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def _write_reproduce_code(path: Path) -> None:
    path.write_text(
        "from projects.OpticsStudio.example.interference_demo.reproduce import main\n\n"
        "if __name__ == '__main__':\n"
        "    main()\n",
        encoding="utf-8",
    )


if __name__ == "__main__":
    main()
