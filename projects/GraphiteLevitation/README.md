# GraphiteLevitation

MATLAB visualizer for diamagnetic levitation of pyrolytic graphite over a compact checkerboard magnet array.

Run from this folder:

```matlab
main
```

The GUI follows the shared `PhysicsVisualizer/utils` layout (`launch_gui_studio`, `create_tab_layout`, `create_control_panel`, `bind_workflow`, `image_output`, and `render_result`).

## Inline scan inputs

There is no separate parameter-scan tab. Four physical inputs accept either a single number or a tuple/list:

- `d [mm]`: circle radius or square side length
- `W [um]`: graphite thickness
- `chi [1e-4]`: no-laser susceptibility magnitude
- `P`: laser strength factor; `P=0` means no laser

Examples:

```text
6
(6,8,10)
1:0.5:3
linspace(1,3,5)
```

If two inputs are tuples, the GUI computes the Cartesian product. File suffixes include only scanned parameters, for example:

```text
visualization_02_potential_d6_W40_chi3_P0.35.png
```

Each generated case produces four figures: normalized `B^2`, magnetic potential, graphite susceptibility map, and a 3D geometry view. Notes report only displacement and tilt for every case.
