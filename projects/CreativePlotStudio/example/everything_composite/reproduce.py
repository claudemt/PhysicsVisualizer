from __future__ import annotations

from pathlib import Path
import json
import sys

ROOT = Path(__file__).resolve().parents[4]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from matplotlib import pyplot as plt

from projects.CreativePlotStudio.app.catalog import CATALOG, slugify
from projects.CreativePlotStudio.core.model import render
from utils import image_output
from utils.image_output import write_manifest


PROJECT = "CreativePlotStudio"
EXAMPLE = "everything_composite"
LEGACY_PARTIAL_COUNT = 34


def iter_catalog_params(sample_count: int = 12000):
    for domain, categories in CATALOG.items():
        for category in categories:
            for item in category.items:
                yield {
                    "domain": domain,
                    "category": category.category,
                    "project": item,
                    "style": "default",
                    "resolution": sample_count,
                }


def reproduce(output_dir: str | Path | None = None, sample_count: int = 12000) -> list[Path]:
    folder = image_output.ensure_dir(output_dir or Path(__file__).resolve().parent / "output")
    individual = image_output.ensure_dir(folder / "individual")
    legacy_batch = image_output.ensure_dir(folder / "output" / "creative_plot_studio_all_python")
    legacy_individual = image_output.ensure_dir(legacy_batch / "individual")
    outputs: list[Path] = []
    canonical: list[Path] = []
    params_used = []
    legacy_partial: list[Path] = []
    for index, params in enumerate(iter_catalog_params(sample_count), start=1):
        bundle = render(params)
        slug = slugify(str(params["project"]))
        path = image_output.save_figure(
            bundle.figures[0],
            individual,
            f"{index:02d}_{slug}.png",
            dpi=240,
            title_band=None,
        )
        canonical.append(path)
        outputs.append(path)
        if index <= LEGACY_PARTIAL_COUNT:
            legacy_path = image_output.save_figure(
                bundle.figures[0],
                legacy_individual,
                f"{index:02d}_{slug}.png",
                dpi=240,
                title_band=None,
            )
            legacy_partial.append(legacy_path)
            outputs.append(legacy_path)
        params_used.append(params)
        plt.close("all")
    composite = image_output.compose_grid(canonical, folder / "preview_composite.png", columns="auto", padding=16)
    outputs.append(composite)
    legacy_composite = image_output.compose_grid(legacy_partial, legacy_batch / "preview_composite.png", columns="auto", padding=16)
    outputs.append(legacy_composite)
    (folder / "parameters.json").write_text(json.dumps(params_used, indent=2, ensure_ascii=False), encoding="utf-8")
    (folder / "parameters.txt").write_text(
        "\n".join(
            f"run_{index:02d}.{key} = {value}"
            for index, params in enumerate(params_used, start=1)
            for key, value in params.items()
        ) + "\n",
        encoding="utf-8",
    )
    reproduce_path = folder / "reproduce.py"
    reproduce_path.write_text(
        "from projects.CreativePlotStudio.example.everything_composite.reproduce import reproduce\n\n"
        "if __name__ == '__main__':\n"
        "    reproduce()\n",
        encoding="utf-8",
    )
    manifest_outputs = [*outputs, folder / "parameters.txt", reproduce_path]
    write_manifest(
        folder,
        PROJECT,
        EXAMPLE,
        params_used,
        manifest_outputs,
        "Catalog-driven Python reproduction with a legacy-compatible partial batch mirror.",
    )
    return outputs


if __name__ == "__main__":
    target = Path(sys.argv[1]) if len(sys.argv) > 1 else None
    for path in reproduce(target):
        print(path)

