function result = run_metal_guide_generation(project_root, params)
%RUN_METAL_GUIDE_GENERATION Generate one or more PEC waveguide studies and save PNG output.

folder = create_waveguide_run_folder(project_root, 'metal', sprintf('%s_%s', params.guide, params.action));
files = {};
map_name = params.map_name;
legend_choice = params.legend_location;

switch params.guide
    case 'rectangular'
        switch params.action
            case 'mode field'
                M = params.mode_matrix;
                image_files = {};
                for k = 1:size(M, 1)
                    m = M(k,1);
                    n = M(k,2);
                    R = rectangular_metal_field(params.mode_type, m, n, params.a, params.b, params.grid_n);
                    fname = sprintf('rectangular_%s_m%d_n%d_a%s_b%s.png', ...
                        params.mode_type, m, n, format_sig3(params.a), format_sig3(params.b));
                    image_files{end+1} = export_waveguide_axes_png(folder, fname, ... %#ok<AGROW>
                        @(ax) plot_scalar_field(ax, R.x, R.y, R.F, R.cbLabel, R.titleText, '$x\;(\mathrm{m})$', '$y\;(\mathrm{m})$', map_name));
                end
                if numel(image_files) > 1
                    row_counts = parse_montage_layout(params.layout_rows, numel(image_files));
                    panel_name = sprintf('rectangular_%s_mode_field_panel_%s.png', params.mode_type, sprintf('%d_', row_counts));
                    panel_file = export_waveguide_image_montage_png(folder, panel_name, image_files, row_counts);
                    files = [{panel_file}, image_files];
                else
                    files = image_files;
                end
            case 'dispersion curves'
                R = rectangular_metal_dispersion(params.mode_type, params.a, params.b, params.max_order, 0, params.fmax_ghz, params.samples);
                fname = sprintf('rectangular_%s_dispersion_a%s_b%s_fmax%sGHz_maxord%d.png', ...
                    params.mode_type, format_sig3(params.a), format_sig3(params.b), format_sig3(params.fmax_ghz), params.max_order);
                files{end+1} = export_waveguide_axes_png(folder, fname, ...
                    @(ax) plot_metal_dispersion(ax, R, legend_choice)); %#ok<AGROW>
            case 'cutoff map'
                R = rectangular_cutoff_map(params.mode_type, params.a, params.b, params.max_order);
                fname = sprintf('rectangular_%s_cutoff_a%s_b%s_maxord%d.png', ...
                    params.mode_type, format_sig3(params.a), format_sig3(params.b), params.max_order);
                files{end+1} = export_waveguide_axes_png(folder, fname, ...
                    @(ax) plot_cutoff_map(ax, R, map_name)); %#ok<AGROW>
            otherwise
                error('Unsupported rectangular metal action: %s', params.action);
        end
    case 'circular'
        switch params.action
            case 'mode field'
                M = params.mode_matrix;
                image_files = {};
                for k = 1:size(M, 1)
                    m = M(k,1);
                    n = M(k,2);
                    R = circular_metal_field(params.mode_type, m, n, params.radius, params.grid_n);
                    fname = sprintf('circular_%s_m%d_n%d_r%s.png', ...
                        params.mode_type, m, n, format_sig3(params.radius));
                    image_files{end+1} = export_waveguide_axes_png(folder, fname, ... %#ok<AGROW>
                        @(ax) plot_scalar_field(ax, R.x, R.y, R.F, R.cbLabel, R.titleText, '$x\;(\mathrm{m})$', '$y\;(\mathrm{m})$', map_name));
                end
                if numel(image_files) > 1
                    row_counts = parse_montage_layout(params.layout_rows, numel(image_files));
                    panel_name = sprintf('circular_%s_mode_field_panel_%s.png', params.mode_type, sprintf('%d_', row_counts));
                    panel_file = export_waveguide_image_montage_png(folder, panel_name, image_files, row_counts);
                    files = [{panel_file}, image_files];
                else
                    files = image_files;
                end
            case 'dispersion curves'
                R = circular_metal_dispersion(params.mode_type, params.radius, params.max_order, 0, params.fmax_ghz, params.samples);
                fname = sprintf('circular_%s_dispersion_r%s_fmax%sGHz_maxord%d.png', ...
                    params.mode_type, format_sig3(params.radius), format_sig3(params.fmax_ghz), params.max_order);
                files{end+1} = export_waveguide_axes_png(folder, fname, ...
                    @(ax) plot_metal_dispersion(ax, R, legend_choice)); %#ok<AGROW>
            otherwise
                error('Unsupported circular metal action: %s', params.action);
        end
    otherwise
        error('Unsupported metal guide: %s', params.guide);
end

result = struct('files', {files}, 'storage_folder', folder);
end
