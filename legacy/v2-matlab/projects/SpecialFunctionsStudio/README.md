# SpecialFunctionsStudio

## Scope

Special-function plotting studio for 1D curves, 3D surfaces, and vector-field-style views.

Run the project with `main.m`.  The GUI uses the shared root-level `utils/` for tab layout, controls, preview behavior, notes browser, export, and parameter/reproduce-code output.

## User-facing organization

- `app/tabs/` defines the GUI tab, its default input values, and the short control-level hints shown inside the tab.
- `docs/physical_formulas.md` is the single formula note for this project.  It explains the mathematics/physics behind the previews and reports.
- `output/` is created on export and contains images or reports plus `parameters.txt` and `reproduce_code.m`.

## Core organization

- `core/special_functions/` contains function-family implementations used by the tab dispatcher.

## Main algorithms

- Bessel/Legendre/Hermite/Laguerre-style families
- Curve and surface result construction
- Shared 1D/3D renderer and composite layout

## Maintenance notes

Keep layout, button sizing, preview placement, image export, and notes rendering in the shared `utils/` files.  Project code should contain only parameter collection, domain-specific computation, and calls into the shared rendering/export functions.
