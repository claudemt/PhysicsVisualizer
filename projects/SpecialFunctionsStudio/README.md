# SpecialFunctionsStudio

Python special-function plotting studio for scalar curves, spherical surfaces, and vector spherical harmonic views.

## Run

```bash
python projects/SpecialFunctionsStudio/main.py
```

## Project Layout

- `app/` declares family, variant, tuple, and range controls.
- `core/` contains catalogs, tuple parsing, scalar functions, spherical functions, and rendering.
- `docs/physical_formulas.md` records the formula reference for the Python port.
- `example/` contains Python reproduction entries for saved legacy examples.
- `output/` is the project-local export target.

All ordinary GUI styling, matplotlib styling, title-safe export, and composite behavior must use the shared `utils/` layer. The MATLAB parity reference remains under `legacy/matlab/projects/SpecialFunctionsStudio/`.
