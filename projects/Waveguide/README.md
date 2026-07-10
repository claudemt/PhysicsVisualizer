# Waveguide

Python waveguide mode visualizer for rectangular, circular, and annular PEC guides, dielectric slabs, and exact-vector cylindrical fiber modes.

## Run

```bash
python projects/Waveguide/main.py
```

## Project Layout

- `app/` declares geometry-specific PEC, planar-dielectric, vector-dispersion, and vector-field controls.
- `core/` contains metal, planar, cylindrical, display, and model dispatch code.
- `docs/physical_formulas.md` records the formula reference for the Python port.
- `example/` contains Python reproduction entries for saved legacy examples.
- `output/` is the project-local export target.

All ordinary GUI styling, matplotlib styling, title-safe export, and composite behavior must use the shared `utils/` layer. The MATLAB parity reference remains under `legacy/matlab/projects/Waveguide/`.
