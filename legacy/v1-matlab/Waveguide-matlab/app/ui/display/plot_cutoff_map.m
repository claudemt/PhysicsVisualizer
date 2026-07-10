function plot_cutoff_map(ax, R, mapName)
%PLOT_CUTOFF_MAP Plot a cutoff-frequency matrix.
axes(ax); %#ok<LAXES>
cla(ax, 'reset');
imagesc(ax, R.nList, R.mList, R.fcGHz);
set(ax, 'YDir', 'normal');
axis(ax, 'tight');
set_project_colormap(ax, mapName);
add_labeled_colorbar(ax, '$f_{\mathrm{c}}\;(\mathrm{GHz})$', []);
xlabel(ax, '$n$', 'Interpreter', 'latex');
ylabel(ax, '$m$', 'Interpreter', 'latex');
title(ax, R.titleText, 'Interpreter', 'latex');
apply_plot_style(ax, 'map');
end
