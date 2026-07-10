# Waveguide Studio GUI Guide

Start the application from MATLAB by running:

```matlab
main
```

The GUI has separate tabs for planar dielectric slabs, metal PEC guides, and cylindrical dielectric guides. Each tab has controls on the left and a preview/results panel on the right.

## Common workflow

1. Choose the waveguide/action.
2. Enter physical parameters.
3. Press **Run**.
4. Select generated PNGs from the preview list.
5. Press **Export** to copy generated figures into the `output/` folder.

## Legend placement

Curve plots provide a legend-position selector:

```text
right side, upper left, lower left, upper right, lower right
```

The default is `right side`. Use an inside-corner location only when the curves do not overlap the legend.

## Metal PEC guides

For rectangular guides, enter width `a` and height `b`. For circular guides, enter radius `r`.

The dispersion action includes **f max (GHz)**. This is the upper frequency limit of the plotted curve and defaults to 10 GHz. The physical cutoff frequency `f_c` is still computed from the mode and geometry, and every legend entry reports that mode's own `f_c`.

## Planar dielectric slab

Use `nco (core)` for `n_co` and `ncl (cladding)` for `n_cl`. Guided modes require `n_co > n_cl`.

The normalized dispersion curve is plotted as `b` versus `V`, where `b` is related to the effective index by

```text
b = (n_eff^2 - n_cl^2)/(n_co^2 - n_cl^2).
```

The notes panel in the GUI gives the definitions for `n_eff`, `beta`, `V`, and `b` for each action.

## Notes panel

The notes panel is intentionally verbose: it explains what the selected plot means, what the axes represent, and which physical quantities are derived rather than direct user inputs.


## Multi-plot heatmap sheets

For **mode field** actions in the planar and metal tabs, you can request several modes at once and also combine them into one high-resolution PNG sheet.

Use the **multi-plot layout** box:

- `4` means four panels per row, with a shorter final row when needed.
- `auto` uses the same four-per-row default.
- A string like `4+4+2` means three exact rows containing 4, 4, and 2 plots.
- The numbers must add up to the total number of generated heatmaps.

The combined sheet trims the white margins of individual PNGs, preserves each panel's aspect ratio, and keeps rows compact instead of stretching them across a large blank canvas.


## Output folders

Exports are copied directly into a flat output folder such as `output/rectangular/`; the export step does not create an additional run-name subfolder.
