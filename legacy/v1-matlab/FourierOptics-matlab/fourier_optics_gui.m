function varargout = fourier_optics_gui()
%FOURIER_OPTICS_GUI Adaptive GUI for 4f Fourier optics demonstrations.
%   Combines object plane, phase plane and Fourier filter plane modules.

plot_style_set('defaults');
app = init_app_state();
app = build_ui(app);
set_app(app);
load_preset(app.Fig, app.Presets(1).Name);
run_simulation(app.Fig);

if nargout > 0
    varargout{1} = app.Fig;
end
end

function app = init_app_state()
app = struct();
app.RootDir = fileparts(mfilename('fullpath'));
app.OutputRoot = fullfile(app.RootDir, 'fourier_optics_output');
if ~exist(app.OutputRoot, 'dir')
    mkdir(app.OutputRoot);
end
app.Modules = discover_plane_modules(app.RootDir);
app.Presets = params_preset();
app.CurrentResult = [];
app.Style = plot_style_set('defaults');

app.Fig = [];
app.MainGrid = [];
app.LeftPanel = [];
app.TabGroup = [];
app.SetupTab = [];
app.BasicTab = [];
app.AdvancedTab = [];
app.InfoTab = [];
app.PresetDropDown = [];
app.ObjectDropDown = [];
app.PhaseDropDown = [];
app.FilterDropDown = [];
app.InfoArea = [];
app.WavelengthField = [];
app.FocalField = [];
app.WindowField = [];
app.SamplesField = [];
app.ObjectScaleField = [];
app.SecondaryScaleField = [];
app.PhaseRadiusField = [];
app.ZernikeCoeffField = [];
app.FilterScaleField = [];
app.ChargeField = [];
app.AutoRangeCheckBox = [];
app.ObjectPlotHalfRangeField = [];
app.FourierPlotHalfRangeField = [];
app.RunButton = [];
app.ExportButton = [];
app.RefreshButton = [];
app.InfoButton = [];
app.StatusLabel = [];
app.SummaryLabel = [];
app.AxObject = [];
app.AxPhase = [];
app.AxAmplitude = [];
app.AxSpectrum = [];
app.AxFilter = [];
app.AxOutput = [];
end

function app = build_ui(app)
screen = get(groot, 'ScreenSize');
width = min(max(1580, round(screen(3) * 0.95)), max(1260, screen(3) - 20));
height = min(max(930, round(screen(4) * 0.92)), max(760, screen(4) - 40));
x0 = max(10, floor((screen(3) - width)/2));
y0 = max(20, floor((screen(4) - height)/2));

app.Fig = uifigure('Name', 'FourierOptics-matlab', ...
    'Position', [x0, y0, width, height], ...
    'Color', app.Style.bg_color, ...
    'AutoResizeChildren', 'on');

app.MainGrid = uigridlayout(app.Fig, [1, 2]);
app.MainGrid.ColumnWidth = {500, '1x'};
app.MainGrid.RowHeight = {'1x'};
app.MainGrid.Padding = [12, 12, 12, 12];
app.MainGrid.ColumnSpacing = 12;

app = build_control_column(app);
app = build_result_column(app);
end

function app = build_control_column(app)
left = uipanel(app.MainGrid, 'Title', 'Controls', 'BackgroundColor', [1, 1, 1]);
left.Layout.Row = 1;
left.Layout.Column = 1;
app.LeftPanel = left;

lg = uigridlayout(left, [2, 1]);
lg.RowHeight = {'1x', 132};
lg.ColumnWidth = {'1x'};
lg.RowSpacing = 10;
lg.Padding = [10, 10, 10, 10];

app.TabGroup = uitabgroup(lg);
app.TabGroup.Layout.Row = 1;
app.TabGroup.Layout.Column = 1;

app.SetupTab = uitab(app.TabGroup, 'Title', 'Setup');
app.BasicTab = uitab(app.TabGroup, 'Title', 'Basic');
app.AdvancedTab = uitab(app.TabGroup, 'Title', 'Advanced');
app.InfoTab = uitab(app.TabGroup, 'Title', 'Info');

app = build_setup_tab(app);
app = build_basic_tab(app);
app = build_advanced_tab(app);
app = build_info_tab(app);
app = build_action_panel(app, lg);
end

function app = build_setup_tab(app)
g = uigridlayout(app.SetupTab, [7, 2]);
g.RowHeight = {26, 34, 34, 34, 34, 34, '1x'};
g.ColumnWidth = {132, '1x'};
g.Padding = [12, 12, 12, 12];
g.RowSpacing = 8;
g.ColumnSpacing = 8;

head = uilabel(g, 'Text', 'Select a preset and a freely combinable object / phase / filter set.');
head.Layout.Row = 1; head.Layout.Column = [1 2];
head.FontName = app.Style.font_name;
head.FontSize = 12;

make_plain_label(g, 'Preset', 2, 1);
app.PresetDropDown = uidropdown(g, 'Items', {app.Presets.Name}, ...
    'ValueChangedFcn', @(src, evt) load_preset(app.Fig, src.Value));
app.PresetDropDown.Layout.Row = 2; app.PresetDropDown.Layout.Column = 2;

make_plain_label(g, 'Object plane', 3, 1);
app.ObjectDropDown = uidropdown(g, 'Items', localItems(app.Modules.object), ...
    'ValueChangedFcn', @(src, evt) update_module_info(app.Fig));
app.ObjectDropDown.Layout.Row = 3; app.ObjectDropDown.Layout.Column = 2;

make_plain_label(g, 'Phase plane', 4, 1);
app.PhaseDropDown = uidropdown(g, 'Items', localItems(app.Modules.phase), ...
    'ValueChangedFcn', @(src, evt) update_module_info(app.Fig));
app.PhaseDropDown.Layout.Row = 4; app.PhaseDropDown.Layout.Column = 2;

make_plain_label(g, 'Filter plane', 5, 1);
app.FilterDropDown = uidropdown(g, 'Items', localItems(app.Modules.filter), ...
    'ValueChangedFcn', @(src, evt) update_module_info(app.Fig));
app.FilterDropDown.Layout.Row = 5; app.FilterDropDown.Layout.Column = 2;

app.InfoButton = uibutton(g, 'Text', 'Open selected-model description', ...
    'ButtonPushedFcn', @(src, evt) open_info_dialog(app.Fig));
app.InfoButton.Layout.Row = 6; app.InfoButton.Layout.Column = [1 2];

notes = uitextarea(g, 'Editable', 'off', 'Value', {
    'The left panel is tabbed to keep the controls readable.', ...
    'Use Basic for routine classroom changes and Advanced for model tuning.', ...
    'Descriptions are available in the Info tab or the button above.'});
notes.Layout.Row = 7; notes.Layout.Column = [1 2];
notes.FontName = app.Style.font_name;
notes.FontSize = 11;
end

function app = build_basic_tab(app)
g = uigridlayout(app.BasicTab, [8, 2]);
g.RowHeight = {28, 28, 28, 28, 28, 28, 28, '1x'};
g.ColumnWidth = {176, '1x'};
g.Padding = [12, 12, 12, 12];
g.RowSpacing = 8;
g.ColumnSpacing = 8;

make_plain_label(g, 'Wavelength (nm)', 1, 1);
app.WavelengthField = uieditfield(g, 'numeric');
app.WavelengthField.Layout.Row = 1; app.WavelengthField.Layout.Column = 2;

make_plain_label(g, 'Focal length (mm)', 2, 1);
app.FocalField = uieditfield(g, 'numeric');
app.FocalField.Layout.Row = 2; app.FocalField.Layout.Column = 2;

make_plain_label(g, 'Window size L (mm)', 3, 1);
app.WindowField = uieditfield(g, 'numeric');
app.WindowField.Layout.Row = 3; app.WindowField.Layout.Column = 2;

make_plain_label(g, 'Samples N', 4, 1);
app.SamplesField = uieditfield(g, 'numeric');
app.SamplesField.Layout.Row = 4; app.SamplesField.Layout.Column = 2;

make_plain_label(g, 'Object scale (mm)', 5, 1);
app.ObjectScaleField = uieditfield(g, 'numeric');
app.ObjectScaleField.Layout.Row = 5; app.ObjectScaleField.Layout.Column = 2;

make_plain_label(g, 'Secondary scale (mm)', 6, 1);
app.SecondaryScaleField = uieditfield(g, 'numeric');
app.SecondaryScaleField.Layout.Row = 6; app.SecondaryScaleField.Layout.Column = 2;

make_plain_label(g, 'Auto adjust plot range', 7, 1);
app.AutoRangeCheckBox = uicheckbox(g, 'Text', 'crop to salient content', 'Value', true, ...
    'ValueChangedFcn', @(src, evt) update_range_field_state(app.Fig));
app.AutoRangeCheckBox.Layout.Row = 7; app.AutoRangeCheckBox.Layout.Column = 2;

helpbox = uitextarea(g, 'Editable', 'off', 'Value', {
    'Basic parameters cover the 4f geometry and the main object size.', ...
    'Secondary scale is reused by slit spacing, lattice pitch, and several Fourier masks.', ...
    'Automatic range adjustment is recommended for classroom viewing.'});
helpbox.Layout.Row = 8; helpbox.Layout.Column = [1 2];
helpbox.FontName = app.Style.font_name;
helpbox.FontSize = 11;
end

function app = build_advanced_tab(app)
g = uigridlayout(app.AdvancedTab, [10, 2]);
g.RowHeight = {28, 28, 28, 28, 28, 28, 28, 28, 28, '1x'};
g.ColumnWidth = {196, '1x'};
g.Padding = [12, 12, 12, 12];
g.RowSpacing = 8;
g.ColumnSpacing = 8;

make_plain_label(g, 'Phase radius (mm)', 1, 1);
app.PhaseRadiusField = uieditfield(g, 'numeric');
app.PhaseRadiusField.Layout.Row = 1; app.PhaseRadiusField.Layout.Column = 2;

make_plain_label(g, 'Zernike coeff (waves)', 2, 1);
app.ZernikeCoeffField = uieditfield(g, 'numeric');
app.ZernikeCoeffField.Layout.Row = 2; app.ZernikeCoeffField.Layout.Column = 2;

make_plain_label(g, 'Filter scale ratio', 3, 1);
app.FilterScaleField = uieditfield(g, 'numeric');
app.FilterScaleField.Layout.Row = 3; app.FilterScaleField.Layout.Column = 2;

make_plain_label(g, 'Vortex charge', 4, 1);
app.ChargeField = uieditfield(g, 'numeric');
app.ChargeField.Layout.Row = 4; app.ChargeField.Layout.Column = 2;

make_plain_label(g, 'Object/output half range (mm)', 5, 1);
app.ObjectPlotHalfRangeField = uieditfield(g, 'numeric');
app.ObjectPlotHalfRangeField.Layout.Row = 5; app.ObjectPlotHalfRangeField.Layout.Column = 2;

make_plain_label(g, 'Fourier/filter half range (mm)', 6, 1);
app.FourierPlotHalfRangeField = uieditfield(g, 'numeric');
app.FourierPlotHalfRangeField.Layout.Row = 6; app.FourierPlotHalfRangeField.Layout.Column = 2;

make_plain_label(g, 'Interpretation', 7, 1);
lab1 = uilabel(g, 'Text', 'Phase radius also acts as the finite phase-pupil support.');
lab1.WordWrap = 'on';
lab1.Layout.Row = 7; lab1.Layout.Column = 2;

make_plain_label(g, 'Intensity rendering', 8, 1);
lab2 = uilabel(g, 'Text', 'All intensity-like maps use the same enhanced HeNe-style display transform.');
lab2.WordWrap = 'on';
lab2.Layout.Row = 8; lab2.Layout.Column = 2;

make_plain_label(g, 'Export DPI', 9, 1);
lab3 = uilabel(g, 'Text', '220 in this release');
lab3.Layout.Row = 9; lab3.Layout.Column = 2;

notes = uitextarea(g, 'Editable', 'off', 'Value', {
    'Advanced parameters are used only by the relevant modules.', ...
    'When auto range is disabled, the two half-range fields become active.', ...
    'Use them to enforce a fixed frame around real-space and Fourier-space maps.'});
notes.Layout.Row = 10; notes.Layout.Column = [1 2];
notes.FontName = app.Style.font_name;
notes.FontSize = 11;
end

function app = build_info_tab(app)
g = uigridlayout(app.InfoTab, [2, 1]);
g.RowHeight = {24, '1x'};
g.ColumnWidth = {'1x'};
g.Padding = [12, 12, 12, 12];
g.RowSpacing = 8;

lbl = uilabel(g, 'Text', 'Descriptions are shown on demand here, not permanently on the left.');
lbl.FontName = app.Style.font_name;
lbl.FontSize = 12;

app.InfoArea = uitextarea(g, 'Editable', 'off', 'Value', {'Ready.'});
app.InfoArea.FontName = app.Style.font_name;
app.InfoArea.FontSize = 12;
end

function app = build_action_panel(app, parentGrid)
action_panel = uipanel(parentGrid, 'Title', 'Run / export', 'BackgroundColor', [1, 1, 1]);
action_panel.Layout.Row = 2;
action_panel.Layout.Column = 1;

ag = uigridlayout(action_panel, [3, 2]);
ag.RowHeight = {32, 32, 26};
ag.ColumnWidth = {'1x', '1x'};
ag.Padding = [8, 8, 8, 8];
ag.RowSpacing = 8;
ag.ColumnSpacing = 8;

app.RunButton = uibutton(ag, 'Text', 'Run 4f simulation', 'ButtonPushedFcn', @(src, evt) run_simulation(app.Fig));
app.RunButton.Layout.Row = 1; app.RunButton.Layout.Column = [1 2];

app.ExportButton = uibutton(ag, 'Text', 'Export current figure set', 'ButtonPushedFcn', @(src, evt) export_current(app.Fig));
app.ExportButton.Layout.Row = 2; app.ExportButton.Layout.Column = 1;

app.RefreshButton = uibutton(ag, 'Text', 'Refresh modules', 'ButtonPushedFcn', @(src, evt) refresh_modules(app.Fig));
app.RefreshButton.Layout.Row = 2; app.RefreshButton.Layout.Column = 2;

app.StatusLabel = uilabel(ag, 'Text', 'idle', 'HorizontalAlignment', 'left');
app.StatusLabel.Layout.Row = 3; app.StatusLabel.Layout.Column = 1;
app.SummaryLabel = uilabel(ag, 'Text', '');
app.SummaryLabel.HorizontalAlignment = 'right';
app.SummaryLabel.Layout.Row = 3; app.SummaryLabel.Layout.Column = 2;
end

function app = build_result_column(app)
right = uipanel(app.MainGrid, 'Title', '4f system views', 'BackgroundColor', [1, 1, 1]);
right.Layout.Row = 1;
right.Layout.Column = 2;

rg = uigridlayout(right, [2, 3]);
rg.RowHeight = {'1x', '1x'};
rg.ColumnWidth = {'1x', '1x', '1x'};
rg.Padding = [10, 10, 10, 10];
rg.RowSpacing = 8;
rg.ColumnSpacing = 8;

app.AxObject = uiaxes(rg); app.AxObject.Layout.Row = 1; app.AxObject.Layout.Column = 1;
app.AxPhase = uiaxes(rg); app.AxPhase.Layout.Row = 1; app.AxPhase.Layout.Column = 2;
app.AxAmplitude = uiaxes(rg); app.AxAmplitude.Layout.Row = 1; app.AxAmplitude.Layout.Column = 3;
app.AxSpectrum = uiaxes(rg); app.AxSpectrum.Layout.Row = 2; app.AxSpectrum.Layout.Column = 1;
app.AxFilter = uiaxes(rg); app.AxFilter.Layout.Row = 2; app.AxFilter.Layout.Column = 2;
app.AxOutput = uiaxes(rg); app.AxOutput.Layout.Row = 2; app.AxOutput.Layout.Column = 3;

plot_style_set('apply_axes', app.AxObject, 'object');
plot_style_set('apply_axes', app.AxPhase, 'phase');
plot_style_set('apply_axes', app.AxAmplitude, 'amplitude');
plot_style_set('apply_axes', app.AxSpectrum, 'spectrum');
plot_style_set('apply_axes', app.AxFilter, 'filter');
plot_style_set('apply_axes', app.AxOutput, 'intensity');
end

function load_preset(fig, preset_name)
app = get_app(fig);
p = params_preset(preset_name);
app.PresetDropDown.Value = p.Name;
app.ObjectDropDown.Value = best_item_match(app.Modules.object, p.object_name);
app.PhaseDropDown.Value = best_item_match(app.Modules.phase, p.phase_name);
app.FilterDropDown.Value = best_item_match(app.Modules.filter, p.filter_name);
app.WavelengthField.Value = p.wavelength_nm;
app.FocalField.Value = p.focal_length_mm;
app.WindowField.Value = p.window_mm;
app.SamplesField.Value = p.n_samples;
app.ObjectScaleField.Value = p.object_scale_mm;
app.SecondaryScaleField.Value = p.secondary_scale_mm;
app.PhaseRadiusField.Value = p.phase_radius_mm;
app.ZernikeCoeffField.Value = p.zernike_coeff_waves;
app.FilterScaleField.Value = p.filter_scale_ratio;
app.ChargeField.Value = p.topological_charge;
app.AutoRangeCheckBox.Value = p.auto_adjust_plot_range;
app.ObjectPlotHalfRangeField.Value = p.object_plot_half_range_mm;
app.FourierPlotHalfRangeField.Value = p.fourier_plot_half_range_mm;
set_app(app);
update_range_field_state(fig);
update_module_info(fig);
end

function refresh_modules(fig)
app = get_app(fig);
app.Modules = discover_plane_modules(app.RootDir);
app.ObjectDropDown.Items = localItems(app.Modules.object);
app.PhaseDropDown.Items = localItems(app.Modules.phase);
app.FilterDropDown.Items = localItems(app.Modules.filter);
set_app(app);
load_preset(fig, app.PresetDropDown.Value);
end

function run_simulation(fig)
app = get_app(fig);
pd = uiprogressdlg(fig, 'Title', 'Running simulation', 'Message', 'Collecting parameters ...', 'Indeterminate', 'off', 'Value', 0.05);
cleanup = onCleanup(@() close_progress(pd)); %#ok<NASGU>
busy_cleanup = onCleanup(@() set_busy_state(fig, false)); %#ok<NASGU>
set_status(fig, 'running ...');
set_busy_state(fig, true);
drawnow;
try
    params = collect_params(app);
    pd.Value = 0.15; pd.Message = 'Resolving selected plane modules ...'; drawnow;
    object_entry = resolve_entry(app.Modules.object, app.ObjectDropDown.Value);
    phase_entry = resolve_entry(app.Modules.phase, app.PhaseDropDown.Value);
    filter_entry = resolve_entry(app.Modules.filter, app.FilterDropDown.Value);
    params.object_name = object_entry.DisplayName;
    params.phase_name = phase_entry.DisplayName;
    params.filter_name = filter_entry.DisplayName;
    pd.Value = 0.40; pd.Message = 'Computing object / phase / Fourier transforms ...'; drawnow;
    result = fourier_4f_formula(params, str2func(object_entry.FunctionName), str2func(phase_entry.FunctionName), str2func(filter_entry.FunctionName));
    app.CurrentResult = result;
    set_app(app);
    pd.Value = 0.82; pd.Message = 'Rendering the six views ...'; drawnow;
    render_result(fig);
    pd.Value = 1.00; pd.Message = 'Simulation completed.'; drawnow;
    set_status(fig, 'done');
catch ME
    set_status(fig, 'error');
    uialert(fig, ME.message, 'Simulation error');
    rethrow(ME);
end
end

function render_result(fig)
app = get_app(fig);
result = app.CurrentResult;
plot_opts = localPlotOptions(result.params);

plot_style_set('draw_map', app.AxObject, result.x_mm, result.y_mm, result.object_amp, 'object', ...
    ['Object: ', escape_latex(result.object_name)], '$A_o$', plot_opts.object);
xlabel(app.AxObject, '$y$ (mm)'); ylabel(app.AxObject, '$x$ (mm)');

plot_style_set('draw_map', app.AxPhase, result.x_mm, result.y_mm, result.phase_wrapped, 'phase', ...
    ['Phase: ', escape_latex(result.phase_name)], '$\phi$ (rad)', plot_opts.object_with_mask(result.phase_support));
xlabel(app.AxPhase, '$y$ (mm)'); ylabel(app.AxPhase, '$x$ (mm)');

plot_style_set('draw_map', app.AxAmplitude, result.x_mm, result.y_mm, result.after_phase_amp, 'amplitude', ...
    'Amplitude after phase plane', '$|U_p|$', plot_opts.object_with_mask(result.phase_support));
xlabel(app.AxAmplitude, '$y$ (mm)'); ylabel(app.AxAmplitude, '$x$ (mm)');

plot_style_set('draw_map', app.AxSpectrum, result.xf_mm, result.yf_mm, result.spectrum_intensity, 'spectrum', ...
    'Fourier-plane intensity', 'enhanced intensity', plot_opts.fourier);
xlabel(app.AxSpectrum, '$y_f$ (mm)'); ylabel(app.AxSpectrum, '$x_f$ (mm)');

plot_style_set('draw_map', app.AxFilter, result.xf_mm, result.yf_mm, result.filter_amp, 'filter', ...
    ['Filter: ', escape_latex(result.filter_name)], '$H$', plot_opts.fourier);
xlabel(app.AxFilter, '$y_f$ (mm)'); ylabel(app.AxFilter, '$x_f$ (mm)');

plot_style_set('draw_map', app.AxOutput, result.x_mm, result.y_mm, result.output_intensity, 'intensity', ...
    'Image-plane intensity', 'enhanced intensity', plot_opts.object);
xlabel(app.AxOutput, '$y$ (mm)'); ylabel(app.AxOutput, '$x$ (mm)');

fig.Name = sprintf('FourierOptics-matlab | %s', result.params.title_stub);
app.SummaryLabel.Text = result.summary;
set_app(app);
update_module_info(fig);
end

function export_current(fig)
app = get_app(fig);
if isempty(app.CurrentResult)
    uialert(fig, 'Run a simulation before exporting.', 'Nothing to export');
    return
end
pd = uiprogressdlg(fig, 'Title', 'Exporting results', 'Message', 'Preparing export bundle ...', 'Indeterminate', 'off', 'Value', 0.10);
cleanup = onCleanup(@() close_progress(pd)); %#ok<NASGU>
busy_cleanup = onCleanup(@() set_busy_state(fig, false)); %#ok<NASGU>
set_status(fig, 'exporting ...');
set_busy_state(fig, true);
drawnow;
try
    pd.Value = 0.35; pd.Message = 'Writing PNG overview and parameter log ...'; drawnow;
    export_dir = export_fourier_results(app.CurrentResult, app.OutputRoot);
    pd.Value = 1.00; pd.Message = 'Export completed.'; drawnow;
    set_status(fig, sprintf('exported: %s', export_dir));
    uialert(fig, sprintf('Export completed successfully.\n\n%s', export_dir), 'Export completed', 'Icon', 'success');
catch ME
    set_status(fig, 'export error');
    uialert(fig, ME.message, 'Export error');
    rethrow(ME);
end
end

function update_module_info(fig)
app = get_app(fig);
obj = resolve_entry(app.Modules.object, app.ObjectDropDown.Value);
ph = resolve_entry(app.Modules.phase, app.PhaseDropDown.Value);
ft = resolve_entry(app.Modules.filter, app.FilterDropDown.Value);
lines = {
    sprintf('Object plane: %s', obj.DisplayName), ...
    pad_description(obj.Description), ...
    ' ', ...
    sprintf('Phase plane: %s', ph.DisplayName), ...
    pad_description(ph.Description), ...
    ' ', ...
    sprintf('Filter plane: %s', ft.DisplayName), ...
    pad_description(ft.Description)};
app.InfoArea.Value = lines;
set_app(app);
end

function open_info_dialog(fig)
app = get_app(fig);
update_module_info(fig);
lines = app.InfoArea.Value;
dlg = uifigure('Name', 'Selected model descriptions', 'Position', [200, 120, 760, 520], 'Color', [1 1 1]);
g = uigridlayout(dlg, [1, 1]);
g.Padding = [10 10 10 10];
ta = uitextarea(g, 'Editable', 'off', 'Value', lines);
ta.FontName = app.Style.font_name;
ta.FontSize = 12;
end

function txt = pad_description(txt)
if isempty(txt)
    txt = 'No additional description.';
end
end

function params = collect_params(app)
params = struct();
params.wavelength_nm = app.WavelengthField.Value;
params.focal_length_mm = app.FocalField.Value;
params.window_mm = app.WindowField.Value;
params.n_samples = round(app.SamplesField.Value);
params.object_scale_mm = app.ObjectScaleField.Value;
params.secondary_scale_mm = app.SecondaryScaleField.Value;
params.phase_radius_mm = app.PhaseRadiusField.Value;
params.zernike_coeff_waves = app.ZernikeCoeffField.Value;
params.filter_scale_ratio = app.FilterScaleField.Value;
params.topological_charge = round(app.ChargeField.Value);
params.auto_adjust_plot_range = logical(app.AutoRangeCheckBox.Value);
params.object_plot_half_range_mm = app.ObjectPlotHalfRangeField.Value;
params.fourier_plot_half_range_mm = app.FourierPlotHalfRangeField.Value;
params.export_dpi = 220;
validateattributes(params.wavelength_nm, {'numeric'}, {'scalar','positive','finite'});
validateattributes(params.focal_length_mm, {'numeric'}, {'scalar','positive','finite'});
validateattributes(params.window_mm, {'numeric'}, {'scalar','positive','finite'});
validateattributes(params.n_samples, {'numeric'}, {'scalar','integer','>=',256,'<=',4096});
validateattributes(params.object_scale_mm, {'numeric'}, {'scalar','positive','finite'});
validateattributes(params.secondary_scale_mm, {'numeric'}, {'scalar','positive','finite'});
validateattributes(params.phase_radius_mm, {'numeric'}, {'scalar','positive','finite'});
validateattributes(params.zernike_coeff_waves, {'numeric'}, {'scalar','finite'});
validateattributes(params.filter_scale_ratio, {'numeric'}, {'scalar','positive','<=',1});
validateattributes(params.topological_charge, {'numeric'}, {'scalar','integer','finite'});
validateattributes(params.object_plot_half_range_mm, {'numeric'}, {'scalar','positive','finite'});
validateattributes(params.fourier_plot_half_range_mm, {'numeric'}, {'scalar','positive','finite'});
end

function update_range_field_state(fig)
app = get_app(fig);
manual_on = ~logical(app.AutoRangeCheckBox.Value);
app.ObjectPlotHalfRangeField.Enable = onoff(manual_on);
app.FourierPlotHalfRangeField.Enable = onoff(manual_on);
set_app(app);
end

function opts = localPlotOptions(params)
opts = struct();
opts.object = struct('auto_adjust_range', params.auto_adjust_plot_range, ...
    'fixed_half_range', params.object_plot_half_range_mm);
opts.fourier = struct('auto_adjust_range', params.auto_adjust_plot_range, ...
    'fixed_half_range', params.fourier_plot_half_range_mm);
opts.object_with_mask = @(mask) struct('auto_adjust_range', params.auto_adjust_plot_range, ...
    'fixed_half_range', params.object_plot_half_range_mm, 'support_mask', mask);
end

function entry = resolve_entry(entries, display_name)
idx = find(strcmpi({entries.DisplayName}, char(string(display_name))), 1, 'first');
if isempty(idx)
    error('Could not resolve module: %s', display_name);
end
entry = entries(idx);
end

function out = best_item_match(entries, preferred)
items = string({entries.DisplayName});
idx = find(strcmpi(items, string(preferred)), 1, 'first');
if isempty(idx)
    out = char(items(1));
else
    out = char(items(idx));
end
end

function set_status(fig, txt)
app = get_app(fig);
app.StatusLabel.Text = txt;
set_app(app);
drawnow;
end

function items = localItems(entries)
if isempty(entries)
    items = {'<none found>'};
else
    items = {entries.DisplayName};
end
end

function out = escape_latex(str)
out = char(string(str));
out = strrep(out, '_', '\_');
out = strrep(out, '%', '\%');
out = strrep(out, '&', '\&');
end

function set_app(app)
setappdata(app.Fig, 'FourierOpticsApp', app);
end

function app = get_app(fig)
app = getappdata(fig, 'FourierOpticsApp');
end

function make_plain_label(parent, txt, row, col)
lbl = uilabel(parent, 'Text', txt, 'FontWeight', 'bold');
lbl.Layout.Row = row;
lbl.Layout.Column = col;
end

function set_busy_state(fig, tf)
app = get_app(fig);
state = onoff(~tf);
app.RunButton.Enable = state;
app.ExportButton.Enable = state;
app.RefreshButton.Enable = state;
set_app(app);
drawnow;
end

function close_progress(pd)
if ~isempty(pd) && isvalid(pd)
    close(pd);
end
end

function s = onoff(tf)
if tf
    s = 'on';
else
    s = 'off';
end
end
