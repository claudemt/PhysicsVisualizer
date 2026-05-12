function tab = create_moving_charge_tab(tab_group, project_root)
app_figure = ancestor(tab_group, 'figure');
defaults = run_moving_charge_generation('defaults');

ui = create_tab_layout(tab_group, 'moving charge', project_root, ...
    'Preview', 'list', ...
    'NotesText', local_notes(defaults.customFields), ...
    'NotesFile', fullfile(project_root, 'docs', 'physical_formulas.md'));

ui.control_grid.RowHeight = {'fit','fit','fit'};

motion_list = {'circular','harmonic'};
slice_list = {'xy','xz','yz'};
part_list = {'tot','vel','rad'};
field_items = {'E_in','E_n','E_mag','B_in','B_n','B_mag','S_stream','tau','E_stream','B_stream'};
field_labels = {'E in-plane','E normal','E magnitude','B in-plane','B normal','B magnitude','Poynting stream','retarded time','E stream','B stream'};
default_custom = defaults.customFields;
if isempty(default_custom)
    default_custom = {'E_in','E_n','E_mag','B_in','B_n','B_mag'};
end
default_labels = local_field_labels(default_custom, field_items, field_labels);

physical = create_control_panel(ui.control_grid, 'section', 'physical parameters', 7);
motion_dd = create_control_panel(physical.grid, 'dropdown', 'motion', motion_list, defaults.motionType, 'Particle trajectory.');
slice_dd = create_control_panel(physical.grid, 'dropdown', 'slice', slice_list, defaults.sliceType, 'Rendered slice plane.');
part_dd = create_control_panel(physical.grid, 'dropdown', 'field part', part_list, defaults.partType, 'Total, velocity, or radiation part.');
a_edit = create_control_panel(physical.grid, 'numeric', 'a/lambda', defaults.a_over_lambda, 'Orbit or oscillation amplitude over wavelength.');
beta_edit = create_control_panel(physical.grid, 'numeric', 'beta max', defaults.beta_max, 'Peak speed ratio, 0 < beta < 1.');
pos_edit = create_control_panel(physical.grid, 'numeric', 'slice position/lambda', defaults.slicePos_over_lambda, 'Position along the slice normal.');
phase_edit = create_control_panel(physical.grid, 'numeric', 'phase t/T', defaults.phase_over_T, 'Observation phase.');

display = create_control_panel(ui.control_grid, 'section', 'custom output', {24, 118});
mode_dd = create_control_panel(display.grid, 'dropdown', 'output mode', {'image','video'}, defaults.outputMode, 'Export selected still images or videos.');
custom_list = create_control_panel(display.grid, 'listbox', 'fields', field_labels, default_labels, ...
    'Select the field views to generate. Still-image Export uses the preview-list selection and layout, like Mie scattering.');
custom_list.ItemsData = field_items;
custom_list.Value = default_custom;

actions = create_control_panel(ui.control_grid, 'section', 'actions', 1);
state = struct('png_paths', {{}}, 'params', struct(), 'runs', {{}});
custom_list.ValueChangedFcn = @(~,~) refresh_notes();
refresh_notes();
bind_workflow(actions.grid, app_figure, @run_callback, @reset_callback, @export_callback, ...
    'GenerateText', 'Run');

    function refresh_notes()
        ui.set_notes(local_notes(local_cellstr(custom_list.Value)));
    end

    function params = read_params()
        selected = local_selected_fields(custom_list, field_items, field_labels);
        if isempty(selected)
            error('Select at least one custom field to generate.');
        end
        params = struct();
        params.motionType = motion_dd.Value;
        params.sliceType = slice_dd.Value;
        params.partType = part_dd.Value;
        params.fieldType = selected{1};
        params.a_over_lambda = a_edit.Value;
        params.beta_max = beta_edit.Value;
        params.slicePos_over_lambda = pos_edit.Value;
        params.phase_over_T = phase_edit.Value;
        params.cmapMode = 'log';
        params.outputMode = mode_dd.Value;
        params.exportAllFields = false;
        params.viewMode = 'custom';
        params.customFields = selected;
        params.selectedFields = selected;
        params = run_moving_charge_generation('normalize', params);
    end

    function run_callback()
        params = read_params();
        preview_params = params;
        preview_params.outputMode = 'image';
        result = run_moving_charge_generation('generate', preview_params, project_root);
        stored_paths = image_output('bind_preview_list', ui.preview_list, ui.preview_axes, result.files);
        state.png_paths = image_output('all_preview_paths', ui.preview_list);
        state.params = params;
        state.runs{end+1} = struct('paths', {stored_paths}, 'params', preview_params);
        refresh_notes();
    end

    function reset_callback()
        motion_dd.Value = defaults.motionType;
        slice_dd.Value = defaults.sliceType;
        part_dd.Value = defaults.partType;
        a_edit.Value = defaults.a_over_lambda;
        beta_edit.Value = defaults.beta_max;
        pos_edit.Value = defaults.slicePos_over_lambda;
        phase_edit.Value = defaults.phase_over_T;
        mode_dd.Value = defaults.outputMode;
        custom_list.Value = default_custom;
        state.png_paths = {};
        state.params = struct();
        state.runs = {};
        image_output('bind_preview_list', ui.preview_list, ui.preview_axes, {});
        refresh_notes();
    end

    function export_callback()
        params = read_params();
        if strcmp(params.outputMode, 'video')
            run_moving_charge_generation('export', params, project_root);
            return;
        end

        if isempty(state.runs)
            preview_params = params;
            preview_params.outputMode = 'image';
            result = run_moving_charge_generation('generate', preview_params, project_root);
            stored_paths = image_output('bind_preview_list', ui.preview_list, ui.preview_axes, result.files);
            state.png_paths = image_output('all_preview_paths', ui.preview_list);
            state.params = params;
            state.runs{end+1} = struct('paths', {stored_paths}, 'params', preview_params);
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
        image_output('export_bundle', project_root, 'moving_charge', paths, ...
            'Params', params_struct, 'ReproduceCode', code, ...
            'Composite', true, 'Layout', layout);
    end

tab = ui.tab;
end

function lines = local_notes(custom_fields)
if nargin < 1, custom_fields = {}; end
lines = { ...
    'This tab visualizes Lienard-Wiechert fields from a moving point charge.', ...
    'motion: circular means charge moves on a circle; harmonic means one-dimensional oscillation.', ...
    'slice chooses the observation plane: xy, xz, or yz. slice position/lambda shifts that plane along its normal.', ...
    'field part: tot is full field, vel is the velocity/Coulomb-like term, rad is the radiation/acceleration term.', ...
    'a/lambda is orbit radius or oscillation amplitude in wavelengths. beta max is maximum v/c and must stay below 1.', ...
    'phase t/T is the observation time within one period; 0.25 means quarter period.', ...
    sprintf('Selected fields: %s. E_in/B_in are in-plane magnitudes; E_n/B_n are normal components; tau is retarded delay.', strjoin(custom_fields, ', ')), ...
    'For images, Run fills the preview list. Select/reorder images there before Preview or Export. For video, one movie is exported per selected field.'};
end

function labels = local_field_labels(keys, all_keys, all_labels)
keys = local_cellstr(keys);
labels = {};
for ii = 1:numel(keys)
    idx = find(strcmp(all_keys, keys{ii}), 1, 'first');
    if ~isempty(idx)
        labels{end+1} = all_labels{idx}; %#ok<AGROW>
    end
end
if isempty(labels)
    labels = all_labels(1:min(6, numel(all_labels)));
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

function code = local_reproduce_code(params)
assignment = params_output('reproduce_code', 'unused_function', params);
parts = splitlines(assignment);
if numel(parts) >= 2
    param_lines = parts(1:end-1);
else
    param_lines = {'params = struct();'};
end
lines = [ ...
    {'export_dir = fileparts(mfilename(''fullpath''));'; ...
     'project_root = fileparts(fileparts(export_dir));'; ...
     'addpath(genpath(project_root));'}; ...
     param_lines(:); ...
    {'run_moving_charge_generation(''export'', params, project_root);'}];
code = strjoin(lines, newline);
end


function selected = local_selected_fields(listbox, field_items, field_labels)
raw = local_cellstr(listbox.Value);
selected = {};
for ii = 1:numel(raw)
    idx = find(strcmp(field_items, raw{ii}), 1, 'first');
    if isempty(idx)
        idx = find(strcmp(field_labels, raw{ii}), 1, 'first');
    end
    if ~isempty(idx)
        selected{end+1} = field_items{idx}; %#ok<AGROW>
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
        {sprintf('params.outputMode = ''image'';'); ...
         sprintf('result_%s = run_moving_charge_generation(''generate'', params, project_root);', suffix); ...
         sprintf('run_files_%s = result_%s.files;', suffix, suffix); ...
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

function s = local_quote(txt)
s = ['''' strrep(char(string(txt)), '''', '''''') ''''];
end
