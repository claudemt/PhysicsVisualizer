function result = run_planar_dielectric_generation(project_root, params)
%RUN_PLANAR_DIELECTRIC_GENERATION Generate one or more planar dielectric studies and save PNG output.
%
% Heatmap and curve-style results are rendered through the shared
% render_result pipeline.  Yyaxis plots (thickness sweep) use the standard
% image_output hidden-figure utility directly.

folder = image_output('clear_cache', project_root, ['waveguide_planar_' params.action]);
files = {};
legend_choice = params.legend_location;

switch params.action
    case 'mode field'
        orders = params.order_list(:).';
        items = cell(1, numel(orders));
        for k = 1:numel(orders)
            order = orders(k);
            R = planar_field(params.mode_type, order, params.freq_ghz, params.n1, params.n2, params.d, params.z_length, params.grid_n);
            item = render_result('heatmap', R.x, R.z, R.F, ...
                'CLim', [-1 1], ...
                'Mask', isfinite(R.F), ...
                'Title', R.titleText, ...
                'XLabel', '$x/d$', ...
                'YLabel', '$z/d$', ...
                'ColorbarLabel', R.cbLabel, ...
                'AxisMode', 'tight');
            item.filename = sprintf('%02d_%s_planar_order%d.png', k, params.mode_type, order);
            items{k} = item;
        end
        bundle = struct('kind', 'bundle', 'items', {items});
        files = render_result('render', bundle, folder, 'DPI', 260);
    case 'dispersion curve'
        R = planar_dispersion(params.mode_type, params.n1, params.n2, params.vmax, params.max_order, params.samples);
        curves = cell(1, numel(R.curves));
        for k = 1:numel(R.curves)
            C = R.curves(k);
            curves{k} = struct('x', C.V, 'y', C.b, 'label', mode_label(R.modeType, C.order));
        end
        titleText = sprintf('Planar slab $\\mathrm{%s}$ normalized dispersion: $n_{\\mathrm{co}}=%s$, $n_{\\mathrm{cl}}=%s$', ...
            R.modeType, format_sig3(R.n1), format_sig3(R.n2));
        result_curve = render_result('curve', curves, ...
            'Title', titleText, ...
            'XLabel', '$V$', ...
            'YLabel', '$b=(n_{\mathrm{eff}}^2-n_{\mathrm{cl}}^2)/(n_{\mathrm{co}}^2-n_{\mathrm{cl}}^2)$', ...
            'XLim', [0 R.Vmax], ...
            'YLim', [0 1], ...
            'LegendLocation', legend_location(legend_choice));
        prefix = sprintf('planar_%s_dispersion', params.mode_type);
        files = [files, render_result('render', result_curve, folder, 'Prefix', prefix, 'DPI', 260)]; %#ok<AGROW>
    case 'mode existence'
        R = planar_existence(params.mode_type, params.vmax, params.max_order);
        curves = cell(1, numel(R.cutoffV));
        for k = 1:numel(R.cutoffV)
            curves{k} = struct('x', [R.cutoffV(k), R.Vmax], 'y', [R.orders(k), R.orders(k)], ...
                'label', mode_label(R.modeType, R.orders(k)));
        end
        titleText = sprintf('Planar mode existence: $\\mathrm{%s}$, $V_{\\mathrm{max}}=%s$', ...
            R.modeType, format_sig3(R.Vmax));
        result_curve = render_result('curve', curves, ...
            'Title', titleText, ...
            'XLabel', '$V$', ...
            'YLabel', '$\mathrm{mode\ order}$', ...
            'XLim', [0 R.Vmax], ...
            'YLim', [-0.6, max(R.orders)+0.6], ...
            'LegendLocation', legend_location(legend_choice));
        prefix = sprintf('planar_%s_mode_existence', params.mode_type);
        files = [files, render_result('render', result_curve, folder, 'Prefix', prefix, 'DPI', 260)]; %#ok<AGROW>
    case 'thickness sweep'
        R = planar_thickness_sweep(params.mode_type, params.n1, params.n2, params.d, params.freq_ghz, params.max_order, params.samples);
        fname = sprintf('planar_%s_thickness_sweep.png', params.mode_type);
        fig = image_output('hidden_figure', 'Position', [100 100 1160 820]);
        ax = axes('Parent', fig, 'Units', 'normalized', 'Position', [0.09 0.11 0.76 0.80]);
        plot_planar_sweep(ax, R, legend_choice);
        files{end+1} = image_output('save_figure', fig, folder, fname, 260); %#ok<AGROW>
        close(fig);
end

result = struct('files', {files}, 'storage_folder', folder);
end
