# Waveguide GUI Studio

A Chladni-style MATLAB GUI rewrite of the waveguide research project.

## Run

Open MATLAB in this folder and run:

```matlab
main
```

`main.m` is the single project entry point. It adds the whole project to the MATLAB path and launches the tabbed GUI.

## Organization

- `app/launch_waveguide_studio.m` creates the main `uifigure` and tab group.
- `app/tabs/` contains one GUI tab per study family.
- `app/content/` contains short explanatory notes displayed in the GUI.
- `app/ui/controls/`, `app/ui/display/`, and `app/ui/utils/` contain common GUI helpers.
- `core/common/` contains shared constants and run/export helpers.
- `core/metal/` contains rectangular and circular PEC guide calculations.
- `core/dielectric/` contains planar slab and cylindrical dielectric formulas.
- `docs/` contains the active GUI and theory notes.
- `output/` receives exported PNGs from the GUI.

Each GUI action reads only the parameters it actually uses. Parameters that are not relevant to the selected waveguide/action are disabled and excluded from validation.


The planar and metal mode-field tools can also generate a combined multi-plot heatmap sheet using a layout string such as `4+4+2`.

Exports are written directly to flat folders such as `output/rectangular/`, `output/circular/`, `output/planar/`, and `output/cylindrical/`.
