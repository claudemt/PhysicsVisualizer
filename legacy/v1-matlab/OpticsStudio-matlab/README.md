# Unified Optics Studio

Unified Optics Studio is a consolidated MATLAB teaching and exploration project that merges overlapping functionality from the supplied optical simulation repositories into a single maintainable application.

## Design goals

- one entry point: `main.m`
- tab-based GUI built programmatically with `uifigure`, `uigridlayout`, and `uitabgroup`
- adaptive layout with a maximized main window and responsive grid-based resizing
- compact left-side parameter panels split into **physical parameters** and **numerical / display parameters**
- right-side preview area with a bottom **notes** panel instead of a formula block
- lower-case, underscore-separated file names
- common numerical kernels shared across tabs
- LaTeX-style titles, labels, legends, and tick labels on output plots
- clearer GUI folder structure with `app/tabs`, `app/panels`, and `app/ui/{controls,display,utils}`

## Modules

1. **fourier studio**  
   A richer modular 4f playground with freely combinable object-plane, phase-plane, and Fourier-filter modules, plus presets and auto/fixed framing controls.
2. **wave optics**  
   Free-space propagation and compact 4F Fourier filtering.
3. **imaging and aberrations**  
   Pupil phase, PSF, OTF, confocal effective PSF, and STED narrowing.
4. **interference and phase**  
   Moire fringes, lateral shearing interferograms, and Gerchberg-Saxton phase retrieval.
5. **geometric optics**  
   Thin-lens imaging, exact refraction at a spherical interface, and Fresnel coefficients.
6. **tomography**  
   Parallel-beam forward projection, sinogram generation, and filtered backprojection.

## Folder layout

- `main.m` — application entry point
- `app/launch_unified_optics_studio.m` — main GUI launcher
- `app/tabs/` — tab-level GUI logic for each physical module
- `app/panels/` — reusable control-panel row builders
- `app/ui/controls/` — standard numeric and dropdown UI builders
- `app/ui/display/` — plotting, image display, LaTeX text, and axis style helpers
- `app/ui/utils/` — export, progress dialog, and image post-processing helpers
- `core/` — numerical models grouped by physical domain
- `docs/notes_catalog.m` — short mode-specific notes shown in the GUI

## Run

From MATLAB:

```matlab
cd(path_to_project)
main
```

## MATLAB compatibility notes

The GUI uses `uifigure`, `uigridlayout`, and `uitabgroup` as the core app-building primitives. The layout is grid-based rather than pixel-placed, so the preview area grows and shrinks with the window. The project also sets the main window to maximized state after the UI is drawn, which is the safer startup pattern for scalable app layouts.

## Provenance of the consolidated modules

The project architecture was derived from these source themes in the uploaded code collection:

- angular spectrum propagation and band limiting
- compact and modular 4F optical filtering GUIs
- Zernike-aberrated pupil imaging and PSF/MTF generation
- confocal, SIM, STED, and phase retrieval demos
- ray tracing, Snell/Fresnel optics, and lens geometry
- projection imaging and filtered backprojection

This unified application does **not** aim for line-by-line compatibility with the original repositories. Instead, it refactors their repeated ideas into a smaller, clearer, GUI-driven teaching and exploration project.
