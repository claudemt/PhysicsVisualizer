from __future__ import annotations

import json
from pathlib import Path

import matplotlib.pyplot as plt

from projects.GraphiteLevitation.core.metrics import compute_visualization_maps
from projects.GraphiteLevitation.core.params import normalize_params
from projects.GraphiteLevitation.core.render import render
from utils import image_output


PLOT_NAMES = [
    "01_B2.png",
    "02_potential.png",
    "03_chi.png",
    "04_system.png",
    "05_force_x.png",
    "06_force_y.png",
    "07_force_z.png",
]


def reproduce_canonical_visualization(output_dir: str | Path | None = None) -> dict:
    output = image_output.ensure_dir(output_dir or Path(__file__).parent / "canonical_visualization" / "generated")
    params = {
        "shape": "circle",
        "d": "6",
        "rotation_deg": 0,
        "W_um": "40",
        "chi": "3.05e-4",
        "array_size": "6 6",
        "magnet_size_mm": "10 10 10",
        "Br": 1.46,
        "height": 0.35,
        "spot_mm": "3 0",
        "P": "0.35",
        "resolution": 140,
    }
    bundle = render(params)
    paths: list[Path] = []
    for fig, filename in zip(bundle.figures, PLOT_NAMES):
        paths.append(image_output.save_figure(fig, output, filename, title_band=None))
        plt.close(fig)
    composite = image_output.compose_grid(paths, output / "composite.png")
    (output / "parameters.txt").write_text("\n".join(f"{k} = {v}" for k, v in params.items()) + "\n", encoding="utf-8")
    (output / "parameters.json").write_text(json.dumps(params, indent=2, ensure_ascii=False), encoding="utf-8")
    report = bundle.report + "\nCanonical Python reproduction because legacy MATLAB had no committed example directory.\n"
    (output / "reproduction_report.md").write_text(report, encoding="utf-8")
    reproduce_path = output / "reproduce.py"
    reproduce_path.write_text(
        "from pathlib import Path\n\n"
        "from projects.GraphiteLevitation.example.canonical_visualization.reproduce import reproduce\n\n\n"
        "if __name__ == \"__main__\":\n"
        "    reproduce(Path(__file__).resolve().parent)\n",
        encoding="utf-8",
    )
    image_output.write_manifest(
        output,
        "GraphiteLevitation",
        "canonical_visualization",
        [params],
        [*paths, composite, output / "parameters.txt", output / "parameters.json", reproduce_path],
        report,
    )
    return {"output_dir": output, "paths": paths, "params": params, "report": bundle.report}


def invariant_map_shape() -> tuple[int, int]:
    params = normalize_params({"resolution": 44, "array_size": "4 4"})
    data = compute_visualization_maps(params)
    return data["B2_norm"].shape


def reproduce_all(output_root: str | Path | None = None) -> dict[str, dict]:
    root = Path(output_root) if output_root is not None else Path(__file__).parent
    return {"canonical_visualization": reproduce_canonical_visualization(root / "canonical_visualization")}
