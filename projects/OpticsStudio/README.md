# OpticsStudio

Python computational optics studio covering Fourier 4f systems, scalar propagation, imaging, interference, ray optics, and tomography across six GUI tabs.

## Run

```bash
python projects/OpticsStudio/main.py
```

## Project Layout

- `app/` declares the six MATLAB-style optics tabs through `utils.control_schema`.
- `core/` contains common optics helpers and per-workflow physics modules.
- `docs/physical_formulas.md` records the formula reference for the Python port.
- `example/` contains the saved Fourier 4f reproduction entry.
- `output/` is the project-local export target.

All ordinary GUI styling, matplotlib styling, title-safe export, and composite behavior must use the shared `utils/` layer. The MATLAB parity reference remains under `legacy/matlab/projects/OpticsStudio/`.
