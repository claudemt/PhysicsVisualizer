# SpecialFunctionsStudio-matlab

A compact MATLAB GUI for visualizing classical special functions. Choose a family, scan parameters, preview the result, and export PNG images with a parameter report and reproducible MATLAB code.

## How to Run

Start MATLAB in the project folder and run:

```matlab
main
```

The project entry point calls `app/utils/launch_gui_studio.m` directly.

## Features

- Interactive GUI for 1D curves and 3D spherical-function visualizations
- Tuple-based parameter scans, including Cartesian products
- Compact control panel for function, parameters, display options, and actions
- 1D crop controls with automatic or manual y-range selection
- 3D panel layout control using integers or row expressions such as `4+3+2+1`
- Legend location control for 1D plots
- Preview notes plus a Markdown notes window
- PNG export to `output/`
- Parameter report and `reproduce_code.m` for command-line reproduction

## Supported Function Families

- Bessel functions: `J`, `Y`, `I`, `K`
- Spherical Bessel functions: `j_n`, `y_n`
- Airy functions and derivatives: `Ai`, `Bi`, `Ai'`, `Bi'`
- Lane--Emden functions
- Complete and incomplete elliptic integrals
- Jacobi elliptic functions: `sn`, `cn`, `dn`
- Gauss hypergeometric function: `2F1`
- Scalar spherical harmonics
- Vector spherical harmonics

## Repository Structure

```text
main.m                         entry point
app/special_function_catalog.m project-specific catalog
app/special_function_dispatch.m project-specific dispatch wrapper
app/render_special_function_from_params.m reproducible command-line renderer
app/tab/create_special_functions_tab.m project GUI assembly
app/utils/                     reusable GUI, rendering, parameter, and output utilities
core/special_functions/        numerical evaluators for each function
docs/                          summary and Markdown notes
.cache/                        temporary previews, created at runtime
output/                        exported bundles, created at runtime
```

## Output

Temporary previews are written to `.cache/`. Exported bundles are written to `output/` and include:

```text
PNG images
composite.png when multiple images are selected
parameters.txt
reproduce_code.m
```

Run `reproduce_code.m` from MATLAB to regenerate the exported result without using the GUI.

## License

MIT-style use for research, teaching, and extension.
