# OpticsStudio

## Scope

Computational optics simulations: **CT tomography** (filtered backprojection) and **scalar wave optics** (angular-spectrum propagation, Fourier-plane filtering).

Run the project with `main.m`.  The GUI uses the shared root-level `utils/` for tab layout, controls, preview behavior, notes browser, export, and parameter/reproduce-code output.

## User-facing organization

- `app/tabs/` defines two GUI tabs:
  - `create_tomography_tab.m` — CT phantom sinogram / filtered backprojection reconstruction.
  - `create_wave_optics_tab.m` — scalar wave propagation (free-space / 4f-filtering).
- `docs/physical_formulas.md` is the single formula note for this project.
- `output/` is created on export and contains images or reports plus `parameters.txt` and `reproduce_code.m`.

## Core organization

- `core/imaging/` — PSF, OTF, Zernike wavefront, circular pupil utilities.
- `core/wave/` — Angular-spectrum propagation, Fourier filter masks.

## Main algorithms

**Tomography (CT)**

- Analytic 2D phantoms (Shepp–Logan, three disks)
- Parallel-beam Radon transform
- Filtered backprojection with user-selectable ramp/window filters
- Reconstruction error metrics (RMSE)

**Wave optics**

- Angular-spectrum propagation with optional band-limiting
- 4f imaging system with Fourier-plane masks (pinhole, ring, slits)
- Synthetic objects (bars, mesh, double slit, aperture, gaussian lattice)

## Maintenance notes

Keep layout, button sizing, preview placement, image export, and notes rendering in the shared `utils/` files.  Project code should contain only parameter collection, domain-specific computation, and calls into the shared rendering/export functions.
