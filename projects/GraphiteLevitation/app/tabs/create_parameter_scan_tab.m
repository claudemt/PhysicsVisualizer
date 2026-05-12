function tab = create_parameter_scan_tab(tab_group, project_root)
%CREATE_PARAMETER_SCAN_TAB Parameter scan for the four-figure visualization model.

app_figure = ancestor(tab_group, 'figure');
defaults = parse_graphite_levitation_params('defaults');
items = parse_graphite_levitation_params('scan_items');
labels = parse_graphite_levitation_params('scan_labels');

ui = create_tab_layout(tab_group, 'parameter scan', project_root, ...
    'Preview', 'list', ...
    'PreviewListWidth', 330, ...
    'NotesText', local_notes(), ...
    'NotesFile', fullfile(project_root, 'docs', 'physical_formulas.md'));
tab = ui.tab;
try, ui.control_grid.RowHeight = {'fit','fit','fit','fit'}; catch, end

base = create_control_panel(ui.control_grid, 'section', 'baseline', 8);
shape_dd = create_control_panel(base.grid, 'dropdown', 'shape', parse_graphite_levitation_params('shape_items'), defaults.graphite.shape, [], 'Baseline graphite shape.');
radius_edit = create_control_panel(base.grid, 'numeric', 'circle radius R [mm]', defaults.graphite.radius*1e3, [], 'Baseline circle radius.');
side_edit = create_control_panel(base.grid, 'numeric', 'square side [mm]', defaults.graphite.side*1e3, [], 'Baseline square side length.');
z_edit = create_control_panel(base.grid, 'numeric', 'height z0 [mm]', defaults.graphite.z0*1e3, [], 'Baseline height.');
array_size_edit = create_control_panel(base.grid, 'text', 'array size', parse_graphite_levitation_params('format_array_size', defaults), [], 'Use Nx*Ny syntax, e.g. 6*6.');
magnet_size_edit = create_control_panel(base.grid, 'text', 'magnet size [mm]', parse_graphite_levitation_params('format_magnet_size', defaults), [], 'Use a*b*c syntax, e.g. 10*10*10.');
br_edit = create_control_panel(base.grid, 'numeric', 'Br [T]', defaults.magnet.Br, [], 'Baseline remanence proxy.');
laser_dd = create_control_panel(base.grid, 'dropdown', 'laser', {'off','on'}, 'off', [], 'Baseline laser state.');

scan = create_control_panel(ui.control_grid, 'section', 'scan', 3);
param_dd = create_control_panel(scan.grid, 'dropdown', 'parameter', labels, labels{strcmp(items, defaults.scan.parameter)}, [], 'Physical parameter to scan.');
values_edit = create_control_panel(scan.grid, 'text', 'values', '(0,0.05,0.1,0.15)', [], 'Supports 1, (1,1.2,1.5), 1:0.1:2, or linspace(1,2,8). Units follow the selected parameter label.');
metric_dd = create_control_panel(scan.grid, 'dropdown', 'highlight', {'displacement','thetaMag','xMin','yMin','UContrast','barrierX','FcxOverMg'}, 'displacement', [], 'First preview metric.');

actions = create_control_panel(ui.control_grid, 'section', 'actions', 1);
state = struct('png_paths', {{}}, 'params', defaults, 'result', [], 'runs', {{}});
bind_workflow(actions.grid, app_figure, @run_callback, @reset_callback, @export_callback);

    function cfg = read_base_params()
        cfg = parse_graphite_levitation_params('defaults');
        cfg.graphite.shape = shape_dd.Value;
        cfg.graphite.radius = radius_edit.Value * 1e-3;
        cfg.graphite.side = side_edit.Value * 1e-3;
        cfg.graphite.z0 = z_edit.Value * 1e-3;
        nxy = parse_graphite_levitation_params('parse_size_pair', array_size_edit.Value);
        cfg.array.nx = nxy(1); cfg.array.ny = nxy(2);
        abc = parse_graphite_levitation_params('parse_size_triple_mm', magnet_size_edit.Value) * 1e-3;
        cfg.magnet.a = abc(1); cfg.magnet.b = abc(2); cfg.magnet.c = abc(3);
        cfg.magnet.Br = br_edit.Value;
        cfg.laser.enabled = strcmpi(char(string(laser_dd.Value)), 'on');
        cfg = validate_graphite_levitation_params(cfg);
    end

    function run_callback()
        cfg = read_base_params();
        parameter = parse_graphite_levitation_params('normalize_scan_parameter', param_dd.Value);
        parsed = parse_graphite_levitation_params('parse_scan_values', values_edit.Value, parameter);
        cfg.scan.parameter = parameter;
        cfg.scan.values = parsed.si;
        cfg.scan.valuesDisplay = parsed.display;
        cfg.scan.highlightMetric = metric_dd.Value;
        cfg.scan.displayLabel = parse_graphite_levitation_params('scan_display_label', parameter);
        cache_dir = image_output('clear_cache', project_root, 'graphite_parameter_scan');
        result = compute_parameter_scan(cfg);
        png_paths = render_graphite_levitation_result('scan', result, cache_dir, 'Prefix', 'scan');
        stored_paths = image_output('bind_preview_list', ui.preview_list, ui.preview_axes, png_paths);
        state.png_paths = image_output('all_preview_paths', ui.preview_list);
        state.params = cfg;
        state.runs{end+1} = struct('paths', {stored_paths}, 'params', cfg);
        state.result = result;
        ui.set_notes(local_run_notes(result));
    end

    function reset_callback()
        d = parse_graphite_levitation_params('defaults');
        shape_dd.Value = d.graphite.shape;
        radius_edit.Value = d.graphite.radius*1e3;
        side_edit.Value = d.graphite.side*1e3;
        z_edit.Value = d.graphite.z0*1e3;
        array_size_edit.Value = parse_graphite_levitation_params('format_array_size', d);
        magnet_size_edit.Value = parse_graphite_levitation_params('format_magnet_size', d);
        br_edit.Value = d.magnet.Br;
        laser_dd.Value = 'off';
        param_dd.Value = labels{strcmp(items, d.scan.parameter)};
        values_edit.Value = '(0,0.05,0.1,0.15)';
        metric_dd.Value = d.scan.highlightMetric;
        state.png_paths = {};
        state.runs = {};
        image_output('bind_preview_list', ui.preview_list, ui.preview_axes, {});
        ui.set_notes(local_notes());
    end

    function export_callback()
        if isempty(state.runs), error('Run before exporting.'); end
        paths = image_output('selected_preview_paths', ui.preview_list, {});
        layout = image_output('preview_layout', ui, 'auto');
        [selected_runs, refs] = local_collect_selected_runs(state.runs, paths);
        dest_names = cell(1, numel(paths));
        for ii = 1:numel(paths)
            dest_names{ii} = image_output('indexed_name', paths{ii}, ii, '.png');
        end
        code = local_history_reproduce_code(selected_runs, refs, dest_names, layout);
        params_struct = local_history_params(selected_runs, dest_names, layout);
        image_output('export_bundle', project_root, 'graphite_parameter_scan', paths, ...
            'Params', params_struct, 'ReproduceCode', code, 'Composite', true, 'Layout', layout);
    end
end

function lines = local_notes()
lines = { ...
    'Scan one physical parameter and plot measurable quantities from the magnetic-potential map.', ...
    'The values field automatically accepts a single number like 1, tuple syntax like (1,1.2,1.5), colon syntax like 1:0.2:2, or linspace(1,2,8).', ...
    'Units follow the selected parameter label: lengths are entered in mm and |chi| in 1e-6.'};
end

function lines = local_run_notes(result)
lines = { ...
    sprintf('Scanned %s with %d value(s).', result.scan.displayLabel, numel(result.scan.valuesDisplay)), ...
    sprintf('First value = %.4g, last value = %.4g.', result.scan.valuesDisplay(1), result.scan.valuesDisplay(end)), ...
    'Laser-related scans report displacement and tilt automatically. CSV metrics are exported with the image bundle.'};
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
lines = {'export_dir = fileparts(mfilename(''fullpath''));'; 'project_root = fileparts(fileparts(export_dir));'; 'addpath(genpath(project_root));'; ''};
for ii = 1:numel(selected_runs)
    suffix = sprintf('%02d', ii);
    param_lines = local_param_assignment_lines(selected_runs{ii}.params);
    lines = [lines; {sprintf('%% Reproduce run %s', suffix); 'params = struct();'}; param_lines(:); ...
        {sprintf('result_%s = compute_parameter_scan(params);', suffix); ...
         sprintf('run_dir_%s = fullfile(export_dir, ''reproduce_run_%s'');', suffix, suffix); ...
         sprintf('if exist(run_dir_%s, ''dir'') == 7, rmdir(run_dir_%s, ''s''); end', suffix, suffix); ...
         sprintf('mkdir(run_dir_%s);', suffix); ...
         sprintf('run_files_%s = render_graphite_levitation_result(''scan'', result_%s, run_dir_%s, ''Prefix'', ''scan'');', suffix, suffix, suffix); ...
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
