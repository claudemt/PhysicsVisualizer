from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime
from typing import Mapping, Sequence

from utils import image_output


HistoryRef = tuple[int, int]


@dataclass(frozen=True)
class HistoryFigure:
    """A live figure reference and its stable display metadata."""

    run_index: int
    item_index: int
    figure: object
    title: str

    @property
    def ref(self) -> HistoryRef:
        return (self.run_index, self.item_index)

    def payload_ref(self) -> dict[str, int]:
        return {"run_index": self.run_index, "item_index": self.item_index}


@dataclass(frozen=True)
class HistoryRun:
    """One Generate result, scoped by the shared window's project/tab key."""

    index: int
    params: dict[str, object]
    title: str
    report: str
    figures: tuple[HistoryFigure, ...]
    created_at: datetime


@dataclass
class TabRunHistory:
    """In-memory Generate history that makes no assumptions about a project."""

    runs: list[HistoryRun] = field(default_factory=list)
    selection: set[HistoryRef] = field(default_factory=set)

    def append(self, params: Mapping[str, object], bundle) -> HistoryRun:
        run_index = len(self.runs) + 1
        fallback = str(getattr(bundle, "title", "result") or "result")
        figures = tuple(
            HistoryFigure(
                run_index=run_index,
                item_index=item_index,
                figure=figure,
                title=image_output.figure_title(figure, fallback),
            )
            for item_index, figure in enumerate(getattr(bundle, "figures", ()), start=1)
        )
        run = HistoryRun(
            index=run_index,
            params=dict(params),
            title=fallback,
            report=str(getattr(bundle, "report", "") or ""),
            figures=figures,
            created_at=datetime.now(),
        )
        self.runs.append(run)
        self.selection.update(figure.ref for figure in figures)
        return run

    def figures(self) -> list[HistoryFigure]:
        return [figure for run in self.runs for figure in run.figures]

    def latest_figures(self) -> list[HistoryFigure]:
        return list(self.runs[-1].figures) if self.runs else []

    def selected_figures(self) -> list[HistoryFigure]:
        return [figure for figure in self.figures() if figure.ref in self.selection]

    def set_selection(self, refs: Sequence[HistoryRef]) -> None:
        available = {figure.ref for figure in self.figures()}
        self.selection = {tuple(ref) for ref in refs if tuple(ref) in available}

    def payload(self, figures: Sequence[HistoryFigure]) -> dict[str, object]:
        """Return the project-neutral multi-run payload used by history-aware renderers."""
        return {
            "history_runs": [dict(run.params) for run in self.runs],
            "history_selection": [figure.payload_ref() for figure in figures],
        }
