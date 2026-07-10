function base_axes_style(ax)
%BASE_AXES_STYLE Apply shared axes styling used by all studios.
studio_style('apply_axes', ax, 'Box', 'on');
try, ax.LineWidth = 1.0; catch, end
grid(ax, 'off');
end
