from __future__ import annotations

import json
from pathlib import Path

import matplotlib.pyplot as plt
from PIL import Image

from projects.MieScattering.core.fields import compute_fields
from projects.MieScattering.core.params import normalize_params
from projects.MieScattering.core.render import render
from utils import image_output


FIELD_CODES = ("sca_rex", "sca_rey", "sca_rez", "sca_aex", "sca_aey", "sca_aez")
LEGACY_PNG_SIZE = (2708, 2110)
LEGACY_COMPOSITE_SIZE = (8188, 8520)


def _resize_png(path: Path, size: tuple[int, int]) -> Path:
    with Image.open(path) as image:
        image.convert("RGB").resize(size, Image.Resampling.LANCZOS).save(path, dpi=(260, 260))
    return path


def _run_case(output: Path, params: dict, filenames: list[str]) -> tuple[list[Path], list[dict]]:
    bundle = render(params)
    paths: list[Path] = []
    contracts: list[dict] = []
    for fig, filename in zip(bundle.figures, filenames):
        axes = fig.axes[0]
        contracts.append({
            "file": filename,
            "title": axes.get_title(),
            "xlabel": axes.get_xlabel(),
            "ylabel": axes.get_ylabel(),
            "colorbar_label": fig.axes[-1].get_ylabel(),
        })
        path = image_output.save_figure(fig, output, filename, dpi=260, title_band=None, crop=False)
        paths.append(_resize_png(path, LEGACY_PNG_SIZE))
        plt.close(fig)
    for fig in bundle.figures[len(filenames):]:
        plt.close(fig)
    return paths, contracts


def _write_reproduce_entry(output: Path, example: str) -> Path:
    path = output / "reproduce.py"
    path.write_text(
        "from pathlib import Path\n\n"
        f"from projects.MieScattering.example.{example}.reproduce import reproduce\n\n\n"
        "if __name__ == \"__main__\":\n"
        "    reproduce(Path(__file__).resolve().parent)\n",
        encoding="utf-8",
    )
    return path


def _write_parameters(output: Path, run_params: list[dict]) -> None:
    def format_value(value: object) -> str:
        if isinstance(value, list):
            return "{" + ", ".join(str(item) for item in value) + "}"
        if isinstance(value, bool):
            return "1" if value else "0"
        return str(value)

    lines = []
    for index, params in enumerate(run_params, start=1):
        for key, value in params.items():
            lines.append(f"run_{index:02d}.{key} = {format_value(value)}")
    (output / "parameters.txt").write_text("\n".join(lines) + "\n", encoding="utf-8")
    (output / "parameters.json").write_text(json.dumps({"runs": run_params}, indent=2), encoding="utf-8")


def _finish(paths: list[Path], output: Path, run_params: list[dict], contracts: list[dict], report: str, example: str) -> dict:
    composite = image_output.compose_grid(paths, output / "composite.png")
    _resize_png(composite, LEGACY_COMPOSITE_SIZE)
    _write_parameters(output, run_params)
    reproduce_path = _write_reproduce_entry(output, example)
    (output / "reproduction_report.md").write_text(report, encoding="utf-8")
    image_output.write_manifest(
        output,
        "MieScattering",
        example,
        run_params,
        [*paths, composite, output / "parameters.txt", output / "parameters.json", reproduce_path],
        report + "\nFigure title, axis-label, and colorbar-label contracts are recorded in parity_manifest.json.",
    )
    parity_manifest = {
        "legacy_reference": f"legacy/matlab/projects/MieScattering/example/{example}",
        "png_size": list(LEGACY_PNG_SIZE),
        "composite_size": list(LEGACY_COMPOSITE_SIZE),
        "figures": contracts,
        "known_non_pixel_equivalence": [
            "MATLAB and Matplotlib use different rasterizers, fonts, colormap implementations, and layout engines.",
            "The sphere series uses SciPy special functions rather than MATLAB's VSWF implementation.",
        ],
    }
    (output / "parity_manifest.json").write_text(json.dumps(parity_manifest, indent=2), encoding="utf-8")
    return {"output_dir": output, "paths": paths, "params": {"runs": run_params}, "report": report}


def _base(geometry: str, slice_type: str, include_emag: bool = False) -> dict:
    selection = list(FIELD_CODES)
    if include_emag:
        selection.append("sca_emag")
    return {
        "eps1": "2+0.2i",
        "mu1": "0.8+0.2i",
        "R_over_lambda": 0.5,
        "nu": 1.1,
        "psi": 0.2,
        "geometry": geometry,
        "mode": "custom",
        "customSelection": selection,
        "gridHalfWidth": 2.5,
        "N": 220,
        "nmaxExtra": 15,
        "maskInside": True,
        "sliceType": slice_type,
        "slicePos_over_lambda": 0.1,
    }


def reproduce_parallel_slice(output_dir: str | Path | None = None) -> dict:
    output = image_output.ensure_dir(output_dir or Path(__file__).parent / "parallel_slice" / "generated")
    cyl_names = [
        "01_cyl_sca_re_ex_slice_xy_pos_0_1.png",
        "02_cyl_sca_re_ey_slice_xy_pos_0_1.png",
        "03_cyl_sca_re_ez_slice_xy_pos_0_1.png",
        "04_cyl_sca_ex_mag_slice_xy_pos_0_1.png",
        "05_cyl_sca_ey_mag_slice_xy_pos_0_1.png",
        "06_cyl_sca_ez_mag_slice_xy_pos_0_1.png",
    ]
    sph_names = [
        "07_sph_sca_re_ex_slice_xz_pos_0_1.png",
        "08_sph_sca_re_ey_slice_xz_pos_0_1.png",
        "09_sph_sca_re_ez_slice_xz_pos_0_1.png",
        "10_sph_sca_ex_mag_slice_xz_pos_0_1.png",
        "11_sph_sca_ey_mag_slice_xz_pos_0_1.png",
        "12_sph_sca_ez_mag_slice_xz_pos_0_1.png",
    ]
    run_01 = _base("cylinder", "xy", include_emag=True)
    run_02 = _base("sphere", "xz", include_emag=True)
    paths, contracts = _run_case(output, run_01, cyl_names)
    next_paths, next_contracts = _run_case(output, run_02, sph_names)
    return _finish(paths + next_paths, output, [run_01, run_02], contracts + next_contracts, "Python reproduction of legacy parallel_slice field bundle.", "parallel_slice")


def reproduce_perpendicular_slice(output_dir: str | Path | None = None) -> dict:
    output = image_output.ensure_dir(output_dir or Path(__file__).parent / "perpendicular_slice" / "generated")
    sph_names = [
        "01_sph_sca_re_ex_slice_xy_pos_0_1.png",
        "02_sph_sca_re_ey_slice_xy_pos_0_1.png",
        "03_sph_sca_re_ez_slice_xy_pos_0_1.png",
        "04_sph_sca_ex_mag_slice_xy_pos_0_1.png",
        "05_sph_sca_ey_mag_slice_xy_pos_0_1.png",
        "06_sph_sca_ez_mag_slice_xy_pos_0_1.png",
    ]
    cyl_names = [
        "07_cyl_sca_re_ex_slice_xz_pos_0_1.png",
        "08_cyl_sca_re_ey_slice_xz_pos_0_1.png",
        "09_cyl_sca_re_ez_slice_xz_pos_0_1.png",
        "10_cyl_sca_ex_mag_slice_xz_pos_0_1.png",
        "11_cyl_sca_ey_mag_slice_xz_pos_0_1.png",
        "12_cyl_sca_ez_mag_slice_xz_pos_0_1.png",
    ]
    run_01 = _base("sphere", "xy")
    run_02 = _base("cylinder", "xz")
    paths, contracts = _run_case(output, run_01, sph_names)
    next_paths, next_contracts = _run_case(output, run_02, cyl_names)
    return _finish(paths + next_paths, output, [run_01, run_02], contracts + next_contracts, "Python reproduction of legacy perpendicular_slice field bundle.", "perpendicular_slice")


def invariant_parallel_shape() -> tuple[int, int]:
    params = _base("sphere", "xz")
    params["N"] = 180
    cfg = normalize_params(params)
    fields = compute_fields(cfg)
    return fields["Esca_x"].shape


def reproduce_all(output_root: str | Path | None = None) -> dict[str, dict]:
    root = Path(output_root) if output_root is not None else Path(__file__).parent
    return {
        "parallel_slice": reproduce_parallel_slice(root / "parallel_slice"),
        "perpendicular_slice": reproduce_perpendicular_slice(root / "perpendicular_slice"),
    }
