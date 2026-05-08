function base_axes_style(ax)
%BASE_AXES_STYLE Apply shared axes styling used by all studios.
apply_tex_style(ax, 'FontSize', 12, 'TitleFontSize', 14, 'Box', 'on');
try, ax.LineWidth = 1.0; catch, end
grid(ax, 'off');
end
