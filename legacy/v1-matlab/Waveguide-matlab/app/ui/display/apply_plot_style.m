function apply_plot_style(ax, plotKind)
%APPLY_PLOT_STYLE Apply common style presets for each plot family.
base_axes_style(ax);
if nargin < 2 || isempty(plotKind)
    plotKind = 'field';
end
switch lower(plotKind)
    case {'curve', 'line', 'sweep'}
        grid(ax, 'on');
    case {'field', 'map', 'image', 'contour'}
        grid(ax, 'off');
    otherwise
        grid(ax, 'off');
end
end
