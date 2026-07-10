"""Repeatable media-contract check against the checked-in MATLAB examples."""
from __future__ import annotations

import argparse
import json
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[3]
LEGACY_ROOT = ROOT / "legacy" / "matlab" / "projects" / "MieScattering" / "example"


def _identity(text: str) -> str:
    return "".join(character.lower() for character in text if character.isalnum())


def _validate_figure_texts(figures: list[dict]) -> list[str]:
    errors: list[str] = []
    for figure in figures:
        name = figure.get("file", "")
        expected_geometry = "cylinder" if "_cyl_" in name else "sphere"
        expected_slice = "xy" if "_slice_xy_" in name else "xz"
        title = _identity(figure.get("title", ""))
        colorbar = _identity(figure.get("colorbar_label", ""))
        xlabel = _identity(figure.get("xlabel", ""))
        ylabel = _identity(figure.get("ylabel", ""))
        if expected_geometry not in title or "scattered" not in title or "scattered" not in colorbar:
            errors.append(f"Figure title/colorbar geometry-family mismatch: {name}")
        if "rex" in name and "reex" not in title:
            errors.append(f"Figure real Ex title mismatch: {name}")
        if "rey" in name and "reey" not in title:
            errors.append(f"Figure real Ey title mismatch: {name}")
        if "rez" in name and "reez" not in title:
            errors.append(f"Figure real Ez title mismatch: {name}")
        if expected_slice == "xy" and ("xlambda" not in xlabel or "ylambda" not in ylabel):
            errors.append(f"Figure xy axis-label mismatch: {name}")
        if expected_slice == "xz" and ("xlambda" not in xlabel or "zlambda" not in ylabel):
            errors.append(f"Figure xz axis-label mismatch: {name}")
    return errors


def verify(example: str, output_dir: str | Path) -> dict:
    actual = Path(output_dir)
    legacy = LEGACY_ROOT / example
    legacy_pngs = sorted(path for path in legacy.glob("*.png"))
    actual_pngs = sorted(path for path in actual.glob("*.png"))
    errors: list[str] = []
    if [path.name for path in actual_pngs] != [path.name for path in legacy_pngs]:
        errors.append("PNG filenames/count differ from legacy")
    for expected in legacy_pngs:
        candidate = actual / expected.name
        if candidate.is_file() and Image.open(candidate).size != Image.open(expected).size:
            errors.append(f"PNG dimensions differ: {expected.name}")

    parameters = json.loads((actual / "parameters.json").read_text(encoding="utf-8"))
    runs = parameters.get("runs", [])
    expected_geometry = (("cylinder", "xy"), ("sphere", "xz")) if example == "parallel_slice" else (("sphere", "xy"), ("cylinder", "xz"))
    expected_common = {"eps1": "2+0.2i", "mu1": "0.8+0.2i", "R_over_lambda": 0.5, "nu": 1.1, "psi": 0.2, "gridHalfWidth": 2.5, "N": 500, "nmaxExtra": 15, "maskInside": True, "slicePos_over_lambda": 0.1}
    if len(runs) != 2:
        errors.append("Mie run count differs from legacy")
    for run, (geometry, slice_type) in zip(runs, expected_geometry):
        expected_selection = ["sca_rex", "sca_rey", "sca_rez", "sca_aex", "sca_aey", "sca_aez"]
        if example == "parallel_slice":
            expected_selection.append("sca_emag")
        if any(run.get(key) != value for key, value in expected_common.items()) or run.get("geometry") != geometry or run.get("sliceType") != slice_type or run.get("mode") != "custom" or run.get("customSelection") != expected_selection:
            errors.append("Mie run parameters differ from legacy")

    manifest = json.loads((actual / "parity_manifest.json").read_text(encoding="utf-8"))
    figures = manifest.get("figures", [])
    if len(figures) != 12:
        errors.append("Figure title/colorbar extraction is incomplete")
    errors.extend(_validate_figure_texts(figures))

    result = {
        "project": "MieScattering",
        "example": example,
        "legacy": str(legacy.relative_to(ROOT)),
        "passed": not errors,
        "errors": errors,
        "checked_pngs": len(legacy_pngs),
        "checked_figure_texts": len(figures),
    }
    (actual / "parity_check.json").write_text(json.dumps(result, indent=2), encoding="utf-8")
    if errors:
        raise AssertionError("; ".join(errors))
    return result


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("example", choices=("parallel_slice", "perpendicular_slice"))
    parser.add_argument("output_dir", type=Path)
    args = parser.parse_args()
    verify(args.example, args.output_dir)
