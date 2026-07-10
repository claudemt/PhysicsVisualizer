from __future__ import annotations

import sys
from pathlib import Path

import matplotlib.pyplot as plt

ROOT = Path(__file__).resolve().parents[4]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from projects.OpticsStudio.core.fourier import fourier_4f_model
from utils import render_result as rr
from utils.image_output import compose_grid, ensure_dir, save_figure, write_manifest


PANEL_NAMES = (
    "01_object.png",
    "02_phase.png",
    "03_after_phase.png",
    "04_spectrum.png",
    "05_filter.png",
    "06_output.png",
)


def legacy_parameters(samples_n: int | None = None) -> dict:
    return {
        "module": "fourier_studio",
        "preset": "HeNe classroom preview",
        "object": "Hex lattice circles",
        "phase": "Zernike coma x",
        "filter": "Mesh",
        "wavelength_nm": 632.8,
        "focal_length_mm": 250.0,
        "window_mm": 4.0,
        "n_samples": int(samples_n or 1536),
        "object_scale_mm": 0.55,
        "secondary_scale_mm": 0.30,
        "phase_radius_mm": 1.00,
        "zernike_coeff_waves": 0.30,
        "filter_scale_ratio": 0.18,
        "topological_charge": 1,
        "plot_range": "auto",
        "object_half_range_mm": 1.2,
        "fourier_half_range_mm": 8.0,
        "image_scaling": "fixed",
    }


def main(output_dir: str | Path | None = None, samples_n: int | None = None) -> list[Path]:
    out = ensure_dir(output_dir or Path(__file__).resolve().parent / "generated")
    params = legacy_parameters(samples_n)
    result = fourier_4f_model(params)

    panels = (
        (result.object_amp, "Object amplitude", "gray", False),
        (result.phase_wrapped, "Phase", None, True),
        (result.after_phase_amp, "After phase amplitude", "gray", False),
        (result.spectrum_intensity, "Fourier spectrum", None, True),
        (result.filter_amp, "Filter", "gray", False),
        (result.output_intensity, "Output intensity", None, True),
    )

    exported: list[Path] = []
    for name, (data, title, cmap, colorbar) in zip(PANEL_NAMES, panels):
        fig, axes = rr.new_figure(f"Fourier 4f - {title}", 1, 1, (7.2, 5.6))
        rr.image(axes[0, 0], data, title, cmap, colorbar=colorbar)
        rr.finish_figure(fig)
        exported.append(save_figure(fig, out, name, title_band=None))
        plt.close(fig)

    exported.append(compose_grid(exported, out / "composite.png", columns=3))
    parameters_path = out / "parameters.txt"
    reproduce_code_path = out / "reproduce_code.py"
    reproduce_path = out / "reproduce.py"
    _write_parameters(parameters_path, params, result.summary)
    _write_reproduce_code(reproduce_code_path)
    _write_reproduce_code(reproduce_path)
    write_manifest(
        out,
        "OpticsStudio",
        "fourier_4f",
        [params],
        [*exported, parameters_path, reproduce_code_path, reproduce_path],
        "Fourier studio reproduction: object -> phase -> Fourier filter -> image plane.",
    )
    return exported


def _write_parameters(path: Path, params: dict, summary: str) -> None:
    lines = [
        "module = fourier_studio",
        "notes = Fourier studio reproduction: object -> phase -> Fourier filter -> image plane.",
        f"status = {summary}",
    ]
    for key, value in params.items():
        lines.append(f"{key} = {value}")
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def _write_reproduce_code(path: Path) -> None:
    path.write_text(
        "from projects.OpticsStudio.example.fourier_4f.reproduce import main\n\n"
        "if __name__ == '__main__':\n"
        "    main()\n",
        encoding="utf-8",
    )


if __name__ == "__main__":
    main()
