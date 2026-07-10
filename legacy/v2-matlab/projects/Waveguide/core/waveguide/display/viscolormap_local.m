function cmapOut = viscolormap_local(N)
%VISCOLORMAP_LOCAL Visible-spectrum colormap (380-780 nm), gamma-corrected.
% Compatibility wrapper around the shared PhysicsVisualizer style palette.

if nargin < 1, N = 256; end
cmapOut = studio_style('visible_colormap', N);
end
