function tab = create_cylindrical_dielectric_tab(tab_group, project_root)
%CREATE_CYLINDRICAL_DIELECTRIC_TAB Build the step-index cylindrical dielectric tab.

app_figure = ancestor(tab_group, 'figure');

tab = uitab(tab_group, 'Title', 'cylindrical dielectric');
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
study_grid = uigridlayout(study_panel, [2 1]);
study_grid.RowHeight = {'fit', 'fit'};
study_grid.Padding = [8 8 8 8];
study_dd = create_dropdown_control(study_grid, 'action', {'normalized dispersion'}, 'normalized dispersion', ...
    'Plot the cylindrical step-index characteristic roots in normalized V-U coordinates.');
study_dd.Enable = 'off';
legend_location_dd = create_dropdown_control(study_grid, 'legend', ...
    {'right side', 'upper left', 'lower left', 'upper right', 'lower right'}, 'right side', ...
    'Legend placement for the dispersion contour plot.');

param_panel = uipanel(left_grid, 'Title', 'parameters');
param_panel.Layout.Row = 2;
param_panel.Layout.Column = 1;
param_grid = uigridlayout(param_panel, [3 1]);
param_grid.RowHeight = {'fit', 'fit', 'fit'};
param_grid.Padding = [8 8 8 8];
param_grid.RowSpacing = 5;

n1_field = create_numeric_control(param_grid, 'nco (core)', 2.50, 'Core refractive index. Must be larger than ncl.');
n2_field = create_numeric_control(param_grid, 'ncl (cladding)', 1.50, 'Cladding refractive index. Must be smaller than nco.');
max_order_field = create_numeric_control(param_grid, 'max order', 5, 'Largest azimuthal order m to draw.');

action_panel = uipanel(left_grid, 'Title', 'actions');
action_panel.Layout.Row = 3;
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
notes_box.Value = notes_catalog('cylindrical', 'dielectric', 'normalized dispersion');

state = struct('generated_files', {{}}, 'current_file', '', 'current_folder', '');

    function run_simulation(~, ~)
        dlg = create_progress_dialog(app_figure, 'Cylindrical dielectric');
        cleanup = onCleanup(@() close_progress_dialog(dlg)); %#ok<NASGU>
        try
            update_progress_dialog(dlg, 0.10, 'Collecting parameters ...');
            params = read_params();

            update_progress_dialog(dlg, 0.35, 'Generating hidden figures ...');
            result = run_cylindrical_dielectric_generation(project_root, params);

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
            uialert(app_figure, ME.message, 'Cylindrical dielectric run failed', 'Icon', 'error');
        end
    end

    function params = read_params()
        params = struct();
        params.n1 = read_positive(n1_field, 'nco');
        params.n2 = read_positive(n2_field, 'ncl');
        params.max_order = read_integer(max_order_field, 'max order', 0, 30);
        params.legend_location = char(string(legend_location_dd.Value));
        params.vmax = 10;
        params.umax = 7;
        params.samples = 260;
        if params.n1 <= params.n2
            error('Cylindrical dielectric guidance requires nco > ncl.');
        end
    end

    function reset_defaults(~, ~)
        n1_field.Value = 2.50;
        n2_field.Value = 1.50;
        max_order_field.Value = 5;
        legend_location_dd.Value = 'right side';
        notes_box.Value = notes_catalog('cylindrical', 'dielectric', 'normalized dispersion');
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
            export_folder = export_generated_waveguide_files(project_root, state.generated_files, 'cylindrical');
            update_progress_dialog(dlg, 1.0, ['Exported to ' export_folder]);
            pause(0.25);
        catch ME
            close_progress_dialog(dlg);
            uialert(app_figure, ME.message, 'Export failed', 'Icon', 'error');
        end
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
        text(preview_axes, 0.5, 0.5, '$\mathrm{run\ to\ generate\ a\ cylindrical\ dielectric\ plot}$', ...
            'Interpreter', 'latex', 'HorizontalAlignment', 'center');
        preview_axes.XLim = [0 1];
        preview_axes.YLim = [0 1];
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
