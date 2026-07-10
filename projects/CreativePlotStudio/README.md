# CreativePlotStudio

Python generative plotting studio for art, fractal, and nonlinear visual programs.

## Run

```bash
python projects/CreativePlotStudio/main.py
```

## Project Layout

- `app/` declares the domain/category/project controls through `utils.control_schema`.
- `core/` contains catalog-driven render dispatch for the Python port.
- `docs/physical_formulas.md` records the catalog and rendering parity notes.
- `example/` contains the `everything_composite` reproduction entry.
- `output/` is the project-local export target.

All ordinary GUI styling, matplotlib styling, title-safe export, and composite behavior must use the shared `utils/` layer. Project-specific colors are allowed only where they encode the artwork or mathematical visual identity. The MATLAB parity reference remains under `legacy/matlab/projects/CreativePlotStudio/`.
