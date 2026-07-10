function create_special_functions_tab(tab_group, project_root)
app = struct();
app.project_root = project_root;
app.cache_dir = image_output('ensure_cache', project_root, 'special_functions');
app.output_dir = image_output('ensure_output', project_root);
app.catalog = parse_special_functions_params('catalog');
app.current_result = [];
app.current_params = [];
app.preview_paths = {};
app.preview_labels = {};
app.preview_counter = 0;

ui = create_tab_layout(tab_group, 'Special Functions', project_root, ...
    'NotesKey', 'special_functions', ...
    'HasPreviewList', true, ...
    'NotesHeight', 170, ...
    'InitialPreviewText', 'run to generate result');
app.figure = ui.app_figure;
app.ui = ui;

left_grid = uigridlayout(ui.control_grid, [5 1]);
left_grid.RowHeight = {'fit', 'fit', 'fit', 'fit', '1x'};
left_grid.ColumnWidth = {'1x'};
left_grid.Padding = [0 0 0 0];
left_grid.RowSpacing = 8;
app.left_grid = left_grid;

function_panel = create_control_panel(left_grid, 'section', 'function', 2);
app.function_panel = function_panel;
app.family_dropdown = create_control_panel(function_panel.grid, 'dropdown', 'family', app.catalog(1).Name, ...
    'Items', {app.catalog.Name}, ...
    'Tooltip', 'Choose a special-function family.', ...
    'InputWidth', 150);
app.family_dropdown.ItemsData = {app.catalog.Key};
app.family_dropdown.Value = app.catalog(1).Key;
app.family_dropdown.ValueChangedFcn = @(~,~) on_family_changed();

app.variant_dropdown = create_control_panel(function_panel.grid, 'dropdown', 'function', '', ...
    'Items', {''}, ...
    'Tooltip', 'Choose a member of the selected family.', ...
    'InputWidth', 150);
app.variant_dropdown.ValueChangedFcn = @(~,~) on_variant_changed();

parameter_panel = create_control_panel(left_grid, 'section', 'parameters', 2, 'RowHeight', {22, 64});
app.parameter_panel = parameter_panel;
app.param_label = create_control_panel(parameter_panel.grid, 'label', '');
app.param_input_area = create_control_panel(parameter_panel.grid, 'scan', '', {''}, ...
    'Tooltip', 'Tuple syntax: (2), (0:5), (1:4,(2,5,7),4), or consecutive tuples.');

axis_panel = create_control_panel(left_grid, 'section', '1d display', 5, 'RowHeight', {'fit', 'fit', 'fit', 'fit', 'fit'});
app.axis_panel = axis_panel;
app.xrange_field = create_control_panel(axis_panel.grid, 'text', 'x range', '(0,20)', ...
    'Tooltip', 'Interval syntax: (xmin,xmax).');
app.crop_mode_dropdown = create_control_panel(axis_panel.grid, 'dropdown', 'crop', 'auto crop', ...
    'Items', {'auto crop', 'crop by y range'}, ...
    'Tooltip', 'Use automatic y-crop or manually enter ymin/ymax.');
app.crop_mode_dropdown.ItemsData = {'auto', 'yrange'};
app.crop_mode_dropdown.Value = 'auto';
app.crop_mode_dropdown.ValueChangedFcn = @(~,~) refresh_crop_panel();
app.ymin_field = create_control_panel(axis_panel.grid, 'text', 'y min', '', 'Tooltip', 'Manual y-axis lower limit.');
app.ymax_field = create_control_panel(axis_panel.grid, 'text', 'y max', '', 'Tooltip', 'Manual y-axis upper limit.');
app.legend_dropdown = create_control_panel(axis_panel.grid, 'legend', 'legend', 'northwest', ...
    'Tooltip', 'Legend location for 1D plots.');

action_panel = create_control_panel(left_grid, 'section', 'actions', 1);
app.action_panel = action_panel;
app.action = create_action_panel(action_panel.grid, app.figure, ...
    @run_visualization, @reset_controls, @export_current_result, ...
    'Labels', {'Run', 'Reset', 'Export'}, ...
    'UseProgress', false);

setappdata(app.figure, 'SpecialFunctionsStudioApp', app);
refresh_family_variants();
refresh_parameter_panel();
refresh_crop_panel();
refresh_notes_box();

    function on_family_changed()
        refresh_family_variants();
        refresh_parameter_panel();
        refresh_crop_panel();
        refresh_notes_box();
    end

    function on_variant_changed()
        refresh_parameter_panel();
        refresh_crop_panel();
        refresh_notes_box();
    end

    function refresh_family_variants()
        app = getappdata(ui.app_figure, 'SpecialFunctionsStudioApp');
        fam = parse_special_functions_params('catalog', app.family_dropdown.Value);
        app.variant_dropdown.Items = {fam.Variants.Name};
        app.variant_dropdown.ItemsData = {fam.Variants.Key};
        if isempty(app.variant_dropdown.Value) || ~any(strcmp(app.variant_dropdown.Value, app.variant_dropdown.ItemsData))
            app.variant_dropdown.Value = fam.Variants(1).Key;
        end
        setappdata(ui.app_figure, 'SpecialFunctionsStudioApp', app);
    end

    function refresh_parameter_panel()
        app = getappdata(ui.app_figure, 'SpecialFunctionsStudioApp');
        fam = parse_special_functions_params('catalog', app.family_dropdown.Value);
        v = parse_special_functions_params('catalog', app.family_dropdown.Value, app.variant_dropdown.Value);
        has_params = ~isempty(v.ParamLabels);
        is_1d = strcmp(v.PlotKind, '1d');
        is_3d = strcmp(v.PlotKind, '3d');
        if has_params
            app.parameter_panel.panel.Visible = 'on';
            app.param_label.Text = sprintf('tuple order: (%s)', strjoin(v.ParamLabels, ', '));
            app.param_input_area.Value = {create_control_panel('default_tuple', v.ParamDefaults)};
        else
            app.parameter_panel.panel.Visible = 'off';
            app.param_input_area.Value = {''};
        end
        app.xrange_field.Value = sprintf('(%g,%g)', fam.DefaultXRange(1), fam.DefaultXRange(2));
        app.axis_panel.panel.Visible = tf_onoff(is_1d);
        try
            app.ui.preview_layout_field.Enable = tf_onoff(is_3d);
            app.ui.preview_composite_button.Enable = tf_onoff(is_3d);
        catch
        end
        app.left_grid.RowHeight = {'fit', choose_height(has_params), choose_height(is_1d), 'fit', '1x'};
        app.current_result = [];
        app.current_params = [];
        app.preview_paths = {};
        app.preview_labels = {};
        setappdata(ui.app_figure, 'SpecialFunctionsStudioApp', app);
        image_output('bind_preview_list', app.ui, {}, 'Labels', {});
    end

    function refresh_crop_panel()
        app = getappdata(ui.app_figure, 'SpecialFunctionsStudioApp');
        v = parse_special_functions_params('catalog', app.family_dropdown.Value, app.variant_dropdown.Value);
        show_y_range = strcmp(v.PlotKind, '1d') && strcmp(app.crop_mode_dropdown.Value, 'yrange');
        app.ymin_field.Parent.Visible = tf_onoff(show_y_range);
        app.ymax_field.Parent.Visible = tf_onoff(show_y_range);
        if show_y_range
            app.axis_panel.grid.RowHeight = {'fit', 'fit', 'fit', 'fit', 'fit'};
        else
            app.axis_panel.grid.RowHeight = {'fit', 'fit', 0, 0, 'fit'};
        end
        setappdata(ui.app_figure, 'SpecialFunctionsStudioApp', app);
    end

    function refresh_notes_box()
        app = getappdata(ui.app_figure, 'SpecialFunctionsStudioApp');
        fam = parse_special_functions_params('catalog', app.family_dropdown.Value);
        v = parse_special_functions_params('catalog', app.family_dropdown.Value, app.variant_dropdown.Value);
        notes = parse_special_functions_params('notes', app.family_dropdown.Value, app.variant_dropdown.Value);
        lines = {};
        lines{end+1} = sprintf('%s / %s', fam.Name, v.Name);
        lines{end+1} = '';
        if isempty(v.ParamLabels)
            lines{end+1} = 'Parameters: none.';
        else
            lines{end+1} = sprintf('Parameter tuple order: (%s)', strjoin(v.ParamLabels, ', '));
        end
        if strcmp(v.PlotKind, '3d')
            lines{end+1} = 'Run generates separate preview images. Select and reorder them before export.';
            lines{end+1} = 'Output layout accepts strings such as 4+3+2+1.';
        else
            lines{end+1} = 'Use the legend dropdown to choose the curve legend location.';
        end
        lines{end+1} = '';
        for k = 1:numel(notes.Summary)
            lines{end+1} = notes.Summary{k}; %#ok<AGROW>
        end
        app.ui.notes_text.Value = lines;
        setappdata(ui.app_figure, 'SpecialFunctionsStudioApp', app);
    end

    function run_visualization()
        pd = uiprogressdlg(ui.app_figure, 'Title', 'Processing', ...
            'Message', 'Processing', ...
            'Value', 0.05, 'Indeterminate', 'off');
        cleanup = onCleanup(@() close_progress(pd)); %#ok<NASGU>
        try
            app = getappdata(ui.app_figure, 'SpecialFunctionsStudioApp');
            params = collect_parameters(app);
            pd.Value = 0.35;
            pd.Message = 'Processing';
            drawnow;
            v = parse_special_functions_params('catalog', params.family, params.variant);
            result = parse_special_functions_params('dispatch', params, str2func(v.FunctionName));
            pd.Value = 0.65;
            pd.Message = 'Processing';
            drawnow;
            [paths, labels] = render_preview_images(app, result, params, 170);
            image_output('bind_preview_list', app.ui, paths, 'Labels', labels, 'Select', 'all');
            app.current_result = result;
            app.current_params = params;
            app.preview_paths = paths;
            app.preview_labels = labels;
            setappdata(ui.app_figure, 'SpecialFunctionsStudioApp', app);
            pd.Value = 1.0;
            pd.Message = 'Processing';
            drawnow;
        catch ME
            uialert(ui.app_figure, ME.message, 'Run error');
            rethrow(ME);
        end
    end

    function reset_controls()
        refresh_parameter_panel();
        refresh_crop_panel();
        refresh_notes_box();
        try
            cla(ui.preview_axes);
            apply_tex_style(ui.preview_axes, 'Title', 'run to generate result', 'AxisMode', 'image');
            text(ui.preview_axes, 0.5, 0.5, apply_tex_style('text', 'run to generate result'), ...
                'Interpreter', 'latex', 'HorizontalAlignment', 'center');
            ui.preview_axes.XLim = [0 1];
            ui.preview_axes.YLim = [0 1];
            ui.preview_axes.XTick = [];
            ui.preview_axes.YTick = [];
            image_output('bind_preview_list', ui, {}, 'Labels', {});
        catch
        end
    end

    function export_current_result()
        pd = uiprogressdlg(ui.app_figure, 'Title', 'Processing', ...
            'Message', 'Processing', ...
            'Value', 0.05, 'Indeterminate', 'off');
        cleanup = onCleanup(@() close_progress(pd)); %#ok<NASGU>
        try
            app = getappdata(ui.app_figure, 'SpecialFunctionsStudioApp');
            if isempty(app.current_result) || isempty(app.preview_paths)
                close_progress(pd);
                run_visualization();
                pd = uiprogressdlg(ui.app_figure, 'Title', 'Processing', 'Message', 'Processing', 'Value', 0.45, 'Indeterminate', 'off');
                app = getappdata(ui.app_figure, 'SpecialFunctionsStudioApp');
            end
            selection = image_output('preview_selection', app.ui);
            if isempty(selection.paths)
                export_paths = app.preview_paths;
                selected_indices = 1:numel(app.preview_paths);
            else
                export_paths = selection.paths;
                selected_indices = selection.indices;
            end
            export_params = app.current_params;
            try
                export_params.layout_text = char(string(app.ui.preview_layout_field.Value));
            catch
            end
            export_params.selected_preview_indices = selected_indices;
            export_params.output_layout = export_params.layout_text;
            family_key = image_output('slug', app.current_result.family);
            variant_key = image_output('slug', app.current_result.variant);
            pd.Value = 0.75;
            pd.Message = 'Processing';
            drawnow;
            info = image_output('export_bundle', app.project_root, sprintf('%s_%s', family_key, variant_key), export_paths, ...
                'Params', export_params, ...
                'RunFunction', '', ...
                'ProjectRoot', app.project_root, ...
                'ExtraCode', 'result = parse_special_functions_params(''render_from_params'', params);', ...
                'Composite', numel(export_paths) > 1, ...
                'Layout', export_params.layout_text);
            pd.Value = 1.0;
            pd.Message = 'Processing';
            drawnow;
            uialert(ui.app_figure, sprintf('Export completed:\n%s', info.output_dir), 'Export completed', 'Icon', 'success');
        catch ME
            uialert(ui.app_figure, ME.message, 'Export error');
            rethrow(ME);
        end
    end
end

function [paths, labels] = render_preview_images(app, result, params, dpi)
run_key = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss_SSS'));
cache_dir = fullfile(app.cache_dir, run_key);
if exist(cache_dir, 'dir') ~= 7
    mkdir(cache_dir);
end
if strcmp(result.kind, '3d')
    n = numel(result.items);
    paths = cell(1, n);
    labels = cell(1, n);
    common_limits = image_output('common_3d_limits', result.items);
    for k = 1:n
        single = result;
        single.items = result.items(k);
        single.layout_text = '1';
        single.common_limits = common_limits;
        label = image_output('clean_label', result.items{k}.title);
        paths{k} = fullfile(cache_dir, sprintf('%02d_%s.png', k, image_output('slug', label)));
        render_result_figure(single, paths{k}, 'Crop', params.crop, 'DPI', dpi, 'RenderOptions', params.render_options);
        labels{k} = label;
    end
else
    paths = {fullfile(cache_dir, sprintf('%s_%s.png', image_output('slug', result.family), image_output('slug', result.variant)))};
    render_result_figure(result, paths{1}, 'Crop', params.crop, 'DPI', dpi, 'RenderOptions', params.render_options);
    labels = {image_output('clean_label', result.title)};
end
end

function params = collect_parameters(app)
params = struct();
params.family = app.family_dropdown.Value;
params.variant = app.variant_dropdown.Value;
v = parse_special_functions_params('catalog', params.family, params.variant);
txt = strjoin(app.param_input_area.Value, '');
params.param_text = txt;
params.arg_matrix = create_control_panel('parse_tuples', txt, numel(v.ParamLabels), create_control_panel('default_tuple', v.ParamDefaults));
if strcmp(v.PlotKind, '1d')
    fam = parse_special_functions_params('catalog', params.family);
    xr = image_output('parse_range', app.xrange_field.Value, fam.DefaultXRange);
    params.xmin = xr(1);
    params.xmax = xr(2);
else
    params.xmin = 0;
    params.xmax = 1;
end
params.crop = struct('mode', 'auto', 'y_range', []);
if strcmp(v.PlotKind, '1d')
    params.crop.mode = app.crop_mode_dropdown.Value;
    if strcmp(params.crop.mode, 'yrange')
        params.crop.y_range = image_output('parse_optional_range', app.ymin_field.Value, app.ymax_field.Value);
    end
end
params.layout_text = '';
if strcmp(v.PlotKind, '3d')
    try
        params.layout_text = char(string(app.ui.preview_layout_field.Value));
    catch
        params.layout_text = '4';
    end
end
params.render_options = struct('legend_location', 'northwest');
if strcmp(v.PlotKind, '1d')
    params.render_options.legend_location = char(string(app.legend_dropdown.Value));
    if strcmp(params.render_options.legend_location, 'none')
        params.render_options.legend_location = 'best';
    end
end
end

function close_progress(pd)
try
    if ~isempty(pd) && isvalid(pd)
        close(pd);
    end
catch
end
end

function v = tf_onoff(tf)
if tf
    v = 'on';
else
    v = 'off';
end
end

function h = choose_height(tf)
if tf
    h = 'fit';
else
    h = 0;
end
end
