function tab = create_chladni_tab(tab_group, project_root)
%CREATE_CHLADNI_TAB Build the Chladni GUI tab.

app_figure = ancestor(tab_group, 'figure');

tab = uitab(tab_group, 'Title', 'chladni figures');
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

physical_panel = uipanel(left_grid, 'Title', 'physical parameters');
physical_panel.Layout.Row = 1;
physical_panel.Layout.Column = 1;
physical_grid = uigridlayout(physical_panel, [6 1]);
physical_grid.RowHeight = {'fit', 'fit', 'fit', 'fit', 'fit', 'fit'};
physical_grid.Padding = [8 8 8 8];
physical_grid.RowSpacing = 5;

type_dd = create_dropdown_control(physical_grid, 'domain', {'rect', 'circ', 'annulus'}, 'rect', ...
    'Choose rectangle, solid disk, or annulus.');
rect_boundary_field = create_text_control(physical_grid, 'boundary (rect ULDR)', 'FFFF', ...
    'Rect uses a 4-letter ULDR code: up, left, down, right. Each letter must be C, S, or F.');
circ_boundary_dd = create_dropdown_control(physical_grid, 'boundary (circ/annulus)', ...
    circ_boundary_options('circ'), 'C', ...
    'Circ uses C/S/F. Annulus uses a two-letter outer-inner code such as CC, CF, or FS.');
nu_field = create_numeric_control(physical_grid, 'nu', 0.225, ...
    'Poisson ratio of the plate material, with 0 < nu < 0.5.');
mode_count = create_numeric_control(physical_grid, 'number of modes', 10, ...
    'How many mode figures to generate.');
xi0_field = create_numeric_control(physical_grid, 'xi_0', 0.45, ...
    'For rect, xi_0 = vertical side / top horizontal side; the horizontal side is fixed to 2 and the vertical side is 2*xi_0. For annulus, xi_0 = R_0/R. Disabled for circ.');

numerical_panel = uipanel(left_grid, 'Title', 'numerical / display parameters');
numerical_panel.Layout.Row = 2;
numerical_panel.Layout.Column = 1;
numerical_grid = uigridlayout(numerical_panel, [1 1]);
numerical_grid.RowHeight = {'fit'};
numerical_grid.Padding = [8 8 8 8];
numerical_grid.RowSpacing = 5;

grid_n = create_numeric_control(numerical_grid, 'grid size', 240, ...
    'Grid resolution used for rendering.');

action_panel = uipanel(left_grid, 'Title', 'actions');
action_panel.Layout.Row = 3;
action_panel.Layout.Column = 1;
action_grid = uigridlayout(action_panel, [1 1]);
action_grid.RowHeight = {28};
action_grid.Padding = [8 8 8 8];
button_block = create_button_row(action_grid, @run_simulation, @reset_defaults, @export_all_generated);
button_block.run.Tooltip = 'Generate the current batch and refresh the preview.';
button_block.export.Tooltip = 'Export all PNG files from the current batch to the local output folder.';

right_grid = uigridlayout(root, [2 1]);
right_grid.Layout.Row = 1;
right_grid.Layout.Column = 2;
right_grid.RowHeight = {'1x', 190};
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
preview_list.Tooltip = 'Preview list for the current generated batch.';

preview_axes = uiaxes(preview_grid);
preview_axes.Layout.Row = 1;
preview_axes.Layout.Column = 2;
apply_axes_style(preview_axes);
reset_preview_axes();

notes_box = uitextarea(right_grid, 'Editable', 'off');
notes_box.Layout.Row = 2;
notes_box.Layout.Column = 1;
notes_box.Value = notes_catalog('rect', 'FFFF', 2.0, 0.9);

state = struct();
state.generated_files = {};
state.current_file = '';
state.current_folder = '';

install_boundary_items();
type_dd.ValueChangedFcn = @(~,~) on_domain_changed();
rect_boundary_field.ValueChangedFcn = @(~,~) on_boundary_changed();
circ_boundary_dd.ValueChangedFcn = @(~,~) on_boundary_changed();
xi0_field.ValueChangedFcn = @(~,~) on_xi0_changed();

    function run_simulation(~, ~)
        dlg = create_progress_dialog(app_figure, 'generating chladni figures');
        try
            params = read_params();
            update_progress_dialog(dlg, 0.15, 'validating parameters');
            notes_box.Value = local_notes(params.type, params.boundary, params.xi0);

            update_progress_dialog(dlg, 0.45, 'solving and rendering');
            result = run_chladni_generation(project_root, params);
            state.generated_files = result.files;
            state.current_folder = result.storage_folder;

            if isempty(result.files)
                error('No PNG output files were generated.');
            end

            update_preview_list(result.files);

            update_progress_dialog(dlg, 0.85, 'updating preview');
            state.current_file = result.files{1};
            preview_list.Value = result.files{1};
            render_png_preview(preview_axes, state.current_file);

            update_progress_dialog(dlg, 1.0, 'complete');
            pause(0.05);
            close_progress_dialog(dlg);
            uialert(app_figure, sprintf('Generated %d preview image(s).', numel(result.files)), ...
                'Generation complete', 'Icon', 'success');
        catch ME
            close_progress_dialog(dlg);
            uialert(app_figure, sprintf('Chladni run failed:\n%s', ME.message), 'Run failed', 'Icon', 'error');
        end
    end

    function params = read_params()
        params = struct();
        params.type = char(lower(string(type_dd.Value)));
        params.boundary = normalize_boundary_input(params.type, current_boundary_value());
        params.nu = nu_field.Value;
        params.k = round(mode_count.Value);
        params.n = round(grid_n.Value);
        params.normalize = true;
        params.xi0 = 0;
        params.a = 1.0;
        params.b = 1.0;

        if ~isfinite(params.nu) || params.nu <= 0 || params.nu >= 0.5
            error('nu must be in (0, 0.5).');
        end
        if ~isfinite(params.k) || params.k < 1
            error('number of modes must be a positive integer.');
        end
        if ~isfinite(params.n) || params.n < 32
            error('grid size must be at least 32.');
        end

        switch params.type
            case 'rect'
                params.xi0 = xi0_field.Value;
                if ~isfinite(params.xi0) || params.xi0 <= 0
                    error('For rect runs, xi0 = vertical side / top horizontal side = b/a must be positive.');
                end
                params.a = 2.0;
                params.b = 2.0 * params.xi0;
            case 'annulus'
                params.xi0 = xi0_field.Value;
                if ~isfinite(params.xi0) || params.xi0 <= 0 || params.xi0 >= 1
                    error('For annulus runs, xi0 must satisfy 0 < xi0 < 1.');
                end
            otherwise
                params.xi0 = 0;
        end
    end

    function reset_defaults(~, ~)
        type_dd.Value = 'rect';
        rect_boundary_field.Value = 'FFFF';
        nu_field.Value = 0.225;
        mode_count.Value = 10;
        xi0_field.Value = 0.45;
        grid_n.Value = 240;
        install_boundary_items();
        notes_box.Value = notes_catalog('rect', 'FFFF', 2.0, 0.9);
        preview_list.Items = {};
        if isprop(preview_list, 'ItemsData')
            preview_list.ItemsData = {};
        end
        reset_preview_axes();
        state.generated_files = {};
        state.current_file = '';
        state.current_folder = '';
    end

    function export_all_generated(~, ~)
        if isempty(state.generated_files)
            uialert(app_figure, 'No generated images are available yet.', 'Nothing to export', 'Icon', 'warning');
            return;
        end

        export_root = fullfile(project_root, 'output');
        if ~exist(export_root, 'dir')
            mkdir(export_root);
        end

        export_folder = fullfile(export_root, local_export_folder_name());
        local_prepare_export_folder(export_folder);

        for i = 1:numel(state.generated_files)
            src = state.generated_files{i};
            [~, name, ext] = fileparts(src);
            copyfile(src, fullfile(export_folder, [name ext]));
        end

        uialert(app_figure, sprintf('Exported %d PNG file(s) to:\n%s', numel(state.generated_files), export_folder), ...
            'Export complete', 'Icon', 'success');
    end

    function name = local_export_folder_name()
        if ~isempty(state.current_folder) && isfolder(state.current_folder)
            name = local_path_leaf(state.current_folder);
            return;
        end
        params = read_params();
        name = sprintf('%s-%s-nu%s-xi%s', lower(params.type), upper(params.boundary), ...
            local_num_tag(params.nu), local_num_tag(params.xi0));
    end

    function name = local_path_leaf(folder_path)
        % fileparts treats trailing numeric tags such as xi0.45 as an
        % extension. Recombine name+ext so folder names keep their full tag.
        clean_path = char(string(folder_path));
        while ~isempty(clean_path) && (clean_path(end) == filesep || clean_path(end) == '/' || clean_path(end) == char(92))
            clean_path(end) = [];
        end
        [~, stem, suffix] = fileparts(clean_path);
        name = [stem suffix];
    end

    function local_prepare_export_folder(folder_path)
        if ~exist(folder_path, 'dir')
            mkdir(folder_path);
            return;
        end
        info = dir(fullfile(folder_path, '*.png'));
        for ii = 1:numel(info)
            delete(fullfile(folder_path, info(ii).name));
        end
    end

    function lines = local_notes(domain_type, boundary, xi0)
        if nargin < 3 || isempty(xi0)
            xi0 = xi0_field.Value;
        end
        if strcmpi(domain_type, 'rect')
            lines = notes_catalog(domain_type, boundary, 2.0, 2.0 * xi0);
        else
            lines = notes_catalog(domain_type, boundary, 1.0, 1.0);
        end
    end

    function on_domain_changed()
        install_boundary_items();
        notes_box.Value = local_notes(char(type_dd.Value), current_boundary_value(), xi0_field.Value);
    end

    function on_boundary_changed()
        notes_box.Value = local_notes(char(type_dd.Value), current_boundary_value(), xi0_field.Value);
    end

    function on_xi0_changed()
        notes_box.Value = local_notes(char(type_dd.Value), current_boundary_value(), xi0_field.Value);
    end

    function on_preview_selected()
        if isempty(preview_list.Items)
            return;
        end
        selected_file = char(string(preview_list.Value));
        if isempty(selected_file) || ~isfile(selected_file)
            return;
        end
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

    function install_boundary_items()
        domain_value = char(type_dd.Value);
        switch domain_value
            case 'rect'
                rect_boundary_field.Enable = 'on';
                circ_boundary_dd.Enable = 'off';
                circ_boundary_dd.Tooltip = 'Disabled for rect. Use the ULDR text code above.';
                if isempty(strtrim(char(string(rect_boundary_field.Value))))
                    rect_boundary_field.Value = 'FFFF';
                else
                    rect_boundary_field.Value = upper(strtrim(char(string(rect_boundary_field.Value))));
                end
                xi0_field.Enable = 'on';
                xi0_field.Tooltip = 'For rect, xi_0 = vertical side / top horizontal side; the horizontal side is fixed to 2 and the vertical side is 2*xi_0.';
                set_dropdown_items(circ_boundary_dd, circ_boundary_options('circ'), 'C');
            case 'circ'
                rect_boundary_field.Enable = 'off';
                rect_boundary_field.Tooltip = 'Disabled for circ. Use the dropdown below.';
                xi0_field.Enable = 'off';
                xi0_field.Tooltip = 'Disabled for circ. A solid disk uses xi_0 = 0.';
                set_dropdown_items(circ_boundary_dd, circ_boundary_options('circ'), 'C');
                circ_boundary_dd.Enable = 'on';
                circ_boundary_dd.Tooltip = 'Circ uses the outer-edge presets C, F, or S.';
            otherwise
                rect_boundary_field.Enable = 'off';
                rect_boundary_field.Tooltip = 'Disabled for annulus. Use the dropdown below.';
                xi0_field.Enable = 'on';
                xi0_field.Tooltip = 'For annulus, xi_0 = R_0 / R with 0 < xi_0 < 1.';
                set_dropdown_items(circ_boundary_dd, circ_boundary_options('annulus'), 'CF');
                circ_boundary_dd.Enable = 'on';
                circ_boundary_dd.Tooltip = 'Annulus uses ordered outer-inner boundary pairs such as CC, CF, or FS.';
        end
    end

    function set_dropdown_items(dd, items, fallback)
        current = char(string(dd.Value));
        dd.Items = items;
        if any(strcmp(items, current))
            dd.Value = current;
        else
            dd.Value = fallback;
        end
    end

    function out = normalize_boundary_input(domain_type, raw_value)
        textValue = strtrim(char(string(raw_value)));
        switch char(lower(string(domain_type)))
            case 'rect'
                if numel(textValue) ~= 4 || any(~ismember(upper(textValue), 'CSF'))
                    error('For rect, boundary must be a 4-letter ULDR code using C/S/F, e.g. CFSF or SSFF.');
                end
                out = upper(textValue);
            case 'circ'
                if any(strcmpi(textValue, {'free', 'simply', 'clamped', 'f', 's', 'c'}))
                    out = upper(textValue(1));
                else
                    error('For circ, boundary must be C, S, F, or the aliases clamped/simply/free.');
                end
            otherwise
                if numel(textValue) ~= 2 || any(~ismember(upper(textValue), 'CSF'))
                    error('For annulus, boundary must be a 2-letter outer-inner code such as CF, SS, or FC.');
                end
                out = upper(textValue);
        end
    end

    function value = current_boundary_value()
        switch char(lower(string(type_dd.Value)))
            case 'rect'
                value = char(string(rect_boundary_field.Value));
            otherwise
                value = char(string(circ_boundary_dd.Value));
        end
    end

    function reset_preview_axes()
        cla(preview_axes);
        apply_axes_style(preview_axes);
        preview_axes.Visible = 'on';
        preview_axes.XTick = [];
        preview_axes.YTick = [];
        title(preview_axes, '$\mathrm{preview}$', 'Interpreter', 'latex');
        text(preview_axes, 0.5, 0.5, '$\mathrm{run\ to\ generate\ figures}$', ...
            'Interpreter', 'latex', 'HorizontalAlignment', 'center');
        preview_axes.XLim = [0 1];
        preview_axes.YLim = [0 1];
    end
end

function tag = local_num_tag(x)
tag = sprintf('%.6g', x);
end
