function apply_axes_style(ax)
try, ax.FontName = 'Times New Roman'; catch, end
try, ax.TickLabelInterpreter = 'latex'; catch, end
try, box(ax,'on'); catch, end
try, grid(ax,'off'); catch, end
end
