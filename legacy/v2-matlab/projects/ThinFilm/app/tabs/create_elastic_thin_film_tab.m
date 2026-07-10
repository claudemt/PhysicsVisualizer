function tab = create_elastic_thin_film_tab(tab_group, project_root)
app_figure = ancestor(tab_group, 'figure');
defaults = thin_film_model('defaults');

ui = create_tab_layout(tab_group, 'elastic film', project_root, ...
    'Preview', 'text', ...
    'NotesText', local_notes(), ...
    'NotesFile', fullfile(project_root, 'docs', 'physical_formulas.md'), ...
    'InitialMessage', 'run to generate a text report');

ui.control_grid.RowHeight = {'fit','fit','fit','fit'};

general = create_control_panel(ui.control_grid, 'section', 'incident wave', 4);
omega_edit = create_control_panel(general.grid, 'numeric', 'omega', defaults.omega, 'Angular frequency.');
kx_edit = create_control_panel(general.grid, 'numeric', 'k_x', defaults.kx, 'Horizontal wave number.');
phii_edit = create_control_panel(general.grid, 'numeric', 'phi_i', defaults.phii, 'Incident P-wave potential amplitude.');
psii_edit = create_control_panel(general.grid, 'numeric', 'psi_i', defaults.psii, 'Incident SV-wave potential amplitude.');

media = create_control_panel(ui.control_grid, 'section', 'boundary media', 2);
air_area = create_control_panel(media.grid, 'text', 'air a [lambda mu eta]', ...
    sprintf('%s %s %s', fmtShort(defaults.a.lambda), fmtShort(defaults.a.mu), fmtShort(defaults.a.eta)), ...
    'Incident-side medium.');
substrate_area = create_control_panel(media.grid, 'text', 'substrate g [lambda mu eta]', ...
    sprintf('%s %s %s', fmtShort(defaults.g.lambda), fmtShort(defaults.g.mu), fmtShort(defaults.g.eta)), ...
    'Substrate-side medium.');

layers = create_control_panel(ui.control_grid, 'section', 'film layers', {110});
layer_area = create_control_panel(layers.grid, 'textarea', 'layers [lambda mu eta h]', ...
    default_layer_text(defaults), 'One layer per row. Blank means no layer.');

actions = create_control_panel(ui.control_grid, 'section', 'actions', 1);
state = struct('data', struct(), 'report_text', '');
bind_workflow(actions.grid, app_figure, @run_callback, @reset_callback, @export_callback, ...
    'GenerateText', 'Run');

    function data = read_params()
        data = struct();
        data.omega = omega_edit.Value;
        data.kx = kx_edit.Value;
        data.phii = phii_edit.Value;
        data.psii = psii_edit.Value;

        a = parse_row3(air_area.Value, 'air a');
        g = parse_row3(substrate_area.Value, 'substrate g');
        data.a = struct('lambda', a(1), 'mu', a(2), 'eta', a(3));
        data.g = struct('lambda', g(1), 'mu', g(2), 'eta', g(3));

        L = create_control_panel('parse_matrix', layer_area.Value);
        if isempty(L)
            data.N = 0;
            data.layers = struct('lambda', {}, 'mu', {}, 'eta', {}, 'h', {});
        else
            if size(L, 2) ~= 4
                error('Layer matrix must have four columns: lambda mu eta h.');
            end
            data.N = size(L, 1);
            data.layers = repmat(struct('lambda', 0, 'mu', 0, 'eta', 0, 'h', 0), data.N, 1);
            for i = 1:data.N
                data.layers(i).lambda = L(i,1);
                data.layers(i).mu = L(i,2);
                data.layers(i).eta = L(i,3);
                data.layers(i).h = L(i,4);
            end
        end
    end

    function run_callback()
        data = read_params();
        out = thin_film_model('report', data);
        ui.preview_text.Value = splitlines(out.text);
        state.data = data;
        state.report_text = out.text;
    end

    function reset_callback()
        omega_edit.Value = defaults.omega;
        kx_edit.Value = defaults.kx;
        phii_edit.Value = defaults.phii;
        psii_edit.Value = defaults.psii;
        air_area.Value = sprintf('%s %s %s', fmtShort(defaults.a.lambda), fmtShort(defaults.a.mu), fmtShort(defaults.a.eta));
        substrate_area.Value = sprintf('%s %s %s', fmtShort(defaults.g.lambda), fmtShort(defaults.g.mu), fmtShort(defaults.g.eta));
        layer_area.Value = splitlines(default_layer_text(defaults));
        ui.preview_text.Value = {'run to generate a text report'};
        state.data = struct();
        state.report_text = '';
    end

    function export_callback()
        if isempty(state.report_text)
            error('Run before exporting.');
        end
        export_params = local_export_safe_elastic_params(state.data);
        code = local_reproduce_elastic_code(export_params);
        params_output('export_text_bundle', project_root, 'thin_film_elastic', state.report_text, ...
            'Params', export_params, 'ReproduceCode', code, 'Filename', 'results.txt');
    end

tab = ui.tab;
end


function export_params = local_export_safe_elastic_params(data)
% Keep the GUI/computation data unchanged, but convert the layer struct array
% to a numeric table before calling the shared params_output utility.
% Existing params_output handles scalar structs and numeric matrices, but not
% non-scalar struct arrays.
export_params = data;
if isfield(export_params, 'layers')
    export_params.layers_table = local_elastic_layers_to_matrix(export_params.layers);
    export_params = rmfield(export_params, 'layers');
end
end

function M = local_elastic_layers_to_matrix(layers)
if isempty(layers)
    M = zeros(0, 4);
    return;
end
M = zeros(numel(layers), 4);
for i = 1:numel(layers)
    M(i, :) = [layers(i).lambda, layers(i).mu, layers(i).eta, layers(i).h];
end
end

function code = local_reproduce_elastic_code(export_params)
assign = params_output('reproduce_code', 'unused_function', export_params);
assign = regexprep(assign, '\s*unused_function\(params\);\s*$', '');
code = strjoin({ ...
    'export_dir = fileparts(mfilename(''fullpath''));', ...
    'project_root = fileparts(fileparts(export_dir));', ...
    'addpath(genpath(project_root));', ...
    '', ...
    assign, ...
    '', ...
    'params.layers = repmat(struct(''lambda'', 0, ''mu'', 0, ''eta'', 0, ''h'', 0), params.N, 1);', ...
    'for i = 1:params.N', ...
    '    params.layers(i).lambda = params.layers_table(i, 1);', ...
    '    params.layers(i).mu     = params.layers_table(i, 2);', ...
    '    params.layers(i).eta    = params.layers_table(i, 3);', ...
    '    params.layers(i).h      = params.layers_table(i, 4);', ...
    'end', ...
    'params = rmfield(params, ''layers_table'');', ...
    '', ...
    'out = thin_film_model(''report'', params);', ...
    'disp(out.text);' ...
    }, newline);
end

function row = parse_row3(txt, label)
M = create_control_panel('parse_matrix', txt);
if numel(M) ~= 3
    error('%s must contain exactly three numbers: lambda mu eta.', label);
end
row = M(:).';
end

function txt = default_layer_text(defaults)
if defaults.N <= 0
    txt = '';
    return;
end
lines = cell(defaults.N, 1);
for i = 1:defaults.N
    L = defaults.layers(i);
    lines{i} = sprintf('%s %s %s %s', fmtShort(L.lambda), fmtShort(L.mu), fmtShort(L.eta), fmtShort(L.h));
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
    'This tab solves elastic-wave reflection/transmission through layered thin films using a transfer matrix.', ...
    'omega is angular frequency. k_x is tangential wavenumber conserved across all layers.', ...
    'phi_i is the incident P-wave scalar potential amplitude; psi_i is the incident SV-wave potential amplitude.', ...
    'air a [lambda mu eta] describes incident-side medium: Lame lambda, shear modulus mu, and density eta.', ...
    'substrate g [lambda mu eta] describes the transmitted-side half-space.', ...
    'layers [lambda mu eta h] uses one row per film layer; blank means no internal film layer.', ...
    'lambda and mu are Lame parameters, eta is density, and h is layer thickness.', ...
    'The solver reports P, SV, and SH reflection/transmission coefficients and energy sums.'};
end
