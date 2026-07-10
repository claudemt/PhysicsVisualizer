function tab = create_planar_dielectric_tab(tab_group, project_root)
%CREATE_PLANAR_DIELECTRIC_TAB Build the symmetric slab-waveguide tab.

app_figure = ancestor(tab_group, 'figure');

tab = uitab(tab_group, 'Title', 'planar dielectric');
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

study_panel = uipanel(left_grid, 'Title', 'study');
study_panel.Layout.Row = 1;
study_panel.Layout.Column = 1;
study_grid = uigridlayout(study_panel, [3 1]);
study_grid.RowHeight = {'fit', 'fit', 'fit'};
study_grid.Padding = [8 8 8 8];
study_grid.RowSpacing = 5;

action_dd = create_dropdown_control(study_grid, 'action', {'mode field', 'dispersion curve', 'mode existence', 'thickness sweep'}, 'mode field', ...
    'Choose the planar slab analysis.');
mode_type_dd = create_dropdown_control(study_grid, 'polarization', {'TE', 'TM'}, 'TE', ...
    'Planar TE has dominant E_y; TM has dominant H_y.');
legend_location_dd = create_dropdown_control(study_grid, 'legend', ...
    {'right side', 'upper left', 'lower left', 'upper right', 'lower right'}, 'right side', ...
    'Legend placement for curve and sweep plots.');

param_panel = uipanel(left_grid, 'Title', 'parameters');
param_panel.Layout.Row = 2;
param_panel.Layout.Column = 1;
param_grid = uigridlayout(param_panel, [5 1]);
param_grid.RowHeight = {'fit', 'fit', 'fit', 'fit', 'fit'};
param_grid.Padding = [8 8 8 8];
param_grid.RowSpacing = 5;

order_field = create_text_control(param_grid, 'order', '0', 'Single order or scan expression, e.g. 0, 0:3, (0:3).');
max_order_field = create_numeric_control(param_grid, 'max order', 5, 'Largest order included in the selected batch plot.');
n1_field = create_numeric_control(param_grid, 'nco (core)', 1.50, 'Core refractive index.');
n2_field = create_numeric_control(param_grid, 'ncl (cladding)', 1.45, 'Cladding refractive index.');
d_field = create_numeric_control(param_grid, 'thickness d (m)', 0.10, 'Physical slab thickness.');

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
notes_box.Value = notes_catalog('planar', 'slab', 'mode field');

state = struct('generated_files', {{}}, 'current_file', '', 'current_folder', '');

update_controls();
action_dd.ValueChangedFcn = @(~,~) on_action_changed();

    function run_simulation(~, ~)
        dlg = create_progress_dialog(app_figure, 'Planar dielectric');
        cleanup = onCleanup(@() close_progress_dialog(dlg)); %#ok<NASGU>
        try
            update_progress_dialog(dlg, 0.10, 'Collecting parameters ...');
            params = read_params();

            update_progress_dialog(dlg, 0.35, 'Generating hidden figures ...');
            result = run_planar_dielectric_generation(project_root, params);

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
            uialert(app_figure, ME.message, 'Planar dielectric run failed', 'Icon', 'error');
        end
    end

    function params = read_params()
        params = struct();
        params.action = char(lower(string(action_dd.Value)));
        params.mode_type = char(string(mode_type_dd.Value));
        params.legend_location = char(string(legend_location_dd.Value));
        params.map_name = 'project';
        params.grid_n = 240;
        params.samples = 260;
        params.vmax = 12;
        params.freq_ghz = 4.0;
        params.z_length = 0.10;
        params.layout_rows = char(string(layout_field.Value));

        switch params.action
            case 'mode field'
                params.order_list = parse_integer_vector_text(order_field, 'order', '0', 0, 100);
                params.n1 = read_positive(n1_field, 'nco');
                params.n2 = read_positive(n2_field, 'ncl');
                params.d = read_positive(d_field, 'thickness d');
                params.z_length = max(params.d, 0.10);
                params.max_order = NaN;
            case 'dispersion curve'
                params.max_order = read_integer(max_order_field, 'max order', 0, 30);
                params.n1 = read_positive(n1_field, 'nco');
                params.n2 = read_positive(n2_field, 'ncl');
                params.d = NaN;
                params.order_list = [];
            case 'mode existence'
                params.max_order = read_integer(max_order_field, 'max order', 0, 30);
                params.order_list = [];
                params.n1 = NaN;
                params.n2 = NaN;
                params.d = NaN;
            case 'thickness sweep'
                params.max_order = read_integer(max_order_field, 'max order', 0, 30);
                params.n1 = read_positive(n1_field, 'nco');
                params.n2 = read_positive(n2_field, 'ncl');
                params.d = read_positive(d_field, 'thickness d');
                params.order_list = [];
            otherwise
                error('Unknown action: %s', params.action);
        end

        if isfinite(params.n1) && params.n1 <= params.n2
            error('Guided slab studies require nco > ncl.');
        end
    end

    function reset_defaults(~, ~)
        action_dd.Value = 'mode field';
        mode_type_dd.Value = 'TE';
        legend_location_dd.Value = 'right side';
        order_field.Value = '0';
        max_order_field.Value = 5;
        n1_field.Value = 1.50;
        n2_field.Value = 1.45;
        d_field.Value = 0.10;
        layout_field.Value = '4';
        update_controls();
        notes_box.Value = notes_catalog('planar', 'slab', 'mode field');
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
            export_folder = export_generated_waveguide_files(project_root, state.generated_files, 'planar');
            update_progress_dialog(dlg, 1.0, ['Exported to ' export_folder]);
            pause(0.25);
        catch ME
            close_progress_dialog(dlg);
            uialert(app_figure, ME.message, 'Export failed', 'Icon', 'error');
        end
    end

    function on_action_changed()
        update_controls();
        notes_box.Value = notes_catalog('planar', 'slab', char(action_dd.Value));
    end

    function update_controls()
        action = char(lower(string(action_dd.Value)));
        is_field = strcmp(action, 'mode field');
        is_disp = strcmp(action, 'dispersion curve');
        is_exist = strcmp(action, 'mode existence');
        is_sweep = strcmp(action, 'thickness sweep');

        set_control_enabled(order_field, is_field, 'Specific slab order or scan expression.', '');
        set_control_enabled(max_order_field, is_disp || is_exist || is_sweep, 'Largest order included.', '');
        set_control_enabled(legend_location_dd, is_disp || is_exist || is_sweep, 'Legend placement for curve and sweep plots.', 'Field plots use a colorbar instead of a legend.');
        set_control_enabled(n1_field, is_field || is_disp || is_sweep, 'Core index.', '');
        set_control_enabled(n2_field, is_field || is_disp || is_sweep, 'Cladding index.', '');
        set_control_enabled(d_field, is_field || is_sweep, 'Slab thickness.', 'Normalized dispersion uses V rather than physical thickness.');
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
        text(preview_axes, 0.5, 0.5, '$\mathrm{run\ to\ generate\ a\ planar\ dielectric\ plot}$', ...
            'Interpreter', 'latex', 'HorizontalAlignment', 'center');
        preview_axes.XLim = [0 1];
        preview_axes.YLim = [0 1];
    end
end

function values = parse_integer_vector_text(field, label, default_text, min_value, max_value)
values = parse_parameter_tuples(char(string(field.Value)), 1, default_text);
if isempty(values), error('%s cannot be empty.', label); end
if any(~isfinite(values(:)) | abs(values(:) - round(values(:))) > 1e-10 | values(:) < min_value | values(:) > max_value)
    error('%s must use integers in [%g, %g].', label, min_value, max_value);
end
values = round(values(:)).';
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
