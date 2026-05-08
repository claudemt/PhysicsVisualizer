# ChladniFigures

## Scope

Thin-plate eigenmodes and forced static deflection on rectangular, circular, and annular domains.

Run the project with `main.m`. The GUI uses the shared root-level `utils/` for layout, controls, preview lists, Notes browser, export, and parameter/reproduce-code output.

## User-facing organization

- `app/tabs/create_chladni_modes_tab.m` collects eigenmode inputs and calls the core mode builder.
- `app/tabs/create_static_sources_tab.m` collects static-load inputs and calls the core forced-response builder.
- `app/special/chladni_input_helpers.m` contains Chladni-specific input parsing that should not be generalized to all projects: arbitrary C/S/F boundary strings, source matrices, and custom load text.
- `docs/physical_formulas.md` is the single full mathematical note for the project.
- `output/` is created on export and contains selected images plus `parameters.txt` and `reproduce_code.m`.

## Core organization

- `core/chladni_figures/compute_chladni_modes.m` dispatches rectangular, disk, and annular eigenmode problems.
- `compute_chladni_rect.m` builds rectangular mode results from Navier/Ritz solvers.
- `compute_chladni_circular.m` builds disk and annulus modes from analytic polar boundary systems.
- `compute_static_sources.m` dispatches static forced-response calculations.
- `compute_static_rect_modal.m` projects loads onto rectangular static modal/Ritz bases.
- `compute_static_circ_green.m` uses polar Green-function sums for disk and annular loads.
- `solve_rect_*` files implement the rectangular boundary-condition solvers.
- `rect_boundary_meta.m`, `rect_boundary_options.m`, and `circ_boundary_options.m` define boundary-code metadata.

## Main algorithms

- Arbitrary rectangular ULDR edge strings over `{C,S,F}`.
- Solid disk boundary presets `C`, `S`, `F`.
- Annular outer-inner boundary pairs such as `CC`, `CF`, `FS`, and `SS`.
- Rectangular eigenmodes through simply-supported closed forms and Ritz/general boundary solvers.
- Circular and annular eigenmodes through analytic Bessel/modified-Bessel boundary matrices.
- Static loads from point/Gaussian sources, uniform loads, custom MATLAB expressions, or mixed loads.

## Maintenance notes

Keep project-specific boundary/load parsing in `app/special/chladni_input_helpers.m`. Keep layout, button sizing, preview placement, notes rendering, and export conventions in the shared root `utils/` files.
