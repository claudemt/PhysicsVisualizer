function tab = create_metal_guides_tab(tab_group, project_root)
%CREATE_METAL_GUIDES_TAB Build the PEC rectangular/circular waveguide tab.

app_figure = ancestor(tab_group, 'figure');

tab = uitab(tab_group, 'Title', 'metal guides');
root = uigridlayout(tab, [1 2]);
root.ColumnWidth = {390, '1x'};
root.RowHeight = {'1x'};
root.Padding = [8 8 8 8];
root.ColumnSpacing = 10;

left_panel = uipanel(root, 'Title', 'controls');
left_panel.Layout.Row = 1;
left_panel.Layout.Column = 1;
left_grid = uigridlayout(left_panel, [4 1]);
left_grid.RowHeight = {'fit', 'fit', 'fit', '1x'};
left_grid.ColumnWidth = {'1x'};
left_grid.Padding = [8 8 8 8];
left_grid.RowSpacing = 8;

study_panel = uipanel(left_grid, 'Title', 'waveguide and study');
study_panel.Layout.Row = 1;
study_panel.Layout.Column = 1;
study_grid = uigridlayout(study_panel, [4 1]);
study_grid.RowHeight = {'fit', 'fit', 'fit', 'fit'};
study_grid.Padding = [8 8 8 8];
study_grid.RowSpacing = 5;

guide_dd = create_dropdown_control(study_grid, 'guide', {'rectangular', 'circular'}, 'rectangular', ...
    'Choose the PEC waveguide cross section.');
action_dd = create_dropdown_control(study_grid, 'action', {'mode field', 'dispersion curves', 'cutoff map'}, 'mode field', ...
    'Choose the plot or analysis to generate.');
mode_type_dd = create_dropdown_control(study_grid, 'polarization', {'TE', 'TM'}, 'TE', ...
    'TE uses longitudinal H_z; TM uses longitudinal E_z.');
legend_location_dd = create_dropdown_control(study_grid, 'legend', ...
    {'right side', 'upper left', 'lower left', 'upper right', 'lower right'}, 'right side', ...
    'Legend placement for dispersion curves.');

param_panel = uipanel(left_grid, 'Title', 'parameters');
param_panel.Layout.Row = 2;
param_panel.Layout.Column = 1;
param_grid = uigridlayout(param_panel, [6 1]);
param_grid.RowHeight = {'fit', 'fit', 'fit', 'fit', 'fit', 'fit'};
param_grid.Padding = [8 8 8 8];
param_grid.RowSpacing = 5;

mode_tuple_field = create_text_control(param_grid, 'm,n tuple(s)', '(1,0)', ...
    'Examples: (1,0), (1:3,4), (1:3,1:3), ((1,4,5),(2,3)).');
max_order_field = create_numeric_control(param_grid, 'max order', 5, 'Largest m/n index included in dispersion or cutoff plots.');
a_field = create_numeric_control(param_grid, 'a width (m)', 0.08, 'Rectangular guide width.');
b_field = create_numeric_control(param_grid, 'b height (m)', 0.04, 'Rectangular guide height.');
radius_field = create_numeric_control(param_grid, 'radius (m)', 0.03, 'Circular guide radius.');
fmax_field = create_numeric_control(param_grid, 'f max (GHz)', 10.0, ...
    'Upper frequency shown in metal dispersion curves. Each mode starts at its own cutoff f_c.');

layout_panel = uipanel(left_grid, 'Title', 'multi-plot display');
layout_panel.Layout.Row = 3;
layout_panel.Layout.Column = 1;
layout_grid = uigridlayout(layout_panel, [1 1]);
layout_grid.RowHeight = {'fit'};
layout_grid.Padding = [8 8 8 8];
layout_field = create_text_control(layout_grid, 'panels / row', '4', ...
    'Use an integer such as 4, or an exact row expression such as 4+4+2. Exact expressions must add up to the number of generated heatmaps.');

action_panel = uipanel(left_grid, 'Title', 'actions');
action_panel.Layout.Row = 4;
action_panel.Layout.Column = 1;
action_grid = uigridlayout(action_panel, [1 1]);
action_grid.RowHeight = {28};
action_grid.Padding = [8 8 8 8];
button_block = create_button_row(action_grid, @run_simulation, @reset_defaults, @export_all_generated);
button_block.run.Text = 'Run';

right_grid = uigridlayout(root, [2 1]);
right_grid.Layout.Row = 1;
right_grid.Layout.Column = 2;
right_grid.RowHeight = {'1x', 130};
right_grid.ColumnWidth = {'1x'};
right_grid.Padding = [0 0 0 0];
right_grid.RowSpacing = 8;

preview_panel = uipanel(right_grid, 'Title', 'preview');
preview_panel.Layout.Row = 1;
preview_panel.Layout.Column = 1;
preview_grid = uigridlayout(preview_panel, [1 2]);
preview_grid.RowHeight = {'1x'};
preview_grid.ColumnWidth = {340, '1x'};
preview_grid.Padding = [6 6 6 6];
preview_grid.ColumnSpacing = 8;

preview_list = uilistbox(preview_grid);
preview_list.Layout.Row = 1;
preview_list.Layout.Column = 1;
preview_list.Multiselect = 'off';
preview_list.ValueChangedFcn = @(~,~) on_preview_selected();

preview_axes = uiaxes(preview_grid);
preview_axes.Layout.Row = 1;
preview_axes.Layout.Column = 2;
apply_axes_style(preview_axes);
reset_preview_axes();

notes_box = uitextarea(right_grid, 'Editable', 'off');
notes_box.Layout.Row = 2;
notes_box.Layout.Column = 1;
notes_box.Value = notes_catalog('metal', 'rectangular', 'mode field');

state = struct('generated_files', {{}}, 'current_file', '', 'current_folder', '');

install_action_items();
update_controls();
guide_dd.ValueChangedFcn = @(~,~) on_guide_changed();
action_dd.ValueChangedFcn = @(~,~) on_action_changed();

    function run_simulation(~, ~)
        dlg = create_progress_dialog(app_figure, 'Metal guide');
        cleanup = onCleanup(@() close_progress_dialog(dlg)); %#ok<NASGU>
        try
            update_progress_dialog(dlg, 0.10, 'Collecting parameters ...');
            params = read_params();

            update_progress_dialog(dlg, 0.35, 'Generating hidden figures ...');
            result = run_metal_guide_generation(project_root, params);

            update_progress_dialog(dlg, 0.78, 'Refreshing preview ...');
            state.generated_files = result.files;
            state.current_folder = result.storage_folder;
            if isempty(result.files), error('No PNG output files were generated.'); end
            update_preview_list(result.files);
            state.current_file = result.files{1};
            preview_list.Value = result.files{1};
            render_png_preview(preview_axes, state.current_file);

            update_progress_dialog(dlg, 1.0, 'Done.');
        catch ME
            close_progress_dialog(dlg);
            uialert(app_figure, ME.message, 'Metal guide run failed', 'Icon', 'error');
        end
    end

    function params = read_params()
        params = struct();
        params.guide = char(lower(string(guide_dd.Value)));
        params.action = char(lower(string(action_dd.Value)));
        params.mode_type = char(string(mode_type_dd.Value));
        params.legend_location = char(string(legend_location_dd.Value));
        params.map_name = 'project';
        params.grid_n = 240;
        params.samples = 260;
        params.layout_rows = char(string(layout_field.Value));

        switch params.guide
            case 'rectangular'
                params.a = read_positive(a_field, 'a width');
                params.b = read_positive(b_field, 'b height');
                params.radius = NaN;
                default_tuple = '(1,0)';
            case 'circular'
                params.radius = read_positive(radius_field, 'radius');
                params.a = NaN;
                params.b = NaN;
                default_tuple = '(1,1)';
            otherwise
                error('Unknown metal guide: %s', params.guide);
        end

        switch params.action
            case 'mode field'
                params.mode_matrix = parse_integer_matrix_text(mode_tuple_field, 'm,n tuple(s)', 2, default_tuple, 0, 100);
                params.max_order = NaN;
                params.fmax_ghz = NaN;
            case 'dispersion curves'
                params.max_order = read_integer(max_order_field, 'max order', 1, 30);
                params.mode_matrix = zeros(0, 2);
                params.fmax_ghz = read_positive(fmax_field, 'f max');
            case 'cutoff map'
                if strcmp(params.guide, 'circular')
                    error('Cutoff map is only available for rectangular PEC guides.');
                end
                params.max_order = read_integer(max_order_field, 'max order', 1, 30);
                params.mode_matrix = zeros(0, 2);
                params.fmax_ghz = NaN;
            otherwise
                error('Unknown action: %s', params.action);
        end

        if strcmp(params.action, 'mode field')
            validate_metal_mode_matrix(params);
        end
    end

    function reset_defaults(~, ~)
        guide_dd.Value = 'rectangular';
        install_action_items();
        action_dd.Value = 'mode field';
        mode_type_dd.Value = 'TE';
        legend_location_dd.Value = 'right side';
        mode_tuple_field.Value = '(1,0)';
        max_order_field.Value = 5;
        a_field.Value = 0.08;
        b_field.Value = 0.04;
        radius_field.Value = 0.03;
        fmax_field.Value = 10.0;
        layout_field.Value = '4';
        update_controls();
        notes_box.Value = notes_catalog('metal', 'rectangular', 'mode field');
        clear_preview();
    end

    function export_all_generated(~, ~)
        if isempty(state.generated_files)
            uialert(app_figure, 'No generated PNG files are available yet.', 'Nothing to export', 'Icon', 'warning');
            return;
        end
        dlg = create_progress_dialog(app_figure, 'Exporting figures');
        cleanup = onCleanup(@() close_progress_dialog(dlg)); %#ok<NASGU>
        try
            update_progress_dialog(dlg, 0.25, 'Copying generated PNG files ...');
            export_folder = export_generated_waveguide_files(project_root, state.generated_files, char(string(guide_dd.Value)));
            update_progress_dialog(dlg, 1.0, ['Exported to ' export_folder]);
            pause(0.25);
        catch ME
            close_progress_dialog(dlg);
            uialert(app_figure, ME.message, 'Export failed', 'Icon', 'error');
        end
    end

    function on_guide_changed()
        install_action_items();
        update_controls();
        notes_box.Value = notes_catalog('metal', char(guide_dd.Value), char(action_dd.Value));
    end

    function on_action_changed()
        update_controls();
        notes_box.Value = notes_catalog('metal', char(guide_dd.Value), char(action_dd.Value));
    end

    function install_action_items()
        current_tuple = strtrim(char(string(mode_tuple_field.Value)));
        switch char(lower(string(guide_dd.Value)))
            case 'rectangular'
                set_dropdown_items(action_dd, {'mode field', 'dispersion curves', 'cutoff map'}, 'mode field');
                if isempty(current_tuple) || strcmp(current_tuple, '(1,1)')
                    mode_tuple_field.Value = '(1,0)';
                end
            otherwise
                set_dropdown_items(action_dd, {'mode field', 'dispersion curves'}, 'mode field');
                if isempty(current_tuple) || strcmp(current_tuple, '(1,0)')
                    mode_tuple_field.Value = '(1,1)';
                end
        end
    end

    function update_controls()
        guide = char(lower(string(guide_dd.Value)));
        action = char(lower(string(action_dd.Value)));
        is_rect = strcmp(guide, 'rectangular');
        is_field = strcmp(action, 'mode field');
        is_disp = strcmp(action, 'dispersion curves');
        is_cutoff = strcmp(action, 'cutoff map');

        set_control_enabled(mode_tuple_field, is_field, 'Tuple syntax: (1,0), (1:3,4), ((1,4,5),(2,3)).', '');
        set_control_enabled(max_order_field, is_disp || is_cutoff, 'Maximum mode index for batch plots.', '');
        set_control_enabled(legend_location_dd, is_disp, 'Legend placement for dispersion curves.', 'This plot does not use a legend.');
        set_control_enabled(a_field, is_rect, 'Rectangular guide width.', '');
        set_control_enabled(b_field, is_rect, 'Rectangular guide height.', '');
        set_control_enabled(radius_field, ~is_rect, 'Circular guide radius.', '');
        set_control_enabled(fmax_field, is_disp, 'Upper frequency shown in dispersion curves. Use about 10 GHz unless you need higher modes.', 'This plot does not use a frequency sweep.');
        set_control_enabled(layout_field, is_field, 'Use auto or a row pattern like 4+4+2 for multi-panel heatmaps.', 'This action does not generate a heatmap batch.');
    end

    function on_preview_selected()
        if isempty(preview_list.Items), return; end
        selected_file = char(string(preview_list.Value));
        if isempty(selected_file) || ~isfile(selected_file), return; end
        state.current_file = selected_file;
        render_png_preview(preview_axes, selected_file);
    end

    function update_preview_list(files)
        labels = cell(size(files));
        for i = 1:numel(files)
            [~, labels{i}, ext] = fileparts(files{i});
            labels{i} = [labels{i} ext];
        end
        preview_list.Items = labels;
        preview_list.ItemsData = files;
    end

    function clear_preview()
        preview_list.Items = {};
        if isprop(preview_list, 'ItemsData'), preview_list.ItemsData = {}; end
        reset_preview_axes();
        state.generated_files = {};
        state.current_file = '';
        state.current_folder = '';
    end

    function reset_preview_axes()
        cla(preview_axes);
        apply_axes_style(preview_axes);
        preview_axes.Visible = 'on';
        preview_axes.XTick = [];
        preview_axes.YTick = [];
        title(preview_axes, '$\mathrm{preview}$', 'Interpreter', 'latex');
        text(preview_axes, 0.5, 0.5, '$\mathrm{run\ to\ generate\ a\ metal\ guide\ plot}$', ...
            'Interpreter', 'latex', 'HorizontalAlignment', 'center');
        preview_axes.XLim = [0 1];
        preview_axes.YLim = [0 1];
    end
end

function M = parse_integer_matrix_text(field, label, n_params, default_text, min_value, max_value)
M = parse_parameter_tuples(char(string(field.Value)), n_params, default_text);
if isempty(M), error('%s cannot be empty.', label); end
if any(~isfinite(M(:)) | abs(M(:) - round(M(:))) > 1e-10 | M(:) < min_value | M(:) > max_value)
    error('%s must use integers in [%g, %g].', label, min_value, max_value);
end
M = round(M);
end

function validate_metal_mode_matrix(params)
M = params.mode_matrix;
for ii = 1:size(M,1)
    m = M(ii,1); n = M(ii,2);
    if strcmp(params.guide, 'rectangular')
        if strcmp(params.mode_type, 'TE') && m == 0 && n == 0
            error('Rectangular TE modes cannot have m = n = 0.');
        end
        if strcmp(params.mode_type, 'TM') && (m == 0 || n == 0)
            error('Rectangular TM modes require m >= 1 and n >= 1.');
        end
    elseif n < 1
        error('Circular PEC modes require n >= 1.');
    end
end
end
function value = read_positive(field, label)
value = field.Value;
if ~isfinite(value) || value <= 0
    error('%s must be a positive number.', label);
end
end

function value = read_integer(field, label, min_value, max_value)
value = field.Value;
if ~isfinite(value) || value < min_value || value > max_value || abs(value - round(value)) > 1e-10
    error('%s must be an integer in [%g, %g].', label, min_value, max_value);
end
value = round(value);
end
