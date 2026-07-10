function plot_planar_existence(ax, R, legendChoice)
%PLOT_PLANAR_EXISTENCE Plot mode existence/cutoff structure.
if nargin < 3 || isempty(legendChoice)
    legendChoice = 'right side';
end
axes(ax); %#ok<LAXES>
cla(ax, 'reset');
hold(ax, 'on');
for k = 1:numel(R.cutoffV)
    y = R.orders(k);
    plot(ax, [R.cutoffV(k) R.Vmax], [y y], 'LineWidth', 4, ...
        'DisplayName', mode_label(R.modeType, y));
    plot(ax, R.cutoffV(k), y, 'ko', 'MarkerFaceColor', 'w', 'HandleVisibility', 'off');
end
hold(ax, 'off');
xlim(ax, [0 R.Vmax]);
ylim(ax, [-0.6 max(R.orders)+0.6]);
yticks(ax, R.orders);
xlabel(ax, '$V$', 'Interpreter', 'latex');
ylabel(ax, '$\mathrm{mode\ order}$', 'Interpreter', 'latex');
title(ax, sprintf('Planar mode existence: $\\mathrm{%s}$, $V_{\\mathrm{max}}=%s$', ...
    R.modeType, format_sig3(R.Vmax)), 'Interpreter', 'latex');
lgd = legend(ax, 'show', 'Location', legend_location(legendChoice), 'Interpreter', 'latex');
lgd.FontName = 'Times New Roman';
lgd.FontSize = 15;
apply_plot_style(ax, 'curve');
end
