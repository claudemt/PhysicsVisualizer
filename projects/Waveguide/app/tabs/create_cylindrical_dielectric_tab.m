function tab = create_cylindrical_dielectric_tab(tab_group, project_root)
app_figure = ancestor(tab_group, 'figure');
ui = create_tab_layout(tab_group, 'cylindrical dielectric', project_root, ...
    'Preview', 'list', ...
    'NotesText', local_notes(), ...
    'NotesFile', fullfile(project_root, 'docs', 'physical_formulas.md'));

ui.control_grid.RowHeight = {'fit','fit'};

params_panel = create_control_panel(ui.control_grid, 'section', 'parameters', 4);
n1_edit = create_control_panel(params_panel.grid, 'numeric', 'nco core', 2.50, 'Core refractive index.');
n2_edit = create_control_panel(params_panel.grid, 'numeric', 'ncl cladding', 1.50, 'Cladding refractive index.');
max_order = create_control_panel(params_panel.grid, 'numeric', 'max order', 5, 'Largest azimuthal order.');
legend_dd = create_control_panel(params_panel.grid, 'legend', 'legend', 'best');

actions = create_control_panel(ui.control_grid, 'section', 'actions', 1);
state = struct('files', {{}}, 'params', struct());
bind_workflow(actions.grid, app_figure, @run_callback, @reset_callback, @export_callback, 'GenerateText', 'Run');

    function params = read_params()
        params = struct();
        params.n1 = parse_waveguide_params('positive', n1_edit, 'nco');
        params.n2 = parse_waveguide_params('positive', n2_edit, 'ncl');
        params.max_order = parse_waveguide_params('integer', max_order, 'max order', 0, 30);
        params.legend_location = char(string(legend_dd.Value));
        params.vmax = 10;
        params.umax = 7;
        params.samples = 260;
        if params.n1 <= params.n2
            error('Cylindrical dielectric guidance requires nco > ncl.');
        end
    end

    function run_callback()
        params = read_params();
        result = run_cylindrical_dielectric_generation(project_root, params);
        if isempty(result.files), error('No PNG output files were generated.'); end
        image_output('bind_preview_list', ui.preview_list, ui.preview_axes, result.files);
        image_output('reset_preview', ui.preview_axes, '');
        state.files = result.files;
        state.params = params;
    end

    function reset_callback()
        n1_edit.Value = 2.50;
        n2_edit.Value = 1.50;
        max_order.Value = 5;
        legend_dd.Value = 'best';
        ui.preview_layout_edit.Value = 'auto';
        state.files = {};
        image_output('bind_preview_list', ui.preview_list, ui.preview_axes, {});
    end

    function export_callback()
        if isempty(state.files), error('Run before exporting.'); end
        paths = image_output('selected_preview_paths', ui.preview_list, state.files);
        layout = image_output('preview_layout', ui, 'auto');
        image_output('export_bundle', project_root, 'waveguide_cylindrical', paths, ...
            'Params', state.params, 'Composite', true, 'Layout', layout);
    end

tab = ui.tab;
end

function lines = local_notes()
lines = { ...
    'Cylindrical dielectric waveguide / fiber mode visualizer.', ...
    'ncore and nclad are refractive indices. Guided modes require ncore > nclad.', ...
    'radius sets fiber/core radius. wavelength or V-number determines mode confinement.', ...
    'mode order controls azimuthal/radial order; polarization/family chooses LP/TE/TM/HE-like output when available.', ...
    'Preview list contains field maps or dispersion plots; Notes explains Bessel-function boundary equations.'};
end
