function plot_planar_dispersion(ax, R, legendChoice)
%PLOT_PLANAR_DISPERSION Plot normalized slab b-V curves.
if nargin < 3 || isempty(legendChoice)
    legendChoice = 'right side';
end
axes(ax); %#ok<LAXES>
cla(ax, 'reset');
hold(ax, 'on');
for k = 1:numel(R.curves)
    C = R.curves(k);
    plot(ax, C.V, C.b, 'LineWidth', 1.9, ...
        'DisplayName', mode_label(R.modeType, C.order));
end
hold(ax, 'off');
xlim(ax, [0 R.Vmax]);
ylim(ax, [0 1]);
xlabel(ax, '$V$', 'Interpreter', 'latex');
ylabel(ax, '$b=(n_{\mathrm{eff}}^2-n_{\mathrm{cl}}^2)/(n_{\mathrm{co}}^2-n_{\mathrm{cl}}^2)$', 'Interpreter', 'latex');
title(ax, sprintf('Planar slab $\\mathrm{%s}$ normalized dispersion: $n_{\\mathrm{co}}=%s$, $n_{\\mathrm{cl}}=%s$', ...
    R.modeType, format_sig3(R.n1), format_sig3(R.n2)), 'Interpreter', 'latex');
lgd = legend(ax, 'show', 'Location', legend_location(legendChoice), 'Interpreter', 'latex');
lgd.FontName = 'Times New Roman';
lgd.FontSize = 15;
apply_plot_style(ax, 'curve');
end
