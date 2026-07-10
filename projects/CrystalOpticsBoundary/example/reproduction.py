from __future__ import annotations

import argparse
from datetime import datetime
from pathlib import Path

from projects.CrystalOpticsBoundary.core import model
from projects.CrystalOpticsBoundary.app.params import params_to_config
from projects.CrystalOpticsBoundary.core.formula import crystal_boundary_formula
from utils import image_output
from utils.image_output import write_manifest


PROJECT = "CrystalOpticsBoundary"


def _write_parameters(folder: Path) -> Path:
    lines = [
        f"Generated: {datetime.now():%Y-%m-%d %H:%M:%S}",
        "",
        "n_inc = 1",
        "k_inc = [0.560968194005;0.785355471607;-0.261785157202]",
        "pol.type = 2",
        "pol.angle_deg = 0",
        "orientation.mode = matrix",
        "orientation.R = [1 0 0.3;0 1 0;-0.2 0 1]",
        "eps_diag = [2.5 2.5 3.2]",
        "eps_lab = []",
        "# Python input alias: orientation_R",
    ]
    path = folder / "parameters.txt"
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    return path


def _write_reproduce_code(folder: Path, example: str) -> Path:
    path = folder / "reproduce_code.py"
    path.write_text(
        "from projects.CrystalOpticsBoundary.example.reproduction import main\n\n"
        f"if __name__ == '__main__':\n    main('{example}')\n",
        encoding="utf-8",
    )
    return path


def typical_example(output: str | Path | None = None) -> list[Path]:
    folder = image_output.ensure_dir(output or Path(__file__).parent / "typical_example")
    params = {
        "n_incident": 1.0,
        "n_inc": 1.0,
        "k_inc": "0.560968194005 0.785355471607 -0.261785157202",
        "alpha_deg": 0.0,
        "orientation": "matrix",
        "orientation_R": "1 0 0.3\n0 1 0\n-0.2 0 1",
        "eps_diag": "2.5 2.5 3.2",
    }
    bundle = model.render(params)
    outputs = []
    results_path = folder / "results.txt"
    results_path.write_text(bundle.report, encoding="utf-8")
    outputs.append(results_path)
    outputs.append(_write_parameters(folder))
    outputs.append(_write_reproduce_code(folder, "typical_example"))
    result = crystal_boundary_formula(params_to_config(params))
    outputs.append(write_manifest(folder, PROJECT, "typical_example", [params], outputs, f"balance={result['single']['energy']['balance']}"))
    return outputs


def energy_balance() -> float:
    params = {
        "n_incident": 1.0,
        "k_inc": "0.560968194005 0.785355471607 -0.261785157202",
        "orientation": "matrix",
        "orientation_R": "1 0 0.3\n0 1 0\n-0.2 0 1",
        "eps_diag": "2.5 2.5 3.2",
    }
    return float(abs(crystal_boundary_formula(params_to_config(params))["single"]["energy"]["balance"]))


def main(example: str | None = None, output: str | Path | None = None) -> list[Path]:
    runners = {"typical_example": typical_example}
    if example is None:
        parser = argparse.ArgumentParser()
        parser.add_argument("example", choices=sorted(runners))
        parser.add_argument("--output", type=Path)
        args = parser.parse_args()
        example = args.example
        output = args.output
    return runners[example](output)


if __name__ == "__main__":
    main()

