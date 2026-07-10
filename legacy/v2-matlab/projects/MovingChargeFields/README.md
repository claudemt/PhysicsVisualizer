# MovingChargeFields

## Scope

Moving point-charge field visualizer with scalar maps, streamlines, and phase-sweep video export.

Run the project with `main.m`.  The GUI uses the shared root-level `utils/` for tab layout, controls, preview behavior, notes browser, export, and parameter/reproduce-code output.

## User-facing organization

- `app/tabs/` defines the GUI tab, its default input values, and the short control-level hints shown inside the tab.
- `docs/physical_formulas.md` is the single formula note for this project.  It explains the mathematics/physics behind the previews and reports.
- `output/` is created on export and contains images or reports plus `parameters.txt` and `reproduce_code.m`.

## Core organization

- `core/moving_charge/` contains retarded-time and Lienard--Wiechert field formulas.
- `app/special/run_moving_charge_generation.m` orchestrates project-level preview/video generation.

## Main algorithms

- Retarded-time solve
- Velocity/radiation field decomposition
- Poynting-vector streamlines
- Frame-normalized video export

## Maintenance notes

Keep layout, button sizing, preview placement, image export, and notes rendering in the shared `utils/` files.  Project code should contain only parameter collection, domain-specific computation, and calls into the shared rendering/export functions.
