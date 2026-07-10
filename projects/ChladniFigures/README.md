# ChladniFigures

Python visualizer for thin-plate eigenmodes and forced static deflection on rectangular, circular, and annular domains.

## Run

```bash
python projects/ChladniFigures/main.py
```

## Project Layout

- `app/` declares the MATLAB-style GUI tabs through `utils.control_schema`.
- `core/` contains the Chladni mode, boundary, and static-source solvers.
- `docs/physical_formulas.md` records the formula reference for the Python port.
- `example/` contains Python reproduction entries for the saved legacy examples.
- `output/` is the project-local export target.

All ordinary GUI styling, matplotlib styling, title-safe export, and composite behavior must use the shared `utils/` layer. The MATLAB parity reference remains under `legacy/matlab/projects/ChladniFigures/`.
