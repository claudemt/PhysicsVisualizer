"""Repeatable media-contract check against the checked-in MATLAB examples."""
from __future__ import annotations

import argparse
import json
from pathlib import Path

import imageio.v2 as imageio
from PIL import Image


ROOT = Path(__file__).resolve().parents[3]
LEGACY_ROOT = ROOT / "legacy" / "matlab" / "projects" / "MovingChargeFields" / "example"


def _identity(text: str) -> str:
    return "".join(character.lower() for character in text if character.isalnum())


def _validate_figure_texts(figures: list[dict], example: str) -> list[str]:
    errors: list[str] = []
    motion = "circ" if example == "circular_motion" else "harm"
    plane = "xy" if example == "circular_motion" else "xz"
    for figure in figures:
        name = figure.get("file", "")
        title = _identity(figure.get("title", ""))
        colorbar = _identity(figure.get("colorbar_label", ""))
        xlabel = _identity(figure.get("xlabel", ""))
        ylabel = _identity(figure.get("ylabel", ""))
        if motion not in title or "tot" not in title:
            errors.append(f"Figure motion/field-part title mismatch: {name}")
        if "electric" in name and "e" not in title:
            errors.append(f"Electric-field title mismatch: {name}")
        if "magnetic" in name and "b" not in title:
            errors.append(f"Magnetic-field title mismatch: {name}")
        if "streamlines" in name and plane not in colorbar:
            errors.append(f"Streamline colorbar plane mismatch: {name}")
        if plane == "xy" and ("xlambda" not in xlabel or "ylambda" not in ylabel):
            errors.append(f"xy axis-label mismatch: {name}")
        if plane == "xz" and ("xlambda" not in xlabel or "zlambda" not in ylabel):
            errors.append(f"xz axis-label mismatch: {name}")
    return errors


def _video_metadata(path: Path) -> tuple[tuple[int, int], float, int]:
    reader = imageio.get_reader(path)
    try:
        meta = reader.get_meta_data()
        return tuple(meta["size"]), float(meta["fps"]), sum(1 for _ in reader)
    finally:
        reader.close()


def verify(example: str, output_dir: str | Path) -> dict:
    actual = Path(output_dir)
    legacy = LEGACY_ROOT / example
    errors: list[str] = []
    legacy_pngs = sorted(legacy.glob("*.png"))
    actual_pngs = sorted(actual.glob("*.png"))
    if [path.name for path in actual_pngs] != [path.name for path in legacy_pngs]:
        errors.append("PNG filenames/count differ from legacy")
    for expected in legacy_pngs:
        candidate = actual / expected.name
        if candidate.is_file() and Image.open(candidate).size != Image.open(expected).size:
            errors.append(f"PNG dimensions differ: {expected.name}")

    legacy_videos = sorted(legacy.glob("*.mp4"))
    actual_videos = sorted(actual.glob("*.mp4"))
    if [path.name for path in actual_videos] != [path.name for path in legacy_videos]:
        errors.append("MP4 filenames/count differ from legacy")
    for expected in legacy_videos:
        candidate = actual / expected.name
        if candidate.is_file() and _video_metadata(candidate) != _video_metadata(expected):
            errors.append(f"MP4 dimensions/fps/frame count differ: {expected.name}")

    parameters = json.loads((actual / "parameters.json").read_text(encoding="utf-8"))
    expected = {
        "motionType": "circular" if example == "circular_motion" else "harmonic",
        "sliceType": "xy" if example == "circular_motion" else "xz",
        "partType": "tot",
        "fieldType": "E_mag",
        "a_over_lambda": 1.2 if example == "circular_motion" else 1.1,
        "beta_max": 0.6 if example == "circular_motion" else 0.7,
        "slicePos_over_lambda": 0.0,
        "phase_over_T": 0.0 if example == "circular_motion" else 0.2,
        "cmapMode": "log",
        "outputMode": "image+video",
        "exportAllFields": False,
        "viewMode": "custom",
        "customFields": ["E_mag", "B_mag", "E_stream", "S_stream"],
        "selectedFields": ["E_mag", "B_mag", "E_stream", "S_stream"],
    }
    if set(parameters) != set(expected) or any(parameters.get(key) != value for key, value in expected.items()):
        errors.append("Legacy parameter contract is incomplete")
    manifest = json.loads((actual / "parity_manifest.json").read_text(encoding="utf-8"))
    figures = manifest.get("figures", [])
    if len(figures) != 4:
        errors.append("Figure title/colorbar extraction is incomplete")
    errors.extend(_validate_figure_texts(figures, example))

    result = {
        "project": "MovingChargeFields",
        "example": example,
        "legacy": str(legacy.relative_to(ROOT)),
        "passed": not errors,
        "errors": errors,
        "checked_pngs": len(legacy_pngs),
        "checked_mp4s": len(legacy_videos),
        "checked_figure_texts": len(figures),
    }
    (actual / "parity_check.json").write_text(json.dumps(result, indent=2), encoding="utf-8")
    if errors:
        raise AssertionError("; ".join(errors))
    return result


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("example", choices=("circular_motion", "harmonic_motion"))
    parser.add_argument("output_dir", type=Path)
    args = parser.parse_args()
    verify(args.example, args.output_dir)
