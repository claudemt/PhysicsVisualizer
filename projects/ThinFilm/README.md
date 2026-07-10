# ThinFilm

Python transfer-matrix report studio for elastic thin films and optical multilayers.

## Run

```bash
python projects/ThinFilm/main.py
```

## Project Layout

- `app/` declares elastic and optical film controls through `utils.control_schema`.
- `core/` contains thin-film common routines and optical/elastic models.
- `docs/physical_formulas.md` records the formula reference for the Python port.
- `example/` contains Python reproduction entries for saved legacy examples.
- `output/` is the project-local export target.

All ordinary GUI styling, report styling, export naming, and metadata behavior must use the shared `utils/` layer. The MATLAB parity reference remains under `legacy/matlab/projects/ThinFilm/`.

Optical angle and thickness sweep plots are Python extensions. MATLAB supplied text-only thin-film workflows, so these plots are intentionally outside MATLAB figure parity while the single-case reports retain the legacy field order and formatting.
