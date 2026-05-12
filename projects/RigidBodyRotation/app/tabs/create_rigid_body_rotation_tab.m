function tab = create_rigid_body_rotation_tab(tab_group, project_root, config)
%CREATE_RIGID_BODY_ROTATION_TAB Rigid-body rotation tab in the shared studio style.
% Static figures are listed in the shared preview list. Videos are exported
% from the display/export section instead of being mixed into the image list.

if nargin < 2 || isempty(project_root)
    project_root = local_project_root();
end
if nargin < 3 || isempty(config)
    config = struct();
end

app = struct();
app.result = [];
app.lastInput = [];
app.png_paths = {};
app.mainName = 'create_rigid_body_rotation_tab';
app.projectRoot = project_root;
app.config = local_merge_config(local_default_config(), config);
app.presets = app.config.presets;
app.fig = ancestor(tab_group, 'figure');

ui = create_tab_layout(tab_group, 'rigid body', project_root, ...
    'Preview', 'list', ...
    'NotesTitle', 'notes', ...
    'NotesText', local_short_notes(), ...
    'NotesFile', fullfile(project_root, 'docs', 'physical_formulas.md'), ...
    'InitialMessage', 'run to generate preview images');
app.ui = ui;

build_controls();
apply_free_preset(app.presets.free(1).name);
apply_fixed_preset(app.presets.fixed(1).name);
toggle_compare_inputs();
update_plot_config();
image_output('bind_preview_list', ui.preview_list, ui.preview_axes, {});

tab = ui.tab;

    function build_controls()
        ui.control_grid.RowHeight = {'1x', 'fit', 'fit'};
        ui.control_grid.RowSpacing = 8;

        motion = create_control_panel(ui.control_grid, 'section', 'parameters', {'1x'});
        app.modeTabs = uitabgroup(motion.grid, 'SelectionChangedFcn', @on_mode_changed);
        app.modeTabs.Layout.Row = 1;
        app.modeTabs.Layout.Column = 1;
        build_free_tab();
        build_fixed_tab();

        display = create_control_panel(ui.control_grid, 'section', 'display / export', 3);
        app.legend2D = create_control_panel(display.grid, 'legend', 'legend 2d', app.config.plot.legendLocation2D);
        app.legend3D = create_control_panel(display.grid, 'legend', 'legend 3d', app.config.plot.legendLocation3D);
        app.outputMode = create_control_panel(display.grid, 'dropdown', 'export mode', {'images','video'}, 'images', ...
            'Run always refreshes image previews. Export mode controls whether Export writes selected images or an animation video.');
        app.legend2D.ValueChangedFcn = @(~,~) update_plot_config();
        app.legend3D.ValueChangedFcn = @(~,~) update_plot_config();

        actions = create_control_panel(ui.control_grid, 'section', 'actions', 1);
        bind_workflow(actions.grid, app.fig, @run_callback, @reset_callback, @export_callback, 'GenerateText', 'Run');

        refresh_mode_notes();
    end

    function build_free_tab()
        app.freeTab = uitab(app.modeTabs, 'Title', 'free rotation');
        g = uigridlayout(app.freeTab, [9, 1]);
        g.RowHeight = {'fit','fit','fit','fit','fit','fit','fit','fit','1x'};
        g.ColumnWidth = {'1x'};
        g.Padding = [8 8 8 8];
        g.RowSpacing = 6;

        app.freePreset = create_control_panel(g, 'dropdown', 'preset', {app.presets.free.name}, app.presets.free(1).name, 'Preset for free Euler rotation.');
        app.freeI = create_control_panel(g, 'text', 'I = [I1 I2 I3]', '', [], 'Principal moments of inertia.');
        app.freeW0 = create_control_panel(g, 'text', 'w0 = [w1 w2 w3]', '', [], 'Initial angular velocity in the body frame.');
        app.freePhi0 = create_control_panel(g, 'text', 'phi0', '', [], 'Initial roll angle used to orient the visual body.');
        app.freeTEnd = create_control_panel(g, 'text', 'tEnd', '', [], 'Simulation end time.');
        app.freeNSamples = create_control_panel(g, 'text', 'nSamples', '', [], 'Number of time samples; must be at least 200.');
        app.freeCompareCheck = create_control_panel(g, 'checkbox', 'multi-IC comparison', false, [], 'Overlay up to five initial conditions.');
        app.freeCompareCheck.ValueChangedFcn = @on_compare_toggle;

        app.freeHelp = uilabel(g, ...
            'Text', 'Compare rows use [w1 w2 w3 phi0]. One row per initial condition; single-case w0 and phi0 are ignored while comparison is on.', ...
            'WordWrap', 'on');
        app.freeHelp.Layout.Row = 8;
        app.freeHelp.Layout.Column = 1;

        app.freeCompareRows = uitextarea(g, 'Value', {'[0.18 2.2 0.05 0]'; '[0.28 1.55 0.32 0.35]'; '[0.10 2.95 -0.22 -0.32]'});
        app.freeCompareRows.Layout.Row = 9;
        app.freeCompareRows.Layout.Column = 1;
        app.freePreset.ValueChangedFcn = @on_preset_changed;
    end

    function build_fixed_tab()
        app.fixedTab = uitab(app.modeTabs, 'Title', 'fixed point');
        g = uigridlayout(app.fixedTab, [12, 1]);
        g.RowHeight = {'fit','fit','fit','fit','fit','fit','fit','fit','fit','fit','fit','1x'};
        g.ColumnWidth = {'1x'};
        g.Padding = [8 8 8 8];
        g.RowSpacing = 6;

        app.fixedPreset = create_control_panel(g, 'dropdown', 'preset', {app.presets.fixed.name}, app.presets.fixed(1).name, 'Preset for a fixed-point rigid body in gravity.');
        app.fixedI = create_control_panel(g, 'text', 'I = [I1 I2 I3]', '', [], 'Principal moments of inertia.');
        app.fixedABody = create_control_panel(g, 'text', 'aBody = [a1 a2 a3]', '', [], 'Center-of-mass vector in the body frame.');
        app.fixedMass = create_control_panel(g, 'text', 'mass', '', [], 'Rigid-body mass.');
        app.fixedG = create_control_panel(g, 'text', 'g', '', [], 'Gravitational acceleration.');
        app.fixedEuler0 = create_control_panel(g, 'text', 'Euler0 = [phi theta psi]', '', [], 'Initial 3-1-3 Euler angles.');
        app.fixedW0 = create_control_panel(g, 'text', 'w0 = [w1 w2 w3]', '', [], 'Initial angular velocity in the body frame.');
        app.fixedTime = create_control_panel(g, 'text', 'tEnd', '', [], 'Simulation end time.');
        app.fixedNSamples = create_control_panel(g, 'text', 'nSamples', '', [], 'Number of time samples; must be at least 200.');
        app.fixedCompareCheck = create_control_panel(g, 'checkbox', 'multi-IC comparison', false, [], 'Overlay up to five initial conditions.');
        app.fixedCompareCheck.ValueChangedFcn = @on_compare_toggle;

        app.fixedHelp = uilabel(g, ...
            'Text', 'Compare rows use [phi theta psi w1 w2 w3]. One row per initial condition; single-case Euler0 and w0 are ignored while comparison is on.', ...
            'WordWrap', 'on');
        app.fixedHelp.Layout.Row = 11;
        app.fixedHelp.Layout.Column = 1;

        app.fixedCompareRows = uitextarea(g, 'Value', {'[0.2 0.95 0.1 0.8 0.1 10]'; '[0.42 1.14 -0.18 1.45 -0.35 9.1]'; '[-0.18 0.78 0.32 0.25 0.46 10.9]'});
        app.fixedCompareRows.Layout.Row = 12;
        app.fixedCompareRows.Layout.Column = 1;
        app.fixedPreset.ValueChangedFcn = @on_preset_changed;
    end

    function on_mode_changed(~, ~)
        refresh_mode_notes();
    end

    function on_compare_toggle(~, ~)
        toggle_compare_inputs();
        refresh_mode_notes();
    end

    function toggle_compare_inputs()
        set_compare_box_state(app.freeCompareRows, app.freeCompareCheck.Value);
        set_compare_box_state(app.fixedCompareRows, app.fixedCompareCheck.Value);
    end

    function set_compare_box_state(boxHandle, isOn)
        if isOn
            boxHandle.Editable = 'on';
            boxHandle.BackgroundColor = [1 1 1];
        else
            boxHandle.Editable = 'off';
            boxHandle.BackgroundColor = [0.94 0.94 0.94];
        end
    end

    function on_preset_changed(src, ~)
        if isequal(src, app.freePreset)
            apply_free_preset(app.freePreset.Value);
        else
            apply_fixed_preset(app.fixedPreset.Value);
        end
        refresh_mode_notes();
    end

    function apply_free_preset(name)
        idx = find(strcmp({app.presets.free.name}, name), 1, 'first');
        if isempty(idx), idx = 1; end
        p = app.presets.free(idx);
        app.freePreset.Value = p.name;
        app.freeI.Value = rigid_common_support('numvec_to_text', p.I);
        app.freeW0.Value = rigid_common_support('numvec_to_text', p.w0);
        app.freePhi0.Value = sprintf('%.12g', p.phi0);
        app.freeTEnd.Value = sprintf('%.12g', p.tEnd);
        app.freeNSamples.Value = sprintf('%d', p.nSamples);
        app.freeCompareRows.Value = format_rows_for_textarea(make_free_compare_rows(p));
    end

    function apply_fixed_preset(name)
        idx = find(strcmp({app.presets.fixed.name}, name), 1, 'first');
        if isempty(idx), idx = 1; end
        p = app.presets.fixed(idx);
        app.fixedPreset.Value = p.name;
        app.fixedI.Value = rigid_common_support('numvec_to_text', p.I);
        app.fixedABody.Value = rigid_common_support('numvec_to_text', p.aBody);
        app.fixedMass.Value = sprintf('%.12g', p.mass);
        app.fixedG.Value = sprintf('%.12g', p.g);
        app.fixedEuler0.Value = rigid_common_support('numvec_to_text', p.euler0);
        app.fixedW0.Value = rigid_common_support('numvec_to_text', p.w0);
        app.fixedTime.Value = sprintf('%.12g', p.tEnd);
        app.fixedNSamples.Value = sprintf('%d', p.nSamples);
        app.fixedCompareRows.Value = format_rows_for_textarea(make_fixed_compare_rows(p));
    end

    function rows = make_free_compare_rows(p)
        rows = [ ...
            p.w0, p.phi0; ...
            p.w0 .* app.config.compareDefaults.free(2).wScale, p.phi0 + app.config.compareDefaults.free(2).phiOffset; ...
            p.w0 .* app.config.compareDefaults.free(3).wScale, p.phi0 + app.config.compareDefaults.free(3).phiOffset];
    end

    function rows = make_fixed_compare_rows(p)
        rows = [ ...
            p.euler0, p.w0; ...
            p.euler0 + app.config.compareDefaults.fixed(2).eulerOffset, p.w0 + app.config.compareDefaults.fixed(2).wOffset; ...
            p.euler0 + app.config.compareDefaults.fixed(3).eulerOffset, p.w0 + app.config.compareDefaults.fixed(3).wOffset];
    end

    function cellLines = format_rows_for_textarea(rows)
        nRows = size(rows, 1);
        cellLines = cell(nRows, 1);
        for ii = 1:nRows
            cellLines{ii} = rigid_common_support('numvec_to_text', rows(ii,:));
        end
    end

    function [modeName, inputData] = gather_input()
        if isequal(app.modeTabs.SelectedTab, app.freeTab)
            modeName = 'free';
            inputData.mode = 'free';
            inputData.I = rigid_common_support('parse_vector', app.freeI.Value, 3, 'I');
            inputData.tEnd = rigid_common_support('parse_scalar', app.freeTEnd.Value, 'tEnd');
            inputData.nSamples = round(rigid_common_support('parse_scalar', app.freeNSamples.Value, 'nSamples'));
            inputData.compareMode = logical(app.freeCompareCheck.Value);
            if inputData.compareMode
                inputData.compareCases = rigid_common_support('parse_case_rows', app.freeCompareRows.Value, 4, 'free compare rows [w1 w2 w3 phi0]');
            else
                inputData.w0 = rigid_common_support('parse_vector', app.freeW0.Value, 3, 'w0');
                inputData.phi0 = rigid_common_support('parse_scalar', app.freePhi0.Value, 'phi0');
            end
        else
            modeName = 'fixed';
            inputData.mode = 'fixed';
            inputData.I = rigid_common_support('parse_vector', app.fixedI.Value, 3, 'I');
            inputData.aBody = rigid_common_support('parse_vector', app.fixedABody.Value, 3, 'aBody');
            inputData.mass = rigid_common_support('parse_scalar', app.fixedMass.Value, 'mass');
            inputData.g = rigid_common_support('parse_scalar', app.fixedG.Value, 'g');
            inputData.tEnd = rigid_common_support('parse_scalar', app.fixedTime.Value, 'tEnd');
            inputData.nSamples = round(rigid_common_support('parse_scalar', app.fixedNSamples.Value, 'nSamples'));
            inputData.compareMode = logical(app.fixedCompareCheck.Value);
            if inputData.compareMode
                inputData.compareCases = rigid_common_support('parse_case_rows', app.fixedCompareRows.Value, 6, 'fixed compare rows [phi theta psi w1 w2 w3]');
            else
                inputData.euler0 = rigid_common_support('parse_vector', app.fixedEuler0.Value, 3, 'Euler0');
                inputData.w0 = rigid_common_support('parse_vector', app.fixedW0.Value, 3, 'w0');
            end
        end

        if inputData.nSamples < 200
            error('nSamples must be at least 200.');
        end
        if inputData.tEnd <= 0
            error('tEnd must be positive.');
        end
    end

    function run_callback()
        update_plot_config();
        [modeName, inputData] = gather_input();
        if isfield(inputData, 'compareMode') && inputData.compareMode
            app.result = rigid_body_solver('compare', inputData);
        elseif strcmp(modeName, 'free')
            app.result = rigid_body_solver('free', inputData);
        else
            app.result = rigid_body_solver('fixed', inputData);
        end
        app.lastInput = inputData;
        app.png_paths = render_static_previews(app.result);
        image_output('bind_preview_list', ui.preview_list, ui.preview_axes, app.png_paths);
        refresh_result_notes();
    end

    function reset_callback()
        apply_free_preset(app.presets.free(1).name);
        apply_fixed_preset(app.presets.fixed(1).name);
        app.freeCompareCheck.Value = false;
        app.fixedCompareCheck.Value = false;
        app.legend2D.Value = app.config.plot.legendLocation2D;
        app.legend3D.Value = app.config.plot.legendLocation3D;
        app.outputMode.Value = 'images';
        toggle_compare_inputs();
        update_plot_config();
        app.result = [];
        app.lastInput = [];
        app.png_paths = {};
        image_output('bind_preview_list', ui.preview_list, ui.preview_axes, {});
        refresh_mode_notes();
    end

    function export_callback()
        if isempty(app.result)
            run_callback();
        end
        if strcmp(app.outputMode.Value, 'video')
            if isfield(app.result, 'isMulti') && app.result.isMulti
                error('Video export is available only for a single initial-condition run. Use export mode = images for multi-IC comparisons.');
            end
            cache_dir = image_output('clear_cache', project_root, 'rigid_body_video');
            video_path = fullfile(cache_dir, 'animation.mp4');
            rigid_common_support('play_animation', [], app.result, true, video_path);
            image_output('export_bundle', project_root, 'rigid_body_video', {video_path}, ...
                'Params', app.lastInput, 'ReproduceCode', local_reproduce_code(app.lastInput, 'video'), ...
                'Composite', false);
            return;
        end

        if isempty(app.png_paths)
            app.png_paths = render_static_previews(app.result);
            image_output('bind_preview_list', ui.preview_list, ui.preview_axes, app.png_paths);
        end
        paths = image_output('selected_preview_paths', ui.preview_list, app.png_paths);
        layout = image_output('preview_layout', ui, 'auto');
        export_params = app.lastInput;
        export_params.legendLocation2D = app.legend2D.Value;
        export_params.legendLocation3D = app.legend3D.Value;
        export_params.previewLayout = layout;
        image_output('export_bundle', project_root, local_module_key(app.result), paths, ...
            'Params', export_params, 'ReproduceCode', local_reproduce_code(export_params, 'images'), ...
            'Composite', true, 'Layout', layout);
    end

    function update_plot_config()
        app.config.plot.legendLocation2D = char(string(app.legend2D.Value));
        app.config.plot.legendLocation3D = char(string(app.legend3D.Value));
        rigid_common_support('set_plot_config', app.config.plot);
    end

    function png_paths = render_static_previews(result)
        update_plot_config();
        cache_dir = image_output('clear_cache', project_root, 'rigid_body_preview');
        names = local_static_names(result);
        png_paths = cell(1, 7);
        cleanup = image_output('hidden_figures'); %#ok<NASGU>
        for k = 1:7
            figSize = app.config.plot.figureSize2D;
            if ismember(k, [2 4 5 6 7])
                figSize = app.config.plot.figureSize3D;
            end
            fig = figure('Color', 'w', 'Position', [80 80 figSize(1) figSize(2)], ...
                'Units', 'pixels', 'PaperPositionMode', 'auto', 'InvertHardcopy', 'off', 'Visible', 'off');
            ax = axes(fig);
            rigid_common_support('style_axes', ax);
            rigid_common_support('render_single_plot', ax, result, k);
            drawnow;
            png_paths{k} = image_output('save_figure', fig, cache_dir, image_output('indexed_name', names{k}, k, '.png'), 220);
            close(fig);
        end
    end

    function refresh_mode_notes()
        if isequal(app.modeTabs.SelectedTab, app.freeTab)
            ui.set_notes(local_mode_notes('free', app.freeCompareCheck.Value));
        else
            ui.set_notes(local_mode_notes('fixed', app.fixedCompareCheck.Value));
        end
    end

    function refresh_result_notes()
        if isempty(app.result)
            refresh_mode_notes();
            return;
        end
        lines = local_mode_notes(app.lastInput.mode, isfield(app.lastInput, 'compareMode') && app.lastInput.compareMode);
        lines{end+1} = '';
        if isfield(app.result, 'isMulti') && app.result.isMulti
            lines{end+1} = sprintf('Generated %d image previews for %d comparison cases. Select one or more images in the list, reorder them, then use Preview/Export for composite output.', numel(app.png_paths), app.result.nCases);
        else
            lines{end+1} = sprintf('Generated %d image previews. For animation output choose export mode = video, then Export.', numel(app.png_paths));
        end
        ui.set_notes(lines);
    end
end

function txt = local_short_notes()
txt = { ...
    'Rigid-body rotation studio for Euler top and fixed-point heavy-top motion.', ...
    'Use free rotation for torque-free Euler equations; use fixed point for gravity torque about a support.', ...
    'The parameter tabs expose inertia, angular velocity, Euler angles, mass, gravity, center of mass, and time sampling.', ...
    'Run always refreshes static image previews. Export mode chooses selected images or a single-case animation video.', ...
    'Open Notes for Euler equations, angular momentum, energy, and Euler-angle conventions.'};
end

function lines = local_mode_notes(modeName, compareMode)
if nargin < 2, compareMode = false; end
switch lower(char(string(modeName)))
    case 'free'
        lines = { ...
            'Free rotation solves Euler equations with no external torque.', ...
            'I = [I1 I2 I3] are principal moments of inertia in the body frame.', ...
            'w0 = [w1 w2 w3] is initial angular velocity in the body frame.', ...
            'phi0 is an initial visual roll angle for orienting the rendered body.', ...
            'tEnd is simulation duration; nSamples is number of time samples.', ...
            'multi-IC comparison overlays several initial angular-velocity rows [w1 w2 w3 phi0].'};
    otherwise
        lines = { ...
            'Fixed-point mode solves a heavy rigid body with one support point under gravity.', ...
            'I = [I1 I2 I3] are principal moments; aBody is center-of-mass vector in body coordinates.', ...
            'mass and g set gravitational torque. Euler0 = [phi theta psi] uses 3-1-3 Euler angles.', ...
            'w0 is body-frame angular velocity. tEnd and nSamples control integration time grid.', ...
            'multi-IC comparison rows are [phi theta psi w1 w2 w3].'};
end
if compareMode
    lines{end+1} = 'Comparison mode exports overlaid images only; video export is disabled because multiple trajectories are shown.';
else
    lines{end+1} = 'Single-case runs can export selected images or an animation video.';
end
end

function names = local_static_names(result)
if isfield(result, 'isMulti') && result.isMulti
    prefix = ['cmp_' result.baseMode '_'];
else
    prefix = [result.mode '_'];
end
labels = {'wt_lab','w_phase_lab','wt_body','w_phase_body','L_body','w_L_body','axis_tips_lab'};
names = cellfun(@(s) image_output('slug', [prefix s]), labels, 'UniformOutput', false);
end

function key = local_module_key(result)
if isfield(result, 'isMulti') && result.isMulti
    key = ['rigid_' result.baseMode '_comparison'];
else
    key = ['rigid_' result.mode '_rotation'];
end
end

function code = local_reproduce_code(params, outputMode)
if nargin < 2, outputMode = 'images'; end
lines = [ ...
    {'export_dir = fileparts(mfilename(''fullpath''));'; ...
     'project_root = fileparts(fileparts(export_dir));'; ...
     'addpath(genpath(project_root));'; ...
     'params = struct();'}; ...
    local_assignment_lines('params', params); ...
    {sprintf('output_mode = ''%s'';', char(string(outputMode))); ...
     '% Re-run through the GUI tab or call rigid_body_solver with params.mode / params.compareMode.'}];
code = strjoin(lines, newline);
end

function lines = local_assignment_lines(prefix, s)
lines = {};
if isempty(s), return; end
if isstruct(s)
    names = fieldnames(s);
    for i = 1:numel(names)
        key = names{i};
        val = s.(key);
        name = [prefix '.' key];
        if isstruct(val) && isscalar(val)
            lines = [lines; local_assignment_lines(name, val)]; %#ok<AGROW>
        else
            lines{end+1,1} = sprintf('%s = %s;', name, local_matlab_literal(val)); %#ok<AGROW>
        end
    end
end
end

function lit = local_matlab_literal(v)
if isnumeric(v) || islogical(v)
    lit = mat2str(v);
elseif ischar(v)
    lit = ['''' strrep(v, '''', '''''') ''''];
elseif isstring(v)
    lit = ['''' strrep(char(v), '''', '''''') ''''];
elseif iscell(v)
    parts = cellfun(@local_matlab_literal, v, 'UniformOutput', false);
    lit = ['{' strjoin(parts(:).', ', ') '}'];
else
    lit = ['''' strrep(char(string(v)), '''', '''''') ''''];
end
end

function projectRoot = local_project_root()
here = fileparts(mfilename('fullpath'));
projectRoot = fileparts(fileparts(here));
end

function cfg = local_default_config()
cfg = struct();
cfg.presets = rigid_common_support('defaults');
cfg.plot = struct( ...
    'w3ScaleTriggerRatio', 3.5, ...
    'animationOmegaScaleTriggerNorm', 5.0, ...
    'figureSize2D', [900 660], ...
    'figureSize3D', [900 700], ...
    'legendLocation2D', 'northeast', ...
    'legendLocation3D', 'northeast');
cfg.compareDefaults = struct();
cfg.compareDefaults.free(1) = struct('wScale', [1 1 1], 'phiOffset', 0.00);
cfg.compareDefaults.free(2) = struct('wScale', [1.55 0.72 2.60], 'phiOffset', 0.35);
cfg.compareDefaults.free(3) = struct('wScale', [0.55 1.34 -1.80], 'phiOffset', -0.32);
cfg.compareDefaults.fixed(1) = struct('eulerOffset', [0 0 0], 'wOffset', [0 0 0]);
cfg.compareDefaults.fixed(2) = struct('eulerOffset', [0.22 0.14 -0.28], 'wOffset', [0.65 -0.45 -0.90]);
cfg.compareDefaults.fixed(3) = struct('eulerOffset', [-0.38 -0.17 0.22], 'wOffset', [-0.55 0.36 0.90]);
end

function out = local_merge_config(base, override)
out = base;
if nargin < 2 || ~isstruct(override) || isempty(fieldnames(override))
    return;
end
fn = fieldnames(override);
for ii = 1:numel(fn)
    key = fn{ii};
    val = override.(key);
    if isfield(out, key) && isstruct(out.(key)) && isstruct(val)
        out.(key) = local_merge_config(out.(key), val);
    else
        out.(key) = val;
    end
end
end
