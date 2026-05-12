function tab = create_static_sources_tab(tab_group, project_root)
%CREATE_STATIC_SOURCES_TAB Forced static Kirchhoff--Love plate response.

app_figure = ancestor(tab_group, 'figure');
ui = create_tab_layout(tab_group, 'static sources', project_root, ...
    'Preview', 'list', ...
    'PreviewListWidth', 340, ...
    'NotesText', local_static_notes('rect', 'SSSS', 'points'), ...
    'NotesFile', fullfile(project_root, 'docs', 'physical_formulas.md'));

tab = ui.tab;
ui.control_grid.RowHeight = {'fit','fit','fit','1x'};

geom = create_control_panel(ui.control_grid, 'section', 'geometry and boundary', 8);
type_dd = create_control_panel(geom.grid, 'dropdown', 'domain', {'rect','circ','annulus'}, 'rect', [], ...
    'Choose rectangle, solid disk, or annulus.');
rect_boundary = create_control_panel(geom.grid, 'text', 'rect boundary ULDR', 'SSSS', [], ...
    'Four letters in up-left-down-right order; each is C, S, or F.');
circ_boundary = create_control_panel(geom.grid, 'dropdown', 'circ / annulus boundary', ...
    chladni_input_helpers('boundary_items','circ'), 'C', [], ...
    'Circ uses C/S/F. Annulus uses ordered outer-inner boundary pairs.');
nu_edit = create_control_panel(geom.grid, 'numeric', 'nu', 0.30, [], 'Poisson ratio, with 0 < nu < 0.5.');
xi0_edit = create_control_panel(geom.grid, 'numeric', 'xi_0', 0.45, [], ...
    'Rect: b/a. Annulus: inner/outer radius. Disabled for circ.');
grid_n = create_control_panel(geom.grid, 'numeric', 'grid size', 220, [], 'Grid resolution for the static heat map.');
truncation = create_control_panel(geom.grid, 'numeric', 'truncation', 60, [], ...
    'Rect: number of modes in the static Ritz sum. Circ/annulus: maximum angular Fourier order.');
D_edit = create_control_panel(geom.grid, 'numeric', 'D', 1.0, [], 'Bending stiffness scale in D nabla^4 w = q.');

load_panel = create_control_panel(ui.control_grid, 'section', 'static load q(x,y)', {24, 24, 86, 86});
load_type_dd = create_control_panel(load_panel.grid, 'dropdown', 'load type', {'points','uniform','custom','mixed'}, 'points', [], ...
    'points: source matrix only. uniform: q=q0. custom: q(X,Y). mixed: q0 + sources + custom.');
q0_edit = create_control_panel(load_panel.grid, 'numeric', 'q0', 1.0, [], 'Constant load component for uniform/mixed.');
sources_area = create_control_panel(load_panel.grid, 'textarea', 'sources [x y P sigma]', ...
    {'[0 0 1 0;'; ' 0.45 0.25 -0.6 0.04]'}, [], ...
    'Rows are [x y P sigma]. sigma=0 is ideal point load; sigma>0 is a normalized Gaussian patch.');
custom_area = create_control_panel(load_panel.grid, 'textarea', 'custom q(X,Y)', ...
    {'@(X,Y) exp(-18*((X-0.25).^2 + (Y+0.1).^2))'}, [], ...
    'Use @(X,Y) ... or a bare expression. Use elementwise operators .*, ./, .^ .');

actions = create_control_panel(ui.control_grid, 'section', 'actions', 1);
state = struct('png_paths', {{}}, 'params', struct(), 'runs', {{}});

bind_workflow(actions.grid, app_figure, @run_callback, @reset_callback, @export_callback, 'GenerateText', 'Run');
type_dd.ValueChangedFcn = @(~,~) on_domain_changed();
rect_boundary.ValueChangedFcn = @(~,~) refresh_notes();
circ_boundary.ValueChangedFcn = @(~,~) refresh_notes();
xi0_edit.ValueChangedFcn = @(~,~) refresh_notes();
load_type_dd.ValueChangedFcn = @(~,~) on_load_changed();

install_boundary_items();
update_load_controls();
refresh_notes();
image_output('bind_preview_list', ui.preview_list, ui.preview_axes, {});

    function on_domain_changed()
        install_boundary_items();
        refresh_notes();
    end

    function on_load_changed()
        update_load_controls();
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
                rect_boundary.Value = 'SSSS';
            else
                rect_boundary.Value = upper(strtrim(char(string(rect_boundary.Value))));
            end
            xi0_edit.Enable = 'on';
            geom.grid.RowHeight = {'fit','fit',0,'fit','fit','fit','fit','fit'};
        elseif is_circ
            circ_boundary.Items = chladni_input_helpers('boundary_items','circ');
            if ~any(strcmp(circ_boundary.Items, circ_boundary.Value)), circ_boundary.Value = 'C'; end
            xi0_edit.Enable = 'off';
            geom.grid.RowHeight = {'fit',0,'fit','fit','fit','fit','fit','fit'};
        else
            circ_boundary.Items = chladni_input_helpers('boundary_items','annulus');
            if ~any(strcmp(circ_boundary.Items, circ_boundary.Value)), circ_boundary.Value = 'CC'; end
            xi0_edit.Enable = 'on';
            geom.grid.RowHeight = {'fit',0,'fit','fit','fit','fit','fit','fit'};
        end
    end

    function update_load_controls()
        lt = char(lower(string(load_type_dd.Value)));
        show_q0 = any(strcmp(lt, {'uniform','mixed'}));
        show_sources = any(strcmp(lt, {'points','mixed'}));
        show_custom = any(strcmp(lt, {'custom','mixed'}));
        q0_edit.Parent.Visible = chladni_input_helpers('onoff', show_q0);
        sources_area.Parent.Visible = chladni_input_helpers('onoff', show_sources);
        custom_area.Parent.Visible = chladni_input_helpers('onoff', show_custom);
        if show_q0, q0_h = 'fit'; else, q0_h = 0; end
        if show_sources, src_h = 86; else, src_h = 0; end
        if show_custom, cust_h = 86; else, cust_h = 0; end
        load_panel.grid.RowHeight = {'fit', q0_h, src_h, cust_h};
        switch lt
            case 'points'
                load_panel.panel.Title = 'static load q(x,y): point/Gaussian sources';
            case 'uniform'
                load_panel.panel.Title = 'static load q(x,y): constant q0';
            case 'custom'
                load_panel.panel.Title = 'static load q(x,y): custom function';
            otherwise
                load_panel.panel.Title = 'static load q(x,y): q0 + sources + custom';
        end
    end

    function refresh_notes()
        ui.set_notes(local_static_notes(type_dd.Value, current_boundary_value(), load_type_dd.Value));
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
        params.n = max(32, round(grid_n.Value));
        params.normalize = true;
        params.D = D_edit.Value;
        params.xi0 = 0;
        params.a = 1.0;
        params.b = 1.0;
        params.load_type = char(lower(string(load_type_dd.Value)));
        params.q0 = 0;
        params.kmodes = max(1, round(truncation.Value));
        params.mmax = max(1, round(truncation.Value));
        params.distribution_samples = max(10, min(42, round(sqrt(max(params.n, 1)))));
        params.draw_zero_contour = false;

        if ~isfinite(params.nu) || params.nu <= 0 || params.nu >= 0.5
            error('nu must be in (0, 0.5).');
        end
        if ~isfinite(params.D) || params.D == 0
            error('D must be finite and nonzero.');
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

        uses_q0 = any(strcmp(params.load_type, {'uniform','mixed'}));
        uses_sources = any(strcmp(params.load_type, {'points','mixed'}));
        uses_custom = any(strcmp(params.load_type, {'custom','mixed'}));
        if uses_q0
            params.q0 = q0_edit.Value;
        end
        if uses_sources
            params.sources = chladni_input_helpers('parse_sources', sources_area);
        end
        if uses_custom
            params.load_function = chladni_input_helpers('load_function_text', custom_area);
        end
    end

    function run_callback()
        params = read_params();
        cache_dir = image_output('clear_cache', project_root, 'static_sources');
        result = compute_static_sources(params);
        png_paths = render_result('render', result, cache_dir, 'Prefix', sprintf('static_%s_%s', params.type, params.boundary));
        stored_paths = image_output('bind_preview_list', ui.preview_list, ui.preview_axes, png_paths);
        state.png_paths = image_output('all_preview_paths', ui.preview_list);
        state.params = params;
        state.runs{end+1} = struct('paths', {stored_paths}, 'params', params);
    end

    function reset_callback()
        type_dd.Value = 'rect';
        rect_boundary.Value = 'SSSS';
        nu_edit.Value = 0.30;
        xi0_edit.Value = 0.45;
        grid_n.Value = 220;
        truncation.Value = 60;
        D_edit.Value = 1.0;
        load_type_dd.Value = 'points';
        q0_edit.Value = 1.0;
        sources_area.Value = {'[0 0 1 0;'; ' 0.45 0.25 -0.6 0.04]'};
        custom_area.Value = {'@(X,Y) exp(-18*((X-0.25).^2 + (Y+0.1).^2))'};
        install_boundary_items();
        update_load_controls();
        refresh_notes();
        state.png_paths = {};
        state.params = struct();
        state.runs = {};
        image_output('bind_preview_list', ui.preview_list, ui.preview_axes, {});
    end

    function export_callback()
        if isempty(state.png_paths)
            error('Generate images before exporting.');
        end
        paths = image_output('selected_preview_paths', ui.preview_list, state.png_paths);
        layout = image_output('preview_layout', ui, 'auto');
        code = strjoin({ ...
            'export_dir = fileparts(mfilename(''fullpath''));', ...
            'project_root = fileparts(fileparts(export_dir));', ...
            'addpath(genpath(project_root));', ...
            params_output('reproduce_code', 'compute_static_sources', state.params)}, newline);
        image_output('export_bundle', project_root, sprintf('static_%s_%s', state.params.type, state.params.boundary), paths, ...
            'Params', state.params, 'ReproduceCode', code, 'Composite', true, 'Layout', layout);
    end
end

function lines = local_static_notes(domain_type, boundary_code, load_type)
lines = { ...
    'This tab solves a static thin-plate response D nabla^4 w = q(x,y).', ...
    sprintf('domain = %s and boundary = %s use the same C/S/F boundary notation as the mode tab.', char(string(domain_type)), char(string(boundary_code))), ...
    sprintf('load type = %s. points uses rows [x y P sigma]; P is force amplitude and sigma is Gaussian width, with sigma=0 for point load.', char(string(load_type))), ...
    'uniform uses q0 as a constant load over the plate. custom uses q(X,Y), a MATLAB expression/function of coordinates.', ...
    'mixed combines q0, point/Gaussian sources, and the custom q(X,Y) expression.', ...
    'nu is Poisson ratio; D is flexural rigidity scale. Changing D rescales amplitudes, not nodal shape after normalization.', ...
    'grid N controls numerical resolution; truncation controls modal/Fourier-Bessel series length.', ...
    'The heatmap is normalized w/w_max. Markers appear only for point or mixed load sources.'};
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
    prefix = sprintf('static_%s_%s', selected_runs{ii}.params.type, selected_runs{ii}.params.boundary);
    lines = [lines; {sprintf('%% Reproduce run %s', suffix); 'params = struct();'}; param_lines(:); ...
        {sprintf('result_%s = compute_static_sources(params);', suffix); ...
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
