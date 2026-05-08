function tab = create_metal_guides_tab(tab_group, project_root)
app_figure = ancestor(tab_group, 'figure');
ui = create_tab_layout(tab_group, 'metal guides', project_root, ...
    'Preview', 'list', ...
    'NotesText', local_notes(), ...
    'NotesFile', fullfile(project_root, 'docs', 'physical_formulas.md'));

ui.control_grid.RowHeight = {'fit','fit','fit'};

study = create_control_panel(ui.control_grid, 'section', 'waveguide and study', 4);
guide_dd = create_control_panel(study.grid, 'dropdown', 'guide', {'rectangular','circular'}, 'rectangular', 'PEC cross section.');
action_dd = create_control_panel(study.grid, 'dropdown', 'action', {'mode field','dispersion curves','cutoff map'}, 'mode field', 'Study type.');
mode_dd = create_control_panel(study.grid, 'dropdown', 'polarization', {'TE','TM'}, 'TE', 'TE or TM modes.');
legend_dd = create_control_panel(study.grid, 'legend', 'legend', 'best');

params_panel = create_control_panel(ui.control_grid, 'section', 'parameters', 6);
tuple_edit = create_control_panel(params_panel.grid, 'text', 'm,n tuples', '(1,0)', 'Examples: (1,0), (1:3,1:3).');
max_order = create_control_panel(params_panel.grid, 'numeric', 'max order', 5, 'Largest order for dispersion/cutoff plots.');
a_edit = create_control_panel(params_panel.grid, 'numeric', 'a width (m)', 0.08, 'Rectangular width.');
b_edit = create_control_panel(params_panel.grid, 'numeric', 'b height (m)', 0.04, 'Rectangular height.');
r_edit = create_control_panel(params_panel.grid, 'numeric', 'radius (m)', 0.03, 'Circular radius.');
fmax_edit = create_control_panel(params_panel.grid, 'numeric', 'f max (GHz)', 10.0, 'Upper frequency for dispersion curves.');

actions = create_control_panel(ui.control_grid, 'section', 'actions', 1);
state = struct('files', {{}}, 'params', struct());
bind_workflow(actions.grid, app_figure, @run_callback, @reset_callback, @export_callback, 'GenerateText', 'Run');

guide_dd.ValueChangedFcn = @(~,~) refresh_controls();
action_dd.ValueChangedFcn = @(~,~) refresh_controls();
refresh_controls();

    function params = read_params()
        params = struct();
        params.guide = lower(char(string(guide_dd.Value)));
        params.action = lower(char(string(action_dd.Value)));
        params.mode_type = char(string(mode_dd.Value));
        params.legend_location = char(string(legend_dd.Value));
        params.map_name = 'project';
        params.grid_n = 240;
        params.samples = 260;
        params.layout_rows = image_output('preview_layout', ui, 'auto');
        if strcmp(params.guide, 'rectangular')
            params.a = parse_waveguide_params('positive', a_edit, 'a width');
            params.b = parse_waveguide_params('positive', b_edit, 'b height');
            params.radius = NaN;
            default_tuple = '(1,0)';
        else
            params.radius = parse_waveguide_params('positive', r_edit, 'radius');
            params.a = NaN; params.b = NaN;
            default_tuple = '(1,1)';
        end
        switch params.action
            case 'mode field'
                params.mode_matrix = parse_waveguide_params('int_matrix', tuple_edit.Value, 2, default_tuple, 0, 100);
                params.max_order = NaN;
                params.fmax_ghz = NaN;
            case 'dispersion curves'
                params.max_order = parse_waveguide_params('integer', max_order, 'max order', 1, 30);
                params.mode_matrix = zeros(0, 2);
                params.fmax_ghz = parse_waveguide_params('positive', fmax_edit, 'f max');
            case 'cutoff map'
                if strcmp(params.guide, 'circular')
                    error('Cutoff map is only available for rectangular PEC guides.');
                end
                params.max_order = parse_waveguide_params('integer', max_order, 'max order', 1, 30);
                params.mode_matrix = zeros(0, 2);
                params.fmax_ghz = NaN;
        end
    end

    function run_callback()
        params = read_params();
        result = run_metal_guide_generation(project_root, params);
        if isempty(result.files), error('No PNG output files were generated.'); end
        image_output('bind_preview_list', ui.preview_list, ui.preview_axes, result.files);
        state.files = result.files;
        state.params = params;
    end

    function reset_callback()
        guide_dd.Value = 'rectangular';
        action_dd.Value = 'mode field';
        mode_dd.Value = 'TE';
        legend_dd.Value = 'best';
        tuple_edit.Value = '(1,0)';
        max_order.Value = 5;
        a_edit.Value = 0.08;
        b_edit.Value = 0.04;
        r_edit.Value = 0.03;
        fmax_edit.Value = 10.0;
        ui.preview_layout_edit.Value = 'auto';
        state.files = {};
        refresh_controls();
        image_output('bind_preview_list', ui.preview_list, ui.preview_axes, {});
    end

    function export_callback()
        if isempty(state.files), error('Run before exporting.'); end
        paths = image_output('selected_preview_paths', ui.preview_list, state.files);
        layout = image_output('preview_layout', ui, 'auto');
        image_output('export_bundle', project_root, 'waveguide_metal', paths, ...
            'Params', state.params, 'Composite', true, 'Layout', layout);
    end

    function refresh_controls()
        if strcmp(guide_dd.Value, 'rectangular')
            tuple_edit.Value = '(1,0)';
        else
            tuple_edit.Value = '(1,1)';
        end
    end

tab = ui.tab;
end

function lines = local_notes()
lines = { ...
    'Metal waveguides: rectangular/circular conducting guides with TE/TM cutoff behavior.', ...
    'guide geometry sets cross-section dimensions. mode indices choose TE_mn or TM_mn families.', ...
    'frequency controls propagation constant beta and whether the mode is above cutoff.', ...
    'action chooses field pattern, cutoff/dispersion curve, or mode comparison.', ...
    'samples/grid controls field-map resolution. Notes lists cutoff and field formulas.'};
end
