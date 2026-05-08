function tab = create_thin_film_tab(tab_group, project_root)
app_figure = ancestor(tab_group, 'figure');
defaults = thin_film_model('defaults');

ui = create_tab_layout(tab_group, 'thin film', project_root, ...
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
    sprintf('%g %g %g', defaults.a.lambda, defaults.a.mu, defaults.a.eta), 'Incident-side medium.');
substrate_area = create_control_panel(media.grid, 'text', 'substrate g [lambda mu eta]', ...
    sprintf('%g %g %g', defaults.g.lambda, defaults.g.mu, defaults.g.eta), 'Substrate-side medium.');

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
        air_area.Value = sprintf('%g %g %g', defaults.a.lambda, defaults.a.mu, defaults.a.eta);
        substrate_area.Value = sprintf('%g %g %g', defaults.g.lambda, defaults.g.mu, defaults.g.eta);
        layer_area.Value = splitlines(default_layer_text(defaults));
        ui.preview_text.Value = {'run to generate a text report'};
        state.data = struct();
        state.report_text = '';
    end

    function export_callback()
        if isempty(state.report_text)
            error('Run before exporting.');
        end
        code = strjoin({ ...
            'project_root = fileparts(mfilename(''fullpath''));', ...
            'addpath(genpath(fullfile(project_root,''app'')));', ...
            'addpath(genpath(fullfile(project_root,''core'')));', ...
            params_output('reproduce_code', 'thin_film_model', state.data)}, newline);
        params_output('export_text_bundle', project_root, 'thin_film', state.report_text, ...
            'Params', state.data, 'ReproduceCode', code, 'Filename', 'results.txt');
    end

tab = ui.tab;
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
    lines{i} = sprintf('%g %g %g %g', L.lambda, L.mu, L.eta, L.h);
end
txt = strjoin(lines, newline);
end

function lines = local_notes()
lines = { ...
    'This tab solves elastic-wave reflection/transmission through layered thin films using a transfer matrix.', ...
    'omega is angular frequency. k_x is tangential wavenumber conserved across all layers.', ...
    'phi_i is the incident P-wave scalar potential amplitude; psi_i is the incident SV-wave potential amplitude.', ...
    'air a [lambda mu eta] describes incident-side medium: Lame lambda, shear modulus mu, and density eta.', ...
    'substrate g [lambda mu eta] describes the final half-space below the film stack.', ...
    'layers [lambda mu eta h] uses one row per layer; h is thickness. Blank means direct interface without film.', ...
    'The report lists reflection/transmission coefficients and intermediate wave quantities. Full derivation is in Notes.'};
end
