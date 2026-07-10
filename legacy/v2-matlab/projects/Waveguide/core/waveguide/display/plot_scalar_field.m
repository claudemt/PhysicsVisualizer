function plot_scalar_field(ax, X, Y, F, cbLabel, titleText, xLabelText, yLabelText, mapName)
%PLOT_SCALAR_FIELD Draw a normalized scalar field using shared heatmap style.
%
% The old implementation duplicated colormap/colorbar/title/label styling.
% render_result provides the shared heatmap style.

[xv, yv] = local_axes_vectors(X, Y);
render_result('apply_heatmap_style', ax, xv, yv, F, ...
    'CLim', [-1 1], ...
    'Mask', isfinite(F), ...
    'Title', titleText, ...
    'XLabel', xLabelText, ...
    'YLabel', yLabelText, ...
    'ColorbarLabel', cbLabel);
axis(ax, 'equal');
axis(ax, 'tight');
end

function [xv, yv] = local_axes_vectors(X, Y)
if isvector(X)
    xv = X;
else
    xv = X(1,:);
end
if isvector(Y)
    yv = Y;
else
    yv = Y(:,1);
end
end
