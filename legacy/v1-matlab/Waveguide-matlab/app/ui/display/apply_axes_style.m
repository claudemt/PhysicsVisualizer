function apply_axes_style(ax)
%APPLY_AXES_STYLE Apply a consistent LaTeX-oriented style to UIAxes.

ax.Box = 'on';
ax.Toolbar.Visible = 'off';
ax.TickLabelInterpreter = 'latex';
ax.FontName = 'Times New Roman';
ax.FontSize = 15;
ax.LineWidth = 1.2;
axis(ax, 'image');
end
