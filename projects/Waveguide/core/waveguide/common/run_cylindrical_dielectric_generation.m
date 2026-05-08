function result = run_cylindrical_dielectric_generation(project_root, params)
%RUN_CYLINDRICAL_DIELECTRIC_GENERATION Generate a cylindrical dielectric dispersion plot.

folder = image_output('clear_cache', project_root, 'waveguide_cylindrical_normalized_dispersion');
R = circular_dielectric_dispersion(params.n1, params.n2, params.vmax, params.umax, params.max_order, params.samples);
fname = 'cylindrical_dielectric_dispersion.png';
file = export_waveguide_axes_png(folder, fname, @(ax) plot_circular_dielectric_dispersion(ax, R, params.legend_location));
result = struct('files', {{file}}, 'storage_folder', folder);
end
