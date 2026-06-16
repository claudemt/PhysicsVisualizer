function plot_metal_dispersion(ax, R, legendChoice)
%PLOT_METAL_DISPERSION Plot beta and group-velocity curves for metal guides.
if nargin < 3 || isempty(legendChoice)
    legendChoice = 'right side';
end

axes(ax); %#ok<LAXES>
cla(ax, 'reset');

curves = R.curves;
[~, idx] = sort([curves.fcGHz], 'ascend');
curves = curves(idx);
max_curves = min(numel(curves), 6);
curves = curves(1:max_curves);

colors = lines(max_curves);
beta_handles = gobjects(1, max_curves);

yyaxis(ax, 'left');
hold(ax, 'on');
for k = 1:max_curves
    C = curves(k);
    beta_handles(k) = plot(ax, C.fGHz, C.beta, '-', ...
        'Color', colors(k,:), 'LineWidth', 1.8, 'DisplayName', C.label);
end
ylabel(ax, '$\beta\;(\mathrm{rad/m})$', 'Interpreter', 'latex');

yyaxis(ax, 'right');
for k = 1:max_curves
    C = curves(k);
    plot(ax, C.fGHz, C.vgOverC, '--', ...
        'Color', colors(k,:), 'LineWidth', 1.4, 'HandleVisibility', 'off');
end
ylabel(ax, '$v_{\mathrm{g}}/c$', 'Interpreter', 'latex');

hold(ax, 'off');
xlabel(ax, '$f\;(\mathrm{GHz})$', 'Interpreter', 'latex');
if isfield(R, 'fMaxGHz') && isfinite(R.fMaxGHz)
    xlim(ax, [0 R.fMaxGHz]);
end
title(ax, R.titleText, 'Interpreter', 'latex');
lgd = legend(ax, beta_handles, 'Location', legend_location(legendChoice), 'Interpreter', 'latex');
render_result('legend', lgd);

yyaxis(ax, 'left');
text(ax, 0.98, 0.05, '$\mathrm{solid}:\ \beta\quad \mathrm{dashed}:\ v_{\mathrm{g}}/c$', ...
    'Units', 'normalized', 'Interpreter', 'latex', 'FontSize', 26, ...
    'HorizontalAlignment', 'right', 'VerticalAlignment', 'bottom');

apply_plot_style(ax, 'curve');
end
