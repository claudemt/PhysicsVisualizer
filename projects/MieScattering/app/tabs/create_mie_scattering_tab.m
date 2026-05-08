function tab = create_mie_scattering_tab(tab_group, project_root)
app_figure = ancestor(tab_group, 'figure');
defaults = parse_mie_scattering_params('defaults');
custom_items = parse_mie_scattering_params('custom_items');
custom_labels = parse_mie_scattering_params('custom_labels');

ui = create_tab_layout(tab_group, 'mie scattering', project_root, ...
    'Preview', 'list', ...
    'NotesText', local_mie_notes(defaults.geometry, defaults.mode), ...
    'NotesFile', fullfile(project_root, 'docs', 'physical_formulas.md'));
ui.control_grid.RowHeight = {'fit','fit','fit'};

phys = create_control_panel(ui.control_grid, 'section', 'physical parameters', 5);
eps_edit = create_control_panel(phys.grid, 'text', 'epsilon_r', defaults.eps1, 'Relative permittivity.');
mu_edit = create_control_panel(phys.grid, 'text', 'mu_r', defaults.mu1, 'Relative permeability.');
R_edit = create_control_panel(phys.grid, 'numeric', 'R/lambda', defaults.R_over_lambda, 'Radius in wavelengths.');
nu_edit = create_control_panel(phys.grid, 'numeric', 'nu', defaults.nu, 'Elliptical-polarization parameter.');
psi_edit = create_control_panel(phys.grid, 'numeric', 'psi', defaults.psi, 'Polarization phase.');

setup = create_control_panel(ui.control_grid, 'section', 'scattering setup', {24,24,90});
geometry_dd = create_control_panel(setup.grid, 'dropdown', 'geometry', {'sphere','cylinder'}, defaults.geometry, 'Geometry.');
mode_dd = create_control_panel(setup.grid, 'dropdown', 'view mode', {'sca','tot','all','custom'}, defaults.mode, 'Field set.');
custom_list = create_control_panel(setup.grid, 'listbox', 'custom fields', custom_labels, custom_labels(1:7), 'Selected fields for custom mode.');
custom_list.ItemsData = custom_items;
custom_list.Value = defaults.customSelection;

actions = create_control_panel(ui.control_grid, 'section', 'actions', 1);
state = struct('png_paths', {{}}, 'params', struct());
geometry_dd.ValueChangedFcn = @(~,~) refresh_notes();
mode_dd.ValueChangedFcn = @(~,~) refresh_notes();
refresh_notes();
bind_workflow(actions.grid, app_figure, @run_callback, @reset_callback, @export_callback, ...
    'GenerateText', 'Run');

    function refresh_notes()
        ui.set_notes(local_mie_notes(geometry_dd.Value, mode_dd.Value));
    end

    function cfg = read_params()
        cfg = struct();
        cfg.eps1 = parse_mie_scattering_params('str2complex', eps_edit.Value);
        cfg.mu1 = parse_mie_scattering_params('str2complex', mu_edit.Value);
        cfg.R_over_lambda = R_edit.Value;
        cfg.nu = nu_edit.Value;
        cfg.psi = psi_edit.Value;
        cfg.geometry = geometry_dd.Value;
        cfg.mode = mode_dd.Value;
        cfg.customSelection = custom_list.Value;
        cfg.gridHalfWidth = defaults.gridHalfWidth;
        cfg.N = defaults.N;
        cfg.nmaxExtra = defaults.nmaxExtra;
        cfg.maskInside = defaults.maskInside;
    end

    function run_callback()
        cfg = read_params();
        cache_dir = image_output('clear_cache', project_root, 'mie_scattering');
        result = compute_mie_scattering(cfg);
        png_paths = render_result('render', result, cache_dir, 'Prefix', 'mie');
        image_output('bind_preview_list', ui.preview_list, ui.preview_axes, png_paths);
        state.png_paths = png_paths;
        state.params = cfg;
    end

    function reset_callback()
        eps_edit.Value = defaults.eps1;
        mu_edit.Value = defaults.mu1;
        R_edit.Value = defaults.R_over_lambda;
        nu_edit.Value = defaults.nu;
        psi_edit.Value = defaults.psi;
        geometry_dd.Value = defaults.geometry;
        mode_dd.Value = defaults.mode;
        custom_list.Value = defaults.customSelection;
        refresh_notes();
        state.png_paths = {};
        image_output('bind_preview_list', ui.preview_list, ui.preview_axes, {});
    end

    function export_callback()
        if isempty(state.png_paths)
            error('Run before exporting.');
        end
        paths = image_output('selected_preview_paths', ui.preview_list, state.png_paths);
        layout = image_output('preview_layout', ui, 'auto');
        code = strjoin({ ...
            'project_root = fileparts(mfilename(''fullpath''));', ...
            'addpath(genpath(fullfile(project_root,''app'')));', ...
            'addpath(genpath(fullfile(project_root,''core'')));', ...
            params_output('reproduce_code', 'compute_mie_scattering', state.params)}, newline);
        image_output('export_bundle', project_root, 'mie_scattering', paths, ...
            'Params', state.params, 'ReproduceCode', code, 'Composite', true, 'Layout', layout);
    end

tab = ui.tab;
end

function lines = local_mie_notes(geometry, mode_name)
lines = { ...
    'This tab computes electromagnetic Mie scattering from a sphere or infinite cylinder.', ...
    'epsilon_r is relative permittivity of the scatterer; complex values model absorption, e.g. 2.25+0.02i.', ...
    'mu_r is relative permeability. For most optical dielectrics use mu_r = 1.', ...
    'R/lambda is particle radius measured in incident wavelength; larger values require more multipole orders.', ...
    'nu controls polarization ellipticity/amplitude mixing; psi is the polarization phase angle between components.', ...
    sprintf('geometry = %s and view mode = %s. custom mode uses the custom field list below.', char(string(geometry)), char(string(mode_name))), ...
    'custom fields select scattered/total field components to generate. The preview list controls final export selection and order.', ...
    'Images show field components or magnitudes on a 2D cut; full coefficient definitions are in Notes.'};
end
