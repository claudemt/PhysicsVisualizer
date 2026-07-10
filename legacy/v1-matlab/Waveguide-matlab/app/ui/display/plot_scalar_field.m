function plot_scalar_field(ax, X, Y, F, cbLabel, titleText, xLabelText, yLabelText, mapName)
%PLOT_SCALAR_FIELD Draw a normalized scalar field.
axes(ax); %#ok<LAXES>
cla(ax, 'reset');
contourf(ax, X, Y, F, 120, 'LineColor', 'none');
axis(ax, 'equal');
axis(ax, 'tight');
set_project_colormap(ax, mapName);
add_labeled_colorbar(ax, cbLabel, [-1 1]);
title(ax, titleText, 'Interpreter', 'latex');
xlabel(ax, xLabelText, 'Interpreter', 'latex');
ylabel(ax, yLabelText, 'Interpreter', 'latex');
apply_plot_style(ax, 'field');
end
