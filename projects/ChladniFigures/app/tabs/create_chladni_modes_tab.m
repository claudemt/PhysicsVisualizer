function tab = create_chladni_modes_tab(tab_group, project_root)
%CREATE_CHLADNI_MODES_TAB Eigenmode Chladni figures with arbitrary C/S/F edge codes.

app_figure = ancestor(tab_group, 'figure');
ui = create_tab_layout(tab_group, 'chladni modes', project_root, ...
    'Preview', 'list', ...
    'PreviewListWidth', 340, ...
    'NotesText', local_mode_notes('rect', 'FFFF'), ...
    'NotesFile', fullfile(project_root, 'docs', 'physical_formulas.md'));

tab = ui.tab;
ui.control_grid.RowHeight = {'fit','fit','fit','1x'};

physical = create_control_panel(ui.control_grid, 'section', 'plate and boundary', 7);
type_dd = create_control_panel(physical.grid, 'dropdown', 'domain', {'rect','circ','annulus'}, 'rect', [], ...
    'rect uses a four-edge ULDR boundary string; circ and annulus use the dropdown below.');
rect_boundary = create_control_panel(physical.grid, 'text', 'rect boundary ULDR', 'FFFF', [], ...
    'Four letters in up-left-down-right order; each letter is C, S, or F. Examples: CFSF, SSSS, FFFF.');
circ_boundary = create_control_panel(physical.grid, 'dropdown', 'circ / annulus boundary', ...
    chladni_input_helpers('boundary_items','circ'), 'C', [], ...
    'Circ uses C/S/F. Annulus uses ordered outer-inner pairs such as CC, CF, FS.');
nu_edit = create_control_panel(physical.grid, 'numeric', 'nu', 0.225, [], 'Poisson ratio, with 0 < nu < 0.5.');
mode_count = create_control_panel(physical.grid, 'numeric', 'number of modes', 10, [], 'How many mode images to compute.');
grid_n = create_control_panel(physical.grid, 'numeric', 'grid size', 240, [], 'Grid resolution used for mode-shape rendering.');
xi0_edit = create_control_panel(physical.grid, 'numeric', 'xi_0', 0.45, [], ...
    'For rect, xi_0=b/a with a=2 and b=2*xi_0. For annulus, xi_0=R0/R. Disabled for circ.');

actions = create_control_panel(ui.control_grid, 'section', 'actions', 1);
state = struct('png_paths', {{}}, 'params', struct(), 'runs', {{}});

bind_workflow(actions.grid, app_figure, @run_callback, @reset_callback, @export_callback, 'GenerateText', 'Run');
type_dd.ValueChangedFcn = @(~,~) on_domain_changed();
rect_boundary.ValueChangedFcn = @(~,~) refresh_notes();
circ_boundary.ValueChangedFcn = @(~,~) refresh_notes();
xi0_edit.ValueChangedFcn = @(~,~) refresh_notes();

install_boundary_items();
refresh_notes();
image_output('bind_preview_list', ui.preview_list, ui.preview_axes, {});

    function on_domain_changed()
        install_boundary_items();
        refresh_notes();
    end

    function install_boundary_items()
        domain = char(string(type_dd.Value));
        is_rect = strcmp(domain, 'rect');
        is_circ = strcmp(domain, 'circ');
        rect_boundary.Parent.Visible = chladni_input_helpers('onoff', is_rect);
        circ_boundary.Parent.Visible = chladni_input_helpers('onoff', ~is_rect);
        if is_rect
            if isempty(strtrim(char(string(rect_boundary.Value))))
                rect_boundary.Value = 'FFFF';
            else
                rect_boundary.Value = upper(strtrim(char(string(rect_boundary.Value))));
            end
            xi0_edit.Enable = 'on';
            physical.grid.RowHeight = {'fit','fit',0,'fit','fit','fit','fit'};
        elseif is_circ
            circ_boundary.Items = chladni_input_helpers('boundary_items','circ');
            if ~any(strcmp(circ_boundary.Items, circ_boundary.Value)), circ_boundary.Value = 'C'; end
            xi0_edit.Enable = 'off';
            physical.grid.RowHeight = {'fit',0,'fit','fit','fit','fit','fit'};
        else
            circ_boundary.Items = chladni_input_helpers('boundary_items','annulus');
            if ~any(strcmp(circ_boundary.Items, circ_boundary.Value)), circ_boundary.Value = 'CF'; end
            xi0_edit.Enable = 'on';
            physical.grid.RowHeight = {'fit',0,'fit','fit','fit','fit','fit'};
        end
    end

    function refresh_notes()
        boundary = current_boundary_value();
        ui.set_notes(local_mode_notes(type_dd.Value, boundary));
    end

    function value = current_boundary_value()
        if strcmp(char(string(type_dd.Value)), 'rect')
            value = char(string(rect_boundary.Value));
        else
            value = char(string(circ_boundary.Value));
        end
    end

    function params = read_params()
        params = struct();
        params.type = char(lower(string(type_dd.Value)));
        params.boundary = chladni_input_helpers('normalize_boundary', params.type, current_boundary_value());
        params.nu = nu_edit.Value;
        params.k = max(1, round(mode_count.Value));
        params.n = max(32, round(grid_n.Value));
        params.normalize = true;
        params.xi0 = 0;
        params.a = 1.0;
        params.b = 1.0;

        if ~isfinite(params.nu) || params.nu <= 0 || params.nu >= 0.5
            error('nu must be in (0, 0.5).');
        end
        switch params.type
            case 'rect'
                params.xi0 = xi0_edit.Value;
                if ~isfinite(params.xi0) || params.xi0 <= 0
                    error('For rect, xi_0=b/a must be positive.');
                end
                params.a = 2.0;
                params.b = 2.0 * params.xi0;
            case 'annulus'
                params.xi0 = xi0_edit.Value;
                if ~isfinite(params.xi0) || params.xi0 <= 0 || params.xi0 >= 1
                    error('For annulus, xi_0=R0/R must satisfy 0 < xi_0 < 1.');
                end
        end
    end

    function run_callback()
        params = read_params();
        cache_dir = image_output('clear_cache', project_root, 'chladni_modes');
        result = compute_chladni_modes(params);
        png_paths = render_result('render', result, cache_dir, 'Prefix', sprintf('chladni_%s_%s', params.type, params.boundary));
        stored_paths = image_output('bind_preview_list', ui.preview_list, ui.preview_axes, png_paths);
        state.png_paths = image_output('all_preview_paths', ui.preview_list);
        state.params = params;
        state.runs{end+1} = struct('paths', {stored_paths}, 'params', params);
    end

    function reset_callback()
        type_dd.Value = 'rect';
        rect_boundary.Value = 'FFFF';
        nu_edit.Value = 0.225;
        mode_count.Value = 10;
        grid_n.Value = 240;
        xi0_edit.Value = 0.45;
        install_boundary_items();
        refresh_notes();
        state.png_paths = {};
        state.params = struct();
        state.runs = {};
        image_output('bind_preview_list', ui.preview_list, ui.preview_axes, {});
    end

    function export_callback()
        if isempty(state.runs)
            error('Generate images before exporting.');
        end
        paths = image_output('selected_preview_paths', ui.preview_list, {});
        layout = image_output('preview_layout', ui, 'auto');
        [selected_runs, refs] = local_collect_selected_runs(state.runs, paths);
        dest_names = cell(1, numel(paths));
        for ii = 1:numel(paths)
            dest_names{ii} = image_output('indexed_name', paths{ii}, ii, '.png');
        end
        code = local_history_reproduce_code(selected_runs, refs, dest_names, layout);
        params_struct = local_history_params(selected_runs, dest_names, layout);
        image_output('export_bundle', project_root, sprintf('chladni_%s_%s', selected_runs{1}.params.type, selected_runs{1}.params.boundary), paths, ...
            'Params', params_struct, 'ReproduceCode', code, ...
            'Composite', true, 'Layout', layout);
    end
end

function lines = local_mode_notes(domain_type, boundary_code)
lines = { ...
    'This tab computes free-vibration Chladni eigenmodes of a thin plate.', ...
    sprintf('domain = %s: rect uses a rectangle; circ uses a disk; annulus uses a ring with inner radius ratio xi_0.', char(string(domain_type))), ...
    sprintf('boundary = %s: C means clamped edge, S simply supported edge, F free edge. Rect strings are ULDR = Up Left Down Right.', char(string(boundary_code))), ...
    'nu is Poisson ratio of the plate material; typical stable values are 0.2--0.35, and the solver requires 0 < nu < 0.5.', ...
    'xi_0 means b/a for a rectangle, and R0/R for an annulus. For a disk xi_0 is ignored.', ...
    'number of modes controls how many eigenmodes are rendered; grid N controls image resolution and runtime.', ...
    'The color map shows normalized transverse deflection w/w_max. Dark/bright sign changes reveal nodal curves.', ...
    'Use the preview list to select, reorder, preview-combine, and export selected mode images.'};
end


function [selected_runs, refs] = local_collect_selected_runs(runs, selected_paths)
selected_paths = local_cellstr(selected_paths);
selected_runs = {};
refs = struct('run_slot', {}, 'file_index', {});
run_slots = [];
for ii = 1:numel(selected_paths)
    found = false;
    for rr = 1:numel(runs)
        idx = find(strcmp(runs{rr}.paths, selected_paths{ii}), 1, 'first');
        if ~isempty(idx)
            slot = find(run_slots == rr, 1, 'first');
            if isempty(slot)
                selected_runs{end+1} = runs{rr}; %#ok<AGROW>
                run_slots(end+1) = rr; %#ok<AGROW>
                slot = numel(selected_runs);
            end
            refs(end+1) = struct('run_slot', slot, 'file_index', idx); %#ok<AGROW>
            found = true;
            break;
        end
    end
    if ~found
        error('Could not resolve one or more selected preview images to their generating run.');
    end
end
end

function params_struct = local_history_params(selected_runs, dest_names, layout)
params_struct = struct();
params_struct.export = struct('layout', layout, 'selected_files', {dest_names});
for ii = 1:numel(selected_runs)
    params_struct.(sprintf('run_%02d', ii)) = selected_runs{ii}.params;
end
end

function code = local_history_reproduce_code(selected_runs, refs, dest_names, layout)
lines = local_reproduce_header();
for ii = 1:numel(selected_runs)
    suffix = sprintf('%02d', ii);
    param_lines = local_param_assignment_lines(selected_runs{ii}.params);
    prefix = sprintf('chladni_%s_%s', selected_runs{ii}.params.type, selected_runs{ii}.params.boundary);
    lines = [lines; {sprintf('%% Reproduce run %s', suffix); 'params = struct();'}; param_lines(:); ...
        {sprintf('result_%s = compute_chladni_modes(params);', suffix); ...
         sprintf('run_dir_%s = fullfile(export_dir, ''reproduce_run_%s'');', suffix, suffix); ...
         sprintf('if exist(run_dir_%s, ''dir'') == 7, rmdir(run_dir_%s, ''s''); end', suffix, suffix); ...
         sprintf('mkdir(run_dir_%s);', suffix); ...
         sprintf('run_files_%s = render_result(''render'', result_%s, run_dir_%s, ''Prefix'', %s);', suffix, suffix, suffix, local_quote(prefix)); ...
         ''}]; %#ok<AGROW>
end
for ii = 1:numel(refs)
    suffix = sprintf('%02d', refs(ii).run_slot);
    lines{end+1,1} = sprintf('copyfile(run_files_%s{%d}, fullfile(export_dir, %s), ''f'');', suffix, refs(ii).file_index, local_quote(dest_names{ii})); %#ok<AGROW>
end
if numel(dest_names) > 1
    lines{end+1,1} = 'selected_files = {'; %#ok<AGROW>
    for ii = 1:numel(dest_names)
        lines{end+1,1} = sprintf('    fullfile(export_dir, %s);', local_quote(dest_names{ii})); %#ok<AGROW>
    end
    lines{end+1,1} = '};'; %#ok<AGROW>
    lines{end+1,1} = sprintf('image_output(''compose_grid'', selected_files, fullfile(export_dir, ''composite.png''), ''Layout'', %s);', local_quote(layout)); %#ok<AGROW>
end
code = strjoin(lines, newline);
end

function lines = local_reproduce_header()
lines = {'export_dir = fileparts(mfilename(''fullpath''));'; 'project_root = fileparts(fileparts(export_dir));'; 'addpath(genpath(project_root));'; ''};
end

function lines = local_param_assignment_lines(params)
tmp = params_output('reproduce_code', 'unused_function', params);
parts = splitlines(tmp);
if numel(parts) >= 2
    lines = parts(1:end-1);
else
    lines = {'params = struct();'};
end
if ~isempty(lines) && strcmp(strtrim(lines{1}), 'params = struct();')
    lines = lines(2:end);
end
end

function c = local_cellstr(x)
if isempty(x)
    c = {};
elseif iscell(x)
    c = cellfun(@char, x(:).', 'UniformOutput', false);
elseif isstring(x)
    c = cellstr(x(:).');
else
    c = {char(string(x))};
end
end

function s = local_quote(txt)
s = ['''' strrep(char(string(txt)), '''', '''''') ''''];
end
