function apply_axes_style(ax)
%APPLY_AXES_STYLE Apply shared image-axes styling.
base_axes_style(ax);
try, ax.Toolbar.Visible = 'off'; catch, end
axis(ax, 'image');
end
