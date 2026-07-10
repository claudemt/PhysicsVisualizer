from __future__ import annotations

from dataclasses import dataclass
from importlib import import_module
from pathlib import Path
from typing import Callable

from utils.render_result import RenderBundle


REPOSITORY_ROOT = Path(__file__).resolve().parents[1]

Params = dict[str, float | int | str | bool]
RenderFn = Callable[[Params], RenderBundle]
ExportHandler = Callable[..., object]


@dataclass(frozen=True)
class ProjectSpec:
    name: str
    title: str
    description: str
    defaults: Params
    render: RenderFn
    formulas: str
    docs_path: str | None = None
    export_handler: ExportHandler | None = None

    @property
    def legacy_docs(self) -> str | None:
        return self.docs_path


PROJECT_ORDER = [
    "ChladniFigures",
    "CreativePlotStudio",
    "CrystalOpticsBoundary",
    "GraphiteLevitation",
    "MieScattering",
    "MovingChargeFields",
    "OpticsStudio",
    "RigidBodyRotation",
    "SpecialFunctionsStudio",
    "ThinFilm",
    "Waveguide",
]


def _docs_path(project: str) -> str | None:
    path = REPOSITORY_ROOT / "projects" / project / "docs" / "physical_formulas.md"
    if path.exists():
        return str(path)
    path = REPOSITORY_ROOT / "legacy" / "matlab" / "projects" / project / "docs" / "physical_formulas.md"
    return str(path) if path.exists() else None


def _load_project(project: str) -> ProjectSpec:
    model = import_module(f"projects.{project}.core.model")
    return ProjectSpec(
        name=project,
        title=str(model.TITLE),
        description=str(model.DESCRIPTION),
        defaults=dict(model.DEFAULTS),
        render=model.render,
        formulas=str(model.FORMULAS),
        docs_path=_docs_path(project),
        export_handler=_discover_export_handler(project, model),
    )


def _discover_export_handler(project: str, model) -> ExportHandler | None:
    """Discover an optional project export hook without project-specific imports.

    Projects may expose ``export_handler``, ``export_bundle``, or ``export_video``
    from ``core.model``. Existing projects can also provide the same callable from
    their conventional ``example.reproduce_support`` module.
    """
    modules = [model]
    try:
        modules.append(import_module(f"projects.{project}.example.reproduce_support"))
    except Exception:  # Optional convention; importing it must not block the GUI.
        pass
    for module in modules:
        for attribute in ("export_handler", "export_bundle", "export_video"):
            handler = getattr(module, attribute, None)
            if callable(handler):
                return handler
    return None


PROJECTS: dict[str, ProjectSpec] = {name: _load_project(name) for name in PROJECT_ORDER}


def project_names() -> list[str]:
    return list(PROJECTS)


def get_project(name: str) -> ProjectSpec:
    if name in PROJECTS:
        return PROJECTS[name]
    folded = {key.lower(): key for key in PROJECTS}
    key = folded.get(name.lower())
    if key:
        return PROJECTS[key]
    raise KeyError(f"Unknown project {name!r}. Available: {', '.join(PROJECTS)}")


def render_project(name: str):
    project = get_project(name)
    return project.render(dict(project.defaults))
