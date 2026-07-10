# ThinFilm

## Scope

Layered thin-film transfer-matrix reports: **elastic waves** (P/SV/SH) and **optical multilayers** (s/p polarization, dielectric stack).

Run the project with `main.m`.  The GUI uses the shared root-level `utils/` for tab layout, controls, preview behavior, notes browser, export, and parameter/reproduce-code output.

## User-facing organization

- `app/tabs/` defines the GUI tab, its default input values, and the short control-level hints shown inside the tab.
- `docs/physical_formulas.md` is the single formula note for this project.  It explains the mathematics/physics behind the previews and reports.
- `output/` is created on export and contains images or reports plus `parameters.txt` and `reproduce_code.m`.

## Core organization

- `core/thin_film/` contains material/layer parsing, transfer-matrix assembly, and text report generation.

## Main algorithms

**Elastic**

- P/SV potential representation
- Layer interface matching
- Stack transfer matrices
- Reflection/transmission diagnostics

**Optical**

- Characteristic admittance \(\zeta=\sqrt{\varepsilon/\mu}\), Snell via fixed \(k_x\)
- Layer matrices \(P\) (s) and \(Q\) (p), stack products
- Fresnel limits at \