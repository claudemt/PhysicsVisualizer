from __future__ import annotations

import argparse
import importlib
import inspect
import subprocess
import sys
from pathlib import Path

import matplotlib

from utils import image_output
from app.project_registry import get_project, project_names


ROOT = Path(__file__).resolve().parent


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="physics-visualizer")
    parser.add_argument("--list", action="store_true", help="List available Python projects.")
    parser.add_argument("--project", default="", help="Project name to render in batch mode.")
    parser.add_argument("--export", default="", help="Export directory for batch rendering.")
    parser.add_argument(
        "--reproduce",
        nargs="?",
        const="all",
        default="",
        help="Run Python example reproduction entries. Use all, Project, or Project/example.",
    )
    parser.add_argument("--no-gui", action="store_true", help="Do not launch the PySide6 desktop GUI.")
    return parser


def render_project(name: str, export_dir: str | Path):
    matplotlib.use("Agg", force=True)
    project = get_project(name)
    bundle = project.render(dict(project.defaults))
    paths = image_output.export_bundle(
        project.name, bundle.figures, export_dir, project.defaults, bundle.report,
        tab_key="default",
    )
    return paths


def default_project_output_dir(name: str) -> Path:
    project = get_project(name)
    return ROOT / "projects" / project.name / "output"


def default_reproduction_output_dir(project: str, example: str) -> Path:
    return ROOT / "projects" / project / "output" / "reproduction" / example


def list_reproduction_entries() -> list[tuple[str, str, Path]]:
    entries: list[tuple[str, str, Path]] = []
    projects_dir = ROOT / "projects"
    for project_dir in sorted(path for path in projects_dir.iterdir() if path.is_dir() and path.name != "__pycache__"):
        example_dir = project_dir / "example"
        if not example_dir.is_dir():
            continue
        for candidate in sorted(path for path in example_dir.iterdir() if path.is_dir()):
            script = candidate / "reproduce.py"
            if script.is_file():
                entries.append((project_dir.name, candidate.name, script))
    return entries


def _matches_reproduction(selector: str, project: str, example: str) -> bool:
    if selector in {"", "all"}:
        return True
    selector_norm = selector.replace("\\", "/").strip("/")
    return selector_norm == project or selector_norm == f"{project}/{example}"


def _run_reproduction_module(project: str, example: str, script: Path, output_dir: Path):
    module_name = f"projects.{project}.example.{example}.reproduce"
    module = importlib.import_module(module_name)
    if callable(getattr(module, "reproduce", None)):
        return module.reproduce(output_dir)
    if callable(getattr(module, "main", None)):
        signature = inspect.signature(module.main)
        if signature.parameters:
            return module.main(output_dir)
    subprocess.run(
        [sys.executable, str(script), "--output", str(output_dir)],
        cwd=ROOT,
        check=True,
    )
    return output_dir


def run_reproductions(selector: str, export_root: str | Path | None = None) -> list[Path]:
    matplotlib.use("Agg", force=True)
    root = image_output.ensure_dir(export_root) if export_root is not None else None
    selected = [
        (project, example, script)
        for project, example, script in list_reproduction_entries()
        if _matches_reproduction(selector, project, example)
    ]
    if not selected:
        known = ", ".join(f"{project}/{example}" for project, example, _ in list_reproduction_entries())
        raise SystemExit(f"No reproduction entry matched {selector!r}. Known entries: {known}")

    output_dirs: list[Path] = []
    for project, example, script in selected:
        out = image_output.ensure_dir(root / project / example) if root is not None else image_output.ensure_dir(default_reproduction_output_dir(project, example))
        _run_reproduction_module(project, example, script, out)
        output_dirs.append(out)
    return output_dirs


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    if args.list:
        for name in project_names():
            print(name)
        return 0
    if args.project:
        out = Path(args.export) if args.export else default_project_output_dir(args.project)
        paths = render_project(args.project, out)
        for path in paths:
            print(path)
        return 0
    if args.reproduce:
        out = Path(args.export) if args.export else None
        paths = run_reproductions(args.reproduce, out)
        for path in paths:
            print(path)
        return 0
    if args.no_gui:
        print("No project selected. Use --list or --project NAME --export DIR.")
        return 0
    from app.main_window import run
    return run()


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
