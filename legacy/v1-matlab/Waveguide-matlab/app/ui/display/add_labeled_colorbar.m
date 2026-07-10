function cb = add_labeled_colorbar(ax, labelText, limits)
%ADD_LABELED_COLORBAR Add a consistently styled colorbar.
cb = colorbar(ax, 'eastoutside');
cb.Label.String = labelText;
cb.Label.Interpreter = 'latex';
cb.TickLabelInterpreter = 'latex';
cb.FontName = 'Times New Roman';
cb.FontSize = 15;
cb.Label.FontName = 'Times New Roman';
cb.Label.FontSize = 17;
if nargin >= 3 && ~isempty(limits)
    caxis(ax, limits);
end
end
