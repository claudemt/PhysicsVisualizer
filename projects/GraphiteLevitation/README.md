# GraphiteLevitation

Python visualizer for diamagnetic levitation of pyrolytic graphite over a compact checkerboard magnet array.

## Run

```bash
python projects/GraphiteLevitation/main.py
```

## Project Layout

- `app/` declares the visualization controls through `utils.control_schema`.
- `core/` contains magnet, graphite, force, and metric calculations.
- `docs/physical_formulas.md` records the formula reference for the Python port.
- `example/` contains canonical Python reproduction entries.
- `output/` is the project-local export target.

All ordinary GUI styling, matplotlib styling, title-safe export, and composite behavior must use the shared `utils/` layer. The MATLAB parity reference remains under `legacy/matlab/projects/GraphiteLevitation/`.
