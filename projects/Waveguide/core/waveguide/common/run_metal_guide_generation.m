function result = run_metal_guide_generation(project_root, params)
%RUN_METAL_GUIDE_GENERATION Generate one or more PEC waveguide studies and save PNG output.

folder = image_output('clear_cache', project_root, sprintf('waveguide_metal_%s_%s', params.guide, params.action));
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
                    fname = sprintf('rectangular_%s_m%d_n%d_field.png', params.mode_type, m, n);
                    image_files{end+1} = export_waveguide_axes_png(folder, fname, ... %#ok<AGROW>
                        @(ax) plot_scalar_field(ax, R.x, R.y, R.F, R.cbLabel, R.titleText, '$x\;(\mathrm{m})$', '$y\;(\mathrm{m})$', map_name));
                end
                files = image_files;
            case 'dispersion curves'
                R = rectangular_metal_dispersion(params.mode_type, params.a, params.b, params.max_order, 0, params.fmax_ghz, params.samples);
                fname = sprintf('rectangular_%s_dispersion.png', params.mode_type);
                files{end+1} = export_waveguide_axes_png(folder, fname, ...
                    @(ax) plot_metal_dispersion(ax, R, legend_choice)); %#ok<AGROW>
            case 'cutoff map'
                R = rectangular_cutoff_map(params.mode_type, params.a, params.b, params.max_order);
                fname = sprintf('rectangular_%s_cutoff_map.png', params.mode_type);
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
                    fname = sprintf('circular_%s_m%d_n%d_field.png', params.mode_type, m, n);
                    image_files{end+1} = export_waveguide_axes_png(folder, fname, ... %#ok<AGROW>
                        @(ax) plot_scalar_field(ax, R.x, R.y, R.F, R.cbLabel, R.titleText, '$x\;(\mathrm{m})$', '$y\;(\mathrm{m})$', map_name));
                end
                files = image_files;
            case 'dispersion curves'
                R = circular_metal_dispersion(params.mode_type, params.radius, params.max_order, 0, params.fmax_ghz, params.samples);
                fname = sprintf('circular_%s_dispersion.png', params.mode_type);
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
