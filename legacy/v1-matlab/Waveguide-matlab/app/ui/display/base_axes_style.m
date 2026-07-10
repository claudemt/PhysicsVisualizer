function base_axes_style(ax)
%BASE_AXES_STYLE Apply common axes styling.
set(ax, 'FontName', 'Times New Roman', 'FontSize', 15, 'LineWidth', 1.2, ...
    'TickLabelInterpreter', 'latex', 'Box', 'on');
if isprop(ax, 'Title') && ~isempty(ax.Title)
    ax.Title.FontName = 'Times New Roman';
    ax.Title.FontSize = 18;
    ax.Title.FontWeight = 'normal';
end
if isprop(ax, 'XLabel') && ~isempty(ax.XLabel)
    ax.XLabel.FontName = 'Times New Roman';
    ax.XLabel.FontSize = 17;
end
if isprop(ax, 'YLabel') && ~isempty(ax.YLabel)
    ax.YLabel.FontName = 'Times New Roman';
    ax.YLabel.FontSize = 17;
end
grid(ax, 'off');
end
