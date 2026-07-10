# CrystalOpticsBoundary

Python report generator for boundary optics at isotropic-to-anisotropic crystal interfaces.

## Run

```bash
python projects/CrystalOpticsBoundary/main.py
```

## Project Layout

- `app/` declares the incident-wave, tensor, orientation, and report controls.
- `core/` contains anisotropic boundary matching and dielectric tensor formulas.
- `docs/physical_formulas.md` records the formula reference for the Python port.
- `example/` contains the saved typical-example reproduction entry.
- `output/` is the project-local export target.

All ordinary GUI styling, report styling, export naming, and metadata behavior must use the shared `utils/` layer. The MATLAB parity reference remains under `legacy/matlab/projects/CrystalOpticsBoundary/`.

The polarization sweep plot is a Python extension for exploring the ported solver. MATLAB supplied no equivalent figure, so it is not claimed as MATLAB figure parity; the single-case text report remains the parity target.
