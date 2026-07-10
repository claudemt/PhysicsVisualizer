# MieScattering

Python electromagnetic scattering visualizer for sphere and cylinder multipole fields.

## Run

```bash
python projects/MieScattering/main.py
```

## Project Layout

- `app/` declares geometry, slice, field, and material controls.
- `core/` contains parameter parsing, coefficients, fields, model dispatch, and rendering.
- `docs/physical_formulas.md` records the formula reference for the Python port.
- `example/` contains Python reproduction entries for saved legacy examples.
- `output/` is the project-local export target.

All ordinary GUI styling, matplotlib styling, title-safe export, and composite behavior must use the shared `utils/` layer. The MATLAB parity reference remains under `legacy/matlab/projects/MieScattering/`.
