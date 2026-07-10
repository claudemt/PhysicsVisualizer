# Project architecture

## Entry point

- `main.m` adds the project tree to the MATLAB path and launches the GUI.

## GUI layer

- `app/launch_unified_optics_studio.m` creates the main maximizable `uifigure` and the tab group.
- `app/tabs/create_fourier_studio_tab.m` builds the richer modular 4f Fourier studio module.
- `app/tabs/create_wave_optics_tab.m` builds the compact wave-optics module.
- `app/tabs/create_imaging_tab.m` builds the imaging and aberration module.
- `app/tabs/create_interference_tab.m` builds the interference and phase module.
- `app/tabs/create_ray_optics_tab.m` builds the geometric-optics module.
- `app/tabs/create_tomography_tab.m` builds the tomography module.

Each tab follows the same layout convention:

1. left control column,
2. top-right preview region,
3. bottom-right notes panel.

The left control column is further split into:

- **physical parameters**
- **numerical / display parameters**
- **actions**
- **status readout**

## App support folders

- `app/panels/create_button_row.m` creates the shared run/reset/export action strip.
- `app/ui/controls/` stores compact label + input constructors.
- `app/ui/display/` stores axis styling, image display, and LaTeX text helpers.
- `app/ui/utils/` stores export, progress dialog, and trimming utilities.

This layout keeps GUI responsibilities grouped by purpose instead of scattering all helpers at one level.

## Numerical core

The `core/` directory contains reusable numerical models shared across tabs:

- `core/fourier/` — modular object-plane, phase-plane, and filter-plane 4f simulation kernels and presets
- `core/wave/` — angular-spectrum propagation and compact Fourier filtering
- `core/imaging/` — pupil generation, PSF, OTF, wavefront basis functions
- `core/interference/` — gratings, shearing interferograms, Gerchberg-Saxton solver
- `core/ray/` — thin-lens rays, spherical-interface refraction, Fresnel coefficients
- `core/tomography/` — phantoms, Radon transform, filtered backprojection

## Notes layer

- `docs/notes_catalog.m` stores short parameter explanations shown in the GUI instead of rendered equations.
