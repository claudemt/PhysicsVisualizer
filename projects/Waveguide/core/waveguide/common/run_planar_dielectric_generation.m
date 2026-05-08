function result = run_planar_dielectric_generation(project_root, params)
%RUN_PLANAR_DIELECTRIC_GENERATION Generate one or more planar dielectric studies and save PNG output.

folder = image_output('clear_cache', project_root, ['waveguide_planar_' params.action]);
files = {};
map_name = params.map_name;
legend_choice = params.legend_location;

switch params.action
    case 'mode field'
        orders = params.order_list(:).';
        image_files = {};
        for k = 1:numel(orders)
            order = orders(k);
            R = planar_field(params.mode_type, order, params.freq_ghz, params.n1, params.n2, params.d, params.z_length, params.grid_n);
            fname = sprintf('planar_%s_order%d_field.png', params.mode_type, order);
            image_files{end+1} = export_waveguide_axes_png(folder, fname, ... %#ok<AGROW>
                @(ax) plot_scalar_field(ax, R.x, R.z, R.F, R.cbLabel, R.titleText, '$x\;(\mathrm{m})$', '$z\;(\mathrm{m})$', map_name));
        end
        files = image_files;
    case 'dispersion curve'
        R = planar_dispersion(params.mode_type, params.n1, params.n2, params.vmax, params.max_order, params.samples);
        fname = sprintf('planar_%s_dispersion.png', params.mode_type);
        files{end+1} = export_waveguide_axes_png(folder, fname, ...
            @(ax) plot_planar_dispersion(ax, R, legend_choice)); %#ok<AGROW>
    case 'mode existence'
        R = planar_existence(params.mode_type, params.vmax, params.max_order);
        fname = sprintf('planar_%s_mode_existence.png', params.mode_type);
        files{end+1} = export_waveguide_axes_png(folder, fname, ...
            @(ax) plot_planar_existence(ax, R, legend_choice)); %#ok<AGROW>
    case 'thickness sweep'
        R = planar_thickness_sweep(params.mode_type, params.n1, params.n2, params.d, params.freq_ghz, params.max_order, params.samples);
        fname = sprintf('planar_%s_thickness_sweep.png', params.mode_type);
        files{end+1} = export_waveguide_axes_png(folder, fname, ...
            @(ax) plot_planar_sweep(ax, R, legend_choice)); %#ok<AGROW>
    otherwise
        error('Unsupported planar dielectric action: %s', params.action);
end

result = struct('files', {files}, 'storage_folder', folder);
end
