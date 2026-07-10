function main_elastic_film_gui(mode)
% main_elastic_film_gui
% Main entry for GUI + build.
%
% Run GUI:
%   main_elastic_film_gui
%   main_elastic_film_gui('run')
%
% Build standalone app (requires MATLAB Compiler):
%   main_elastic_film_gui('build')
%
% File structure requested by user:
% - elastic_film_formula.m : formulas / solver only
% - main_elastic_film_gui.m: GUI, export, and compile entry

    if nargin < 1 || isempty(mode)
        mode = 'run';
    end

    switch lower(mode)
        case 'run'
            launchGui();
        case 'build'
            buildStandalone();
        otherwise
            error('Unknown mode: %s. Use ''run'' or ''build''.', mode);
    end
end

function launchGui()
    S = struct();
    S.defaults = elastic_film_formula('defaultInput');
    S.notes = createNotes();

    S.fig = figure( ...
        'Name', 'Elastic Film GUI', ...
        'NumberTitle', 'off', ...
        'Color', 'w', ...
        'MenuBar', 'none', ...
        'ToolBar', 'none', ...
        'Units', 'normalized', ...
        'Position', [0.03 0.05 0.94 0.88], ...
        'Resize', 'on');

    try
        set(S.fig, 'WindowState', 'maximized');
    catch
    end

    S.leftPanel = uipanel( ...
        'Parent', S.fig, ...
        'Title', 'Input', ...
        'Units', 'normalized', ...
        'Position', [0.01 0.02 0.36 0.96], ...
        'BackgroundColor', 'w', ...
        'FontSize', 12, ...
        'FontWeight', 'bold');

    S.rightPanel = uipanel( ...
        'Parent', S.fig, ...
        'Title', 'Output', ...
        'Units', 'normalized', ...
        'Position', [0.38 0.02 0.61 0.96], ...
        'BackgroundColor', 'w', ...
        'FontSize', 12, ...
        'FontWeight', 'bold');

    uicontrol(S.leftPanel, ...
        'Style', 'text', ...
        'String', 'Layer count N', ...
        'Units', 'normalized', ...
        'Position', [0.03 0.948 0.18 0.032], ...
        'BackgroundColor', 'w', ...
        'HorizontalAlignment', 'left', ...
        'FontSize', 11, ...
        'FontWeight', 'bold');

    S.ctrl.N = uicontrol(S.leftPanel, ...
        'Style', 'edit', ...
        'String', num2str(S.defaults.N), ...
        'Units', 'normalized', ...
        'Position', [0.22 0.948 0.10 0.040], ...
        'BackgroundColor', 'white', ...
        'FontSize', 11);

    uicontrol(S.leftPanel, ...
        'Style', 'text', ...
        'String', 'Click Refresh after changing layer tab number.', ...
        'Units', 'normalized', ...
        'Position', [0.34 0.946 0.62 0.035], ...
        'BackgroundColor', 'w', ...
        'ForegroundColor', [0.35 0.35 0.35], ...
        'HorizontalAlignment', 'left', ...
        'FontSize', 9);

    S.inputTabs = uitabgroup( ...
        'Parent', S.leftPanel, ...
        'Units', 'normalized', ...
        'Position', [0.02 0.28 0.96 0.65], ...
        'SelectionChangedFcn', @onTabChanged);

    S.notesPanel = uipanel( ...
        'Parent', S.leftPanel, ...
        'Title', 'Notes', ...
        'Units', 'normalized', ...
        'Position', [0.02 0.10 0.96 0.15], ...
        'BackgroundColor', 'w', ...
        'FontSize', 11, ...
        'FontWeight', 'bold');

    S.ctrl.notesBox = uicontrol(S.notesPanel, ...
        'Style', 'edit', ...
        'Units', 'normalized', ...
        'Position', [0.02 0.06 0.96 0.88], ...
        'Min', 0, ...
        'Max', 20, ...
        'Enable', 'inactive', ...
        'HorizontalAlignment', 'left', ...
        'BackgroundColor', 'white', ...
        'FontSize', 10, ...
        'String', '');

    S.ctrl.refresh = uicontrol(S.leftPanel, ...
        'Style', 'pushbutton', ...
        'String', 'Refresh', ...
        'Units', 'normalized', ...
        'Position', [0.05 0.03 0.24 0.055], ...
        'FontSize', 12, ...
        'FontWeight', 'bold', ...
        'Callback', @refreshTabs);

    S.ctrl.calculate = uicontrol(S.leftPanel, ...
        'Style', 'pushbutton', ...
        'String', 'Calculate', ...
        'Units', 'normalized', ...
        'Position', [0.38 0.03 0.24 0.055], ...
        'FontSize', 12, ...
        'FontWeight', 'bold', ...
        'Callback', @calculateNow);

    S.ctrl.export = uicontrol(S.leftPanel, ...
        'Style', 'pushbutton', ...
        'String', 'Export', ...
        'Units', 'normalized', ...
        'Position', [0.71 0.03 0.24 0.055], ...
        'FontSize', 12, ...
        'FontWeight', 'bold', ...
        'Callback', @exportTxt);

    S.resultTabs = uitabgroup( ...
        'Parent', S.rightPanel, ...
        'Units', 'normalized', ...
        'Position', [0.01 0.01 0.98 0.98]);

    S.tabSummary = uitab('Parent', S.resultTabs, 'Title', 'Summary');
    S.tabP       = uitab('Parent', S.resultTabs, 'Title', 'P incidence');
    S.tabSV      = uitab('Parent', S.resultTabs, 'Title', 'SV incidence');
    S.tabSH      = uitab('Parent', S.resultTabs, 'Title', 'SH incidence');

    S.axSummary = makeOutputAxes(S.tabSummary);
    S.axP       = makeOutputAxes(S.tabP);
    S.axSV      = makeOutputAxes(S.tabSV);
    S.axSH      = makeOutputAxes(S.tabSH);

    buildInputTabs(S.defaults.N);
    loadExampleData();
    renderStartupMessage();
    updateNotesByTitle('General');

    function ax = makeOutputAxes(parentObj)
        ax = axes( ...
            'Parent', parentObj, ...
            'Units', 'normalized', ...
            'Position', [0 0 1 1], ...
            'Visible', 'off', ...
            'XLim', [0 1], ...
            'YLim', [0 1], ...
            'XTick', [], ...
            'YTick', []);
    end

    function buildInputTabs(N)
        delete(allchild(S.inputTabs));

        S.N = N;
        S.ctrl.layers = struct([]);

        S.inTabGeneral = uitab('Parent', S.inputTabs, 'Title', 'General');
        S.inTabA       = uitab('Parent', S.inputTabs, 'Title', 'Air a');
        S.inTabG       = uitab('Parent', S.inputTabs, 'Title', 'Substrate g');

        makeInputPair(S.inTabGeneral, 'omega', 0.80, 'omega');
        makeInputPair(S.inTabGeneral, 'k_x',   0.64, 'kx');
        makeInputPair(S.inTabGeneral, 'phi_i', 0.48, 'phii');
        makeInputPair(S.inTabGeneral, 'psi_i', 0.32, 'psii');

        makeInputPair(S.inTabA, 'lambda_a', 0.80, 'lambda_a');
        makeInputPair(S.inTabA, 'mu_a',     0.64, 'mu_a');
        makeInputPair(S.inTabA, 'eta_a',    0.48, 'eta_a');

        makeInputPair(S.inTabG, 'lambda_g', 0.80, 'lambda_g');
        makeInputPair(S.inTabG, 'mu_g',     0.64, 'mu_g');
        makeInputPair(S.inTabG, 'eta_g',    0.48, 'eta_g');

        for m = 1:N
            t = uitab('Parent', S.inputTabs, 'Title', ['Layer ' num2str(m)]);
            S.ctrl.layers(m).tab = t;
            makeLayerPair(t, ['lambda_' num2str(m)], 0.80, m, 'lambda');
            makeLayerPair(t, ['mu_'     num2str(m)], 0.64, m, 'mu');
            makeLayerPair(t, ['eta_'    num2str(m)], 0.48, m, 'eta');
            makeLayerPair(t, ['h_'      num2str(m)], 0.32, m, 'h');
        end
    end

    function makeInputPair(parentObj, labelText, y, key)
        uicontrol(parentObj, ...
            'Style', 'text', ...
            'String', labelText, ...
            'Units', 'normalized', ...
            'Position', [0.10 y 0.24 0.08], ...
            'BackgroundColor', 'w', ...
            'HorizontalAlignment', 'left', ...
            'FontSize', 12, ...
            'FontWeight', 'bold');

        S.ctrl.(key) = uicontrol(parentObj, ...
            'Style', 'edit', ...
            'Units', 'normalized', ...
            'Position', [0.38 y 0.30 0.10], ...
            'BackgroundColor', 'white', ...
            'FontSize', 12);
    end

    function makeLayerPair(parentObj, labelText, y, idx, fieldName)
        uicontrol(parentObj, ...
            'Style', 'text', ...
            'String', labelText, ...
            'Units', 'normalized', ...
            'Position', [0.10 y 0.24 0.08], ...
            'BackgroundColor', 'w', ...
            'HorizontalAlignment', 'left', ...
            'FontSize', 12, ...
            'FontWeight', 'bold');

        S.ctrl.layers(idx).(fieldName) = uicontrol(parentObj, ...
            'Style', 'edit', ...
            'Units', 'normalized', ...
            'Position', [0.38 y 0.30 0.10], ...
            'BackgroundColor', 'white', ...
            'FontSize', 12);
    end

    function onTabChanged(~, evt)
        updateNotesByTitle(evt.NewValue.Title);
    end

    function updateNotesByTitle(tabTitle)
        if startsWith(tabTitle, 'Layer ')
            noteLines = S.notes.layer;
        elseif strcmp(tabTitle, 'General')
            noteLines = S.notes.general;
        elseif strcmp(tabTitle, 'Air a')
            noteLines = S.notes.air;
        elseif strcmp(tabTitle, 'Substrate g')
            noteLines = S.notes.substrate;
        else
            noteLines = {'No notes available.'};
        end
        set(S.ctrl.notesBox, 'String', noteLines);
    end

    function refreshTabs(~, ~)
        newN = round(str2double(get(S.ctrl.N, 'String')));
        if isnan(newN) || newN < 0
            errordlg('N must be a nonnegative integer.', 'Invalid N');
            return;
        end

        buildInputTabs(newN);

        if newN == S.defaults.N
            loadExampleData();
        else
            loadNeutralData(newN);
        end

        set(S.inputTabs, 'SelectedTab', S.inTabGeneral);
        updateNotesByTitle('General');

        setLatexMessage(S.axSummary, '$\mathrm{Tabs\ refreshed.\ Click\ Calculate\ to\ update\ the\ output.}$');
        clearOutputAxes(S.axP);
        clearOutputAxes(S.axSV);
        clearOutputAxes(S.axSH);
    end

    function loadNeutralData(N)
        set(S.ctrl.omega,    'String', num2str(S.defaults.omega));
        set(S.ctrl.kx,       'String', num2str(S.defaults.kx));
        set(S.ctrl.phii,     'String', num2str(S.defaults.phii));
        set(S.ctrl.psii,     'String', num2str(S.defaults.psii));

        set(S.ctrl.lambda_a, 'String', num2str(S.defaults.lambda_a));
        set(S.ctrl.mu_a,     'String', num2str(S.defaults.mu_a));
        set(S.ctrl.eta_a,    'String', num2str(S.defaults.eta_a));

        set(S.ctrl.lambda_g, 'String', num2str(S.defaults.lambda_g));
        set(S.ctrl.mu_g,     'String', num2str(S.defaults.mu_g));
        set(S.ctrl.eta_g,    'String', num2str(S.defaults.eta_g));

        for m = 1:N
            if m <= numel(S.defaults.layers)
                d = S.defaults.layers(m);
            else
                d = struct('lambda', 1.3, 'mu', 1.0, 'eta', 1.0, 'h', 1.0);
            end
            set(S.ctrl.layers(m).lambda, 'String', num2str(d.lambda));
            set(S.ctrl.layers(m).mu,     'String', num2str(d.mu));
            set(S.ctrl.layers(m).eta,    'String', num2str(d.eta));
            set(S.ctrl.layers(m).h,      'String', num2str(d.h));
        end
    end

    function loadExampleData()
        d = S.defaults;

        if S.N ~= d.N
            buildInputTabs(d.N);
        end

        set(S.ctrl.N,        'String', num2str(d.N));
        set(S.ctrl.omega,    'String', num2str(d.omega));
        set(S.ctrl.kx,       'String', num2str(d.kx));
        set(S.ctrl.phii,     'String', num2str(d.phii));
        set(S.ctrl.psii,     'String', num2str(d.psii));

        set(S.ctrl.lambda_a, 'String', num2str(d.lambda_a));
        set(S.ctrl.mu_a,     'String', num2str(d.mu_a));
        set(S.ctrl.eta_a,    'String', num2str(d.eta_a));

        set(S.ctrl.lambda_g, 'String', num2str(d.lambda_g));
        set(S.ctrl.mu_g,     'String', num2str(d.mu_g));
        set(S.ctrl.eta_g,    'String', num2str(d.eta_g));

        for m = 1:d.N
            set(S.ctrl.layers(m).lambda, 'String', num2str(d.layers(m).lambda));
            set(S.ctrl.layers(m).mu,     'String', num2str(d.layers(m).mu));
            set(S.ctrl.layers(m).eta,    'String', num2str(d.layers(m).eta));
            set(S.ctrl.layers(m).h,      'String', num2str(d.layers(m).h));
        end
    end

    function renderStartupMessage()
        setLatexMessage(S.axSummary, '$\mathrm{Default\ example\ loaded.\ Click\ Calculate\ to\ show\ the\ numeric\ output.}$');
        clearOutputAxes(S.axP);
        clearOutputAxes(S.axSV);
        clearOutputAxes(S.axSH);
    end

    function data = collectInputData()
        data.N = round(str2double(get(S.ctrl.N, 'String')));
        if isnan(data.N) || data.N < 0
            error('Invalid N.');
        end

        data.omega = readNum(S.ctrl.omega, 'omega');
        data.kx    = readNum(S.ctrl.kx,    'k_x');
        data.phii  = readNum(S.ctrl.phii,  'phi_i');
        data.psii  = readNum(S.ctrl.psii,  'psi_i');

        data.a.lambda = readNum(S.ctrl.lambda_a, 'lambda_a');
        data.a.mu     = readNum(S.ctrl.mu_a,     'mu_a');
        data.a.eta    = readNum(S.ctrl.eta_a,    'eta_a');

        data.g.lambda = readNum(S.ctrl.lambda_g, 'lambda_g');
        data.g.mu     = readNum(S.ctrl.mu_g,     'mu_g');
        data.g.eta    = readNum(S.ctrl.eta_g,    'eta_g');

        if data.N > 0
            data.layers = repmat(struct('lambda', 0, 'mu', 0, 'eta', 0, 'h', 0), data.N, 1);
            for m = 1:data.N
                data.layers(m).lambda = readNum(S.ctrl.layers(m).lambda, ['lambda_' num2str(m)]);
                data.layers(m).mu     = readNum(S.ctrl.layers(m).mu,     ['mu_' num2str(m)]);
                data.layers(m).eta    = readNum(S.ctrl.layers(m).eta,    ['eta_' num2str(m)]);
                data.layers(m).h      = readNum(S.ctrl.layers(m).h,      ['h_' num2str(m)]);
            end
        else
            data.layers = struct('lambda', {}, 'mu', {}, 'eta', {}, 'h', {});
        end
    end

    function v = readNum(h, name)
        v = str2double(get(h, 'String'));
        if isnan(v)
            error(['Invalid numeric input: ' name]);
        end
    end

    function calculateNow(~, ~)
        wb = waitbar(0, 'Reading inputs...', 'Name', 'Calculate');
        try
            data = collectInputData();
            waitbar(0.25, wb, 'Building transfer matrices...');
            pause(0.05);

            R = elastic_film_formula('solve', data);
            waitbar(0.75, wb, 'Rendering output...');
            pause(0.05);

            S.lastData = data;
            S.lastResult = R;
            renderAll(data, R);

            waitbar(1.0, wb, 'Done');
            pause(0.12);
            if ishandle(wb), close(wb); end
        catch ME
            if ishandle(wb), close(wb); end
            renderError(ME.message);
        end
    end

    function renderAll(data, R)
        renderSummary(data);
        renderP(R);
        renderSV(R);
        renderSH(R);
    end

    function renderError(msg)
        clearOutputAxes(S.axSummary);
        clearOutputAxes(S.axP);
        clearOutputAxes(S.axSV);
        clearOutputAxes(S.axSH);

        text(S.axSummary, 0.04, 0.95, 'Calculation failed', ...
            'Interpreter', 'none', ...
            'FontSize', 14, ...
            'FontWeight', 'bold', ...
            'Color', [0.8 0 0], ...
            'VerticalAlignment', 'top');
        text(S.axSummary, 0.04, 0.86, msg, ...
            'Interpreter', 'none', ...
            'FontSize', 12, ...
            'Color', [0.8 0 0], ...
            'VerticalAlignment', 'top');
    end

    function renderSummary(data)
        clearOutputAxes(S.axSummary);
        lines = {};
        lines{end+1} = '$\mathrm{Input\ parameters}$';
        lines{end+1} = ['$N=' num2str(data.N) '$'];
        lines{end+1} = ['$\omega=' fmtLatex(data.omega) ',\ k_x=' fmtLatex(data.kx) ',\ \phi_i=' fmtLatex(data.phii) ',\ \psi_i=' fmtLatex(data.psii) '$'];
        lines{end+1} = ['$\mathrm{Air\ side\ a:}\ \lambda_a=' fmtLatex(data.a.lambda) ',\ \mu_a=' fmtLatex(data.a.mu) ',\ \eta_a=' fmtLatex(data.a.eta) '$'];
        lines{end+1} = ['$\mathrm{Substrate\ side\ g:}\ \lambda_g=' fmtLatex(data.g.lambda) ',\ \mu_g=' fmtLatex(data.g.mu) ',\ \eta_g=' fmtLatex(data.g.eta) '$'];

        if data.N > 0
            for m = 1:data.N
                lines{end+1} = ['$\mathrm{Layer\ ' num2str(m) ':}\ \lambda_{' num2str(m) '}=' fmtLatex(data.layers(m).lambda) ...
                    ',\ \mu_{' num2str(m) '}=' fmtLatex(data.layers(m).mu) ...
                    ',\ \eta_{' num2str(m) '}=' fmtLatex(data.layers(m).eta) ...
                    ',\ h_{' num2str(m) '}=' fmtLatex(data.layers(m).h) '$'];
            end
        end

        renderLatexLines(S.axSummary, lines, 0.04, 0.97, 0.46);
    end

    function renderP(R)
        clearOutputAxes(S.axP);
        lines = {};
        lines{end+1} = '$\mathrm{P\ incidence}$';
        lines{end+1} = ['$r_P=' fmtLatex(R.rP_P) '$'];
        lines{end+1} = ['$R_P=' fmtLatex(R.RP_P) '$'];
        lines{end+1} = ['$r_{SV}=' fmtLatex(R.rSV_P) '$'];
        lines{end+1} = ['$R_{SV}=' fmtLatex(R.RSV_P) '$'];
        lines{end+1} = ['$t_P=' fmtLatex(R.tP_P) '$'];
        lines{end+1} = ['$T_P=' fmtLatex(R.TP_P) '$'];
        lines{end+1} = ['$t_{SV}=' fmtLatex(R.tSV_P) '$'];
        lines{end+1} = ['$T_{SV}=' fmtLatex(R.TSV_P) '$'];
        lines{end+1} = ['$R_P+R_{SV}+T_P+T_{SV}=' fmtLatex(R.EP) '$'];
        renderLatexLines(S.axP, lines, 0.05, 0.97, 0.80);
    end

    function renderSV(R)
        clearOutputAxes(S.axSV);
        lines = {};
        lines{end+1} = '$\mathrm{SV\ incidence}$';
        lines{end+1} = ['$r_P=' fmtLatex(R.rP_SV) '$'];
        lines{end+1} = ['$R_P=' fmtLatex(R.RP_SV) '$'];
        lines{end+1} = ['$r_{SV}=' fmtLatex(R.rSV_SV) '$'];
        lines{end+1} = ['$R_{SV}=' fmtLatex(R.RSV_SV) '$'];
        lines{end+1} = ['$t_P=' fmtLatex(R.tP_SV) '$'];
        lines{end+1} = ['$T_P=' fmtLatex(R.TP_SV) '$'];
        lines{end+1} = ['$t_{SV}=' fmtLatex(R.tSV_SV) '$'];
        lines{end+1} = ['$T_{SV}=' fmtLatex(R.TSV_SV) '$'];
        lines{end+1} = ['$R_P+R_{SV}+T_P+T_{SV}=' fmtLatex(R.ESV) '$'];
        renderLatexLines(S.axSV, lines, 0.05, 0.97, 0.80);
    end

    function renderSH(R)
        clearOutputAxes(S.axSH);
        lines = {};
        lines{end+1} = '$\mathrm{SH\ incidence}$';
        lines{end+1} = ['$r_{SH}=' fmtLatex(R.rSH) '$'];
        lines{end+1} = ['$R_{SH}=' fmtLatex(R.RSH) '$'];
        lines{end+1} = ['$t_{SH}=' fmtLatex(R.tSH) '$'];
        lines{end+1} = ['$T_{SH}=' fmtLatex(R.TSH) '$'];
        lines{end+1} = ['$R_{SH}+T_{SH}=' fmtLatex(R.ESH) '$'];
        renderLatexLines(S.axSH, lines, 0.05, 0.97, 0.80);
    end

    function renderLatexLines(ax, lines, x0, y0, colWidth)
        x = x0;
        y = y0;
        dy = 0.058;
        minY = 0.07;
        for k = 1:numel(lines)
            if y < minY
                x = x + colWidth;
                y = y0;
            end
            text(ax, x, y, lines{k}, ...
                'Interpreter', 'latex', ...
                'FontSize', 14, ...
                'VerticalAlignment', 'top');
            y = y - dy;
        end
    end

    function setLatexMessage(ax, latexStr)
        clearOutputAxes(ax);
        text(ax, 0.04, 0.95, latexStr, ...
            'Interpreter', 'latex', ...
            'FontSize', 14, ...
            'VerticalAlignment', 'top');
    end

    function clearOutputAxes(ax)
        cla(ax);
        set(ax, 'Visible', 'off', 'XLim', [0 1], 'YLim', [0 1], 'XTick', [], 'YTick', []);
    end

    function exportTxt(~, ~)
        if ~isfield(S, 'lastResult')
            errordlg('Please click Calculate first.', 'Export');
            return;
        end

        wb = waitbar(0, 'Preparing export...', 'Name', 'Export');
        try
            thisFullPath = mfilename('fullpath');
            [thisDir, thisBase, ~] = fileparts(thisFullPath);
            outDir = fullfile(thisDir, [thisBase '_output']);
            if ~exist(outDir, 'dir')
                mkdir(outDir);
            end

            waitbar(0.35, wb, 'Building text...');
            txt = buildTxt(S.lastData, S.lastResult);

            waitbar(0.70, wb, 'Writing file...');
            stamp = datestr(now, 'yyyymmdd_HHMMSS');
            outFile = fullfile(outDir, [thisBase '_' stamp '.txt']);
            fid = fopen(outFile, 'w');
            if fid < 0
                error('Cannot open file for writing.');
            end
            fwrite(fid, txt);
            fclose(fid);

            waitbar(1.0, wb, 'Done');
            pause(0.12);
            if ishandle(wb), close(wb); end
            msgbox(['Export finished:' newline outFile], 'Export');
        catch ME
            if ishandle(wb), close(wb); end
            errordlg(ME.message, 'Export');
        end
    end
end

function buildStandalone()
    mainPath = mfilename('fullpath');
    mainDir = fileparts(mainPath);
    buildDir = fullfile(mainDir, 'build_main_elastic_film_gui');

    if ~exist(buildDir, 'dir')
        mkdir(buildDir);
    end

    oldDir = pwd;
    cleanupObj = onCleanup(@() cd(oldDir));
    cd(mainDir);

    if exist('mcc', 'file') ~= 2
        clear cleanupObj;
        error('MATLAB Compiler (mcc) was not found in the current MATLAB environment.');
    end

    cmd = sprintf('mcc -m main_elastic_film_gui.m -a elastic_film_formula.m -d "%s"', buildDir);
    disp('Build command:');
    disp(cmd);
    eval(cmd);
    fprintf('Build finished. Output folder: %s\n', buildDir);

    clear cleanupObj;
end

function notes = createNotes()
    notes.general = { ...
        'General tab', ...
        '1. omega: angular frequency.', ...
        '2. k_x: horizontal wavenumber.', ...
        '3. phi_i: incident P-wave potential amplitude.', ...
        '4. psi_i: incident SV-wave potential amplitude.', ...
        'Use phi_i = 1 for pure P incidence or psi_i = 1 for pure SV incidence.'};

    notes.air = { ...
        'Air a tab', ...
        '1. lambda_a: first Lame constant of the air-side medium.', ...
        '2. mu_a: shear modulus of the air-side medium.', ...
        '3. eta_a: density parameter of the air-side medium.'};

    notes.substrate = { ...
        'Substrate g tab', ...
        '1. lambda_g: first Lame constant of the substrate.', ...
        '2. mu_g: shear modulus of the substrate.', ...
        '3. eta_g: density parameter of the substrate.'};

    notes.layer = { ...
        'Layer tab', ...
        '1. lambda_m: first Lame constant of the current layer.', ...
        '2. mu_m: shear modulus of the current layer.', ...
        '3. eta_m: density parameter of the current layer.', ...
        '4. h_m: thickness of the current layer.', ...
        'All layer tabs share the same field meaning; only the layer index changes.'};
end

function s = fmtLatex(x)
    x = cleanSmallImag(x);
    if isreal(x)
        s = num2str(real(x), '%.6g');
        return;
    end
    xr = real(x);
    xi = imag(x);
    if abs(xr) < 1e-14
        xr = 0;
    end
    if abs(xi) < 1e-14
        xi = 0;
    end
    if xi >= 0
        s = [num2str(xr, '%.6g') '+' num2str(abs(xi), '%.6g') 'i'];
    else
        s = [num2str(xr, '%.6g') '-' num2str(abs(xi), '%.6g') 'i'];
    end
end

function s = fmtPlain(x)
    x = cleanSmallImag(x);
    if isreal(x)
        s = num2str(real(x), '%.6g');
        return;
    end
    xr = real(x);
    xi = imag(x);
    if abs(xr) < 1e-14
        xr = 0;
    end
    if abs(xi) < 1e-14
        xi = 0;
    end
    if xi >= 0
        s = [num2str(xr, '%.6g') ' + ' num2str(abs(xi), '%.6g') 'i'];
    else
        s = [num2str(xr, '%.6g') ' - ' num2str(abs(xi), '%.6g') 'i'];
    end
end

function out = cleanSmallImag(out)
    if isstruct(out)
        if numel(out) > 1
            for jj = 1:numel(out)
                out(jj) = cleanSmallImag(out(jj));
            end
        else
            fn = fieldnames(out);
            for ii = 1:numel(fn)
                out.(fn{ii}) = cleanSmallImag(out.(fn{ii}));
            end
        end
    elseif isnumeric(out) && isscalar(out)
        if abs(imag(out)) < 1e-12 * max(1, abs(real(out)))
            out = real(out);
        end
    end
end

function txt = buildTxt(data, R)
    lines = {};
    lines{end+1} = 'Elastic film result';
    lines{end+1} = '===================';
    lines{end+1} = '';
    lines{end+1} = ['N = ' num2str(data.N)];
    lines{end+1} = ['omega = ' fmtPlain(data.omega)];
    lines{end+1} = ['k_x = ' fmtPlain(data.kx)];
    lines{end+1} = ['phi_i = ' fmtPlain(data.phii)];
    lines{end+1} = ['psi_i = ' fmtPlain(data.psii)];
    lines{end+1} = '';

    lines{end+1} = 'Air side';
    lines{end+1} = ['lambda_a = ' fmtPlain(data.a.lambda)];
    lines{end+1} = ['mu_a = ' fmtPlain(data.a.mu)];
    lines{end+1} = ['eta_a = ' fmtPlain(data.a.eta)];
    lines{end+1} = '';

    lines{end+1} = 'Substrate side';
    lines{end+1} = ['lambda_g = ' fmtPlain(data.g.lambda)];
    lines{end+1} = ['mu_g = ' fmtPlain(data.g.mu)];
    lines{end+1} = ['eta_g = ' fmtPlain(data.g.eta)];
    lines{end+1} = '';

    for m = 1:data.N
        lines{end+1} = ['Layer ' num2str(m)];
        lines{end+1} = ['lambda_' num2str(m) ' = ' fmtPlain(data.layers(m).lambda)];
        lines{end+1} = ['mu_'     num2str(m) ' = ' fmtPlain(data.layers(m).mu)];
        lines{end+1} = ['eta_'    num2str(m) ' = ' fmtPlain(data.layers(m).eta)];
        lines{end+1} = ['h_'      num2str(m) ' = ' fmtPlain(data.layers(m).h)];
        lines{end+1} = '';
    end

    lines{end+1} = 'P incidence';
    lines{end+1} = ['r_P = ' fmtPlain(R.rP_P)];
    lines{end+1} = ['R_P = ' fmtPlain(R.RP_P)];
    lines{end+1} = ['r_SV = ' fmtPlain(R.rSV_P)];
    lines{end+1} = ['R_SV = ' fmtPlain(R.RSV_P)];
    lines{end+1} = ['t_P = ' fmtPlain(R.tP_P)];
    lines{end+1} = ['T_P = ' fmtPlain(R.TP_P)];
    lines{end+1} = ['t_SV = ' fmtPlain(R.tSV_P)];
    lines{end+1} = ['T_SV = ' fmtPlain(R.TSV_P)];
    lines{end+1} = ['Energy sum = ' fmtPlain(R.EP)];
    lines{end+1} = '';

    lines{end+1} = 'SV incidence';
    lines{end+1} = ['r_P = ' fmtPlain(R.rP_SV)];
    lines{end+1} = ['R_P = ' fmtPlain(R.RP_SV)];
    lines{end+1} = ['r_SV = ' fmtPlain(R.rSV_SV)];
    lines{end+1} = ['R_SV = ' fmtPlain(R.RSV_SV)];
    lines{end+1} = ['t_P = ' fmtPlain(R.tP_SV)];
    lines{end+1} = ['T_P = ' fmtPlain(R.TP_SV)];
    lines{end+1} = ['t_SV = ' fmtPlain(R.tSV_SV)];
    lines{end+1} = ['T_SV = ' fmtPlain(R.TSV_SV)];
    lines{end+1} = ['Energy sum = ' fmtPlain(R.ESV)];
    lines{end+1} = '';

    lines{end+1} = 'SH incidence';
    lines{end+1} = ['r_SH = ' fmtPlain(R.rSH)];
    lines{end+1} = ['R_SH = ' fmtPlain(R.RSH)];
    lines{end+1} = ['t_SH = ' fmtPlain(R.tSH)];
    lines{end+1} = ['T_SH = ' fmtPlain(R.TSH)];
    lines{end+1} = ['Energy sum = ' fmtPlain(R.ESH)];

    txt = sprintf('%s\n', lines{:});
end
