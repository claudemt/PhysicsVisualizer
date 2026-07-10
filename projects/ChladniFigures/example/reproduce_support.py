from __future__ import annotations

import json
from pathlib import Path

import matplotlib.pyplot as plt

from projects.ChladniFigures.core.modes_circular import CircularMode, compute_annulus_sequence
from projects.ChladniFigures.core.modes_rect import compute_rect_modes
from projects.ChladniFigures.core.static_circular import StaticCircularResult, compute_static_circular_response
from projects.ChladniFigures.core.static_rect import StaticRectResult, compute_static_rect_modal
from utils import image_output
from utils import render_result as rr


ANNULUS_SEQUENCE = [
    (1, 1), (0, 1), (2, 1), (3, 1), (4, 1),
    (0, 2), (1, 2), (5, 1), (2, 2), (6, 1),
    (3, 2), (7, 1), (4, 2), (8, 1), (0, 3),
    (1, 3), (5, 2), (9, 1), (2, 3), (3, 3),
]


def _write_reproduce_entry(output_dir: Path, example: str) -> Path:
    path = output_dir / "reproduce.py"
    path.write_text(
        "from pathlib import Path\n\n"
        f"from projects.ChladniFigures.example.{example}.reproduce import reproduce\n\n\n"
        "if __name__ == \"__main__\":\n"
        "    reproduce(Path(__file__).resolve().parent)\n",
        encoding="utf-8",
    )
    return path


def _finish(paths: list[Path], output_dir: Path, params: dict, report: str, example: str) -> dict:
    composite = image_output.compose_grid(paths, output_dir / "composite.png")
    (output_dir / "parameters.txt").write_text(_format_params(params), encoding="utf-8")
    (output_dir / "parameters.json").write_text(json.dumps(params, indent=2, ensure_ascii=False), encoding="utf-8")
    reproduce_path = _write_reproduce_entry(output_dir, example)
    (output_dir / "reproduction_report.md").write_text(report + "\n", encoding="utf-8")
    image_output.write_manifest(
        output_dir,
        "ChladniFigures",
        example,
        [params],
        [*paths, composite, output_dir / "parameters.txt", output_dir / "parameters.json", reproduce_path],
        report,
    )
    return {"output_dir": output_dir, "paths": paths, "params": params, "report": report}


def _format_params(params: dict) -> str:
    return "\n".join(f"{key} = {value}" for key, value in params.items()) + "\n"


def _mode_fig(mode: CircularMode, title: str):
    fig, axes = rr.new_figure(title, 1, 1, (6.4, 5.6))
    ax = axes[0, 0]
    rr.image(
        ax,
        mode.u,
        f"{mode.tag}, Lambda={mode.lam_disp:.4g}",
        None,
        extent=[mode.x.min(), mode.x.max(), mode.y.min(), mode.y.max()],
        label="$w/w_{max}$",
        aspect="equal",
    )
    rr.set_axis_text(ax, xlabel="$x$", ylabel="$y$", aspect="equal")
    ax.contour(mode.x, mode.y, mode.u, levels=[0], colors="k", linewidths=0.65)
    rr.finish_figure(fig)
    return fig


def _static_fig(result: StaticRectResult | StaticCircularResult, title: str):
    fig, axes = rr.new_figure(title, 1, 1, (6.4, 5.6))
    extent = [result.x.min(), result.x.max(), result.y.min(), result.y.max()]
    load_label = result.load_label.replace(" ", r"\ ")
    plot_title = (
        f"$\\mathrm{{{result.domain}}}\\quad\\mathrm{{{load_label}}}"
        f"\\quad\\nu={result.nu:.4g}\\quad\\xi_0={result.xi0:.4g}\\quad\\mathrm{{{result.boundary}}}$"
    )
    rr.image(axes[0, 0], result.u, plot_title, None, extent=extent, label="$w/w_{max}$", aspect="equal")
    rr.set_axis_text(axes[0, 0], xlabel="$x$", ylabel="$y$", aspect="equal")
    axes[0, 0].contour(result.x, result.y, result.u, levels=[0], colors="k", linewidths=0.65)
    rr.finish_figure(fig)
    return fig


def reproduce_annulus_eigen_mode(output_dir: str | Path | None = None) -> dict:
    output = image_output.ensure_dir(output_dir or Path(__file__).parent / "annulus_eigen_mode" / "generated")
    params = {"type": "annulus", "boundary": "FC", "nu": 0.225, "k": 20, "n": 180, "xi0": 0.2}
    modes = compute_annulus_sequence(ANNULUS_SEQUENCE, boundary="FC", xi0=0.2, grid_n=params["n"])
    paths: list[Path] = []
    for idx, (mode, (m, s)) in enumerate(zip(modes, ANNULUS_SEQUENCE), start=1):
        fig = _mode_fig(mode, f"{idx:02d} Chladni annulus FC m{m} s{s}")
        paths.append(image_output.save_figure(fig, output, f"{idx:02d}_chladni_annulus_fc_m{m}_s{s}.png", title_band=None))
        plt.close(fig)
    return _finish(paths, output, params, "Python reproduction of legacy annulus_eigen_mode using ChladniFigures.core.modes_circular.", "annulus_eigen_mode")


def reproduce_square_eigen_mode(output_dir: str | Path | None = None) -> dict:
    output = image_output.ensure_dir(output_dir or Path(__file__).parent / "square_eigen_mode" / "generated")
    params = {"type": "rect", "boundary": "FFFF", "nu": 0.225, "k": 20, "n": 180, "xi0": 1, "a": 2, "b": 2}
    modes = compute_rect_modes(boundary="FFFF", nu=params["nu"], count=params["k"], grid_n=params["n"], a=2.0, b=2.0)
    paths: list[Path] = []
    for idx, mode in enumerate(modes, start=1):
        fig, axes = rr.new_figure(f"{idx:02d} Chladni rect FFFF mode {idx}", 1, 1, (6.4, 5.6))
        rr.image(axes[0, 0], mode.u, f"FFFF mode {idx}, Lambda={mode.lam_disp:.4g}", None, extent=[-1, 1, -1, 1], label="$w/w_{max}$", aspect="equal")
        rr.set_axis_text(axes[0, 0], xlabel="$x$", ylabel="$y$", aspect="equal")
        axes[0, 0].contour(mode.x, mode.y, mode.u, levels=[0], colors="k", linewidths=0.65)
        rr.finish_figure(fig)
        paths.append(image_output.save_figure(fig, output, f"{idx:02d}_chladni_rect_ffff_mode_{idx}.png", title_band=None))
        plt.close(fig)
    return _finish(paths, output, params, "Python reproduction of legacy square_eigen_mode using ChladniFigures.core.modes_rect.", "square_eigen_mode")


def reproduce_static_point_source(output_dir: str | Path | None = None) -> dict:
    output = image_output.ensure_dir(output_dir or Path(__file__).parent / "static_point_source" / "generated")
    sources = "-0.2 -0.6 -0.6 0; 0.45 0.25 0.1 0.04"
    params = {"type": "mixed", "boundary": "FSCS", "nu": 0.3, "n": 150, "sources": sources}
    cases = [
        ("01_chladni_static_annulus_point_sources.png", compute_static_circular_response(domain="annulus", xi0=0.2, grid_n=150, sources=sources), "annulus point sources"),
        ("02_chladni_static_disk_point_sources.png", compute_static_circular_response(domain="disk", xi0=0.0, grid_n=150, sources=sources), "disk point sources"),
        ("03_chladni_static_rect_point_sources.png", compute_static_rect_modal(boundary="FSCS", nu=0.3, grid_n=150, truncation=40, d_rigidity=0.6, q0=0.0, sources=sources, a=2.0, b=1.8), "rect FSCS point sources"),
        ("04_chladni_static_rect_point_sources.png", compute_static_rect_modal(boundary="SSSS", nu=0.3, grid_n=150, truncation=40, d_rigidity=0.6, q0=0.0, sources=sources, a=2.0, b=1.8), "rect SSSS point sources"),
    ]
    paths: list[Path] = []
    for filename, result, title in cases:
        fig = _static_fig(result, title)
        paths.append(image_output.save_figure(fig, output, filename, title_band=None))
        plt.close(fig)
    return _finish(paths, output, params, "Python reproduction of legacy static_point_source using rectangular and circular static core solvers.", "static_point_source")


def reproduce_all(output_root: str | Path | None = None) -> dict[str, dict]:
    root = Path(output_root) if output_root is not None else Path(__file__).parent
    return {
        "annulus_eigen_mode": reproduce_annulus_eigen_mode(root / "annulus_eigen_mode"),
        "square_eigen_mode": reproduce_square_eigen_mode(root / "square_eigen_mode"),
        "static_point_source": reproduce_static_point_source(root / "static_point_source"),
    }
