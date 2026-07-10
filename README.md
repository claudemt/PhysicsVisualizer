# PhysicsVisualizer

PhysicsVisualizer is a Python desktop and batch visualization suite for physics, engineering, optics, mechanics, electromagnetics, and applied mathematics — designed for research demonstrations, classroom teaching, exploratory modeling, and visual interpretation of physical or mathematical systems.

## Quick Start

Install the package:

```bash
python -m pip install -e .
```

List available projects:

```bash
python cli.py --list
```

Launch any project by its entry point:

```bash
python projects/Waveguide/main.py
```

Every project follows this pattern:

```text
projects/<ProjectName>/main.py
```

Generated images and reports are written to the project's `output/` folder. GUI export defaults to a timestamped subfolder such as `projects/Waveguide/output/20260710_141011`.

Read `docs/physical_formulas.md` in each project for the input parameters and physical formulas. Command-line examples live under each project's `example/` folder.

For command-line export:

```bash
python cli.py --project Waveguide --export projects/Waveguide/output/demo
```

## Projects

| Project | What it does |
|---|---|
| ChladniFigures | Visualizes thin-plate vibration modes and static plate deflection under external loads. |
| CreativePlotStudio | Provides generative art, fractal, nonlinear, and artistic plotting workflows. |
| CrystalOpticsBoundary | Computes reflection and transmission behavior at anisotropic crystal boundaries. |
| GraphiteLevitation | Visualizes diamagnetic levitation of graphite over compact checkerboard magnet arrays. |
| MieScattering | Visualizes electromagnetic scattering fields for sphere- and cylinder-style models. |
| MovingChargeFields | Visualizes retarded electric and magnetic fields, Poynting flow, and phase-sweep videos for moving charges. |
| OpticsStudio | Includes Fourier optics, wave propagation, imaging, interference, ray optics, and tomography modules. |
| RigidBodyRotation | Simulates free and fixed-point rigid-body attitude dynamics with image and video output. |
| SpecialFunctionsStudio | Plots curves, surfaces, and vector-style visualizations for special functions. |
| ThinFilm | Computes layered elastic-wave and electromagnetic-wave transfer-matrix cases. |
| Waveguide | Visualizes metallic and dielectric waveguide modes, cutoff behavior, dispersion, and field profiles. |

## License

This project is released under the MIT License.
