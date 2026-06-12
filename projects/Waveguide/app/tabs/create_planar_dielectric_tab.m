function tab = create_planar_dielectric_tab(tab_group, project_root)
app_figure = ancestor(tab_group, 'figure');
ui = create_tab_layout(tab_group, 'planar dielectric', project_root, ...
    'Preview', 'list', ...
    'NotesText', local_notes(), ...
    'NotesFile', fullfile(project_root, 'docs', 'physical_formulas.md'));

ui.control_grid.RowHeight = {'fit','fit','fit'};

study = create_control_panel(ui.control_grid, 'section', 'study', 3);
action_dd = create_control_panel(study.grid, 'dropdown', 'action', {'mode field','dispersion curve','mode existence','thickness sweep'}, 'mode field', 'Planar slab analysis.');
mode_dd = create_control_panel(study.grid, 'dropdown', 'polarization', {'TE','TM'}, 'TE', 'TE or TM.');
legend_dd = create_control_panel(study.grid, 'legend', 'legend', 'best');

params_panel = create_control_panel(ui.control_grid, 'section', 'parameters', 5);
order_edit = create_control_panel(params_panel.grid, 'text', 'order', '(0)', 'Single order or scan expression.');
max_order = create_control_panel(params_panel.grid, 'numeric', 'max order', 5, 'Largest order for batch plots.');
n1_edit = create_control_panel(params_panel.grid, 'numeric', 'nco core', 1.50, 'Core refractive index.');
n2_edit = create_control_panel(params_panel.grid, 'numeric', 'ncl cladding', 1.45, 'Cladding refractive index.');
d_edit = create_control_panel(params_panel.grid, 'numeric', 'thickness d (m)', 0.10, 'Slab thickness.');

actions = create_control_panel(ui.control_grid, 'section', 'actions', 1);
state = struct('files', {{}}, 'params', struct());
bind_workflow(actions.grid, app_figure, @run_callback, @reset_callback, @export_callback, 'GenerateText', 'Run');

    function params = read_params()
        params = struct();
        params.action = lower(char(string(action_dd.Value)));
        params.mode_type = char(string(mode_dd.Value));
        params.legend_location = char(string(legend_dd.Value));
        params.map_name = 'project';
        params.grid_n = 240;
        params.samples = 260;
        params.vmax = 12;
        params.freq_ghz = 4.0;
        params.z_length = 0.10;
        params.layout_rows = image_output('preview_layout', ui, 'auto');
        switch params.action
            case 'mode field'
                params.order_list = parse_waveguide_params('int_vector', order_edit.Value, '(0)', 0, 100);
                params.n1 = parse_waveguide_params('positive', n1_edit, 'nco');
                params.n2 = parse_waveguide_params('positive', n2_edit, 'ncl');
                params.d = parse_waveguide_params('positive', d_edit, 'thickness d');
                params.z_length = max(params.d, 0.10);
                params.max_order = NaN;
            case 'dispersion curve'
                params.max_order = parse_waveguide_params('integer', max_order, 'max order', 0, 30);
                params.n1 = parse_waveguide_params('positive', n1_edit, 'nco');
                params.n2 = parse_waveguide_params('positive', n2_edit, 'ncl');
                params.d = NaN;
                params.order_list = [];
            case 'mode existence'
                params.max_order = parse_waveguide_params('integer', max_order, 'max order', 0, 30);
                params.order_list = [];
                params.n1 = NaN; params.n2 = NaN; params.d = NaN;
            case 'thickness sweep'
                params.max_order = parse_waveguide_params('integer', max_order, 'max order', 0, 30);
                params.n1 = parse_waveguide_params('positive', n1_edit, 'nco');
                params.n2 = parse_waveguide_params('positive', n2_edit, 'ncl');
                params.d = parse_waveguide_params('positive', d_edit, 'thickness d');
                params.order_list = [];
        end
        if isfinite(params.n1) && params.n1 <= params.n2
            error('Guided slab studies require nco > ncl.');
        end
    end

    function run_callback()
        params = read_params();
        result = run_planar_dielectric_generation(project_root, params);
        if isempty(result.files), error('No PNG output files were generated.'); end
        image_output('bind_preview_list', ui.preview_list, ui.preview_axes, result.files);
        image_output('reset_preview', ui.preview_axes, '');
        state.files = result.files;
        state.params = params;
    end

    function reset_callback()
        action_dd.Value = 'mode field';
        mode_dd.Value = 'TE';
        legend_dd.Value = 'best';
        order_edit.Value = '(0)';
        max_order.Value = 5;
        n1_edit.Value = 1.50;
        n2_edit.Value = 1.45;
        d_edit.Value = 0.10;
        ui.preview_layout_edit.Value = 'auto';
        state.files = {};
        image_output('bind_preview_list', ui.preview_list, ui.preview_axes, {});
    end

    function export_callback()
        if isempty(state.files), error('Run before exporting.'); end
        paths = image_output('selected_preview_paths', ui.preview_list, state.files);
        layout = image_output('preview_layout', ui, 'auto');
        image_output('export_bundle', project_root, 'waveguide_planar', paths, ...
            'Params', state.params, 'Composite', true, 'Layout', layout);
    end

tab = ui.tab;
end

function lines = local_notes()
lines = { ...
    'Planar dielectric waveguide: slab core index nco between cladding index ncl.', ...
    'action chooses field plot, dispersion curve, mode-existence map, or thickness sweep.', ...
    'polarization selects TE or TM. mode order is the integer transverse order to render or compare.', ...
    'nco and ncl are refractive indices; guided modes require nco > ncl.', ...
    'thickness d sets slab thickness in normalized units used by the core solver.', ...
    'legend controls curve labels. layout controls exported composite arrangement. Notes gives dispersion equations.'};
end
