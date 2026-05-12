function tab = create_crystal_boundary_tab(tab_group, project_root)
%CREATE_CRYSTAL_BOUNDARY_TAB Crystal boundary optics tab with clear matrix/vector inputs.

app_figure = ancestor(tab_group, 'figure');
defaults = parse_crystal_boundary_params('defaults');

ui = create_tab_layout(tab_group, 'crystal boundary optics', project_root, ...
    'ControlWidth', 500, ...
    'Preview', 'text', ...
    'NotesText', local_crystal_notes('principal + orientation', 'none'), ...
    'NotesFile', fullfile(project_root, 'docs', 'physical_formulas.md'), ...
    'InitialMessage', 'run to generate a text report');

ui.control_grid.RowHeight = {'fit','1x','fit'};
ui.control_grid.RowSpacing = 8;

incident = create_control_panel(ui.control_grid, 'section', 'incident wave', 3);
n_inc_edit = create_control_panel(incident.grid, 'numeric', 'n_inc', defaults.n_inc, 'Incident-medium refractive index.');
k_inc_edit = create_control_panel(incident.grid, 'text', 'k_inc = [kx ky kz]', vec_text(defaults.k_inc), 'Incident direction. It will be normalized and must satisfy kz < 0.');
alpha_edit = create_control_panel(incident.grid, 'numeric', 'alpha deg', defaults.pol.angle_deg, 'Linear-polarization angle in the s/p basis.');
try, alpha_edit.Limits = [-180 180]; catch, end

crystal = create_control_panel(ui.control_grid, 'section', 'crystal parameters', {'fit','1x'});
material_mode_dd = create_control_panel(crystal.grid, 'dropdown', 'material input', ...
    {'principal + orientation','direct eps_lab'}, 'principal + orientation', ...
    'Choose principal-values mode or enter the lab-frame dielectric tensor directly.');

stack_panel = uipanel(crystal.grid, 'BorderType', 'none');
stack_panel.Layout.Row = 2;
stack_panel.Layout.Column = 1;
stack_grid = uigridlayout(stack_panel, [1 1]);
stack_grid.RowHeight = {'1x'};
stack_grid.ColumnWidth = {'1x'};
stack_grid.Padding = [0 0 0 0];

% Direct tensor input: preserve the original clear 3-by-3 numeric grid.
direct_panel = uipanel(stack_grid, 'Title', 'direct eps_lab');
direct_panel.Layout.Row = 1;
direct_panel.Layout.Column = 1;
direct_grid = uigridlayout(direct_panel, [3 1]);
direct_grid.RowHeight = {'fit','fit','fit'};
direct_grid.ColumnWidth = {'1x'};
direct_grid.Padding = [8 8 8 8];
direct_grid.RowSpacing = 8;
uilabel(direct_grid, 'Text', 'Enter the dielectric tensor directly in the lab frame.');
eps_lab_edits = local_matrix_editor(direct_grid, defaults.eps_lab, 'eps_lab');
uilabel(direct_grid, 'Text', 'For lossless dielectrics, eps_lab is typically real-symmetric.', 'FontAngle', 'italic');

% Principal values + orientation input: vector line plus mode-specific controls.
principal_panel = uipanel(stack_grid, 'Title', 'principal values + orientation');
principal_panel.Layout.Row = 1;
principal_panel.Layout.Column = 1;
principal_grid = uigridlayout(principal_panel, [4 1]);
principal_grid.RowHeight = {'fit','fit','fit','fit'};
principal_grid.ColumnWidth = {'1x'};
principal_grid.Padding = [8 8 8 8];
principal_grid.RowSpacing = 6;

eps_diag_edit = create_control_panel(principal_grid, 'text', 'eps_diag = [e1 e2 e3]', vec_text(defaults.eps_diag), 'Principal dielectric tensor entries.');
orientation_mode_dd = create_control_panel(principal_grid, 'dropdown', 'orientation', {'none','axis','euler_zyx','matrix'}, defaults.orientation.mode, 'Crystal-to-lab orientation rule.');

ori_stack = uipanel(principal_grid, 'Title', 'orientation input');
ori_stack.Layout.Row = 3;
ori_stack.Layout.Column = 1;
ori_stack_grid = uigridlayout(ori_stack, [1 1]);
ori_stack_grid.RowHeight = {'fit'};
ori_stack_grid.ColumnWidth = {'1x'};
ori_stack_grid.Padding = [6 6 6 6];

none_panel = uipanel(ori_stack_grid, 'BorderType', 'none');
none_panel.Layout.Row = 1;
none_panel.Layout.Column = 1;
none_grid = uigridlayout(none_panel, [1 1]);
none_grid.RowHeight = {'fit'};
none_grid.ColumnWidth = {'1x'};
none_grid.Padding = [0 0 0 0];
uilabel(none_grid, 'Text', 'No extra orientation input is needed.');

axis_panel = uipanel(ori_stack_grid, 'BorderType', 'none');
axis_panel.Layout.Row = 1;
axis_panel.Layout.Column = 1;
axis_grid = uigridlayout(axis_panel, [1 1]);
axis_grid.RowHeight = {'fit'};
axis_grid.ColumnWidth = {'1x'};
axis_grid.Padding = [0 0 0 0];
axis_edit = create_control_panel(axis_grid, 'text', 'optic axis [ax ay az]', vec_text(defaults.orientation.optic_axis), 'Only valid for uniaxial crystals.');

euler_panel = uipanel(ori_stack_grid, 'BorderType', 'none');
euler_panel.Layout.Row = 1;
euler_panel.Layout.Column = 1;
euler_grid = uigridlayout(euler_panel, [2 1]);
euler_grid.RowHeight = {'fit','fit'};
euler_grid.ColumnWidth = {'1x'};
euler_grid.Padding = [0 0 0 0];
euler_grid.RowSpacing = 6;
uilabel(euler_grid, 'Text', 'Euler ZYX angles in degrees.');
euler_edits = local_vector_editor(euler_grid, defaults.orientation.euler_deg, {'alpha','beta','gamma'});

matrix_panel = uipanel(ori_stack_grid, 'BorderType', 'none');
matrix_panel.Layout.Row = 1;
matrix_panel.Layout.Column = 1;
matrix_grid = uigridlayout(matrix_panel, [2 1]);
matrix_grid.RowHeight = {'fit','fit'};
matrix_grid.ColumnWidth = {'1x'};
matrix_grid.Padding = [0 0 0 0];
matrix_grid.RowSpacing = 6;
uilabel(matrix_grid, 'Text', 'Enter the 3x3 rotation matrix R (principal axes to lab frame).');
R_edits = local_matrix_editor(matrix_grid, defaults.orientation.R, 'R');

orientation_hint = uilabel(principal_grid, ...
    'Text', 'Tip: axis mode is only available for uniaxial crystals.', ...
    'FontAngle', 'italic');
orientation_hint.Layout.Row = 4;
orientation_hint.Layout.Column = 1;

actions = create_control_panel(ui.control_grid, 'section', 'actions', 1);
state = struct('cfg', struct(), 'report_text', '');
material_mode_dd.ValueChangedFcn = @(~,~) sync_material_mode();
orientation_mode_dd.ValueChangedFcn = @(~,~) sync_orientation_mode();
eps_diag_edit.ValueChangedFcn = @(~,~) refresh_orientation_options();

bind_workflow(actions.grid, app_figure, @run_callback, @reset_callback, @export_callback, 'GenerateText', 'Run');
sync_material_mode();
refresh_orientation_options();

    function run_callback()
        cfg = read_params();
        result = crystal_boundary_formula(cfg);
        report_text = render_crystal_report(result);
        ui.preview_text.Value = splitlines(report_text);
        state.cfg = cfg;
        state.report_text = report_text;
        refresh_notes();
    end

    function reset_callback()
        n_inc_edit.Value = defaults.n_inc;
        k_inc_edit.Value = vec_text(defaults.k_inc);
        alpha_edit.Value = defaults.pol.angle_deg;
        material_mode_dd.Value = 'principal + orientation';
        eps_diag_edit.Value = vec_text(defaults.eps_diag);
        orientation_mode_dd.Value = defaults.orientation.mode;
        axis_edit.Value = vec_text(defaults.orientation.optic_axis);
        local_set_vector(euler_edits, defaults.orientation.euler_deg);
        local_set_matrix(eps_lab_edits, defaults.eps_lab);
        local_set_matrix(R_edits, defaults.orientation.R);
        sync_material_mode();
        refresh_orientation_options();
        ui.preview_text.Value = {'run to generate a text report'};
        state.cfg = struct();
        state.report_text = '';
    end

    function export_callback()
        if isempty(state.report_text)
            error('Run before exporting.');
        end
        code_lines = [ ...
            {'export_dir = fileparts(mfilename(''fullpath''));'; ...
             'project_root = fileparts(fileparts(export_dir));'; ...
             'addpath(genpath(project_root));'; ...
             'params = struct();'}; ...
            params_output_assignment_lines(state.cfg); ...
            {'result = crystal_boundary_formula(params);'; ...
             'report_text = render_crystal_report(result);'}];
        code = strjoin(code_lines, newline);
        params_output('export_text_bundle', project_root, 'crystal_boundary', state.report_text, ...
            'Params', state.cfg, 'ReproduceCode', code, 'Filename', 'results.txt');
    end

    function cfg = read_params()
        cfg = struct();
        cfg.n_inc = double(n_inc_edit.Value);
        cfg.k_inc = parse_three_vector(k_inc_edit.Value, 'k_inc');
        if norm(cfg.k_inc) == 0
            error('k_inc must be nonzero.');
        end
        cfg.k_inc = cfg.k_inc / norm(cfg.k_inc);
        if cfg.k_inc(3) >= 0
            error('k_inc(3) must be negative after normalization.');
        end
        cfg.pol = struct('type', 2, 'angle_deg', double(alpha_edit.Value));
        cfg.orientation = struct();

        if strcmp(material_mode_dd.Value, 'direct eps_lab')
            cfg.eps_lab = local_get_matrix(eps_lab_edits);
            cfg.eps_diag = [];
        else
            cfg.eps_diag = parse_three_vector(eps_diag_edit.Value, 'eps_diag').';
            cfg.eps_lab = [];
            cfg.orientation.mode = char(orientation_mode_dd.Value);
            switch cfg.orientation.mode
                case 'none'
                    % no extra fields
                case 'axis'
                    cfg.orientation.optic_axis = parse_three_vector(axis_edit.Value, 'optic axis');
                    if norm(cfg.orientation.optic_axis) == 0
                        error('Optic axis must be nonzero.');
                    end
                case 'euler_zyx'
                    cfg.orientation.euler_deg = local_get_vector(euler_edits);
                case 'matrix'
                    cfg.orientation.R = local_get_matrix(R_edits);
                otherwise
                    error('Unknown orientation mode.');
            end
        end
    end

    function sync_material_mode()
        direct_panel.Visible = 'off';
        principal_panel.Visible = 'off';
        if strcmp(material_mode_dd.Value, 'direct eps_lab')
            direct_panel.Visible = 'on';
        else
            principal_panel.Visible = 'on';
        end
        refresh_notes();
    end

    function refresh_orientation_options()
        vals = parse_optional_three_vector(eps_diag_edit.Value);
        items = {'none','axis','euler_zyx','matrix'};
        if ~isempty(vals) && ~is_uniaxial_eps(vals)
            items = {'none','euler_zyx','matrix'};
            if strcmp(orientation_mode_dd.Value, 'axis')
                orientation_mode_dd.Value = 'euler_zyx';
            end
        end
        orientation_mode_dd.Items = items;
        sync_orientation_mode();
    end

    function sync_orientation_mode()
        none_panel.Visible = 'off';
        axis_panel.Visible = 'off';
        euler_panel.Visible = 'off';
        matrix_panel.Visible = 'off';
        switch char(orientation_mode_dd.Value)
            case 'none'
                none_panel.Visible = 'on';
            case 'axis'
                axis_panel.Visible = 'on';
            case 'euler_zyx'
                euler_panel.Visible = 'on';
            case 'matrix'
                matrix_panel.Visible = 'on';
        end
        refresh_notes();
    end

    function refresh_notes()
        ui.set_notes(local_crystal_notes(material_mode_dd.Value, orientation_mode_dd.Value));
    end

tab = ui.tab;
end

function edits = local_matrix_editor(parent, values, label_text)
row = local_next_row(parent);
wrap = uipanel(parent, 'BorderType', 'none');
wrap.Layout.Row = row;
wrap.Layout.Column = 1;
g = uigridlayout(wrap, [4 3]);
g.RowHeight = {18, 34, 34, 34};
g.ColumnWidth = {'1x','1x','1x'};
g.Padding = [0 0 0 0];
g.RowSpacing = 5;
g.ColumnSpacing = 6;
for jj = 1:3
    lab = uilabel(g, 'Text', sprintf('%s(:,%d)', char(string(label_text)), jj), 'HorizontalAlignment', 'center');
    lab.Layout.Row = 1;
    lab.Layout.Column = jj;
end
edits = gobjects(3,3);
for ii = 1:3
    for jj = 1:3
        edits(ii,jj) = uieditfield(g, 'numeric', 'Value', values(ii,jj), 'HorizontalAlignment', 'center');
        edits(ii,jj).Layout.Row = ii + 1;
        edits(ii,jj).Layout.Column = jj;
    end
end
end

function edits = local_vector_editor(parent, values, labels)
row = local_next_row(parent);
wrap = uipanel(parent, 'BorderType', 'none');
wrap.Layout.Row = row;
wrap.Layout.Column = 1;
g = uigridlayout(wrap, [2 3]);
g.RowHeight = {30, 18};
g.ColumnWidth = {'1x','1x','1x'};
g.Padding = [0 0 0 0];
g.RowSpacing = 4;
g.ColumnSpacing = 6;
edits = gobjects(1,3);
for kk = 1:3
    edits(kk) = uieditfield(g, 'numeric', 'Value', values(kk), 'HorizontalAlignment', 'center');
    edits(kk).Layout.Row = 1;
    edits(kk).Layout.Column = kk;
    lab = uilabel(g, 'Text', labels{kk}, 'HorizontalAlignment', 'center');
    lab.Layout.Row = 2;
    lab.Layout.Column = kk;
end
end

function row = local_next_row(grid)
try
    used = arrayfun(@(c)c.Layout.Row, grid.Children);
    used = used(isfinite(used));
    if isempty(used), row = 1; else, row = max(used) + 1; end
catch
    row = numel(grid.Children) + 1;
end
end

function M = local_get_matrix(edits)
M = zeros(3,3);
for ii = 1:3
    for jj = 1:3
        M(ii,jj) = double(edits(ii,jj).Value);
    end
end
end

function local_set_matrix(edits, M)
for ii = 1:3
    for jj = 1:3
        edits(ii,jj).Value = M(ii,jj);
    end
end
end

function v = local_get_vector(edits)
v = zeros(1, numel(edits));
for kk = 1:numel(edits)
    v(kk) = double(edits(kk).Value);
end
end

function local_set_vector(edits, v)
v = v(:).';
for kk = 1:min(numel(edits), numel(v))
    edits(kk).Value = v(kk);
end
end

function v = parse_three_vector(text_value, label_text)
vals = str2num(char(string(text_value))); %#ok<ST2NM>
if numel(vals) ~= 3
    error('%s must contain exactly three numbers.', label_text);
end
v = double(vals(:));
end

function v = parse_optional_three_vector(text_value)
vals = str2num(char(string(text_value))); %#ok<ST2NM>
if numel(vals) ~= 3
    v = [];
else
    v = double(vals(:)).';
end
end

function tf = is_uniaxial_eps(vals)
vals = vals(:).';
tol = 1e-10;
tf = (abs(vals(1)-vals(2)) < tol) || (abs(vals(1)-vals(3)) < tol) || (abs(vals(2)-vals(3)) < tol);
end

function text_value = vec_text(v)
v = v(:).';
parts = arrayfun(@(x)format_number(x), v, 'UniformOutput', false);
text_value = strjoin(parts, ' ');
end

function s = format_number(x)
if abs(x - round(x)) < 1e-12
    s = sprintf('%d', round(x));
else
    s = sprintf('%.12g', x);
end
end

function lines = params_output_assignment_lines(params)
tmp = params_output('reproduce_code', 'unused_function', params);
parts = splitlines(tmp);
if numel(parts) >= 3
    lines = parts(2:end-1);
else
    lines = {};
end
end

function lines = local_crystal_notes(material_mode, orient_mode)
lines = { ...
    'This tab solves optical boundary conditions at an anisotropic crystal interface.', ...
    'n_inc is incident refractive index. k_inc is the incident direction vector; it must point toward the boundary.', ...
    'polarization angle uses the s/p basis; vector mode accepts a raw electric-field direction; sweep scans polarizations.', ...
    'eps principal are dielectric constants along crystal principal axes. eps_lab is the full dielectric tensor in lab coordinates.', ...
    'orientation chooses how principal axes rotate into the lab frame: Euler zyx, optic axis, matrix R, or none.', ...
    sprintf('Current material input = %s; orientation = %s. The 3x3 grids are matrices, not row vectors.', char(string(material_mode)), char(string(orient_mode))), ...
    'Euler zyx deg are rotations in degrees. optic axis is the uniaxial axis direction before normalization.', ...
    'Run generates a text report of reflected/transmitted modes, electric fields, and energy balance.'};
end
