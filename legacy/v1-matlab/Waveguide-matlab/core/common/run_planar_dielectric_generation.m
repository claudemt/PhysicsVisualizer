function result = run_planar_dielectric_generation(project_root, params)
%RUN_PLANAR_DIELECTRIC_GENERATION Generate one or more planar dielectric studies and save PNG output.

folder = create_waveguide_run_folder(project_root, 'planar', params.action);
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
            fname = sprintf('planar_%s_order%d_nco%s_ncl%s_d%s.png', ...
                params.mode_type, order, format_sig3(params.n1), format_sig3(params.n2), format_sig3(params.d));
            image_files{end+1} = export_waveguide_axes_png(folder, fname, ... %#ok<AGROW>
                @(ax) plot_scalar_field(ax, R.x, R.z, R.F, R.cbLabel, R.titleText, '$x\;(\mathrm{m})$', '$z\;(\mathrm{m})$', map_name));
        end
        if numel(image_files) > 1
            row_counts = parse_montage_layout(params.layout_rows, numel(image_files));
            panel_name = sprintf('planar_%s_mode_field_panel_%s.png', params.mode_type, sprintf('%d_', row_counts));
            panel_file = export_waveguide_image_montage_png(folder, panel_name, image_files, row_counts);
            files = [{panel_file}, image_files];
        else
            files = image_files;
        end
    case 'dispersion curve'
        R = planar_dispersion(params.mode_type, params.n1, params.n2, params.vmax, params.max_order, params.samples);
        fname = sprintf('planar_%s_dispersion_nco%s_ncl%s_maxord%d.png', ...
            params.mode_type, format_sig3(params.n1), format_sig3(params.n2), params.max_order);
        files{end+1} = export_waveguide_axes_png(folder, fname, ...
            @(ax) plot_planar_dispersion(ax, R, legend_choice)); %#ok<AGROW>
    case 'mode existence'
        R = planar_existence(params.mode_type, params.vmax, params.max_order);
        fname = sprintf('planar_%s_mode_existence_maxord%d.png', params.mode_type, params.max_order);
        files{end+1} = export_waveguide_axes_png(folder, fname, ...
            @(ax) plot_planar_existence(ax, R, legend_choice)); %#ok<AGROW>
    case 'thickness sweep'
        R = planar_thickness_sweep(params.mode_type, params.n1, params.n2, params.d, params.freq_ghz, params.max_order, params.samples);
        fname = sprintf('planar_%s_thickness_sweep_nco%s_ncl%s_d%s_maxord%d.png', ...
            params.mode_type, format_sig3(params.n1), format_sig3(params.n2), format_sig3(params.d), params.max_order);
        files{end+1} = export_waveguide_axes_png(folder, fname, ...
            @(ax) plot_planar_sweep(ax, R, legend_choice)); %#ok<AGROW>
    otherwise
        error('Unsupported planar dielectric action: %s', params.action);
end

result = struct('files', {files}, 'storage_folder', folder);
end
