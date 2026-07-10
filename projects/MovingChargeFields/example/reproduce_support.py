from __future__ import annotations

import json
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import imageio.v2 as imageio
from PIL import Image

from projects.MovingChargeFields.core.fields import compute_payload
from projects.MovingChargeFields.core.render import draw_field, render
from utils import render_result as rr
from utils import image_output


FIELD_NAMES = [
    "01_electric_field_magnitude.png",
    "02_magnetic_field_magnitude.png",
    "03_electric_field_streamlines.png",
    "04_poynting_streamlines.png",
]

VIDEO_FIELDS = ("E_mag", "B_mag", "E_stream", "S_stream")
LEGACY_VIDEO_NAMES = {
    "E_mag": "05_electric_field_magnitude.mp4",
    "B_mag": "06_magnetic_field_magnitude.mp4",
    "E_stream": "07_electric_field_streamlines.mp4",
    "S_stream": "08_poynting_streamlines.mp4",
}
LEGACY_VIDEO_SIZE = (1500, 1250)
LEGACY_VIDEO_FRAMES = 60
LEGACY_VIDEO_FPS = 20
LEGACY_STILL_SIZES = {
    "circular_motion": [(2433, 2230), (2433, 2230), (2439, 2230), (2439, 2233)],
    "harmonic_motion": [(2433, 2231), (2433, 2231), (2433, 2231), (2433, 2233)],
}


def _resize_png(path: Path, size: tuple[int, int]) -> Path:
    with Image.open(path) as image:
        image.convert("RGB").resize(size, Image.Resampling.LANCZOS).save(path)
    return path


def _frame_array(fig) -> np.ndarray:
    """Return a fixed-size RGB frame without materializing a PNG per phase."""
    fig.canvas.draw()
    rgba = np.asarray(fig.canvas.buffer_rgba())
    image = Image.fromarray(rgba).convert("RGB")
    return np.asarray(image.resize(LEGACY_VIDEO_SIZE, Image.Resampling.LANCZOS))


def _write_parameters(output: Path, params: dict) -> None:
    def format_value(value: object) -> str:
        if isinstance(value, list):
            return "{" + ", ".join(str(item) for item in value) + "}"
        if isinstance(value, bool):
            return "1" if value else "0"
        return str(value)

    (output / "parameters.txt").write_text(
        "\n".join(f"{key} = {format_value(value)}" for key, value in params.items()) + "\n",
        encoding="utf-8",
    )
    (output / "parameters.json").write_text(json.dumps(params, indent=2), encoding="utf-8")


def _run(output: Path, params: dict, scenario: str) -> dict:
    still_params = dict(params)
    still_params["resolution"] = 301
    bundle = render(still_params)
    paths: list[Path] = []
    contracts: list[dict] = []
    for fig, filename, size in zip(bundle.figures, FIELD_NAMES, LEGACY_STILL_SIZES[scenario]):
        axes = fig.axes[0]
        contracts.append({
            "file": filename,
            "title": axes.get_title(),
            "xlabel": axes.get_xlabel(),
            "ylabel": axes.get_ylabel(),
            "colorbar_label": fig.axes[-1].get_ylabel(),
        })
        paths.append(_resize_png(image_output.save_figure(fig, output, filename, dpi=300, title_band=None, crop=False), size))
        plt.close(fig)
    composite = image_output.compose_grid(paths, output / "composite.png")
    _write_parameters(output, params)
    videos = export_videos(output, params, scenario, frame_count=LEGACY_VIDEO_FRAMES, fields=VIDEO_FIELDS)
    report = f"Python reproduction of legacy {scenario} still-image field bundle and per-field MP4 animations.\n"
    (output / "reproduction_report.md").write_text(report, encoding="utf-8")
    reproduce_path = output / "reproduce.py"
    reproduce_path.write_text(
        "from pathlib import Path\n\n"
        f"from projects.MovingChargeFields.example.{scenario}.reproduce import reproduce\n\n\n"
        "if __name__ == \"__main__\":\n"
        "    reproduce(Path(__file__).resolve().parent)\n",
        encoding="utf-8",
    )
    image_output.write_manifest(
        output,
        "MovingChargeFields",
        scenario,
        [params],
        [*paths, composite, *videos.values(), output / "parameters.txt", output / "parameters.json", reproduce_path],
        report,
    )
    parity_manifest = {
        "legacy_reference": f"legacy/matlab/projects/MovingChargeFields/example/{scenario}",
        "stills": [{"file": path.name, "size": list(size)} for path, size in zip(paths, LEGACY_STILL_SIZES[scenario])],
        "videos": [{"file": videos[field].name, "size": list(LEGACY_VIDEO_SIZE), "fps": LEGACY_VIDEO_FPS, "frames": LEGACY_VIDEO_FRAMES} for field in VIDEO_FIELDS],
        "figures": contracts,
        "known_non_pixel_equivalence": [
            "MATLAB stream2 colored streamline surfaces are approximated with seeded Matplotlib LineCollection paths.",
            "MATLAB and Matplotlib use different rasterizers, fonts, colormaps, and video encoders.",
        ],
    }
    (output / "parity_manifest.json").write_text(json.dumps(parity_manifest, indent=2), encoding="utf-8")
    return {"output_dir": output, "paths": paths, "video": videos["E_mag"], "videos": videos, "params": params, "report": bundle.report}


def export_video(output: Path, params: dict, scenario: str, frame_count: int = LEGACY_VIDEO_FRAMES, field: str = "E_mag") -> Path:
    frames_dir = image_output.ensure_dir(output / "video_frames" / field)
    base = dict(params)
    base["fields"] = field
    base["resolution"] = 221
    video_path = output / LEGACY_VIDEO_NAMES[field]
    with imageio.get_writer(video_path, fps=LEGACY_VIDEO_FPS, macro_block_size=1) as writer:
        for phase in np.linspace(0.0, 1.0, int(frame_count)):
            frame_params = dict(base)
            frame_params["phase"] = float(phase)
            bundle = render(frame_params)
            writer.append_data(_frame_array(bundle.figures[0]))
            plt.close(bundle.figures[0])
    return video_path


def export_videos(
    output: Path,
    params: dict,
    scenario: str,
    frame_count: int = LEGACY_VIDEO_FRAMES,
    fields: tuple[str, ...] = VIDEO_FIELDS,
) -> dict[str, Path]:
    for field in fields:
        image_output.ensure_dir(output / "video_frames" / field)
    base = dict(params)
    base["fields"] = ",".join(fields)
    base["resolution"] = 221
    part = str(base.get("field_part", base.get("partType", "tot"))).lower()
    if part not in {"tot", "vel", "rad"}:
        part = "tot"
    video_paths = {field: output / LEGACY_VIDEO_NAMES[field] for field in fields}
    writers = {field: imageio.get_writer(path, fps=LEGACY_VIDEO_FPS, macro_block_size=1) for field, path in video_paths.items()}
    try:
        for phase in np.linspace(0.0, 1.0, int(frame_count)):
            frame_params = dict(base)
            frame_params["phase"] = float(phase)
            payload = compute_payload(frame_params)
            motion = str(frame_params.get("motion", frame_params.get("motionType", "circular")))
            for field in fields:
                fig = _animation_frame_figure(payload, field, part, motion)
                writers[field].append_data(_frame_array(fig))
                plt.close(fig)
    finally:
        for writer in writers.values():
            writer.close()
    return video_paths


def _animation_frame_figure(payload: dict, field: str, part: str, motion: str):
    fig, axes = rr.new_figure("moving charge field", 1, 1, (5.4, 4.8))
    ax = axes[0, 0]
    draw_field(ax, payload, field, part, motion, stream_density=0.35)
    rr.finish_figure(fig)
    return fig


def reproduce_circular_motion(output_dir: str | Path | None = None) -> dict:
    output = image_output.ensure_dir(output_dir or Path(__file__).parent / "circular_motion" / "generated")
    return _run(output, {
        "motionType": "circular",
        "sliceType": "xy",
        "partType": "tot",
        "fieldType": "E_mag",
        "a_over_lambda": 1.2,
        "beta_max": 0.6,
        "slicePos_over_lambda": 0.0,
        "phase_over_T": 0.0,
        "cmapMode": "log",
        "outputMode": "image+video",
        "exportAllFields": False,
        "viewMode": "custom",
        "customFields": list(VIDEO_FIELDS),
        "selectedFields": list(VIDEO_FIELDS),
    }, "circular_motion")


def reproduce_harmonic_motion(output_dir: str | Path | None = None) -> dict:
    output = image_output.ensure_dir(output_dir or Path(__file__).parent / "harmonic_motion" / "generated")
    return _run(output, {
        "motionType": "harmonic",
        "sliceType": "xz",
        "partType": "tot",
        "fieldType": "E_mag",
        "a_over_lambda": 1.1,
        "beta_max": 0.7,
        "slicePos_over_lambda": 0.0,
        "phase_over_T": 0.2,
        "cmapMode": "log",
        "outputMode": "image+video",
        "exportAllFields": False,
        "viewMode": "custom",
        "customFields": list(VIDEO_FIELDS),
        "selectedFields": list(VIDEO_FIELDS),
    }, "harmonic_motion")


def invariant_retarded_grid() -> tuple[int, int]:
    payload = compute_payload({"motion": "circular", "resolution": 42})
    return payload["data"]["tr"].shape


def reproduce_all(output_root: str | Path | None = None) -> dict[str, dict]:
    root = Path(output_root) if output_root is not None else Path(__file__).parent
    return {
        "circular_motion": reproduce_circular_motion(root / "circular_motion"),
        "harmonic_motion": reproduce_harmonic_motion(root / "harmonic_motion"),
    }
