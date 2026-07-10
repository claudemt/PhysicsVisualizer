from __future__ import annotations

import sys
from pathlib import Path

import matplotlib.pyplot as plt

ROOT = Path(__file__).resolve().parents[4]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from projects.SpecialFunctionsStudio.core.model import render
from projects.SpecialFunctionsStudio.core.special_functions import compute_1d_curves
from projects.SpecialFunctionsStudio.core.tuple_parser import parse_tuple_scan
from utils.image_output import ensure_dir, save_figure, write_manifest


def main(output_dir: str | Path | None = None) -> list[Path]:
    out = ensure_dir(output_dir or Path(__file__).resolve().parent / "generated")
    params = {
        "family": "Bessel",
        "variant": "Modified Bessel K",
        "tuple_scan": "(0:5)",
        "x_range": "0 5",
        "crop_mode": "yrange",
        "y_range": "0 1",
        "legend_location": "northeast",
    }
    bundle = render(params)
    path = save_figure(bundle.figures[0], out, "01_modified_bessel_function_k_n_x.png", title_band=None)
    plt.close(bundle.figures[0])
    parameters_path = out / "parameters.txt"
    reproduce_code_path = out / "reproduce_code.py"
    reproduce_path = out / "reproduce.py"
    _write_parameters(parameters_path, params)
    _write_reproduce_code(reproduce_code_path)
    _write_reproduce_code(reproduce_path)
    write_manifest(
        out,
        "SpecialFunctionsStudio",
        "modified_bessel_k",
        [params],
        [path, parameters_path, reproduce_code_path, reproduce_path],
        "Modified Bessel K reproduction.",
    )
    return [path]


def sample_invariant() -> float:
    x = parse_tuple_scan("(1)", expected_cols=1)
    curves = compute_1d_curves("k", __import__("numpy").linspace(0.1, 5.0, 64), x)
    return float(curves[0]["y"][0])


def _write_parameters(path: Path, params: dict) -> None:
    lines = [
        "export.layout = auto",
        "export.selected_files = {01_modified_bessel_function_k_n_x.png}",
        "run_01.family = bessel",
        "run_01.variant = k",
        "run_01.param_text = (0:5)",
    ]
    lines.extend(f"run_01.{key} = {value}" for key, value in params.items())
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def _write_reproduce_code(path: Path) -> None:
    path.write_text(
        "from projects.SpecialFunctionsStudio.example.modified_bessel_k.reproduce import main\n\n"
        "if __name__ == '__main__':\n"
        "    main()\n",
        encoding="utf-8",
    )


if __name__ == "__main__":
    main()
