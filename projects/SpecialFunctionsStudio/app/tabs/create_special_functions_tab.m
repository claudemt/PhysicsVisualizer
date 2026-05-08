function tab = create_special_functions_tab(tab_group, project_root)
app_figure = ancestor(tab_group, 'figure');
catalog = parse_special_functions_params('catalog');

ui = create_tab_layout(tab_group, 'special functions', project_root, ...
    'Preview', 'list', ...
    'NotesText', local_special_notes(catalog(1), catalog(1).Variants(1)), ...
    'NotesFile', fullfile(project_root, 'docs', 'physical_formulas.md'));

ui.control_grid.RowHeight = {'fit','fit','fit','fit'};

function_panel = create_control_panel(ui.control_grid, 'section', 'function', 2);
family_dd = create_control_panel(function_panel.grid, 'dropdown', 'family', {catalog.Name}, catalog(1).Key, 'Choose a special-function family.');
family_dd.ItemsData = {catalog.Key};
family_dd.Value = catalog(1).Key;
variant_dd = create_control_panel(function_panel.grid, 'dropdown', 'function', {catalog(1).Variants.Name}, catalog(1).Variants(1).Key, 'Choose a function.');
variant_dd.ItemsData = {catalog(1).Variants.Key};
variant_dd.Value = catalog(1).Variants(1).Key;

parameter_panel = create_control_panel(ui.control_grid, 'section', 'parameters', {22, 80});
param_label = create_control_panel(parameter_panel.grid, 'text', 'tuple order', '');
param_label.Editable = 'off';
param_area = create_control_panel(parameter_panel.grid, 'scan', 'tuples', {''}, 'Tuple syntax: (2), (0:5), (1:4,(2,5,7),4).');

axis_panel = create_control_panel(ui.control_grid, 'section', '1d display', 5);
xrange_edit = create_control_panel(axis_panel.grid, 'text', 'x range', '(0,20)', 'Interval syntax: (xmin,xmax).');
crop_dd = create_control_panel(axis_panel.grid, 'dropdown', 'crop', {'auto crop','crop by y range'}, 'auto', 'Use automatic y-crop or manually enter ymin/ymax.');
crop_dd.ItemsData = {'auto','yrange'};
ymin_edit = create_control_panel(axis_panel.grid, 'text', 'y min', '', 'Manual y-axis lower limit.');
ymax_edit = create_control_panel(axis_panel.grid, 'text', 'y max', '', 'Manual y-axis upper limit.');
legend_dd = create_control_panel(axis_panel.grid, 'legend', 'legend', 'northwest');

actions = create_control_panel(ui.control_grid, 'section', 'actions', 1);
state = struct('png_paths', {{}}, 'params', struct(), 'result', []);

family_dd.ValueChangedFcn = @(~,~) refresh_family();
variant_dd.ValueChangedFcn = @(~,~) refresh_variant();
crop_dd.ValueChangedFcn = @(~,~) refresh_crop();
bind_workflow(actions.grid, app_figure, @run_callback, @reset_callback, @export_callback, ...
    'GenerateText', 'Run');

refresh_family();

    function refresh_family()
        fam = parse_special_functions_params('catalog', family_dd.Value);
        variant_dd.Items = {fam.Variants.Name};
        variant_dd.ItemsData = {fam.Variants.Key};
        variant_dd.Value = fam.Variants(1).Key;
        refresh_variant();
    end

    function refresh_variant()
        fam = parse_special_functions_params('catalog', family_dd.Value);
        v = parse_special_functions_params('catalog', family_dd.Value, variant_dd.Value);
        has_params = ~isempty(v.ParamLabels);
        is_1d = strcmp(v.PlotKind, '1d');
        is_3d = strcmp(v.PlotKind, '3d');

        parameter_panel.panel.Visible = tf_onoff(has_params);
        if has_params
            param_label.Value = sprintf('(%s)', strjoin(v.ParamLabels, ', '));
            param_area.Value = {create_control_panel('default_tuple', v.ParamDefaults)};
        else
            param_label.Value = '';
            param_area.Value = {''};
        end

        xrange_edit.Value = sprintf('(%g,%g)', fam.DefaultXRange(1), fam.DefaultXRange(2));
        axis_panel.panel.Visible = tf_onoff(is_1d);
        ui.preview_layout_edit.Enable = tf_onoff(is_3d);
        ui.preview_composite_button.Enable = tf_onoff(is_3d);
        refresh_crop();
        refresh_notes();
        state.png_paths = {};
        state.params = struct();
        state.result = [];
        image_output('bind_preview_list', ui.preview_list, ui.preview_axes, {});
    end

    function refresh_crop()
        show_y_range = strcmp(crop_dd.Value, 'yrange');
        ymin_edit.Parent.Visible = tf_onoff(show_y_range);
        ymax_edit.Parent.Visible = tf_onoff(show_y_range);
        if show_y_range
            axis_panel.grid.RowHeight = {'fit','fit','fit','fit','fit'};
        else
            axis_panel.grid.RowHeight = {'fit','fit',0,0,'fit'};
        end
    end

    function refresh_notes()
        fam = parse_special_functions_params('catalog', family_dd.Value);
        v = parse_special_functions_params('catalog', family_dd.Value, variant_dd.Value);
        ui.set_notes(local_special_notes(fam, v));
    end

    function params = read_params()
        params = struct();
        params.family = family_dd.Value;
        params.variant = variant_dd.Value;
        v = parse_special_functions_params('catalog', params.family, params.variant);
        txt = strjoin(param_area.Value, '');
        params.param_text = txt;
        params.arg_matrix = create_control_panel('parse_tuples', txt, numel(v.ParamLabels), create_control_panel('default_tuple', v.ParamDefaults));
        if strcmp(v.PlotKind, '1d')
            fam = parse_special_functions_params('catalog', params.family);
            xr = image_output('parse_range', xrange_edit.Value, fam.DefaultXRange);
            params.xmin = xr(1);
            params.xmax = xr(2);
        else
            params.xmin = 0;
            params.xmax = 1;
        end
        params.crop = struct('mode', 'auto', 'y_range', []);
        if strcmp(v.PlotKind, '1d')
            params.crop.mode = crop_dd.Value;
            if strcmp(params.crop.mode, 'yrange')
                params.crop.y_range = image_output('parse_optional_range', ymin_edit.Value, ymax_edit.Value);
            end
        end
        params.layout_text = image_output('preview_layout', ui, 'auto');
        params.render_options = struct('legend_location', 'northwest');
        if strcmp(v.PlotKind, '1d')
            params.render_options.legend_location = char(string(legend_dd.Value));
            if strcmp(params.render_options.legend_location, 'none')
                params.render_options.legend_location = 'best';
            end
        end
    end

    function run_callback()
        params = read_params();
        v = parse_special_functions_params('catalog', params.family, params.variant);
        result = parse_special_functions_params('dispatch', params, str2func(v.FunctionName));
        result.family = params.family;
        result.variant = params.variant;
        result.layout_text = params.layout_text;
        cache_dir = image_output('clear_cache', project_root, 'special_functions');
        png_paths = render_result('render', result, cache_dir, ...
            'Prefix', sprintf('%s_%s', image_output('slug', params.family), image_output('slug', params.variant)), ...
            'DPI', 180, 'Crop', params.crop, 'RenderOptions', params.render_options, 'Layout', params.layout_text);
        image_output('bind_preview_list', ui.preview_list, ui.preview_axes, png_paths);
        state.png_paths = png_paths;
        state.params = params;
        state.result = result;
    end

    function reset_callback()
        family_dd.Value = catalog(1).Key;
        ui.preview_layout_edit.Value = 'auto';
        refresh_family();
        image_output('bind_preview_list', ui.preview_list, ui.preview_axes, {});
    end

    function export_callback()
        if isempty(state.png_paths)
            error('Run before exporting.');
        end
        paths = image_output('selected_preview_paths', ui.preview_list, state.png_paths);
        layout = image_output('preview_layout', ui, 'auto');
        export_params = state.params;
        export_params.layout_text = layout;
        code_lines = [ ...
            {'project_root = fileparts(mfilename(''fullpath''));'; ...
             'addpath(genpath(fullfile(project_root,''app'')));'; ...
             'addpath(genpath(fullfile(project_root,''core'')));'; ...
             'params = struct();'}; ...
            params_output_assignment_lines(export_params); ...
            {'out = parse_special_functions_params(''render_from_params'', params);'}];
        code = strjoin(code_lines, newline);
        image_output('export_bundle', project_root, 'special_functions', paths, ...
            'Params', export_params, 'ReproduceCode', code, ...
            'Composite', true, 'Layout', layout);
    end

tab = ui.tab;
end

function lines = params_output_assignment_lines(params)
tmp = params_output('reproduce_code', 'unused_function', params);
parts = splitlines(tmp);
if numel(parts) >= 3
    lines = parts(2:end-1);
else
    lines = {};
end
end

function v = tf_onoff(tf)
if tf
    v = 'on';
else
    v = 'off';
end
end

function lines = local_special_notes(family, variant)
if isempty(variant.ParamLabels)
    param_line = 'parameter tuples: none needed for this variant.';
else
    param_line = sprintf('parameter tuples use order (%s). Enter examples such as (0:5) or (2,1).', strjoin(variant.ParamLabels, ', '));
end
if strcmp(variant.PlotKind, '3d')
    plot_line = '3D variants generate one selectable preview per tuple. layout controls exported composite rows, e.g. auto or 3+2.';
else
    plot_line = '1D variants use x min/x max for the horizontal domain; crop can be automatic or a manual y range.';
end
lines = { ...
    sprintf('Special functions: %s / %s.', family.Name, variant.Name), ...
    param_line, ...
    'family selects the mathematical function class; variant selects the concrete function, derivative, or surface/vector form.', ...
    'legend location controls curve labels. For 3D variants it mostly affects exported 2D curve cases, not surfaces.', ...
    plot_line, ...
    'Run computes the selected tuples. Use the preview list to choose/reorder outputs before export. Notes explains the equations and orthogonality.'};
end
