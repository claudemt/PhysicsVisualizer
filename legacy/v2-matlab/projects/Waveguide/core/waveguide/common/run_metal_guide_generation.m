function result = run_metal_guide_generation(project_root, params)
%RUN_METAL_GUIDE_GENERATION Generate one or more PEC waveguide studies and save PNG output.
%
% Heatmap-style results (mode fields, cutoff maps) are rendered through the
% shared render_result pipeline so all projects use the same hidden-figure
% creation and unified visual style.  Yyaxis dispersion curves are created
% with the standard image_output hidden-figure utility directly.

folder = image_output('clear_cache', project_root, sprintf('waveguide_metal_%s_%s', params.guide, params.action));
files = {};
map_name = params.map_name;
legend_choice = params.legend_location;

switch params.guide
    case 'rectangular'
        switch params.action
            case 'mode field'
                M = params.mode_matrix;
                items = cell(1, size(M, 1));
                for k = 1:size(M, 1)
                    m = M(k,1);
                    n = M(k,2);
                    R = rectangular_metal_field(params.mode_type, m, n, params.a, params.xi0, params.grid_n);
                    item = render_result('heatmap', R.x, R.y, R.F, ...
                        'CLim', [-1 1], ...
                        'Mask', isfinite(R.F), ...
                        'Title', R.titleText, ...
                        'XLabel', '$x/a$', ...
                        'YLabel', '$y/a$', ...
                        'ColorbarLabel', R.cbLabel, ...
                        'AxisMode', 'tight');
                    item.filename = sprintf('%02d_%s_rectangular_m%d_n%d.png', k, params.mode_type, m, n);
                    items{k} = item;
                end
                bundle = struct('kind', 'bundle', 'items', {items});
                files = render_result('render', bundle, folder, 'DPI', 260);
            case 'dispersion curves'
                R = rectangular_metal_dispersion(params.mode_type, params.a, params.b, params.max_order, 0, params.fmax_ghz, params.samples);
                fname = sprintf('rectangular_%s_dispersion.png', params.mode_type);
                fig = image_output('hidden_figure', 'Position', [100 100 1160 820]);
                ax = axes('Parent', fig, 'Units', 'normalized', 'Position', [0.09 0.11 0.76 0.80]);
                plot_metal_dispersion(ax, R, legend_choice);
                files{end+1} = image_output('save_figure', fig, folder, fname, 260); %#ok<AGROW>
                close(fig);
            case 'cutoff map'
                R = rectangular_cutoff_map(params.mode_type, params.a, params.b, params.max_order);
                cmap = local_project_colormap(map_name);
                item = render_result('heatmap', R.nList, R.mList, R.fcGHz, ...
                    'Title', R.titleText, ...
                    'XLabel', '$n$', ...
                    'YLabel', '$m$', ...
                    'ColorbarLabel', '$f_{\mathrm{c}}\;(\mathrm{GHz})$', ...
                    'Colormap', cmap, ...
                    'AxisMode', 'tight');
                bundle = struct('kind', 'bundle', 'items', {{item}});
                prefix = sprintf('rectangular_%s_cutoff_map', params.mode_type);
                files = [files, render_result('render', bundle, folder, 'Prefix', prefix, 'DPI', 260)]; %#ok<AGROW>
        end
    case 'annulus'
        switch params.action
            case 'mode field'
                M = params.mode_matrix;
                items = cell(1, size(M, 1));
                for k = 1:size(M, 1)
                    m = M(k,1);
                    n = M(k,2);
                    R = circular_metal_field(params.mode_type, m, n, params.radius, params.grid_n, params.xi0);
                    item = render_result('heatmap', R.x, R.y, R.F, ...
                        'CLim', [-1 1], ...
                        'Mask', isfinite(R.F), ...
                        'Title', R.titleText, ...
                        'XLabel', '$x/a$', ...
                        'YLabel', '$y/a$', ...
                        'ColorbarLabel', R.cbLabel, ...
                        'AxisMode', 'tight');
                    if isfield(R, 'boundaryRadii') && ~isempty(R.boundaryRadii)
                        item.circleRadii = R.boundaryRadii;
                    end
                    item.filename = sprintf('%02d_%s_annular_m%d_n%d.png', k, params.mode_type, m, n);
                    items{k} = item;
                end
                bundle = struct('kind', 'bundle', 'items', {items});
                files = render_result('render', bundle, folder, 'DPI', 260);
            case 'dispersion curves'
                R = circular_metal_dispersion(params.mode_type, params.radius, params.max_order, 0, params.fmax_ghz, params.samples);
                fname = sprintf('annular_%s_dispersion.png', params.mode_type);
                fig = image_output('hidden_figure', 'Position', [100 100 1160 820]);
                ax = axes('Parent', fig, 'Units', 'normalized', 'Position', [0.09 0.11 0.76 0.80]);
                plot_metal_dispersion(ax, R, legend_choice);
                files{end+1} = image_output('save_figure', fig, folder, fname, 260); %#ok<AGROW>
                close(fig);
        end
end

result = struct('files', {files}, 'storage_folder', folder);
end

function cmap = local_project_colormap(mapName)
%LOCAL_PROJECT_COLORMAP Return the Project colormap for the given map name.
if nargin < 1 || isempty(mapName)
    mapName = 'project';
end
mapName = lower(strtrim(char(string(mapName))));
switch mapName
    case {'project', 'visible', 'spectrum', 'vis'}
        cmap = viscolormap_local(256);
    case {'parula', 'turbo', 'gray', 'hot', 'jet', 'hsv', 'cool', 'spring', 'summer', 'autumn', 'winter'}
        try
            cmap = feval(mapName, 256);
        catch
            cmap = viscolormap_local(256);
        end
    otherwise
        cmap = viscolormap_local(256);
end
end
