function rigid_body_rotation(config)
%RIGID_BODY_ROTATION GUI for rigid-body rotation demos.
% Modes:
%   1) free rotation
%   2) fixed-point motion in gravity
% The GUI now supports either a single initial condition or a multi-IC
% comparison run with up to five initial-condition sets.

    app = struct();
    app.result = [];
    app.lastInput = [];
    app.mainName = 'rigid_body_rotation';
    app.mainDir = fileparts(which(app.mainName));
    if isempty(app.mainDir)
        app.mainDir = fileparts(mfilename('fullpath'));
    end
    if nargin < 1 || isempty(config)
        config = struct();
    end
    app.config = local_merge_config(local_default_config(), config);
    rigid_common_support('set_plot_config', app.config.plot);
    app.outputRootDefault = fullfile(app.mainDir, [app.mainName '_output']);
    app.presets = app.config.presets;

    build_ui();
    apply_free_preset(app.presets.free(1).name);
    apply_fixed_preset(app.presets.fixed(1).name);
    toggle_compare_inputs();
    refresh_play_availability();
    write_log('Ready. Choose a mode, edit parameters, then click Run.');

    function build_ui()
        scr = get(groot, 'ScreenSize');
        figW = min(1320, max(980, scr(3) - 80));
        figH = min(860, max(660, scr(4) - 110));
        figW = min(figW, scr(3) - 40);
        figH = min(figH, scr(4) - 60);
        figX = max(20, round((scr(3) - figW) / 2));
        figY = max(20, round((scr(4) - figH) / 2));
        app.fig = uifigure( ...
            'Name', 'Rigid Body Rotation Explorer', ...
            'Position', [figX, figY, figW, figH], ...
            'AutoResizeChildren', 'off', ...
            'Color', [0.97 0.97 0.97]);
        app.fig.SizeChangedFcn = @on_resize;

        app.mainGrid = uigridlayout(app.fig, [1, 2]);
        app.mainGrid.Padding = [10 10 10 10];
        app.mainGrid.ColumnSpacing = 10;
        app.mainGrid.RowSpacing = 10;
        app.mainGrid.ColumnWidth = {390, '1x'};
        app.mainGrid.RowHeight = {'1x'};

        app.ctrlPanel = uipanel(app.mainGrid, 'Title', 'Controls', 'FontWeight', 'bold');
        app.ctrlPanel.Layout.Row = 1;
        app.ctrlPanel.Layout.Column = 1;

        app.previewPanel = uipanel(app.mainGrid, 'Title', 'Preview', 'FontWeight', 'bold');
        app.previewPanel.Layout.Row = 1;
        app.previewPanel.Layout.Column = 2;

        ctrlGrid = uigridlayout(app.ctrlPanel, [6, 1]);
        ctrlGrid.RowHeight = {'fit', 410, 'fit', 'fit', 'fit', '1x'};
        ctrlGrid.ColumnWidth = {'1x'};
        ctrlGrid.Padding = [10 10 10 10];
        ctrlGrid.RowSpacing = 8;

        app.infoLabel = uilabel(ctrlGrid, ...
            'Text', 'Single-case mode and multi-IC comparison mode are both available. Comparison mode overlays up to five initial-condition sets.', ...
            'WordWrap', 'on', ...
            'FontSize', 13);
        app.infoLabel.Layout.Row = 1;

        app.modeTabs = uitabgroup(ctrlGrid, 'SelectionChangedFcn', @on_mode_changed);
        app.modeTabs.Layout.Row = 2;

        build_free_tab();
        build_fixed_tab();
        build_output_box(ctrlGrid);
        build_button_row(ctrlGrid);
        build_log_box(ctrlGrid);

        previewGrid = uigridlayout(app.previewPanel, [1, 1]);
        previewGrid.RowHeight = {'1x'};
        previewGrid.ColumnWidth = {'1x'};
        previewGrid.Padding = [6 6 6 6];

        app.previewTabs = uitabgroup(previewGrid);
        app.previewTabs.Layout.Row = 1;
        app.previewTabs.Layout.Column = 1;

        tabNames = {'w(t)-lab', 'w(p)-lab', 'w(t)-body', 'w(p)-body', 'L(p)-body', 'w&L(p)-body', 'axis(p)-lab', 'Animation'};
        tabTitles = { ...
            '$\omega(t)$ in lab frame', ...
            '$\omega$ in lab frame', ...
            '$\omega(t)$ in body frame', ...
            '$\omega$ in body frame', ...
            '$L$ in body frame', ...
            '$\omega$ and $L$ in body frame', ...
            'Axis tips in lab frame', ...
            'Animation'};

        app.axes = cell(8,1);
        app.tabs = gobjects(8,1);
        for k = 1:8
            app.tabs(k) = uitab(app.previewTabs, 'Title', tabNames{k});
            tg = uigridlayout(app.tabs(k), [1 1]);
            tg.Padding = [6 6 6 6];
            app.axes{k} = uiaxes(tg);
            app.axes{k}.Layout.Row = 1;
            app.axes{k}.Layout.Column = 1;
            rigid_common_support('style_axes', app.axes{k});
            title(app.axes{k}, tabTitles{k}, 'Interpreter', 'latex');
        end
        rigid_common_support('set_empty_animation_axes', app.axes{8}, 'Run a simulation, then click Play.');
        on_mode_changed();
        on_resize();
    end

    function build_free_tab()
        app.freeTab = uitab(app.modeTabs, 'Title', 'Free rotation');
        g = uigridlayout(app.freeTab, [9, 2]);
        g.RowHeight = {'fit','fit','fit','fit','fit','fit','fit','fit','1x'};
        g.ColumnWidth = {165,'1x'};
        g.Padding = [8 8 8 8];
        g.RowSpacing = 6;

        add_label(g, 1, 'Preset');
        app.freePreset = uidropdown(g, 'Items', {app.presets.free.name}, 'ValueChangedFcn', @on_preset_changed);
        app.freePreset.Layout.Row = 1; app.freePreset.Layout.Column = 2;

        add_label(g, 2, 'I = [I1 I2 I3]');
        app.freeI = uieditfield(g, 'text');
        app.freeI.Layout.Row = 2; app.freeI.Layout.Column = 2;

        add_label(g, 3, 'w0 = [w1 w2 w3]');
        app.freeW0 = uieditfield(g, 'text');
        app.freeW0.Layout.Row = 3; app.freeW0.Layout.Column = 2;

        add_label(g, 4, 'phi0');
        app.freePhi0 = uieditfield(g, 'text');
        app.freePhi0.Layout.Row = 4; app.freePhi0.Layout.Column = 2;

        add_label(g, 5, 'tEnd');
        app.freeTEnd = uieditfield(g, 'text');
        app.freeTEnd.Layout.Row = 5; app.freeTEnd.Layout.Column = 2;

        add_label(g, 6, 'nSamples');
        app.freeNSamples = uieditfield(g, 'text');
        app.freeNSamples.Layout.Row = 6; app.freeNSamples.Layout.Column = 2;

        app.freeCompareCheck = uicheckbox(g, ...
            'Text', 'Enable multi-IC comparison (up to 5 rows)', ...
            'ValueChangedFcn', @on_compare_toggle);
        app.freeCompareCheck.Layout.Row = 7;
        app.freeCompareCheck.Layout.Column = [1 2];
        app.freeCompareCheck.FontWeight = 'bold';

        app.freeHelp = uilabel(g, ...
            'Text', ['Compare-row format: [w1 w2 w3 phi0].' ...
                     '''One row per initial condition, single-case params ignored. ' ], ...
            'WordWrap', 'on');
        app.freeHelp.Layout.Row = 8; app.freeHelp.Layout.Column = [1 2];

        app.freeCompareRows = uitextarea(g, 'Value', {'[0.18 2.2 0.05 0]'; '[0.28 1.55 0.32 0.35]'; '[0.10 2.95 -0.22 -0.32]'});
        app.freeCompareRows.Layout.Row = 9; app.freeCompareRows.Layout.Column = [1 2];
    end

    function build_fixed_tab()
        app.fixedTab = uitab(app.modeTabs, 'Title', 'Fixed point in gravity');
        g = uigridlayout(app.fixedTab, [11, 2]);
        g.RowHeight = {'fit','fit','fit','fit','fit','fit','fit','fit','fit','fit','1x'};
        g.ColumnWidth = {165,'1x'};
        g.Padding = [8 8 8 8];
        g.RowSpacing = 6;

        add_label(g, 1, 'Preset');
        app.fixedPreset = uidropdown(g, 'Items', {app.presets.fixed.name}, 'ValueChangedFcn', @on_preset_changed);
        app.fixedPreset.Layout.Row = 1; app.fixedPreset.Layout.Column = 2;

        add_label(g, 2, 'I = [I1 I2 I3]');
        app.fixedI = uieditfield(g, 'text');
        app.fixedI.Layout.Row = 2; app.fixedI.Layout.Column = 2;

        add_label(g, 3, 'aBody = [a1 a2 a3]');
        app.fixedABody = uieditfield(g, 'text');
        app.fixedABody.Layout.Row = 3; app.fixedABody.Layout.Column = 2;

        add_label(g, 4, 'mass');
        app.fixedMass = uieditfield(g, 'text');
        app.fixedMass.Layout.Row = 4; app.fixedMass.Layout.Column = 2;

        add_label(g, 5, 'g');
        app.fixedG = uieditfield(g, 'text');
        app.fixedG.Layout.Row = 5; app.fixedG.Layout.Column = 2;

        add_label(g, 6, 'Euler0 = [phi theta psi]');
        app.fixedEuler0 = uieditfield(g, 'text');
        app.fixedEuler0.Layout.Row = 6; app.fixedEuler0.Layout.Column = 2;

        add_label(g, 7, 'w0 = [w1 w2 w3]');
        app.fixedW0 = uieditfield(g, 'text');
        app.fixedW0.Layout.Row = 7; app.fixedW0.Layout.Column = 2;

        add_label(g, 8, '[tEnd nSamples]');
        app.fixedTime = uieditfield(g, 'text');
        app.fixedTime.Layout.Row = 8; app.fixedTime.Layout.Column = 2;

        app.fixedCompareCheck = uicheckbox(g, ...
            'Text', 'Enable multi-IC comparison (up to 5 rows)', ...
            'ValueChangedFcn', @on_compare_toggle);
        app.fixedCompareCheck.Layout.Row = 9;
        app.fixedCompareCheck.Layout.Column = [1 2];
        app.fixedCompareCheck.FontWeight = 'bold';

        app.fixedHelp = uilabel(g, ...
            'Text', ['Compare-row format: [phi theta psi w1 w2 w3].' ...
                     '''One row per initial condition, single-case params ignored.'], ...
            'WordWrap', 'on');
        app.fixedHelp.Layout.Row = 10; app.fixedHelp.Layout.Column = [1 2];

        app.fixedCompareRows = uitextarea(g, 'Value', {'[0.2 0.95 0.1 0.8 0.1 10]'; '[0.42 1.14 -0.18 1.45 -0.35 9.1]'; '[-0.18 0.78 0.32 0.25 0.46 10.9]'});
        app.fixedCompareRows.Layout.Row = 11; app.fixedCompareRows.Layout.Column = [1 2];
    end

    function build_output_box(parent)
        pnl = uipanel(parent, 'Title', 'Output');
        pnl.Layout.Row = 3;
        g = uigridlayout(pnl, [2, 1]);
        g.RowHeight = {'fit', 'fit'};
        g.ColumnWidth = {'1x'};
        g.Padding = [8 8 8 8];

        app.outputRoot = uieditfield(g, 'text', 'Value', app.outputRootDefault, 'Editable', 'off');
        app.outputRoot.Layout.Row = 1;
    end

    function build_button_row(parent)
        g = uigridlayout(parent, [1, 4]);
        g.Layout.Row = 4;
        g.ColumnWidth = {'1x','1x','1x','1x'};
        g.ColumnSpacing = 8;
        app.runBtn = uibutton(g, 'Text', 'Run', 'ButtonPushedFcn', @on_run);
        app.exportBtn = uibutton(g, 'Text', 'Export', 'ButtonPushedFcn', @on_export);
        app.playBtn = uibutton(g, 'Text', 'Play', 'ButtonPushedFcn', @on_play);
        app.clearBtn = uibutton(g, 'Text', 'Clear', 'ButtonPushedFcn', @on_clear);
    end

    function build_log_box(parent)
        app.logBox = uitextarea(parent, 'Editable', 'off');
        app.logBox.Layout.Row = 6;
        app.logBox.Value = {'Ready.'};
    end

    function add_label(parent, row, str)
        lbl = uilabel(parent, 'Text', str);
        lbl.Layout.Row = row;
        lbl.Layout.Column = 1;
        lbl.FontWeight = 'bold';
    end

    function on_resize(~, ~)
        figPos = app.fig.Position;
        if figPos(3) < 1160
            app.mainGrid.RowHeight = {360, '1x'};
            app.mainGrid.ColumnWidth = {'1x'};
            app.ctrlPanel.Layout.Row = 1; app.ctrlPanel.Layout.Column = 1;
            app.previewPanel.Layout.Row = 2; app.previewPanel.Layout.Column = 1;
        else
            app.mainGrid.RowHeight = {'1x'};
            app.mainGrid.ColumnWidth = {390, '1x'};
            app.ctrlPanel.Layout.Row = 1; app.ctrlPanel.Layout.Column = 1;
            app.previewPanel.Layout.Row = 1; app.previewPanel.Layout.Column = 2;
        end
    end

    function on_mode_changed(~, ~)
        if isequal(app.modeTabs.SelectedTab, app.freeTab)
            app.infoLabel.Text = 'Mode 1: free rotation.';
        else
            app.infoLabel.Text = 'Mode 2: fixed-point motion in gravity.';
        end
        refresh_play_availability();
    end

    function on_compare_toggle(~, ~)
        toggle_compare_inputs();
        refresh_play_availability();
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

    function refresh_play_availability()
        disablePlay = false;
        if isequal(app.modeTabs.SelectedTab, app.freeTab)
            disablePlay = logical(app.freeCompareCheck.Value);
        elseif isequal(app.modeTabs.SelectedTab, app.fixedTab)
            disablePlay = logical(app.fixedCompareCheck.Value);
        end
        if disablePlay
            app.playBtn.Enable = 'off';
        else
            app.playBtn.Enable = 'on';
        end
    end

    function on_preset_changed(src, ~)
        if isequal(src, app.freePreset)
            apply_free_preset(app.freePreset.Value);
        else
            apply_fixed_preset(app.fixedPreset.Value);
        end
    end

    function apply_free_preset(name)
        idx = find(strcmp({app.presets.free.name}, name), 1, 'first');
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
        p = app.presets.fixed(idx);
        app.fixedPreset.Value = p.name;
        app.fixedI.Value = rigid_common_support('numvec_to_text', p.I);
        app.fixedABody.Value = rigid_common_support('numvec_to_text', p.aBody);
        app.fixedMass.Value = sprintf('%.12g', p.mass);
        app.fixedG.Value = sprintf('%.12g', p.g);
        app.fixedEuler0.Value = rigid_common_support('numvec_to_text', p.euler0);
        app.fixedW0.Value = rigid_common_support('numvec_to_text', p.w0);
        app.fixedTime.Value = rigid_common_support('numvec_to_text', [p.tEnd p.nSamples]);
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
            tmp = rigid_common_support('parse_vector', app.fixedTime.Value, 2, '[tEnd nSamples]');
            inputData.tEnd = tmp(1);
            inputData.nSamples = round(tmp(2));
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

    function on_run(~, ~)
        try
            local_reset_preview_axes();
            app.result = [];
            app.lastInput = [];
            drawnow limitrate nocallbacks;
            [modeName, inputData] = gather_input();
            if isfield(inputData, 'compareMode') && inputData.compareMode
                app.result = rigid_multi_compare(inputData);
            else
                if strcmp(modeName, 'free')
                    app.result = rigid_free_motion(inputData);
                else
                    app.result = rigid_fixed_rotation(inputData);
                end
            end
            app.lastInput = inputData;
            rigid_common_support('render_preview', app.axes, app.result);
            app.previewTabs.SelectedTab = app.tabs(1);
            if isfield(app.result, 'isMulti') && app.result.isMulti
                app.playBtn.Enable = 'off';
                write_log(sprintf('Run finished: %s multi-IC comparison, %d cases, %d samples each.', app.result.baseMode, app.result.nCases, numel(app.result.t)));
            else
                refresh_play_availability();
                write_log(sprintf('Run finished: %s mode, %d samples.', app.result.mode, numel(app.result.t)));
            end
        catch ME
            write_log(['Run failed: ' ME.message]);
            uialert(app.fig, ME.message, 'Run error');
        end
    end

    function on_export(~, ~)
        try
            if isempty(app.result)
                error('No result is available. Click Run first.');
            end
            outDir = rigid_common_support('export_outputs', app.result, app.lastInput, app.outputRoot.Value, app.mainName);
            write_log(['Export complete: ' outDir]);
        catch ME
            write_log(['Export failed: ' ME.message]);
            uialert(app.fig, ME.message, 'Export error');
        end
    end

    function on_play(~, ~)
        try
            if isempty(app.result)
                error('No result is available. Click Run first.');
            end
            if isfield(app.result, 'isMulti') && app.result.isMulti
                rigid_common_support('set_empty_animation_axes', app.axes{8}, 'Animation is disabled in multi-IC comparison mode.');
                app.previewTabs.SelectedTab = app.tabs(8);
                write_log('Animation disabled in multi-IC comparison mode.');
                return;
            end
            rigid_common_support('play_animation', app.axes{8}, app.result, false, '');
            app.previewTabs.SelectedTab = app.tabs(8);
            write_log('Animation preview updated.');
        catch ME
            write_log(['Play failed: ' ME.message]);
            uialert(app.fig, ME.message, 'Animation error');
        end
    end

    function on_clear(~, ~)
        local_reset_preview_axes();
        rigid_common_support('set_empty_animation_axes', app.axes{8}, 'Run a simulation, then click Play.');
        app.result = [];
        app.lastInput = [];
        refresh_play_availability();
        write_log('Preview cleared.');
    end


    function local_reset_preview_axes()
        for kk = 1:numel(app.axes)
            rigid_common_support('reset_axes', app.axes{kk});
            if kk <= numel(app.tabs)
                try
                    title(app.axes{kk}, app.tabs(kk).Title, 'Interpreter', 'none');
                catch
                    title(app.axes{kk}, '', 'Interpreter', 'none');
                end
            end
        end
    end

    function write_log(msg)
        oldValue = app.logBox.Value;
        if ischar(oldValue)
            oldValue = {oldValue};
        end
        stamp = char(datetime('now', 'Format', 'HH:mm:ss'));
        app.logBox.Value = [oldValue; {[stamp '  ' msg]}];
        drawnow limitrate;
    end
    function cfg = local_default_config()
        cfg = struct();
        cfg.presets = rigid_common_support('defaults');
        cfg.plot = struct( ...
            'w3ScaleTriggerRatio', 3.5, ...
            'animationOmegaScaleTriggerNorm', 5.0, ...
            'figureSize2D', [840 660], ...
            'figureSize3D', [780 660], ...
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

end
