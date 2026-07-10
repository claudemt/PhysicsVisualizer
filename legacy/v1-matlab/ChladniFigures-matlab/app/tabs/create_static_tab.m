function tab = create_static_tab(tab_group, project_root)
%CREATE_STATIC_TAB Build the static-load GUI tab.
%
% This tab is deliberately separate from create_chladni_tab.  The Chladni tab
% solves eigenvalue problems and draws nodal-line figures.  This tab solves
% the static Kirchhoff--Love problem D*nabla^4 w = q and draws a heat map of w.

app_figure = ancestor(tab_group, 'figure');

tab = uitab(tab_group, 'Title', 'static sources');
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

physical_panel = uipanel(left_grid, 'Title', 'geometry and boundary');
physical_panel.Layout.Row = 1;
physical_panel.Layout.Column = 1;
physical_grid = uigridlayout(physical_panel, [6 1]);
physical_grid.RowHeight = {'fit', 'fit', 'fit', 'fit', 'fit', 'fit'};
physical_grid.Padding = [8 8 8 8];
physical_grid.RowSpacing = 5;

type_dd = create_dropdown_control(physical_grid, 'domain', {'rect', 'circ', 'annulus'}, 'rect', ...
    'Choose rectangle, solid disk, or annulus.');
rect_boundary_field = create_text_control(physical_grid, 'boundary (rect ULDR)', 'SSSS', ...
    'Rect uses a 4-letter ULDR code: up, left, down, right. Each letter must be C, S, or F.');
circ_boundary_dd = create_dropdown_control(physical_grid, 'boundary (circ/annulus)', ...
    circ_boundary_options('circ'), 'C', ...
    'Circ uses C/S/F. Annulus uses a two-letter outer-inner code such as CC, CF, or FS.');
nu_field = create_numeric_control(physical_grid, 'nu', 0.30, ...
    'Poisson ratio of the plate material, with 0 < nu < 0.5.');
xi0_field = create_numeric_control(physical_grid, 'xi_0', 0.45, ...
    'For rect, xi_0 = vertical side / top horizontal side; the horizontal side is fixed to 2 and the vertical side is 2*xi_0. For annulus, xi_0 = R_0/R. Disabled for circ.');
grid_n = create_numeric_control(physical_grid, 'grid size', 220, ...
    'Grid resolution used for rendering the static heat map.');

load_panel = uipanel(left_grid, 'Title', 'static load q(x,y)');
load_panel.Layout.Row = 2;
load_panel.Layout.Column = 1;
load_grid = uigridlayout(load_panel, [5 1]);
load_grid.RowHeight = {'fit', 'fit', 76, 76, 'fit'};
load_grid.Padding = [8 8 8 8];
load_grid.RowSpacing = 5;

load_type_dd = create_dropdown_control(load_grid, 'load type', {'points', 'uniform', 'custom', 'mixed'}, 'points', ...
    'points: source matrix only. uniform: q=q0 only. custom: q(X,Y) only. mixed: q0 + sources + custom.');
q0_field = create_numeric_control(load_grid, 'q0', 1.0, ...
    'Used only by uniform and mixed loads. For uniform/mixed it is the constant component; for self-weight use rho*h*g in consistent units.');
sources_field = create_multiline_text_control(load_grid, 'sources [x y P sigma]', ...
    {'[0 0 1 0;'; ' 0.45 0.25 -0.6 0.04]'}, ...
    'Multiple rows are allowed in plotted Cartesian coordinates. Rect: inside the rectangle; disk: hypot(x,y)<1; annulus: xi_0<hypot(x,y)<1. sigma=0 means ideal point load; sigma>0 means a normalized Gaussian load.');
function_field = create_multiline_text_control(load_grid, 'custom q(X,Y)', ...
    {'@(X,Y) exp(-18*((X-0.25).^2 + (Y+0.1).^2))'}, ...
    'Use @(X,Y) ... or @(X,Y,mask) ... or a bare expression. X,Y are Cartesian samples in the actual plate material; use elementwise operators .*, ./, .^ .');
truncation_field = create_numeric_control(load_grid, 'truncation', 60, ...
    'Rect: number of modes in the static Ritz sum. Circ/annulus: maximum angular Fourier order.');

action_panel = uipanel(left_grid, 'Title', 'actions');
action_panel.Layout.Row = 3;
action_panel.Layout.Column = 1;
action_grid = uigridlayout(action_panel, [1 1]);
action_grid.RowHeight = {28};
action_grid.Padding = [8 8 8 8];
button_block = create_button_row(action_grid, @run_static_simulation, @reset_defaults, @export_all_generated);
button_block.run.Text = 'Run';
button_block.run.Tooltip = 'Generate the static heat map and refresh the preview.';
button_block.export.Tooltip = 'Export all PNG files from the current static run to the local output folder.';

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
preview_list.Tooltip = 'Preview list for the current static run.';

preview_axes = uiaxes(preview_grid);
preview_axes.Layout.Row = 1;
preview_axes.Layout.Column = 2;
apply_axes_style(preview_axes);
reset_preview_axes();

notes_box = uitextarea(right_grid, 'Editable', 'off');
notes_box.Layout.Row = 2;
notes_box.Layout.Column = 1;
notes_box.Value = local_notes('rect', 'SSSS', 'points');

state = struct();
state.generated_files = {};
state.current_file = '';
state.current_folder = '';
state.current_params = struct();

install_boundary_items();
update_load_controls();
type_dd.ValueChangedFcn = @(~,~) on_domain_changed();
rect_boundary_field.ValueChangedFcn = @(~,~) on_boundary_changed();
circ_boundary_dd.ValueChangedFcn = @(~,~) on_boundary_changed();
xi0_field.ValueChangedFcn = @(~,~) on_xi0_changed();
load_type_dd.ValueChangedFcn = @(~,~) on_load_changed();

    function run_static_simulation(~, ~)
        dlg = create_progress_dialog(app_figure, 'generating static response');
        try
            params = read_params();
            update_progress_dialog(dlg, 0.15, 'validating static load');
            notes_box.Value = local_notes(params.type, params.boundary, params.load_type);

            update_progress_dialog(dlg, 0.45, 'solving static plate problem');
            result = run_static_source_generation(project_root, params);
            state.generated_files = result.files;
            state.current_folder = result.storage_folder;
            state.current_params = params;

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
            uialert(app_figure, sprintf('Generated %d static heat map(s).', numel(result.files)), ...
                'Static run complete', 'Icon', 'success');
        catch ME
            close_progress_dialog(dlg);
            uialert(app_figure, sprintf('Static run failed:\n%s', ME.message), 'Static run failed', 'Icon', 'error');
        end
    end

    function params = read_params()
        params = struct();
        params.type = char(lower(string(type_dd.Value)));
        params.boundary = normalize_boundary_input(params.type, current_boundary_value());
        params.nu = nu_field.Value;
        params.n = round(grid_n.Value);
        params.normalize = true;
        params.D = 1.0;
        params.xi0 = 0;
        params.a = 1.0;
        params.b = 1.0;
        params.load_type = char(lower(string(load_type_dd.Value)));
        params.q0 = 0;
        params.kmodes = max(1, round(truncation_field.Value));
        params.mmax = max(1, round(truncation_field.Value));
        params.distribution_samples = max(10, min(42, round(sqrt(max(params.n, 1)))));
        params.draw_zero_contour = false;

        uses_q0 = any(strcmp(params.load_type, {'uniform', 'mixed'}));
        uses_sources = any(strcmp(params.load_type, {'points', 'mixed'}));
        uses_custom = any(strcmp(params.load_type, {'custom', 'mixed'}));

        if uses_q0
            params.q0 = q0_field.Value;
        end
        if uses_sources
            params.sources = parse_sources_text(control_text_value(sources_field));
        end

        if ~isfinite(params.nu) || params.nu <= 0 || params.nu >= 0.5
            error('nu must be in (0, 0.5).');
        end
        if ~isfinite(params.n) || params.n < 32
            error('grid size must be at least 32.');
        end
        if uses_q0 && ~isfinite(params.q0)
            error('q0 must be finite for the selected load type.');
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

        if uses_sources && isempty(params.sources)
            error('Point-source and mixed loads require a source matrix, for example [0 0 1 0; 0.5 0 -0.5 0.05].');
        end

        if uses_custom
            fn_text = strtrim(control_text_value(function_field));
            if isempty(fn_text)
                error('Custom and mixed loads require a custom q(X,Y) function.');
            end
            params.load_function = fn_text;
        end
    end

    function reset_defaults(~, ~)
        type_dd.Value = 'rect';
        rect_boundary_field.Value = 'SSSS';
        nu_field.Value = 0.30;
        xi0_field.Value = 0.45;
        grid_n.Value = 220;
        load_type_dd.Value = 'points';
        q0_field.Value = 1.0;
        sources_field.Value = {'[0 0 1 0;'; ' 0.45 0.25 -0.6 0.04]'};
        function_field.Value = {'@(X,Y) exp(-18*((X-0.25).^2 + (Y+0.1).^2))'};
        truncation_field.Value = 60;
        install_boundary_items();
        update_load_controls();
        notes_box.Value = local_notes('rect', 'SSSS', 'points');
        preview_list.Items = {};
        if isprop(preview_list, 'ItemsData')
            preview_list.ItemsData = {};
        end
        reset_preview_axes();
        state.generated_files = {};
        state.current_file = '';
        state.current_folder = '';
        state.current_params = struct();
    end

    function export_all_generated(~, ~)
        if isempty(state.generated_files)
            uialert(app_figure, 'No generated static heat maps are available yet.', 'Nothing to export', 'Icon', 'warning');
            return;
        end

        export_root = fullfile(project_root, 'output');
        if ~exist(export_root, 'dir')
            mkdir(export_root);
        end

        export_folder = fullfile(export_root, local_export_folder_name());
        local_prepare_export_folder(export_folder);

        if isfield(state, 'current_params') && ~isempty(fieldnames(state.current_params))
            export_params = state.current_params;
        else
            export_params = read_params();
        end

        base_name = local_static_export_base_name(export_params);
        exported_files = cell(size(state.generated_files));
        export_indices = zeros(size(state.generated_files));
        next_index = local_next_static_index(export_folder, base_name);
        for i = 1:numel(state.generated_files)
            src = state.generated_files{i};
            [~, ~, ext] = fileparts(src);
            dst_name = sprintf('%s-%02d%s', base_name, next_index, ext);
            dst = fullfile(export_folder, dst_name);
            while isfile(dst)
                next_index = next_index + 1;
                dst_name = sprintf('%s-%02d%s', base_name, next_index, ext);
                dst = fullfile(export_folder, dst_name);
            end
            copyfile(src, dst);
            exported_files{i} = dst;
            export_indices(i) = next_index;
            next_index = next_index + 1;
        end

        local_write_static_params_log(export_folder, export_params, exported_files, export_indices);

        uialert(app_figure, sprintf('Exported %d static PNG file(s) to:\n%s\nUpdated params.txt.', numel(state.generated_files), export_folder), ...
            'Export complete', 'Icon', 'success');
    end

    function name = local_export_folder_name()
        if ~isempty(state.current_folder) && isfolder(state.current_folder)
            name = local_path_leaf(state.current_folder);
            return;
        end
        params = read_params();
        name = local_static_export_base_name(params);
    end

    function name = local_static_export_base_name(params)
        domain_type = char(lower(string(params.type)));
        if strcmp(domain_type, 'square')
            domain_type = 'rect';
        elseif strcmp(domain_type, 'circle')
            domain_type = 'circ';
        elseif strcmp(domain_type, 'ring')
            domain_type = 'annulus';
        end
        name = sprintf('static-%s-%s-nu%s-xi%s', domain_type, char(upper(string(params.boundary))), ...
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
        end
    end

    function next_index = local_next_static_index(folder_path, base_name)
        info = dir(fullfile(folder_path, [base_name '-*.png']));
        next_index = 1;
        pattern = ['^' regexptranslate('escape', base_name) '-(\d+)\.png$'];
        for ii = 1:numel(info)
            tok = regexp(info(ii).name, pattern, 'tokens', 'once');
            if isempty(tok), continue; end
            value = str2double(tok{1});
            if isfinite(value)
                next_index = max(next_index, value + 1);
            end
        end
    end

    function local_write_static_params_log(folder_path, params, exported_files, export_indices)
        params_path = fullfile(folder_path, 'params.txt');
        is_new = ~isfile(params_path);
        if ~is_new
            info = dir(params_path);
            is_new = isempty(info) || info.bytes == 0;
        end

        fid = fopen(params_path, 'a');
        if fid < 0
            error('Could not open params.txt for writing: %s', params_path);
        end
        cleaner = onCleanup(@() fclose(fid)); %#ok<NASGU>

        if is_new
            fprintf(fid, '====== Basic parameters ======\n');
            local_write_basic_params(fid, params);
            fprintf(fid, '\n ====== Force distribution records ====== \n');
        end

        for jj = 1:numel(exported_files)
            [~, exported_name, exported_ext] = fileparts(exported_files{jj});
            fprintf(fid, '\n%02d -> %s%s\n', export_indices(jj), exported_name, exported_ext);
            local_write_load_distribution(fid, params);
        end
    end

    function local_write_basic_params(fid, params)
        fprintf(fid, 'domain = %s\n', char(lower(string(params.type))));
        fprintf(fid, 'boundary = %s\n', char(upper(string(params.boundary))));
        fprintf(fid, 'nu = %s\n', local_num_tag(params.nu));
        fprintf(fid, 'xi0 = %s\n', local_num_tag(params.xi0));
        if isfield(params, 'a'), fprintf(fid, 'a = %s\n', local_num_tag(params.a)); end
        if isfield(params, 'b'), fprintf(fid, 'b = %s\n', local_num_tag(params.b)); end
        fprintf(fid, 'grid_n = %d\n', round(params.n));
        if isfield(params, 'D'), fprintf(fid, 'D = %s\n', local_num_tag(params.D)); end
        if isfield(params, 'kmodes'), fprintf(fid, 'kmodes = %d\n', round(params.kmodes)); end
        if isfield(params, 'mmax'), fprintf(fid, 'mmax = %d\n', round(params.mmax)); end
        if isfield(params, 'distribution_samples')
            fprintf(fid, 'distribution_samples = %d\n', round(params.distribution_samples));
        end
        if isfield(params, 'normalize')
            fprintf(fid, 'normalize = %d\n', logical(params.normalize));
        end
        if isfield(params, 'draw_zero_contour')
            fprintf(fid, 'draw_zero_contour = %d\n', logical(params.draw_zero_contour));
        end
    end

    function local_write_load_distribution(fid, params)
        lt = char(lower(string(params.load_type)));
        fprintf(fid, 'force_distribution.type = %s\n', lt);
        if any(strcmp(lt, {'uniform', 'mixed'})) && isfield(params, 'q0')
            fprintf(fid, 'force_distribution.q0 = %s\n', local_num_tag(params.q0));
        end
        if any(strcmp(lt, {'points', 'mixed'})) && isfield(params, 'sources')
            fprintf(fid, 'force_distribution.sources [x y P sigma] =\n');
            local_write_numeric_matrix(fid, params.sources);
        end
        if any(strcmp(lt, {'custom', 'mixed'})) && isfield(params, 'load_function')
            fprintf(fid, 'force_distribution.custom_q = %s\n', char(string(params.load_function)));
        end
    end

    function local_write_numeric_matrix(fid, M)
        if isempty(M)
            fprintf(fid, '  []\n');
            return;
        end
        for rr = 1:size(M, 1)
            fprintf(fid, '  ');
            for cc = 1:size(M, 2)
                fprintf(fid, '% .12g', M(rr, cc));
                if cc < size(M, 2), fprintf(fid, '  '); end
            end
            fprintf(fid, '\n');
        end
    end

    function lines = local_notes(domain_type, boundary, load_type)
        lines = static_notes_catalog(domain_type, boundary, load_type);
    end

    function on_domain_changed()
        install_boundary_items();
        notes_box.Value = local_notes(char(type_dd.Value), current_boundary_value(), char(load_type_dd.Value));
    end

    function on_boundary_changed()
        notes_box.Value = local_notes(char(type_dd.Value), current_boundary_value(), char(load_type_dd.Value));
    end

    function on_xi0_changed()
        notes_box.Value = local_notes(char(type_dd.Value), current_boundary_value(), char(load_type_dd.Value));
    end

    function on_load_changed()
        update_load_controls();
        notes_box.Value = local_notes(char(type_dd.Value), current_boundary_value(), char(load_type_dd.Value));
    end

    function update_load_controls()
        lt = char(lower(string(load_type_dd.Value)));
        show_q0 = any(strcmp(lt, {'uniform', 'mixed'}));
        show_sources = any(strcmp(lt, {'points', 'mixed'}));
        show_custom = any(strcmp(lt, {'custom', 'mixed'}));

        set_control_row_visibility(q0_field, show_q0);
        set_control_row_visibility(sources_field, show_sources);
        set_control_row_visibility(function_field, show_custom);

        if show_q0
            q0_height = 'fit';
        else
            q0_height = 0;
        end
        if show_sources
            sources_height = 76;
        else
            sources_height = 0;
        end
        if show_custom
            custom_height = 76;
        else
            custom_height = 0;
        end
        load_grid.RowHeight = {'fit', q0_height, sources_height, custom_height, 'fit'};

        switch lt
            case 'points'
                load_panel.Title = 'static load q(x,y): point/Gaussian sources';
            case 'uniform'
                load_panel.Title = 'static load q(x,y): constant q0';
            case 'custom'
                load_panel.Title = 'static load q(x,y): custom function';
            otherwise
                load_panel.Title = 'static load q(x,y): q0 + sources + custom';
        end
    end

    function set_control_row_visibility(control, tf)
        row = control.Parent;
        if tf
            value = 'on';
        else
            value = 'off';
        end
        if isprop(row, 'Visible')
            row.Visible = value;
        end
        control.Enable = value;
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
                    rect_boundary_field.Value = 'SSSS';
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
                set_dropdown_items(circ_boundary_dd, circ_boundary_options('annulus'), 'CC');
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
                    error('For rect, boundary must be a 4-letter ULDR code using C/S/F, e.g. CFSF or SSSS.');
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

    function S = parse_sources_text(text_value)
        txt = strtrim(char(string(text_value)));
        if isempty(txt)
            S = zeros(0, 4);
            return;
        end
        S = str2num(txt); %#ok<ST2NM>
        if isempty(S) || ~isnumeric(S)
            error('Source matrix must be numeric, for example [0 0 1 0; 0.5 0 -0.5 0.05].');
        end
        if isvector(S)
            S = S(:).';
        end
        if size(S, 2) == 2
            S = [S ones(size(S,1),1) zeros(size(S,1),1)];
        elseif size(S, 2) == 3
            S = [S zeros(size(S,1),1)];
        elseif size(S, 2) ~= 4
            error('Source matrix must have 2, 3, or 4 columns: [x y P sigma].');
        end
    end

    function reset_preview_axes()
        cla(preview_axes);
        apply_axes_style(preview_axes);
        preview_axes.Visible = 'on';
        preview_axes.XTick = [];
        preview_axes.YTick = [];
        title(preview_axes, '$\mathrm{static\ preview}$', 'Interpreter', 'latex');
        text(preview_axes, 0.5, 0.5, 'run to generate a heat map', ...
            'Interpreter', 'latex', 'HorizontalAlignment', 'center');
        preview_axes.XLim = [0 1];
        preview_axes.YLim = [0 1];
    end
end


function field = create_multiline_text_control(parent, label_text, default_value, tooltip_text)
%CREATE_MULTILINE_TEXT_CONTROL A taller text-area row for matrices/functions.
row = uigridlayout(parent, [1 2]);
row.ColumnWidth = {120, '1x'};
row.RowHeight = {'1x'};
row.Padding = [0 0 0 0];
row.ColumnSpacing = 6;
label = uilabel(row, 'Text', label_text, 'HorizontalAlignment', 'left', 'VerticalAlignment', 'top');
label.Layout.Row = 1;
label.Layout.Column = 1;
field = uitextarea(row, 'Value', default_value);
field.Layout.Row = 1;
field.Layout.Column = 2;
if nargin >= 4 && ~isempty(tooltip_text)
    label.Tooltip = tooltip_text;
    field.Tooltip = tooltip_text;
end
end

function txt = control_text_value(control)
%CONTROL_TEXT_VALUE Return uieditfield/uitextarea contents as one string.
v = control.Value;
if iscell(v)
    txt = strjoin(cellfun(@char, v(:).', 'UniformOutput', false), newline);
elseif isstring(v)
    txt = strjoin(cellstr(v(:).'), newline);
else
    txt = char(v);
end
end

function tag = local_num_tag(x)
% Match the eigenmode export convention: keep the decimal point in
% numeric tags, e.g. 0.225 instead of 0p225.  The file extension is
% appended separately by the caller, so internal decimal points are safe.
tag = sprintf('%.6g', x);
end
