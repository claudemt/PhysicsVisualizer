from __future__ import annotations

import json
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np

from projects.RigidBodyRotation.core.render import render
from projects.RigidBodyRotation.core.solver import RigidCompareResult, default_input, solve
from utils import image_output
from utils import render_result as rr


PLOT_NAMES = [
    "01_wt_lab.png",
    "02_w_phase_lab.png",
    "03_wt_body.png",
    "04_w_phase_body.png",
    "05_L_body.png",
    "06_w_L_body.png",
    "07_axis_tips_lab.png",
]


def _run(output: Path, params: dict, scenario: str) -> dict:
    bundle = render(params)
    paths: list[Path] = []
    for fig, filename in zip(bundle.figures, PLOT_NAMES):
        paths.append(image_output.save_figure(fig, output, filename, title_band=None))
        plt.close(fig)
    composite = image_output.compose_grid(paths, output / "composite.png")
    (output / "parameters.txt").write_text("\n".join(f"{k} = {v}" for k, v in params.items()) + "\n", encoding="utf-8")
    (output / "parameters.json").write_text(json.dumps(params, indent=2, ensure_ascii=False), encoding="utf-8")
    video_path = export_video(output, params, scenario, frame_count=18)
    report = bundle.report + f"\nScenario: {scenario}\n"
    (output / "reproduction_report.md").write_text(report, encoding="utf-8")
    reproduce_path = output / "reproduce.py"
    reproduce_path.write_text(
        "from pathlib import Path\n\n"
        f"from projects.RigidBodyRotation.example.{scenario}.reproduce import reproduce\n\n\n"
        "if __name__ == \"__main__\":\n"
        "    reproduce(Path(__file__).resolve().parent)\n",
        encoding="utf-8",
    )
    image_output.write_manifest(
        output,
        "RigidBodyRotation",
        scenario,
        [params],
        [*paths, composite, video_path, output / "parameters.txt", output / "parameters.json", reproduce_path],
        report,
    )
    return {"output_dir": output, "paths": paths, "video": video_path, "params": params, "report": bundle.report}


def export_video(output: Path, params: dict, scenario: str, frame_count: int | None = None) -> Path:
    input_data = default_input(params)
    result = solve(input_data)
    if isinstance(result, RigidCompareResult):
        raise ValueError("Video export is available only for a single initial-condition run")
    frames_dir = image_output.ensure_dir(output / "video_frames")
    frame_paths: list[Path] = []
    total = len(result.t)
    n_frames = min(total, 300 if frame_count is None else max(1, int(frame_count)))
    indices = np.unique(np.linspace(0, total - 1, n_frames, dtype=int))
    omega_scale = 10.0 if np.max(np.linalg.norm(result.w_lab, axis=1)) > 5.0 else 1.0
    omega_label = "$\\omega/10$" if omega_scale == 10.0 else "$\\omega$"
    points = np.vstack((result.axis_tips.reshape(-1, 3), result.w_lab / omega_scale, np.zeros((1, 3))))
    mins, maxs = points.min(axis=0), points.max(axis=0)
    span = max(float((maxs - mins).max()), 1.0)
    center = (mins + maxs) / 2

    fig = plt.figure(figsize=(5.2, 5.0))
    ax = fig.add_subplot(111, projection="3d")
    lines = []
    for axis_idx, label in enumerate(("$\\hat e_1$", "$\\hat e_2$", "$\\hat e_3$")):
        vector = result.axis_tips[indices[0], :, axis_idx]
        lines.append(ax.plot3D((0, vector[0]), (0, vector[1]), (0, vector[2]), linewidth=1.0, label=label)[0])
    omega = result.w_lab[indices[0]] / omega_scale
    omega_line = ax.plot3D((0, omega[0]), (0, omega[1]), (0, omega[2]), linewidth=1.0, label=omega_label)[0]
    rr.set_axis_text(
        ax,
        title="Body axes and $\\omega$ in lab frame",
        xlabel="$x$",
        ylabel="$y$",
        zlabel="$z$",
        grid=True,
    )
    half = 0.58 * span
    ax.set_xlim(center[0] - half, center[0] + half)
    ax.set_ylim(center[1] - half, center[1] + half)
    ax.set_zlim(center[2] - half, center[2] + half)
    ax.set_box_aspect((1, 1, 1))
    ax.set_proj_type("ortho")
    legend_location = {
        "northeast": "upper right",
        "northwest": "upper left",
        "best": "best",
    }.get(input_data["legend_3d"].strip().casefold(), "upper right")
    rr.apply_legend(ax.legend(loc=legend_location))
    rr.finish_figure(fig, reserve_title=False)
    for frame_number, idx in enumerate(indices, start=1):
        for axis_idx, line in enumerate(lines):
            vector = result.axis_tips[idx, :, axis_idx]
            line.set_data_3d((0, vector[0]), (0, vector[1]), (0, vector[2]))
        omega = result.w_lab[idx] / omega_scale
        omega_line.set_data_3d((0, omega[0]), (0, omega[1]), (0, omega[2]))
        frame_path = image_output.save_figure(fig, frames_dir, f"{frame_number:03d}_attitude.png", dpi=110, title_band=None)
        frame_paths.append(frame_path)
    plt.close(fig)
    return image_output.save_animation(frame_paths, output / f"{scenario}_attitude.mp4", fps=30)


def reproduce_canonical_free_rotation(output_dir: str | Path | None = None) -> dict:
    output = image_output.ensure_dir(output_dir or Path(__file__).parent / "canonical_free_rotation" / "generated")
    return _run(output, {
        "mode": "free rotation",
        "I": "1 2 3",
        "w0": "0.18 2.2 0.04",
        "phi0": 0,
        "tEnd": 18,
        "nSamples": 1200,
    }, "canonical_free_rotation")


def reproduce_canonical_fixed_point(output_dir: str | Path | None = None) -> dict:
    output = image_output.ensure_dir(output_dir or Path(__file__).parent / "canonical_fixed_point" / "generated")
    return _run(output, {
        "mode": "fixed point",
        "I": "1 1.4 2",
        "aBody": "0 0 1",
        "mass": 1,
        "g": 9.81,
        "Euler0": "0 0.55 0",
        "w0": "0 0 15",
        "tEnd": 8,
        "nSamples": 1000,
    }, "canonical_fixed_point")


def invariant_free_energy_drift() -> float:
    result = solve(default_input({"mode": "free rotation", "nSamples": 240, "tEnd": 4}))
    return float((result.energy.max() - result.energy.min()) / abs(result.energy.mean()))


def reproduce_all(output_root: str | Path | None = None) -> dict[str, dict]:
    root = Path(output_root) if output_root is not None else Path(__file__).parent
    return {
        "canonical_free_rotation": reproduce_canonical_free_rotation(root / "canonical_free_rotation"),
        "canonical_fixed_point": reproduce_canonical_fixed_point(root / "canonical_fixed_point"),
    }
