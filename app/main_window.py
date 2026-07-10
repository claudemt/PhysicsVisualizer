from __future__ import annotations

import sys
import tempfile
from io import BytesIO
from html import escape
from datetime import datetime
from functools import lru_cache
from importlib import import_module
from inspect import Parameter, signature
from pathlib import Path
from typing import Mapping

from PySide6.QtCore import QObject, QItemSelectionModel, QSignalBlocker, Qt, QThread, Signal
from PySide6.QtGui import QFont, QFontDatabase, QPixmap
from PySide6.QtWidgets import (
    QApplication,
    QAbstractItemView,
    QCheckBox,
    QComboBox,
    QFrame,
    QGridLayout,
    QGroupBox,
    QHBoxLayout,
    QLabel,
    QLineEdit,
    QListWidget,
    QListWidgetItem,
    QMainWindow,
    QMessageBox,
    QProgressBar,
    QPushButton,
    QScrollArea,
    QSplitter,
    QSizePolicy,
    QTabWidget,
    QTextEdit,
    QVBoxLayout,
    QWidget,
)

from utils import image_output, style
from utils.control_schema import ControlSpec, TabSpec
from app.run_history import HistoryFigure, TabRunHistory
from app.project_registry import PROJECTS, REPOSITORY_ROOT, ProjectSpec


def _qt_font_family() -> str:
    _register_qt_fonts()
    families = set(QFontDatabase.families())
    for family in ("Microsoft YaHei UI", "Microsoft YaHei", "Segoe UI", "Arial", "DejaVu Sans", "Tahoma"):
        if family in families:
            return family
    return QApplication.font().family() or "Sans Serif"


@lru_cache(maxsize=1)
def _register_qt_fonts() -> None:
    """Make GUI fonts available even when Qt's platform plugin finds none."""
    candidates = (
        Path("C:/Windows/Fonts/msyh.ttc"),
        Path("C:/Windows/Fonts/segoeui.ttf"),
        Path("C:/Windows/Fonts/arial.ttf"),
        Path("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"),
    )
    for path in candidates:
        if path.is_file():
            QFontDatabase.addApplicationFont(str(path))


def _apply_app_style(app: QApplication) -> None:
    app.setFont(QFont(_qt_font_family(), style.tokens().font_size))
    if not app.styleSheet():
        app.setStyleSheet(style.qt_stylesheet(_qt_font_family()))


def run_project_from_file(file_path: str) -> int:
    return run_project(Path(file_path).resolve().parent.name)


class _RenderWorker(QObject):
    """Run project.render() off the GUI thread and report progress/result/error."""

    progress = Signal(str, int)
    finished = Signal(object)
    failed = Signal(str)

    def __init__(self, project: ProjectSpec, params: dict):
        super().__init__()
        self.project = project
        self.params = params

    def run(self) -> None:
        try:
            self.progress.emit("Rendering…", 30)
            bundle = self.project.render(self.params)
            self.progress.emit("Finalizing figures…", 90)
            self.finished.emit(bundle)
        except Exception as exc:  # noqa: BLE001 - surface to GUI
            self.failed.emit(str(exc))


class _ExportWorker(QObject):
    progress = Signal(str, int)
    finished = Signal(list, str)
    failed = Signal(str)

    def __init__(
        self,
        project: ProjectSpec,
        tab_key: str,
        figures,
        params,
        report: str,
        folder: Path,
    ):
        super().__init__()
        self.project = project
        self.tab_key = tab_key
        self.figures = figures
        self.params = params
        self.report = report
        self.folder = folder

    def run(self) -> None:
        try:
            if self.project.export_handler is not None and _requests_video(self.params):
                self.progress.emit("Exporting video…", 20)
                paths = _run_export_handler(
                    self.project.export_handler,
                    project_name=self.project.name,
                    tab_key=self.tab_key,
                    figures=self.figures,
                    params=self.params,
                    report=self.report,
                    folder=self.folder,
                )
            else:
                self.progress.emit("Saving figures…", 20)
                paths = image_output.export_bundle(
                    self.project.name,
                    self.figures,
                    self.folder,
                    self.params,
                    self.report,
                    tab_key=self.tab_key,
                )
            self.progress.emit("Writing composite and reports…", 90)
            self.finished.emit(paths, str(self.folder))
        except Exception as exc:  # noqa: BLE001
            self.failed.emit(str(exc))


def _requests_video(params: Mapping[str, object]) -> bool:
    """Recognize a video request from common, project-neutral parameter shapes."""
    for key, value in params.items():
        key_text = str(key).casefold()
        value_text = str(value).strip().casefold()
        if "video" in key_text and value_text not in {"", "0", "false", "none", "off", "no"}:
            return True
        if key_text.endswith("mode") and "video" in value_text:
            return True
    return False


def _run_export_handler(
    handler,
    *,
    project_name: str,
    tab_key: str,
    figures,
    params: Mapping[str, object],
    report: str,
    folder: Path,
) -> list[Path]:
    """Call a project export convention using only its declared parameter names."""
    context = {
        "output": folder,
        "output_dir": folder,
        "folder": folder,
        "destination": folder,
        "params": dict(params),
        "parameters": dict(params),
        "scenario": tab_key,
        "tab_key": tab_key,
        "project": project_name,
        "project_name": project_name,
        "figures": list(figures),
        "report": report,
        "notes": report,
    }
    args = []
    kwargs = {}
    accepts_kwargs = False
    bound_names = set()
    for parameter in signature(handler).parameters.values():
        if parameter.kind == Parameter.VAR_KEYWORD:
            accepts_kwargs = True
            continue
        if parameter.kind == Parameter.VAR_POSITIONAL:
            continue
        if parameter.name not in context:
            if parameter.default is Parameter.empty:
                raise TypeError(
                    f"Export handler {handler!r} requires unsupported parameter {parameter.name!r}."
                )
            continue
        if parameter.kind == Parameter.POSITIONAL_ONLY:
            args.append(context[parameter.name])
        else:
            kwargs[parameter.name] = context[parameter.name]
        bound_names.add(parameter.name)
    if accepts_kwargs:
        kwargs.update({key: value for key, value in context.items() if key not in bound_names})
    return _export_paths(handler(*args, **kwargs))


def _export_paths(result: object) -> list[Path]:
    """Normalize project hook return values for the shared completion message."""
    if result is None:
        return []
    if isinstance(result, Mapping):
        values = []
        for key in ("paths", "path", "video", "videos"):
            if key in result:
                values.append(result[key])
        result = values or list(result.values())
    if isinstance(result, (str, Path)):
        return [Path(result)]
    try:
        items = list(result)
    except TypeError:
        return [Path(result)]
    paths: list[Path] = []
    for item in items:
        if isinstance(item, Mapping):
            paths.extend(_export_paths(item))
        elif isinstance(item, (str, Path)):
            paths.append(Path(item))
    return paths


class _StaticFigurePreview(QWidget):
    """A read-only pixmap preview. The source matplotlib figure is not interactive."""

    def __init__(self, fig):
        super().__init__()
        self.label = QLabel(self)
        self.label.setAlignment(Qt.AlignCenter)
        self.label.setObjectName("StaticFigurePreview")
        self._pixmap = self._render_pixmap(fig)
        self._configure_widget()

    def _configure_widget(self) -> None:
        self.setMinimumSize(300, 220)
        self.setSizePolicy(QSizePolicy.Expanding, QSizePolicy.Expanding)
        self.setMouseTracking(False)

    @staticmethod
    def _render_pixmap(fig) -> QPixmap:
        buffer = BytesIO()
        fig.savefig(buffer, format="png", dpi=240, facecolor="white", bbox_inches="tight", pad_inches=0.18)
        pixmap = QPixmap()
        pixmap.loadFromData(buffer.getvalue(), "PNG")
        return pixmap

    def _sync_pixmap(self) -> None:
        if self._pixmap.isNull():
            return
        target = self.rect().size()
        scaled = self._pixmap.scaled(target, Qt.KeepAspectRatio, Qt.SmoothTransformation)
        self.label.setPixmap(scaled)
        self.label.setGeometry(self.rect())

    def resizeEvent(self, event) -> None:  # noqa: N802 - Qt API
        self._sync_pixmap()
        super().resizeEvent(event)


class _StaticPixmapPreview(_StaticFigurePreview):
    """Read-only preview for an already rendered pixmap."""

    def __init__(self, pixmap: QPixmap, object_name: str = "StaticCompositePreview"):
        QWidget.__init__(self)
        self.label = QLabel(self)
        self.label.setAlignment(Qt.AlignCenter)
        self.label.setObjectName(object_name)
        self._pixmap = pixmap
        self._configure_widget()


class ProjectControls(QWidget):
    def __init__(self, project: ProjectSpec, tab: TabSpec):
        super().__init__()
        self.setObjectName("ProjectControls")
        self.project = project
        self.tab = tab
        self.fields: dict[str, tuple[ControlSpec, QWidget]] = {}
        self.field_rows: dict[str, QWidget] = {}
        self.field_labels: dict[str, QLabel] = {}
        self._sections: list[tuple[QFrame, QGridLayout, QLabel, list[str]]] = []
        self._updating = False
        self._column_count = 2
        self._tokens = style.tokens()
        layout = QVBoxLayout(self)
        cp = self._tokens.control_padding
        layout.setContentsMargins(cp, cp, cp, cp)
        layout.setSpacing(self._tokens.layout_spacing)
        for section in tab.sections:
            if not section.controls:
                continue
            group = QFrame()
            group.setObjectName("ControlSection")
            grid = QGridLayout(group)
            grid.setContentsMargins(cp, cp, cp, cp)
            grid.setHorizontalSpacing(cp)
            grid.setVerticalSpacing(max(2, cp - 2))
            heading = QLabel(section.title)
            heading.setObjectName("SectionTitle")
            heading.setWordWrap(True)
            heading.setSizePolicy(QSizePolicy.Ignored, QSizePolicy.Preferred)
            heading_font = heading.font()
            heading_font.setBold(True)
            heading.setFont(heading_font)
            keys: list[str] = []
            for control in section.controls:
                self._build_field_cell(control)
                keys.append(control.key)
            self._sections.append((group, grid, heading, keys))
            layout.addWidget(group)
        layout.addStretch(1)
        self._relayout_sections()
        self._connect_dynamic_controls()
        self._sync_dynamic()

    def _label_for(self, control: ControlSpec) -> QLabel:
        label = QLabel(control.label)
        label.setObjectName("FieldLabel")
        label.setAlignment(Qt.AlignLeft | Qt.AlignBottom)
        label.setWordWrap(True)
        label.setMinimumWidth(0)
        label.setMaximumWidth(16777215)
        label.setSizePolicy(QSizePolicy.Ignored, QSizePolicy.Preferred)
        return label

    def _build_field_cell(self, control: ControlSpec) -> None:
        cell = QWidget()
        cell.setObjectName("FieldCell")
        cell_layout = QVBoxLayout(cell)
        cell_layout.setContentsMargins(0, 0, 0, 0)
        cell_layout.setSpacing(self._tokens.dense_spacing)
        label = self._label_for(control)
        widget = self._make_widget(control)
        if control.tooltip:
            label.setToolTip(control.tooltip)
            widget.setToolTip(control.tooltip)
        cell_layout.addWidget(label)
        cell_layout.addWidget(widget)
        field_height = max(24, widget.minimumSizeHint().height(), widget.minimumHeight())
        label_height = max(16, label.minimumSizeHint().height())
        cell.setMinimumHeight(label_height + field_height + self._tokens.dense_spacing)
        self.fields[control.key] = (control, widget)
        self.field_rows[control.key] = cell
        self.field_labels[control.key] = label

    def _relayout_sections(self) -> None:
        tall_kinds = {"textarea", "matrix", "listbox", "multiselect"}
        for _group, grid, heading, keys in self._sections:
            while grid.count():
                grid.takeAt(0)
            for column in range(self._column_count):
                grid.setColumnStretch(column, 1)
            grid.addWidget(heading, 0, 0, 1, self._column_count)
            row = 1
            column = 0
            for key in keys:
                control, _widget = self.fields[key]
                cell = self.field_rows[key]
                if cell.isHidden():
                    continue
                tall = control.kind.lower() in tall_kinds
                if tall:
                    if column:
                        row += 1
                        column = 0
                    grid.addWidget(cell, row, 0, 1, self._column_count)
                    row += 1
                    continue
                grid.addWidget(cell, row, column)
                column += 1
                if column >= self._column_count:
                    row += 1
                    column = 0

    def resizeEvent(self, event) -> None:  # noqa: N802 - Qt API
        columns = 1 if event.size().width() < 300 else 2
        if columns != self._column_count:
            self._column_count = columns
            self._relayout_sections()
        super().resizeEvent(event)

    def _make_widget(self, control: ControlSpec) -> QWidget:
        default = self.project.defaults.get(control.key, control.default)
        kind = control.kind.lower()
        if kind in {"combo", "dropdown", "choice"}:
            field = QComboBox()
            field.addItems([str(item) for item in control.options])
            field.setMinimumWidth(96)
            field.setSizeAdjustPolicy(QComboBox.AdjustToMinimumContentsLengthWithIcon)
            field.setMinimumContentsLength(10)
            field.setSizePolicy(QSizePolicy.Expanding, QSizePolicy.Fixed)
            if str(default) and str(default) not in [field.itemText(i) for i in range(field.count())]:
                field.insertItem(0, str(default))
            index = field.findText(str(default))
            if index >= 0:
                field.setCurrentIndex(index)
            return field
        if kind in {"bool", "checkbox"}:
            field = QCheckBox()
            field.setChecked(bool(default))
            return field
        if kind in {"textarea", "matrix", "listbox", "multiselect"}:
            if kind == "multiselect":
                field = QListWidget()
                field.setSelectionMode(QListWidget.MultiSelection)
                defaults = {part.strip() for part in str(default).split(",") if part.strip()}
                for option in control.options:
                    item = QListWidgetItem(str(option))
                    field.addItem(item)
                    if str(option) in defaults:
                        item.setSelected(True)
                field.setMinimumHeight(self._tokens.list_min_height)
                field.setSizePolicy(QSizePolicy.Expanding, QSizePolicy.Preferred)
                return field
            field = QTextEdit()
            field.setPlainText(str(default))
            field.setMinimumHeight(
                self._tokens.textarea_min_height if kind == "textarea" else self._tokens.matrix_min_height
            )
            field.setMaximumHeight(
                self._tokens.textarea_max_height if kind == "textarea" else self._tokens.matrix_max_height
            )
            field.setSizePolicy(QSizePolicy.Expanding, QSizePolicy.Fixed)
            return field
        field = QLineEdit()
        field.setText(str(default))
        field.setMinimumWidth(96)
        field.setClearButtonEnabled(True)
        field.setSizePolicy(QSizePolicy.Expanding, QSizePolicy.Fixed)
        return field

    def _connect_dynamic_controls(self) -> None:
        for key, (_control, field) in self.fields.items():
            if isinstance(field, QComboBox):
                field.currentTextChanged.connect(lambda _value, field_key=key: self._sync_dynamic(field_key))
            elif isinstance(field, QCheckBox):
                field.toggled.connect(lambda _value, field_key=key: self._sync_dynamic(field_key))
            elif isinstance(field, QLineEdit):
                field.textChanged.connect(lambda _value, field_key=key: self._sync_dynamic(field_key))
            elif isinstance(field, QTextEdit):
                field.textChanged.connect(lambda field_key=key: self._sync_dynamic(field_key))
            elif isinstance(field, QListWidget):
                field.itemSelectionChanged.connect(lambda field_key=key: self._sync_dynamic(field_key))

    @staticmethod
    def _normalized(value: object) -> str:
        return str(value).strip().casefold()

    @classmethod
    def _find_option(cls, options: tuple[str, ...] | list[str], value: object) -> int:
        normalized = cls._normalized(value)
        return next(
            (index for index, option in enumerate(options) if cls._normalized(option) == normalized),
            -1,
        )

    def _set_options(self, key: str, options: tuple[str, ...]) -> bool:
        entry = self.fields.get(key)
        if entry is None or not isinstance(entry[1], QComboBox):
            return False
        control, field = entry
        current_options = tuple(field.itemText(index) for index in range(field.count()))
        if current_options == options:
            return False
        field = entry[1]
        current = field.currentText()
        default = self.project.defaults.get(key, control.default)
        with QSignalBlocker(field):
            field.clear()
            field.addItems(list(options))
            index = self._find_option(options, current)
            if index < 0:
                index = self._find_option(options, default)
            field.setCurrentIndex(index if index >= 0 else (0 if options else -1))
        return current != field.currentText() or current_options != options

    def _set_value(self, key: str, value: object) -> None:
        entry = self.fields.get(key)
        if entry is None:
            return
        field = entry[1]
        with QSignalBlocker(field):
            if isinstance(field, QComboBox):
                options = [field.itemText(index) for index in range(field.count())]
                index = self._find_option(options, value)
                if index >= 0:
                    field.setCurrentIndex(index)
            elif isinstance(field, QCheckBox):
                field.setChecked(bool(value))
            elif isinstance(field, QTextEdit):
                field.setPlainText(str(value))
            elif isinstance(field, QListWidget):
                selected = {part.strip() for part in str(value).split(",") if part.strip()}
                for index in range(field.count()):
                    item = field.item(index)
                    item.setSelected(item.text() in selected)
            elif isinstance(field, QLineEdit):
                field.setText(str(value))

    @classmethod
    def _matches_any(cls, value: object, allowed: tuple[object, ...]) -> bool:
        normalized = cls._normalized(value)
        return any(value == candidate or normalized == cls._normalized(candidate) for candidate in allowed)

    @classmethod
    def _conditions_match(cls, conditions: dict[str, tuple[object, ...]], values: dict[str, object]) -> bool:
        return all(
            dependency in values and cls._matches_any(values[dependency], allowed)
            for dependency, allowed in conditions.items()
        )

    @classmethod
    def _mapping_value(cls, mapping: dict[str, object], selector: object):
        normalized = cls._normalized(selector)
        return next(
            (value for key, value in mapping.items() if cls._normalized(key) == normalized),
            None,
        )

    def _refresh_dependent_options(self) -> None:
        for _iteration in range(max(1, len(self.fields))):
            changed = False
            values = {**self.tab.render_overrides, **self.values()}
            for key, (control, _field) in self.fields.items():
                if not control.depends_on or not control.options_by:
                    continue
                options = self._mapping_value(control.options_by, values.get(control.depends_on, ""))
                choices = tuple(options) if options is not None else control.options
                changed = self._set_options(key, choices) or changed
            if not changed:
                return

    def _sync_dynamic(self, changed_key: str | None = None) -> None:
        if self._updating:
            return
        self._updating = True
        try:
            if changed_key is not None:
                control, _field = self.fields[changed_key]
                selected = self.values().get(changed_key)
                preset = self._mapping_value(control.preset_values, selected)
                if preset is not None:
                    for _iteration in range(max(1, len(self.fields))):
                        for key, value in preset.items():
                            self._set_value(key, value)
                        self._refresh_dependent_options()
                        current = self.values()
                        if all(
                            key not in self.fields or self._matches_any(current.get(key), (value,))
                            for key, value in preset.items()
                        ):
                            break

            self._refresh_dependent_options()
            values = {**self.tab.render_overrides, **self.values()}
            for key, (control, field) in self.fields.items():
                self.field_rows[key].setVisible(self._conditions_match(control.visible_when, values))
                field.setEnabled(self._conditions_match(control.enabled_when, values))
            for group, _grid, _heading, keys in self._sections:
                group.setVisible(any(self.field_rows[key].isVisible() for key in keys))
            self._relayout_sections()
            self.updateGeometry()
        finally:
            self._updating = False

    @staticmethod
    def _coerce(text: str) -> object:
        value = text.strip()
        lowered = value.lower()
        if lowered in {"true", "false", "on", "off"}:
            return lowered in {"true", "on"}
        try:
            if value and all(ch not in value for ch in ".eE"):
                return int(value)
            return float(value)
        except ValueError:
            return value

    def values(self) -> dict[str, object]:
        out: dict[str, object] = {}
        for key, (control, field) in self.fields.items():
            if isinstance(field, QComboBox):
                out[key] = self._coerce(field.currentText())
            elif isinstance(field, QCheckBox):
                out[key] = field.isChecked()
            elif isinstance(field, QTextEdit):
                out[key] = field.toPlainText().strip()
            elif isinstance(field, QListWidget):
                out[key] = ",".join(item.text() for item in field.selectedItems())
            elif isinstance(field, QLineEdit):
                out[key] = self._coerce(field.text())
            else:
                out[key] = control.default
        return out


class ProjectStudioWindow(QMainWindow):
    def __init__(self, project_name: str | None = None, allow_project_switch: bool = True):
        super().__init__()
        app = QApplication.instance()
        if app is not None:
            _apply_app_style(app)
        self.allow_project_switch = allow_project_switch
        self.fixed_project_name = project_name
        self.setWindowTitle("PhysicsVisualizer")
        self.resize(1480, 900)
        self.current_bundle = None
        self.current_canvas = None
        self.preview_figures = []
        self.figure_list_widget: QListWidget | None = None
        self.preview_layout_edit: QLineEdit | None = None
        self._run_history: dict[tuple[str, str], TabRunHistory] = {}
        self._preview_order: dict[tuple[str, str], list[tuple[int, int]]] = {}
        self._preview_hidden_refs: dict[tuple[str, str], set[tuple[int, int]]] = {}
        self._preview_layout_values: dict[tuple[str, str], str] = {}
        self.project_tabs: list[TabSpec] = []
        self.controls_by_index: dict[int, ProjectControls] = {}
        self._render_thread: QThread | None = None
        self._export_thread: QThread | None = None
        self._render_worker: _RenderWorker | None = None
        self._export_worker: _ExportWorker | None = None
        self._tokens = style.tokens()

        root = QWidget()
        self.setCentralWidget(root)
        outer = QHBoxLayout(root)
        outer.setContentsMargins(
            self._tokens.layout_margin,
            self._tokens.layout_margin,
            self._tokens.layout_margin,
            self._tokens.layout_margin,
        )
        outer.setSpacing(self._tokens.layout_spacing)
        splitter = QSplitter(Qt.Horizontal)
        outer.addWidget(splitter)

        left = QWidget()
        left.setObjectName("ControlRail")
        left.setMinimumWidth(self._tokens.control_panel_min_width)
        left.setMaximumWidth(self._tokens.control_panel_max_width)
        left.setSizePolicy(QSizePolicy.Preferred, QSizePolicy.Expanding)
        left_layout = QVBoxLayout(left)
        left_layout.setContentsMargins(
            self._tokens.layout_margin,
            self._tokens.layout_margin,
            self._tokens.layout_margin,
            self._tokens.layout_margin,
        )
        left_layout.setSpacing(self._tokens.layout_spacing)
        self.project_title = QLabel()
        self.project_title.setObjectName("ProjectTitle")
        self.project_title.setWordWrap(True)
        left_layout.addWidget(self.project_title)
        self.project_combo = QComboBox()
        if allow_project_switch:
            self.project_combo.addItems(list(PROJECTS))
            left_layout.addWidget(QLabel("project"))
            left_layout.addWidget(self.project_combo)
        else:
            self.project_combo.hide()
        self.description = QLabel()
        self.description.setWordWrap(True)
        self.description.setObjectName("ProjectDescription")
        left_layout.addWidget(self.description)
        self.tab_widget = QTabWidget()
        self.tab_widget.setDocumentMode(True)
        self.tab_widget.tabBar().setUsesScrollButtons(True)
        self.tab_widget.tabBar().setExpanding(False)
        self.tab_widget.setMinimumWidth(self._tokens.control_panel_min_width - 2 * self._tokens.layout_margin)
        left_layout.addWidget(self.tab_widget, 1)

        action_bar = QFrame()
        action_bar.setObjectName("ActionBar")
        action_layout = QHBoxLayout(action_bar)
        action_layout.setContentsMargins(0, self._tokens.dense_spacing, 0, 0)
        action_layout.setSpacing(self._tokens.layout_spacing)
        self.render_button = QPushButton("Generate")
        self.render_button.setProperty("role", "primary")
        self.reset_button = QPushButton("Reset")
        self.export_button = QPushButton("Export")
        action_layout.addWidget(self.render_button, 2)
        action_layout.addWidget(self.reset_button, 1)
        action_layout.addWidget(self.export_button, 1)
        left_layout.addWidget(action_bar)

        right = QWidget()
        right.setObjectName("PreviewArea")
        right_layout = QVBoxLayout(right)
        right_layout.setContentsMargins(
            self._tokens.layout_spacing,
            self._tokens.layout_spacing,
            self._tokens.layout_spacing,
            self._tokens.layout_spacing,
        )
        right_layout.setSpacing(self._tokens.layout_spacing)
        right_splitter = QSplitter(Qt.Vertical)
        self.preview = QScrollArea()
        self.preview.setWidgetResizable(True)
        self.preview.setObjectName("PreviewScroll")
        self.preview.setAlignment(Qt.AlignCenter)
        self.preview_placeholder = QLabel("Generate a project to preview results.")
        self.preview_placeholder.setAlignment(Qt.AlignCenter)
        self.preview.setWidget(self.preview_placeholder)
        self.notes = QTextEdit()
        self.notes.setReadOnly(True)
        self.notes.setObjectName("NotesPanel")
        self.notes.setMinimumHeight(96)
        right_splitter.addWidget(self.preview)
        right_splitter.addWidget(self.notes)
        right_splitter.setSizes([790, 150])
        right_splitter.setStretchFactor(0, 5)
        right_splitter.setStretchFactor(1, 2)
        right_layout.addWidget(right_splitter, 1)

        splitter.addWidget(left)
        splitter.addWidget(right)
        splitter.setStretchFactor(0, 2)
        splitter.setStretchFactor(1, 6)
        splitter.setSizes([620, 860])

        # Status bar with an embedded progress indicator.
        self.status = self.statusBar()
        self.status_label = QLabel("Ready")
        self.status_progress = QProgressBar()
        self.status_progress.setFixedWidth(self._tokens.control_panel_min_width // 2)
        self.status_progress.setRange(0, 100)
        self.status_progress.setValue(0)
        self.status_progress.setVisible(False)
        self.status.addPermanentWidget(self.status_progress)
        self.status.addWidget(self.status_label, 1)

        self.project_combo.currentTextChanged.connect(self.load_project)
        self.tab_widget.currentChanged.connect(self.update_tab_notes)
        self.render_button.clicked.connect(self.render_current)
        self.reset_button.clicked.connect(lambda: self.load_project(self.project.name))
        self.export_button.clicked.connect(self.export_current)
        initial_project = project_name or self.project_combo.currentText() or next(iter(PROJECTS))
        if allow_project_switch:
            index = self.project_combo.findText(initial_project)
            if index >= 0:
                self.project_combo.setCurrentIndex(index)
        self.load_project(initial_project)

    # ---- status / progress helpers ----

    def _set_busy(self, message: str, indeterminate: bool = True) -> None:
        self.status_label.setText(message)
        self.status_progress.setVisible(True)
        self.status_progress.setRange(0, 0) if indeterminate else self.status_progress.setRange(0, 100)
        self.render_button.setEnabled(False)
        self.reset_button.setEnabled(False)
        self.export_button.setEnabled(False)
        self.tab_widget.setEnabled(False)
        self.project_combo.setEnabled(False)

    def _set_progress(self, value: int) -> None:
        if self.status_progress.maximum() == 0:
            self.status_progress.setRange(0, 100)
        self.status_progress.setValue(value)

    def _set_idle(self, message: str = "Ready") -> None:
        self.status_label.setText(message)
        self.status_progress.setVisible(False)
        self.render_button.setEnabled(True)
        self.reset_button.setEnabled(True)
        self.export_button.setEnabled(True)
        self.tab_widget.setEnabled(True)
        self.project_combo.setEnabled(self.allow_project_switch)

    # ---- tabs ----

    def _load_tabs(self, project_name: str) -> list[TabSpec]:
        try:
            module = import_module(f"projects.{project_name}.app.tabs")
            tabs = module.get_tabs()
        except Exception:
            tabs = []
        if not tabs:
            from utils.control_schema import c, section, tab

            controls = [c(key, key, default=value) for key, value in self.project.defaults.items()]
            tabs = [tab("main", self.project.title, section("parameters", *controls), preview="axesgrid")]
        return list(tabs)

    def _configure_tab_layout(self) -> None:
        many_tabs = len(self.project_tabs) >= 4
        self.tab_widget.setTabPosition(QTabWidget.West if many_tabs else QTabWidget.North)
        self.tab_widget.tabBar().setUsesScrollButtons(True)
        self.tab_widget.tabBar().setExpanding(False)
        self.tab_widget.tabBar().setElideMode(Qt.ElideNone if many_tabs else Qt.ElideRight)

    def load_project(self, name: str):
        self.project = PROJECTS[name]
        self.setWindowTitle(f"{self.project.title} - PhysicsVisualizer")
        self.project_title.setText(self.project.title)
        self.description.setText(self.project.description)
        self.tab_widget.clear()
        self.controls_by_index.clear()
        self.project_tabs = self._load_tabs(name)
        self._configure_tab_layout()
        for index, tab in enumerate(self.project_tabs):
            scroll = QScrollArea()
            scroll.setWidgetResizable(True)
            scroll.setObjectName("ControlsScroll")
            scroll.setHorizontalScrollBarPolicy(Qt.ScrollBarAlwaysOff)
            controls = ProjectControls(self.project, tab)
            scroll.setWidget(controls)
            self.controls_by_index[index] = controls
            self.tab_widget.addTab(scroll, tab.title)
        self.current_bundle = None
        self.update_tab_notes()
        self._set_idle(f"Loaded {self.project.title}")

    def current_tab(self) -> TabSpec:
        index = max(0, self.tab_widget.currentIndex())
        return self.project_tabs[index]

    def current_controls(self) -> ProjectControls:
        return self.controls_by_index[max(0, self.tab_widget.currentIndex())]

    def _history_for(self, tab: TabSpec | None = None) -> TabRunHistory:
        active_tab = tab or self.current_tab()
        key = (self.project.name, active_tab.key)
        return self._run_history.setdefault(key, TabRunHistory())

    def _render_params(self, tab: TabSpec | None = None) -> dict[str, object]:
        active_tab = tab or self.current_tab()
        params: dict[str, object] = dict(self.project.defaults)
        params.update(active_tab.render_overrides)
        params.update(self.current_controls().values())
        return params

    def update_tab_notes(self):
        if not hasattr(self, "project") or not self.project_tabs:
            return
        tab = self.current_tab()
        self.notes.setHtml(
            "<style>body{font-size:10pt;line-height:1.35;}"
            "h3{font-size:14pt;margin:0 0 2px 0;}"
            "h4{font-size:11pt;margin:0 0 5px 0;}"
            "p{margin:2px 0;color:#263244;}</style>"
            f"<h3>{escape(self.project.title)}</h3>"
            f"<h4>{escape(tab.title)}</h4>"
            f"<p>{escape(self.project.description)}</p>"
            f"<p>{escape(self.project.formulas)}</p>"
        )
        placeholder = QLabel(tab.initial_message)
        placeholder.setObjectName("PreviewPlaceholder")
        placeholder.setAlignment(Qt.AlignCenter)
        placeholder.setWordWrap(True)
        self.preview.setWidget(placeholder)

    # ---- render ----

    def render_current(self):
        if self._render_thread is not None:
            return
        self._set_busy("Rendering…")
        try:
            tab = self.current_tab()
            params = self._render_params(tab)
        except Exception as exc:  # noqa: BLE001
            self._set_idle("Ready")
            QMessageBox.critical(self, "Render failed", str(exc))
            return

        self._render_thread = QThread(self)
        self._render_worker = _RenderWorker(self.project, params)
        self._render_worker.moveToThread(self._render_thread)
        self._render_worker.progress.connect(self._on_render_progress)
        self._render_worker.finished.connect(self._on_render_finished)
        self._render_worker.failed.connect(self._on_render_failed)
        self._render_thread.started.connect(self._render_worker.run)
        self._render_thread.start()

    def _on_render_progress(self, message: str, value: int) -> None:
        self.status_label.setText(message)
        self._set_progress(value)

    def _on_render_finished(self, bundle) -> None:
        self._teardown_render_thread()
        self.current_bundle = bundle
        tab = self.current_tab()
        self._history_for(tab).append(self._render_params(tab), bundle)
        self._show_bundle(tab)
        self.notes.setMarkdown(bundle.report or self.project.formulas)
        self._set_idle("Render complete")

    def _on_render_failed(self, message: str) -> None:
        self._teardown_render_thread()
        self._set_idle("Render failed")
        QMessageBox.critical(self, "Render failed", message)

    def _teardown_render_thread(self) -> None:
        if self._render_thread is not None:
            self._render_thread.quit()
            self._render_thread.wait(5000)
            self._render_thread = None
            self._render_worker = None

    # ---- preview ----

    def _figure_panel(self, fig) -> QWidget:
        panel = QWidget()
        panel.setSizePolicy(QSizePolicy.Expanding, QSizePolicy.Expanding)
        layout = QVBoxLayout(panel)
        layout.setContentsMargins(
            self._tokens.layout_spacing,
            self._tokens.layout_spacing,
            self._tokens.layout_spacing,
            self._tokens.layout_spacing,
        )
        layout.setSpacing(self._tokens.dense_spacing)
        layout.addWidget(_StaticFigurePreview(fig), 1)
        return panel

    def _preview_key(self, tab: TabSpec) -> tuple[str, str]:
        return (self.project.name, tab.key)

    def _ordered_history_figures(self, tab: TabSpec, history: TabRunHistory) -> list[HistoryFigure]:
        key = self._preview_key(tab)
        available = {figure.ref: figure for figure in history.figures()}
        hidden = self._preview_hidden_refs.setdefault(key, set())
        hidden.intersection_update(available)
        saved_order = [ref for ref in self._preview_order.get(key, []) if ref in available and ref not in hidden]
        saved = set(saved_order)
        saved_order.extend(ref for ref in available if ref not in saved and ref not in hidden)
        self._preview_order[key] = saved_order
        return [available[ref] for ref in saved_order]

    def _store_current_preview_order(self, tab: TabSpec, figure_list: QListWidget | None = None) -> None:
        widget = figure_list or self.figure_list_widget
        if widget is None:
            return
        refs: list[tuple[int, int]] = []
        for row in range(widget.count()):
            ref = widget.item(row).data(Qt.UserRole)
            if ref is not None:
                refs.append(tuple(ref))
        self._preview_order[self._preview_key(tab)] = refs

    def _selected_history_from_list(self, tab: TabSpec) -> list[HistoryFigure]:
        history = self._history_for(tab)
        available = {figure.ref: figure for figure in history.figures()}
        widget = self.figure_list_widget
        if widget is None:
            selected = history.selected_figures()
            return selected or self._ordered_history_figures(tab, history)
        selected_refs = {tuple(item.data(Qt.UserRole)) for item in widget.selectedItems()}
        ordered_refs: list[tuple[int, int]] = []
        for row in range(widget.count()):
            ref = tuple(widget.item(row).data(Qt.UserRole))
            if not selected_refs or ref in selected_refs:
                ordered_refs.append(ref)
        return [available[ref] for ref in ordered_refs if ref in available]

    def _preview_layout_text(self) -> str:
        if self.preview_layout_edit is None:
            return "auto"
        return self.preview_layout_edit.text().strip() or "auto"

    @staticmethod
    def _clear_layout(layout: QVBoxLayout | QHBoxLayout | QGridLayout) -> None:
        while layout.count():
            item = layout.takeAt(0)
            if item.widget():
                item.widget().deleteLater()
            elif item.layout():
                ProjectStudioWindow._clear_layout(item.layout())

    def _set_figure_host(self, figure_layout: QVBoxLayout, widget: QWidget) -> None:
        self._clear_layout(figure_layout)
        figure_layout.addWidget(widget, 1)

    def _composite_preview_widget(self, selected: list[HistoryFigure], layout_text: str) -> QWidget:
        if not selected:
            label = QLabel("Select at least one preview.")
            label.setAlignment(Qt.AlignCenter)
            return label
        with tempfile.TemporaryDirectory(prefix="physicsvisualizer_preview_") as tmp:
            tmp_dir = Path(tmp)
            paths = []
            for index, history_figure in enumerate(selected, start=1):
                label = image_output.indexed_name(history_figure.title, index)
                paths.append(image_output.save_figure(history_figure.figure, tmp_dir, label, dpi=240, crop=True))
            composite = image_output.compose_grid(paths, tmp_dir / "preview_composite.png", columns=layout_text)
            pixmap = QPixmap(str(composite))
        return _StaticPixmapPreview(pixmap)

    def _select_all_previews(self, tab: TabSpec, figure_list: QListWidget) -> None:
        figure_list.selectAll()
        refs = [tuple(figure_list.item(row).data(Qt.UserRole)) for row in range(figure_list.count())]
        self._history_for(tab).set_selection(refs)

    def _delete_selected_previews(self, tab: TabSpec, figure_list: QListWidget, figure_layout: QVBoxLayout) -> None:
        selected_rows = sorted((index.row() for index in figure_list.selectedIndexes()), reverse=True)
        if not selected_rows:
            return
        key = self._preview_key(tab)
        hidden = self._preview_hidden_refs.setdefault(key, set())
        for row in selected_rows:
            item = figure_list.takeItem(row)
            if item is not None:
                hidden.add(tuple(item.data(Qt.UserRole)))
        self._store_current_preview_order(tab, figure_list)
        self._history_for(tab).set_selection(
            [tuple(figure_list.item(row).data(Qt.UserRole)) for row in range(figure_list.count())]
        )
        if figure_list.count():
            figure_list.setCurrentRow(0)
        else:
            label = QLabel("No preview generated.")
            label.setAlignment(Qt.AlignCenter)
            self._set_figure_host(figure_layout, label)

    def _move_selected_previews(self, tab: TabSpec, figure_list: QListWidget, direction: int) -> None:
        rows = sorted({index.row() for index in figure_list.selectedIndexes()}, reverse=direction > 0)
        if not rows:
            return
        selected_refs = {tuple(figure_list.item(row).data(Qt.UserRole)) for row in rows}
        for row in rows:
            target = row + direction
            if target < 0 or target >= figure_list.count() or target in rows:
                continue
            item = figure_list.takeItem(row)
            figure_list.insertItem(target, item)
            item.setSelected(True)
        for row in range(figure_list.count()):
            item = figure_list.item(row)
            item.setSelected(tuple(item.data(Qt.UserRole)) in selected_refs)
        self._store_current_preview_order(tab, figure_list)
        self._history_for(tab).set_selection(
            [tuple(figure_list.item(row).data(Qt.UserRole)) for row in range(figure_list.count())
             if tuple(figure_list.item(row).data(Qt.UserRole)) in selected_refs]
        )

    def _show_bundle(self, tab: TabSpec):
        if self.current_bundle is None:
            return
        if tab.preview != "list":
            self.figure_list_widget = None
            self.preview_layout_edit = None
        if tab.preview == "text" and self.current_bundle.report:
            report = QTextEdit()
            report.setReadOnly(True)
            report.setMarkdown(self.current_bundle.report)
            self.preview.setWidget(report)
            return
        figures = list(self.current_bundle.figures)
        self.preview_figures = figures
        if not figures:
            placeholder = QLabel(self.current_bundle.report or "No preview generated.")
            placeholder.setAlignment(Qt.AlignCenter)
            placeholder.setWordWrap(True)
            self.preview.setWidget(placeholder)
            return
        if tab.preview == "list":
            history = self._history_for(tab)
            history_figures = self._ordered_history_figures(tab, history)
            figure_by_ref = {figure.ref: figure for figure in history_figures}
            panel = QWidget()
            layout = QHBoxLayout(panel)
            layout.setContentsMargins(
                self._tokens.dense_spacing,
                self._tokens.dense_spacing,
                self._tokens.dense_spacing,
                self._tokens.dense_spacing,
            )
            layout.setSpacing(self._tokens.control_padding)
            preview_splitter = QSplitter(Qt.Horizontal)

            list_panel = QWidget()
            list_layout = QVBoxLayout(list_panel)
            list_layout.setContentsMargins(0, 0, 0, 0)
            list_layout.setSpacing(self._tokens.dense_spacing)

            figure_list = QListWidget()
            figure_list.setObjectName("PreviewFigureList")
            figure_list.setSelectionMode(QAbstractItemView.ExtendedSelection)
            figure_list.setMinimumWidth(160)
            figure_list.setMaximumWidth(300)
            for history_figure in history_figures:
                item = QListWidgetItem(
                    f"Run {history_figure.run_index:02d} / {history_figure.item_index:02d}  {history_figure.title}"
                )
                item.setData(Qt.UserRole, history_figure.ref)
                figure_list.addItem(item)
                item.setSelected(history_figure.ref in history.selection)
            list_layout.addWidget(figure_list, 1)

            order_bar = QHBoxLayout()
            order_bar.setContentsMargins(0, 0, 0, 0)
            order_bar.setSpacing(self._tokens.dense_spacing)
            up_button = QPushButton("Up")
            down_button = QPushButton("Down")
            all_button = QPushButton("All")
            delete_button = QPushButton("Del")
            up_button.setObjectName("PreviewMoveUpButton")
            down_button.setObjectName("PreviewMoveDownButton")
            all_button.setObjectName("PreviewSelectAllButton")
            delete_button.setObjectName("PreviewDeleteButton")
            delete_button.setProperty("role", "danger")
            for button in (up_button, down_button, all_button, delete_button):
                button.setMinimumHeight(28)
                order_bar.addWidget(button)
            list_layout.addLayout(order_bar)

            compose_bar = QHBoxLayout()
            compose_bar.setContentsMargins(0, 0, 0, 0)
            compose_bar.setSpacing(self._tokens.dense_spacing)
            layout_label = QLabel("layout")
            layout_label.setObjectName("MutedLabel")
            preview_layout_edit = QLineEdit(self._preview_layout_values.get(self._preview_key(tab), "auto"))
            preview_layout_edit.setObjectName("CompositeLayoutField")
            preview_layout_edit.setAlignment(Qt.AlignCenter)
            preview_layout_edit.setToolTip("Use auto, columns:N, N, or MATLAB row syntax like 3+2+1.")
            preview_button = QPushButton("Preview")
            preview_button.setObjectName("CompositePreviewButton")
            compose_bar.addWidget(layout_label, 0)
            compose_bar.addWidget(preview_layout_edit, 1)
            compose_bar.addWidget(preview_button, 0)
            list_layout.addLayout(compose_bar)
            self.preview_layout_edit = preview_layout_edit

            figure_host = QWidget()
            figure_layout = QVBoxLayout(figure_host)
            figure_layout.setContentsMargins(0, 0, 0, 0)

            def select_figure(row: int):
                if 0 <= row < figure_list.count():
                    ref = tuple(figure_list.item(row).data(Qt.UserRole))
                    history_figure = figure_by_ref.get(ref)
                    if history_figure is not None:
                        self._set_figure_host(figure_layout, self._figure_panel(history_figure.figure))

            def save_history_selection() -> None:
                self._store_current_preview_order(tab, figure_list)
                history.set_selection(
                    [tuple(item.data(Qt.UserRole)) for item in figure_list.selectedItems()]
                )

            def preview_composite() -> None:
                selected = self._selected_history_from_list(tab)
                self._set_figure_host(figure_layout, self._composite_preview_widget(selected, self._preview_layout_text()))

            figure_list.currentRowChanged.connect(select_figure)
            figure_list.itemSelectionChanged.connect(save_history_selection)
            preview_layout_edit.textChanged.connect(
                lambda value: self._preview_layout_values.__setitem__(self._preview_key(tab), value.strip() or "auto")
            )
            up_button.clicked.connect(lambda: self._move_selected_previews(tab, figure_list, -1))
            down_button.clicked.connect(lambda: self._move_selected_previews(tab, figure_list, 1))
            all_button.clicked.connect(lambda: self._select_all_previews(tab, figure_list))
            delete_button.clicked.connect(lambda: self._delete_selected_previews(tab, figure_list, figure_layout))
            preview_button.clicked.connect(preview_composite)
            preview_layout_edit.returnPressed.connect(preview_composite)

            preview_splitter.addWidget(list_panel)
            preview_splitter.addWidget(figure_host)
            preview_splitter.setStretchFactor(0, 0)
            preview_splitter.setStretchFactor(1, 1)
            preview_splitter.setSizes([210, 760])
            layout.addWidget(preview_splitter, 1)
            self.preview.setWidget(panel)
            self.figure_list_widget = figure_list
            if history_figures:
                selected_row = next(
                    (index for index, figure in enumerate(history_figures) if figure.ref in history.selection),
                    0,
                )
                figure_list.setCurrentItem(figure_list.item(selected_row), QItemSelectionModel.NoUpdate)
            return
        self.figure_list_widget = None
        self.preview_layout_edit = None
        self.preview.setWidget(self._figure_panel(figures[0]))

    # ---- export ----

    def _default_export_folder(self) -> Path:
        return REPOSITORY_ROOT / "projects" / self.project.name / "output"

    def export_current(self):
        if self._export_thread is not None:
            return
        if self.current_bundle is None:
            self.render_current()
        if self.current_bundle is None:
            return

        tab = self.current_tab()
        history = self._history_for(tab)
        selected_history: list[HistoryFigure] = []
        if tab.preview == "list":
            selected_history = self._selected_history_from_list(tab)
            if not selected_history:
                self._set_idle("Select at least one preview to export.")
                return
        else:
            selected_history = history.latest_figures()
        figures = [history_figure.figure for history_figure in selected_history]
        params = self._render_params(tab)
        if selected_history:
            params.update(history.payload(selected_history))
        if tab.preview == "list":
            params["composite_layout"] = self._preview_layout_text()

        stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        tab_key = tab.key
        folder = self._default_export_folder() / stamp
        self._set_busy("Exporting…", indeterminate=False)
        self._set_progress(10)

        self._export_thread = QThread(self)
        self._export_worker = _ExportWorker(
            self.project,
            tab_key,
            figures,
            params,
            self.current_bundle.report,
            folder,
        )
        self._export_worker.moveToThread(self._export_thread)
        self._export_worker.progress.connect(self._on_export_progress)
        self._export_worker.finished.connect(self._on_export_finished)
        self._export_worker.failed.connect(self._on_export_failed)
        self._export_thread.started.connect(self._export_worker.run)
        self._export_thread.start()

    def _on_export_progress(self, message: str, value: int) -> None:
        self.status_label.setText(message)
        self._set_progress(value)

    def _on_export_finished(self, paths: list, folder: str) -> None:
        self._teardown_export_thread()
        self._set_idle(f"Exported to {folder}")

    def _on_export_failed(self, message: str) -> None:
        self._teardown_export_thread()
        self._set_idle("Export failed")
        QMessageBox.critical(self, "Export failed", message)

    def _teardown_export_thread(self) -> None:
        if self._export_thread is not None:
            self._export_thread.quit()
            self._export_thread.wait(10000)
            self._export_thread = None
            self._export_worker = None


class MainWindow(ProjectStudioWindow):
    def __init__(self):
        super().__init__(None, allow_project_switch=True)


def run(project_name: str | None = None) -> int:
    app = QApplication.instance() or QApplication(sys.argv)
    app.setStyleSheet("")
    _apply_app_style(app)
    window = ProjectStudioWindow(project_name, allow_project_switch=project_name is None)
    window.show()
    return int(app.exec())


def run_project(project_name: str) -> int:
    return run(project_name)
