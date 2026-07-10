function plot_planar_sweep(ax, R, legendChoice)
%PLOT_PLANAR_SWEEP Plot thickness-scan results.
if nargin < 3 || isempty(legendChoice)
    legendChoice = 'right side';
end
axes(ax); %#ok<LAXES>
cla(ax, 'reset');
yyaxis(ax, 'left');
plot(ax, R.dValues, R.modeCount, 'LineWidth', 2.0, ...
    'DisplayName', '$\mathrm{guided\ modes}$');
ylabel(ax, '$\mathrm{guided\ mode\ count}$', 'Interpreter', 'latex');
yyaxis(ax, 'right');
hold(ax, 'on');
for k = 1:numel(R.branches)
    B = R.branches(k);
    plot(ax, R.dValues, B.neff, '--', 'LineWidth', 1.5, ...
        'DisplayName', mode_label(R.modeType, B.order));
end
hold(ax, 'off');
ylabel(ax, '$n_{\mathrm{eff}}$', 'Interpreter', 'latex');
xlabel(ax, '$d\;(\mathrm{m})$', 'Interpreter', 'latex');
title(ax, sprintf('Planar thickness sweep: $\\mathrm{%s}$, $f=%s\\;\\mathrm{GHz}$, $n_{\\mathrm{co}}=%s$, $n_{\\mathrm{cl}}=%s$', ...
    R.modeType, format_sig3(R.freqGHz), format_sig3(R.n1), format_sig3(R.n2)), 'Interpreter', 'latex');
lgd = legend(ax, 'show', 'Location', legend_location(legendChoice), 'Interpreter', 'latex');
lgd.FontName = 'Times New Roman';
lgd.FontSize = 15;
apply_plot_style(ax, 'curve');
end
