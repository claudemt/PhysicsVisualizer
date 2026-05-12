function tab = create_mie_scattering_tab(tab_group, project_root)
app_figure = ancestor(tab_group, 'figure');
defaults = parse_mie_scattering_params('defaults');
custom_items = parse_mie_scattering_params('custom_items');
custom_labels = parse_mie_scattering_params('custom_labels');

ui = create_tab_layout(tab_group, 'mie scattering', project_root, ...
    'Preview', 'list', ...
    'NotesText', local_mie_notes(defaults.geometry), ...
    'NotesFile', fullfile(project_root, 'docs', 'physical_formulas.md'));
ui.control_grid.RowHeight = {'fit','fit','fit'};

phys = create_control_panel(ui.control_grid, 'section', 'physical parameters', 5);
eps_edit = create_control_panel(phys.grid, 'text', 'epsilon_r', defaults.eps1, 'Relative permittivity.');
mu_edit = create_control_panel(phys.grid, 'text', 'mu_r', defaults.mu1, 'Relative permeability.');
R_edit = create_control_panel(phys.grid, 'numeric', 'R/lambda', defaults.R_over_lambda, 'Radius in wavelengths.');
nu_edit = create_control_panel(phys.grid, 'numeric', 'nu', defaults.nu, 'Elliptical-polarization parameter.');
psi_edit = create_control_panel(phys.grid, 'numeric', 'psi', defaults.psi, 'Polarization phase.');

setup = create_control_panel(ui.control_grid, 'section', 'scattering setup', {24,90});
geometry_dd = create_control_panel(setup.grid, 'dropdown', 'geometry', {'sphere','cylinder'}, defaults.geometry, 'Geometry.');
custom_list = create_control_panel(setup.grid, 'listbox', 'fields', custom_labels, custom_labels(1:7), 'Select the field views to generate.');
custom_list.ItemsData = custom_items;
custom_list.Value = defaults.customSelection;

actions = create_control_panel(ui.control_grid, 'section', 'actions', 1);
state = struct('png_paths', {{}}, 'params', struct(), 'runs', {{}});
geometry_dd.ValueChangedFcn = @(~,~) refresh_notes();
custom_list.ValueChangedFcn = @(~,~) refresh_notes();
refresh_notes();
bind_workflow(actions.grid, app_figure, @run_callback, @reset_callback, @export_callback, ...
    'GenerateText', 'Run');

    function refresh_notes()
        ui.set_notes(local_mie_notes(geometry_dd.Value));
    end

    function cfg = read_params()
        cfg = struct();
        cfg.eps1 = parse_mie_scattering_params('str2complex', eps_edit.Value);
        cfg.mu1 = parse_mie_scattering_params('str2complex', mu_edit.Value);
        cfg.R_over_lambda = R_edit.Value;
        cfg.nu = nu_edit.Value;
        cfg.psi = psi_edit.Value;
        cfg.geometry = geometry_dd.Value;
        cfg.mode = 'custom';
        cfg.customSelection = local_resolve_custom_selection(custom_list, custom_items, custom_labels);
        if isempty(cfg.customSelection)
            error('Select at least one field to generate.');
        end
        cfg.gridHalfWidth = defaults.gridHalfWidth;
        cfg.N = defaults.N;
        cfg.nmaxExtra = defaults.nmaxExtra;
        cfg.maskInside = defaults.maskInside;
    end

    function run_callback()
        cfg = read_params();
        cache_dir = image_output('clear_cache', project_root, 'mie_scattering');
        result = compute_mie_scattering(cfg);
        png_paths = render_result('render', result, cache_dir, 'Prefix', 'mie');
        stored_paths = image_output('bind_preview_list', ui.preview_list, ui.preview_axes, png_paths);
        state.png_paths = image_output('all_preview_paths', ui.preview_list);
        state.params = cfg;
        state.runs{end+1} = struct('paths', {stored_paths}, 'params', cfg);
    end

    function reset_callback()
        eps_edit.Value = defaults.eps1;
        mu_edit.Value = defaults.mu1;
        R_edit.Value = defaults.R_over_lambda;
        nu_edit.Value = defaults.nu;
        psi_edit.Value = defaults.psi;
        geometry_dd.Value = defaults.geometry;
        custom_list.Value = defaults.customSelection;
        refresh_notes();
        state.png_paths = {};
        state.runs = {};
        image_output('bind_preview_list', ui.preview_list, ui.preview_axes, {});
    end

    function export_callback()
        if isempty(state.runs)
            error('Run before exporting.');
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
        image_output('export_bundle', project_root, 'mie_scattering', paths, ...
            'Params', params_struct, 'ReproduceCode', code, 'Composite', true, 'Layout', layout);
    end

tab = ui.tab;
end

function lines = local_mie_notes(geometry)
lines = { ...
    'This tab computes electromagnetic Mie scattering from a sphere or infinite cylinder.', ...
    'epsilon_r is relative permittivity of the scatterer; complex values model absorption, e.g. 2.25+0.02i.', ...
    'mu_r is relative permeability. For most optical dielectrics use mu_r = 1.', ...
    'R/lambda is particle radius measured in incident wavelength; larger values require more multipole orders.', ...
    'nu controls polarization ellipticity/amplitude mixing; psi is the polarization phase angle between components.', ...
    sprintf('geometry = %s. Use the field list below to choose exactly which scattered/total components to generate.', char(string(geometry))), ...
    'fields selects the scattered/total field components to generate. The preview list controls final export selection and order.', ...
    'Images show field components or magnitudes on a 2D cut; full coefficient definitions are in Notes.'};
end


function selected = local_resolve_custom_selection(listbox, item_keys, item_labels)
raw = local_cellstr(listbox.Value);
selected = {};
for ii = 1:numel(raw)
    idx = find(strcmp(item_keys, raw{ii}), 1, 'first');
    if isempty(idx)
        idx = find(strcmp(item_labels, raw{ii}), 1, 'first');
    end
    if ~isempty(idx)
        selected{end+1} = item_keys{idx}; %#ok<AGROW>
    end
end
selected = unique(selected, 'stable');
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
    lines = [lines; {sprintf('%% Reproduce run %s', suffix); 'params = struct();'}; param_lines(:); ...
        {sprintf('result_%s = compute_mie_scattering(params);', suffix); ...
         sprintf('run_dir_%s = fullfile(export_dir, ''reproduce_run_%s'');', suffix, suffix); ...
         sprintf('if exist(run_dir_%s, ''dir'') == 7, rmdir(run_dir_%s, ''s''); end', suffix, suffix); ...
         sprintf('mkdir(run_dir_%s);', suffix); ...
         sprintf('run_files_%s = render_result(''render'', result_%s, run_dir_%s, ''Prefix'', ''mie'');', suffix, suffix, suffix); ...
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
lines = { ...
    'export_dir = fileparts(mfilename(''fullpath''));'; ...
    'project_root = fileparts(fileparts(export_dir));'; ...
    'addpath(genpath(project_root));'; ...
    ''};
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
