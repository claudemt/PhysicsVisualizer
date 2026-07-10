# CreativePlotStudio

## Scope

Generative MATLAB plotting studio for art, fractal, and nonlinear visual programs.

Run the project with `main.m`.  The GUI uses the shared root-level `utils/` for tab layout, controls, preview behavior, notes browser, export, and parameter/reproduce-code output.

## User-facing organization

- `app/tabs/` defines the GUI tab, its default input values, and the short control-level hints shown inside the tab.
- `docs/physical_formulas.md` is the single formula note for this project.  It explains the mathematics/physics behind the previews and reports.
- `output/` is created on export and contains images or reports plus `parameters.txt` and `reproduce_code.m`.

## Core organization

- `core/art/`, `core/fractals/`, and `core/nonlinear/` contain script families.
- `core/common/` contains reusable color/script helpers.

## Main algorithms

- Parametric and polar curves
- Complex escape-time maps
- Iterated nonlinear maps
- Palette interpolation and axes rendering

## Maintenance notes

Keep layout, button sizing, preview placement, image export, and notes rendering in the shared `utils/` files.  Project code should contain only parameter collection, domain-specific computation, and calls into the shared rendering/export functions.
