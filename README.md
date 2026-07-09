# PhysicsVisualizer

PhysicsVisualizer is a collection of MATLAB-based visualization projects for physics, engineering, optics, mechanics, electromagnetics, and applied mathematics.

The repository is designed for research demonstrations, classroom teaching, exploratory modeling, and visual interpretation of physical or mathematical systems.

## Projects

| Project | What it does |
|---|---|
| ChladniFigures | Visualizes thin-plate vibration modes and static plate deflection under external loads. |
| CreativePlotStudio | Provides generative art, fractal, and nonlinear plotting scripts. |
| CrystalOpticsBoundary | Generates text reports for reflection and transmission at anisotropic crystal boundaries. |
| GraphiteLevitation | Visualizes diamagnetic levitation of graphite over compact checkerboard magnet arrays. |
| MieScattering | Visualizes electromagnetic scattering fields for sphere- and cylinder-style models. |
| MovingChargeFields | Visualizes retarded electric and magnetic fields, Poynting flow, and phase-sweep videos for moving charges. |
| OpticsStudio | Includes Fourier optics, wave propagation, imaging, interference, ray optics, and tomography modules. |
| RigidBodyRotation | Simulates free and fixed-point rigid-body attitude dynamics with image and video output. |
| SpecialFunctionsStudio | Plots curves, surfaces, and vector-style visualizations for special functions. |
| ThinFilm | Generates layered elastic-wave and electromagnetic-wave transfer-matrix text reports. |
| Waveguide | Visualizes metallic and dielectric waveguide modes, cutoff behavior, dispersion, and field profiles. |

## Running

Open MATLAB in the desired project folder and run:

```m
main
```

Generated images, reports, parameter files, and reproduction scripts are written to the project-specific `output/` folder.

Read `docs/physical_formulas.md` in each project to understand the meaning of input parameters and physics formulas behind. You can run `reproduce_code.m` in `example/*/` folder to yield typical figures and learn how to write command line instead of clicking on GUI.

## Repository Layout

All projects share a root-level `utils/` layer. This shared layer provides the common GUI layout, control styling, preview behavior, notes browsing, export naming, parameter reports, and reproduction-code output.

Each project follows a similar organization:

- `main.m` launches the project GUI.
- `app/tabs/` contains GUI tabs, controls, default inputs, tooltips, and user-facing workflow logic.
- `core/` contains the project-specific physical, mathematical, or numerical algorithms.
- `docs/physical_formulas.md` explains the relevant physics or mathematics and how to interpret the generated images or reports.
- `output/` is created automatically when results are exported.

## Shared Style Contract

All projects must use the shared style utilities in `utils/` for GUI chrome, plot typography, preview behavior, and exports. New project code should not hardcode panel colors, button colors, font families, default axes font sizes, notes CSS, or ordinary export behavior unless the visual choice is part of the scientific/artistic data being rendered.

The main public style entry point is `utils/studio_style.m`:

- `studio_style('tokens')` returns the shared color, font, spacing, padding, and axes-size tokens.
- `studio_style('apply_panel', panel)` styles panels and section headers.
- `studio_style('apply_grid', grid, mode)` applies shared grid padding and spacing.
- `studio_style('apply_label', label, mode)` styles normal and hint labels.
- `studio_style('apply_component', component, mode)` styles edit fields, dropdowns, list boxes, text areas, and other controls.
- `studio_style('apply_button', button, mode)` styles primary, secondary, and danger buttons.
- `studio_style('apply_axes', ax, ...)` applies the shared MATLAB axes typography, title spacing, tick interpreters, grid/box settings, and labels.
- `studio_style('apply_legend', lgd, ...)` applies shared legend typography.
- `studio_style('notes_css')` returns the shared notes-browser CSS.
- `studio_style('visible_colormap', n)` returns the shared visible-spectrum colormap.

Project GUIs should be launched with `launch_gui_studio`, organized with `create_tab_layout`, populated with `create_control_panel`, and wired with `bind_workflow`. If a tab needs a custom `uipanel`, `uigridlayout`, label, field, text area, or button, it must call the matching `studio_style` helper immediately after creating that component. Local helper names such as `apply_axes_style` are acceptable only as thin semantic wrappers around `studio_style`.

Plot output should use `studio_style('apply_axes')`, `apply_tex_style`, `render_result`, and `studio_style('apply_legend')` for shared fonts and mathematical text rendering. Colorbars should use `render_result('style_colorbar', ...)` or the equivalent shared defaults. Project-specific colormaps are allowed when they encode a physical field, visual spectrum, or generative-art palette; otherwise use the shared visible-spectrum colormap.

Image export and preview code should use `image_output('save_figure')`, `image_output('export_bundle')`, `image_output('reset_preview')`, and the shared preview/composition helpers. This keeps export padding, smart cropping, title preservation, bundle naming, and preview states consistent. In particular, CreativePlotStudio titles should go through `safe_title` / `set_latex_title` so exported images keep their title band instead of being cropped away.

When adding or refactoring a project, treat the shared style layer as the contract: extend `studio_style` or the existing shared utilities first, then connect project code to that interface.


## License

This project is released under the MIT License.
