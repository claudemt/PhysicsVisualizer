from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any


@dataclass(frozen=True)
class ControlSpec:
    key: str
    label: str
    kind: str = "text"
    default: Any = ""
    options: tuple[str, ...] = ()
    tooltip: str = ""
    depends_on: str = ""
    options_by: dict[str, tuple[str, ...]] = field(default_factory=dict)
    visible_when: dict[str, tuple[Any, ...]] = field(default_factory=dict)
    enabled_when: dict[str, tuple[Any, ...]] = field(default_factory=dict)
    preset_values: dict[str, dict[str, Any]] = field(default_factory=dict)


@dataclass(frozen=True)
class SectionSpec:
    title: str
    controls: tuple[ControlSpec, ...] = ()


@dataclass(frozen=True)
class TabSpec:
    key: str
    title: str
    preview: str = "list"
    notes_title: str = "notes"
    initial_message: str = "run to generate result"
    sections: tuple[SectionSpec, ...] = ()
    render_overrides: dict[str, Any] = field(default_factory=dict)


def c(key: str, label: str, kind: str = "text", default="", options=(), tooltip: str = "", *,
      depends_on: str = "", options_by=None, visible_when=None, enabled_when=None,
      preset_values=None) -> ControlSpec:
    return ControlSpec(
        key=key,
        label=label,
        kind=kind,
        default=default,
        options=tuple(options),
        tooltip=tooltip,
        depends_on=depends_on,
        options_by={str(name): tuple(items) for name, items in dict(options_by or {}).items()},
        visible_when={str(name): tuple(items) for name, items in dict(visible_when or {}).items()},
        enabled_when={str(name): tuple(items) for name, items in dict(enabled_when or {}).items()},
        preset_values={str(name): dict(values) for name, values in dict(preset_values or {}).items()},
    )


def section(title: str, *controls: ControlSpec) -> SectionSpec:
    return SectionSpec(title=title, controls=tuple(controls))


def tab(
    key: str,
    title: str,
    *sections: SectionSpec,
    preview: str = "list",
    initial_message: str = "run to generate result",
    **overrides,
) -> TabSpec:
    return TabSpec(
        key=key,
        title=title,
        preview=preview,
        initial_message=initial_message,
        sections=tuple(sections),
        render_overrides=dict(overrides),
    )
