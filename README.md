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


## License

This project is released under the MIT License.