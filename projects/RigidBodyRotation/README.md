# RigidBodyRotation

Python rigid-body attitude dynamics visualizer for torque-free rotation and fixed-point gravity cases.

## Run

```bash
python projects/RigidBodyRotation/main.py
```

## Project Layout

- `app/` declares rigid-body parameter, comparison, and export controls.
- `core/` contains kinematics, solver, model dispatch, and rendering code.
- `docs/physical_formulas.md` records the formula reference for the Python port.
- `example/` contains canonical Python reproduction entries.
- `output/` is the project-local export target.

All ordinary GUI styling, matplotlib styling, title-safe export, animation export, and composite behavior must use the shared `utils/` layer. The MATLAB parity reference remains under `legacy/matlab/projects/RigidBodyRotation/`.
