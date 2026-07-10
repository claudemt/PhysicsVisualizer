function result = run_cylindrical_dielectric_generation(project_root, params)
%RUN_CYLINDRICAL_DIELECTRIC_GENERATION Generate a cylindrical dielectric dispersion plot.
%
% Contour-based results use the standard image_output hidden-figure utility
% directly since render_result does not have a native contour result kind.

folder = image_output('clear_cache', project_root, 'waveguide_cylindrical_normalized_dispersion');
R = circular_dielectric_dispersion(params.n1, params.n2, params.vmax, params.umax, params.max_order, params.samples);
fname = 'cylindrical_dielectric_dispersion.png';
fig = image_output('hidden_figure', 'Position', [100 100 1160 820]);
ax = axes('Parent', fig, 'Units', 'normalized', 'Position', [0.09 0.11 0.76 0.80]);
plot_circular_dielectric_dispersion(ax, R, params.legend_location);
file = image_output('save_figure', fig, folder, fname, 260);
close(fig);
result = struct('files', {{file}}, 'storage_folder', folder);
end
