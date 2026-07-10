from __future__ import annotations

import sys
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np

ROOT = Path(__file__).resolve().parents[4]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from projects.SpecialFunctionsStudio.core.catalog import get_variant
from projects.SpecialFunctionsStudio.core.rendering import render_surfaces
from projects.SpecialFunctionsStudio.core.special_functions import compute_spherical_items
from utils.image_output import compose_grid, ensure_dir, save_figure, write_manifest


def legacy_pairs() -> list[tuple[int, int]]:
    return [(l, m) for l in range(3, -1, -1) for m in range(-l, l + 1)]


def main(output_dir: str | Path | None = None) -> list[Path]:
    out = ensure_dir(output_dir or Path(__file__).resolve().parent / "generated")
    variant = get_variant("Spherical Harmonics", "Spherical Harmonic")
    exported: list[Path] = []
    for idx, (l, m) in enumerate(legacy_pairs(), start=1):
        item = compute_spherical_items("ylm", np.array([[l, m]], dtype=float))[0]
        bundle = render_surfaces(variant, [item])
        name = f"{idx:02d}_spherical_harmonics_ylm_l_{l}_m_{abs(m)}.png"
        exported.append(save_figure(bundle.figures[0], out, name, title_band=None))
        plt.close(bundle.figures[0])
    exported.append(compose_grid(exported, out / "composite.png", columns="7+5+3+1"))
    params = {
        "family": "spherical_harmonics",
        "variant": "ylm",
        "param_text": "(0:3,-3:3)",
    }
    parameters_path = out / "parameters.txt"
    reproduce_code_path = out / "reproduce_code.py"
    reproduce_path = out / "reproduce.py"
    _write_parameters(parameters_path, exported[:-1])
    _write_reproduce_code(reproduce_code_path)
    _write_reproduce_code(reproduce_path)
    write_manifest(
        out,
        "SpecialFunctionsStudio",
        "spherical_harmonic",
        [params],
        [*exported, parameters_path, reproduce_code_path, reproduce_path],
        "Spherical harmonic surface reproduction.",
    )
    return exported


def _write_parameters(path: Path, files: list[Path]) -> None:
    lines = [
        "export.layout = 7+5+3+1",
        "run_01.family = spherical_harmonics",
        "run_01.variant = ylm",
        "run_01.param_text = (0:3,-3:3)",
        "export.selected_files = {" + ", ".join(file.name for file in files) + "}",
    ]
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def _write_reproduce_code(path: Path) -> None:
    path.write_text(
        "from projects.SpecialFunctionsStudio.example.spherical_harmonic.reproduce import main\n\n"
        "if __name__ == '__main__':\n"
        "    main()\n",
        encoding="utf-8",
    )


if __name__ == "__main__":
    main()
