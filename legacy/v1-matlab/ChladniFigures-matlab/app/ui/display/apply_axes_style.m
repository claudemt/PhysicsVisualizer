function apply_axes_style(ax)
%APPLY_AXES_STYLE Apply a consistent LaTeX-oriented style to UIAxes.

ax.Box = 'on';
ax.Toolbar.Visible = 'off';
ax.TickLabelInterpreter = 'latex';
ax.FontSize = 12;
ax.LineWidth = 1.0;
axis(ax, 'image');
end
