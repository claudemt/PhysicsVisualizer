from __future__ import annotations

import argparse
from datetime import datetime
from pathlib import Path

from projects.ThinFilm.core.thin_film import render_report
from projects.ThinFilm.core.thin_film.model import elastic_defaults, optical_defaults
from utils import image_output
from utils.image_output import write_manifest


PROJECT = "ThinFilm"


def _write_parameters(folder: Path, lines: list[str]) -> Path:
    lines = [f"Generated: {datetime.now():%Y-%m-%d %H:%M:%S}", "", *lines]
    path = folder / "parameters.txt"
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    return path


def _write_reproduce_code(folder: Path, example: str) -> Path:
    path = folder / "reproduce_code.py"
    path.write_text(
        "from projects.ThinFilm.example.reproduction import main\n\n"
        f"if __name__ == '__main__':\n    main('{example}')\n",
        encoding="utf-8",
    )
    return path


def thin_film_elastic(output: str | Path | None = None) -> list[Path]:
    folder = image_output.ensure_dir(output or Path(__file__).parent / "thin_film_elastic")
    data = elastic_defaults()
    data["layers"] = [
        {"lambda": 4.0, "mu": 1.5, "eta": 4.4, "h": 9.8},
        {"lambda": 1.0, "mu": 1.1, "eta": 1.5, "h": 6.0},
        {"lambda": 2.1, "mu": 3.1, "eta": 5.4, "h": 1.0},
    ]
    result, text = render_report("elastic", data)
    outputs = []
    results_path = folder / "results.txt"
    results_path.write_text(text, encoding="utf-8")
    outputs.append(results_path)
    outputs.append(_write_parameters(folder, [
        "omega = 1",
        "kx = 0.1",
        "phii = 1",
        "psii = 1",
        "a.lambda = 1.3",
        "a.mu = 1",
        "a.eta = 1",
        "g.lambda = 1.3",
        "g.mu = 5.2",
        "g.eta = 1.9",
        "N = 3",
        "layers_table = [4 1.5 4.4 9.8;1 1.1 1.5 6;2.1 3.1 5.4 1]",
    ]))
    outputs.append(_write_reproduce_code(folder, "thin_film_elastic"))
    outputs.append(write_manifest(folder, PROJECT, "thin_film_elastic", [data], outputs, f"EP={result['EP']}; ESV={result['ESV']}; ESH={result['ESH']}"))
    return outputs


def thin_film_optical(output: str | Path | None = None) -> list[Path]:
    folder = image_output.ensure_dir(output or Path(__file__).parent / "thin_film_optical")
    data = optical_defaults()
    data["theta_a"] = 0.68
    data["layers"] = [
        {"eps": 2.25, "mu": 1.0, "h": 1.111},
        {"eps": 1.12, "mu": 1.3, "h": 2.0},
        {"eps": 1.5, "mu": 1.0, "h": 3.1},
    ]
    result, text = render_report("optical", data)
    outputs = []
    results_path = folder / "results.txt"
    results_path.write_text(text, encoding="utf-8")
    outputs.append(results_path)
    outputs.append(_write_parameters(folder, [
        "omega = 1",
        "theta_a = 0.68",
        "a.eps = 1",
        "a.mu = 1",
        "g.eps = 2.25",
        "g.mu = 1",
        "N = 3",
        "layers_table = [2.25 1 1.111;1.12 1.3 2;1.5 1 3.1]",
    ]))
    outputs.append(_write_reproduce_code(folder, "thin_film_optical"))
    outputs.append(write_manifest(folder, PROJECT, "thin_film_optical", [data], outputs, f"Es={result['Es']}; Ep={result['Ep']}"))
    return outputs


def main(example: str | None = None, output: str | Path | None = None) -> list[Path]:
    runners = {
        "thin_film_elastic": thin_film_elastic,
        "thin_film_optical": thin_film_optical,
    }
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

