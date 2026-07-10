# MovingChargeFields

Python moving point-charge field visualizer with scalar maps, streamlines, retarded-time fields, and phase-sweep video export.

## Run

```bash
python projects/MovingChargeFields/main.py
```

## Project Layout

- `app/` declares motion, slice, field, and display controls.
- `core/` contains motion, retarded-time field, formula, model, and rendering code.
- `docs/physical_formulas.md` records the formula reference for the Python port.
- `example/` contains Python reproduction entries for saved legacy examples.
- `output/` is the project-local export target.

All ordinary GUI styling, matplotlib styling, title-safe export, animation export, and composite behavior must use the shared `utils/` layer. The MATLAB parity reference remains under `legacy/matlab/projects/MovingChargeFields/`.
