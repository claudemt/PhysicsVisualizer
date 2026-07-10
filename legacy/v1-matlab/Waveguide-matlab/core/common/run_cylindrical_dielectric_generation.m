function result = run_cylindrical_dielectric_generation(project_root, params)
%RUN_CYLINDRICAL_DIELECTRIC_GENERATION Generate a cylindrical dielectric dispersion plot.

folder = create_waveguide_run_folder(project_root, 'cylindrical', 'normalized_dispersion');
R = circular_dielectric_dispersion(params.n1, params.n2, params.vmax, params.umax, params.max_order, params.samples);
fname = sprintf('cylindrical_dielectric_nco%s_ncl%s_maxord%d.png', ...
    format_sig3(params.n1), format_sig3(params.n2), params.max_order);
file = export_waveguide_axes_png(folder, fname, @(ax) plot_circular_dielectric_dispersion(ax, R, params.legend_location));
result = struct('files', {{file}}, 'storage_folder', folder);
end
