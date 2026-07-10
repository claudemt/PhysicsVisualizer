function plot_circular_dielectric_dispersion(ax, R, legendChoice)
%PLOT_CIRCULAR_DIELECTRIC_DISPERSION Plot step-index characteristic contours.
if nargin < 3 || isempty(legendChoice)
    legendChoice = 'right side';
end
axes(ax); %#ok<LAXES>
cla(ax, 'reset');
hold(ax, 'on');
colors = lines(max(1, numel(R.curves)));
for k = 1:numel(R.curves)
    C = R.curves(k);
    contour(ax, R.V, R.U, C.Phi, [0 0], 'LineWidth', 2.0, ...
        'Color', colors(k,:), 'DisplayName', sprintf('$m=%d$', C.order));
end
plot(ax, [0 R.Vmax], [0 R.Vmax], 'k--', 'LineWidth', 1.5, 'DisplayName', '$U=V$');
hold(ax, 'off');
xlim(ax, [0 R.Vmax]);
ylim(ax, [0 R.Umax]);
xlabel(ax, '$V$', 'Interpreter', 'latex');
ylabel(ax, '$U$', 'Interpreter', 'latex');
title(ax, sprintf('Cylindrical dielectric dispersion: $n_{\\mathrm{co}}=%s$, $n_{\\mathrm{cl}}=%s$', ...
    format_sig3(R.n1), format_sig3(R.n2)), 'Interpreter', 'latex');
lgd = legend(ax, 'show', 'Location', legend_location(legendChoice), 'Interpreter', 'latex');
lgd.FontName = 'Times New Roman';
lgd.FontSize = 15;
axis(ax, 'square');
apply_plot_style(ax, 'contour');
end
