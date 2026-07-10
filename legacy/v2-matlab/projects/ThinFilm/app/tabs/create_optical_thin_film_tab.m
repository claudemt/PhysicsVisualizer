function tab = create_optical_thin_film_tab(tab_group, project_root)
app_figure = ancestor(tab_group, 'figure');
defaults = thin_film_model('defaults_optical');

ui = create_tab_layout(tab_group, 'optical stack', project_root, ...
    'Preview', 'text', ...
    'NotesText', local_notes(), ...
    'NotesFile', fullfile(project_root, 'docs', 'physical_formulas.md'), ...
    'InitialMessage', 'run to generate a text report');

ui.control_grid.RowHeight = {'fit','fit','fit','fit'};

general = create_control_panel(ui.control_grid, 'section', 'incidence', 3);
omega_edit = create_control_panel(general.grid, 'numeric', 'omega', defaults.omega, 'Angular frequency.');
theta_edit = create_control_panel(general.grid, 'numeric', 'theta_a', defaults.theta_a, ...
    'Incidence angle in medium a (radians, measured from the interface normal).');

media = create_control_panel(ui.control_grid, 'section', 'boundary media', 2);
air_area = create_control_panel(media.grid, 'text', 'medium a [eps mu]', ...
    sprintf('%s %s', fmtShort(defaults.a.eps), fmtShort(defaults.a.mu)), ...
    'Incident-side permittivity and permeability (constants may be scaled together).');
substrate_area = create_control_panel(media.grid, 'text', 'medium g [eps mu]', ...
    sprintf('%s %s', fmtShort(defaults.g.eps), fmtShort(defaults.g.mu)), 'Substrate half-space.');

layers = create_control_panel(ui.control_grid, 'section', 'film layers', {110});
layer_area = create_control_panel(layers.grid, 'textarea', 'layers [eps mu h]', ...
    default_layer_text(defaults), ...
    ['One row per layer. First two columns are eps and mu (numbers). Third column h may be a number ', ...
    'or coeff*lambda (spaces allowed), using wavelength in medium a; see Notes.']);

actions = create_control_panel(ui.control_grid, 'section', 'actions', 1);
state = struct('data', struct(), 'report_text', '');
bind_workflow(actions.grid, app_figure, @run_callback, @reset_callback, @export_callback, ...
    'GenerateText', 'Run');

    function data = read_params()
        data = struct();
        data.omega = omega_edit.Value;
        data.theta_a = theta_edit.Value;

        a = parse_row2(air_area.Value, 'medium a');
        g = parse_row2(substrate_area.Value, 'medium g');
        data.a = struct('eps', a(1), 'mu', a(2));
        data.g = struct('eps', g(1), 'mu', g(2));

        Ly = parse_optical_layer_table(layer_area.Value, data.omega, data.theta_a, data.a.eps, data.a.mu);
        data.N = Ly.N;
        data.layers = Ly.layers;
    end

    function run_callback()
        data = read_params();
        out = thin_film_model('report_optical', data);
        ui.preview_text.Value = splitlines(out.text);
        state.data = data;
        state.report_text = out.text;
    end

    function reset_callback()
        omega_edit.Value = defaults.omega;
        theta_edit.Value = defaults.theta_a;
        air_area.Value = sprintf('%s %s', fmtShort(defaults.a.eps), fmtShort(defaults.a.mu));
        substrate_area.Value = sprintf('%s %s', fmtShort(defaults.g.eps), fmtShort(defaults.g.mu));
        layer_area.Value = splitlines(default_layer_text(defaults));
        ui.preview_text.Value = {'run to generate a text report'};
        state.data = struct();
        state.report_text = '';
    end

    function export_callback()
        if isempty(state.report_text)
            error('Run before exporting.');
        end
        export_params = local_export_safe_optical_params(state.data);
        code = local_reproduce_optical_code(export_params);
        params_output('export_text_bundle', project_root, 'thin_film_optical', state.report_text, ...
            'Params', export_params, 'ReproduceCode', code, 'Filename', 'results.txt');
    end

tab = ui.tab;
end


function export_params = local_export_safe_optical_params(data)
% Keep the GUI/computation data unchanged, but convert the layer struct array
% to a numeric table before calling the shared params_output utility.
% Existing params_output handles scalar structs and numeric matrices, but not
% non-scalar struct arrays.
export_params = data;
if isfield(export_params, 'layers')
    export_params.layers_table = local_optical_layers_to_matrix(export_params.layers);
    export_params = rmfield(export_params, 'layers');
end
end

function M = local_optical_layers_to_matrix(layers)
if isempty(layers)
    M = zeros(0, 3);
    return;
end
M = zeros(numel(layers), 3);
for i = 1:numel(layers)
    M(i, :) = [layers(i).eps, layers(i).mu, layers(i).h];
end
end

function code = local_reproduce_optical_code(export_params)
assign = params_output('reproduce_code', 'unused_function', export_params);
assign = regexprep(assign, '\s*unused_function\(params\);\s*$', '');
code = strjoin({ ...
    'export_dir = fileparts(mfilename(''fullpath''));', ...
    'project_root = fileparts(fileparts(export_dir));', ...
    'addpath(genpath(project_root));', ...
    '', ...
    assign, ...
    '', ...
    'params.layers = repmat(struct(''eps'', 0, ''mu'', 0, ''h'', 0), params.N, 1);', ...
    'for i = 1:params.N', ...
    '    params.layers(i).eps = params.layers_table(i, 1);', ...
    '    params.layers(i).mu  = params.layers_table(i, 2);', ...
    '    params.layers(i).h   = params.layers_table(i, 3);', ...
    'end', ...
    'params = rmfield(params, ''layers_table'');', ...
    '', ...
    'out = thin_film_model(''report_optical'', params);', ...
    'disp(out.text);' ...
    }, newline);
end

function row = parse_row2(txt, label)
M = create_control_panel('parse_matrix', txt);
if numel(M) ~= 2
    error('%s must contain exactly two numbers: eps mu.', label);
end
row = M(:).';
end

function Ly = parse_optical_layer_table(layer_text, omega, theta_a, eps_a, mu_a)
lines = splitlines(strtrim(layer_text));
keep = ~cellfun(@(s) isempty(strtrim(s)), lines);
lines = lines(keep);
if isempty(lines)
    Ly = struct('N', 0, 'layers', struct('eps', {}, 'mu', {}, 'h', {}));
    return;
end
n = numel(lines);
Ly.layers = repmat(struct('eps', 0, 'mu', 0, 'h', 0), n, 1);
for i = 1:n
    tok = regexp(strtrim(lines{i}), '^\s*(\S+)\s+(\S+)\s+(.+)$', 'tokens', 'once');
    if isempty(tok)
        error('Layer row %d: need three fields eps mu h (h may be a number or coeff*lambda).', i);
    end
    eps_m = str2double(tok{1});
    mu_m = str2double(tok{2});
    if isnan(eps_m) || isnan(mu_m)
        error('Layer row %d: eps and mu must be numeric.', i);
    end
    h_spec = strtrim(tok{3});
    Ly.layers(i).eps = eps_m;
    Ly.layers(i).mu = mu_m;
    Ly.layers(i).h = optical_film_formula('resolve_h', h_spec, omega, theta_a, eps_a, mu_a, eps_m, mu_m);
end
Ly.N = n;
end

function txt = default_layer_text(defaults)
if defaults.N <= 0
    txt = '';
    return;
end
lines = cell(defaults.N, 1);
for i = 1:defaults.N
    L = defaults.layers(i);
    lines{i} = sprintf('%s %s %s', fmtShort(L.eps), fmtShort(L.mu), fmtShort(L.h));
end
txt = strjoin(lines, newline);
end

function s = fmtShort(x)
x = double(x);
if abs(x) >= 1 || x == 0
    x = round(x, 3);
else
    x = round(x, 4);
end
s = sprintf('%g', x);
end

function lines = local_notes()
lines = { ...
    'Multilayer optical stack: transfer matrices P (s) and Q (p).', ...
    'Third column h: plain number, or coeff*lambda (lambda is case-insensitive; spaces around * are OK).', ...
    'lambda means wavelength in medium a; optical thickness n_m*cos(theta_m)*h = coeff*lambda (theta_m from Snell).', ...
    'Examples: 1.1 1.9 1.3  and  1.1 1.9 1.8*lambda  and  1.1 1.9 1.8 * lambda.', ...
    'omega, theta_a, and medium a define lambda and incidence; each layer uses its own eps, mu for n_m.'};
end
