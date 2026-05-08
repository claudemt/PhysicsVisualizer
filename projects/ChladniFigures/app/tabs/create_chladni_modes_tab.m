function tab = create_chladni_modes_tab(tab_group, project_root)
%CREATE_CHLADNI_MODES_TAB Eigenmode Chladni figures with arbitrary C/S/F edge codes.

app_figure = ancestor(tab_group, 'figure');
ui = create_tab_layout(tab_group, 'chladni modes', project_root, ...
    'Preview', 'list', ...
    'PreviewListWidth', 340, ...
    'NotesText', local_mode_notes('rect', 'FFFF'), ...
    'NotesFile', fullfile(project_root, 'docs', 'physical_formulas.md'));

tab = ui.tab;
ui.control_grid.RowHeight = {'fit','fit','fit','1x'};

physical = create_control_panel(ui.control_grid, 'section', 'plate and boundary', 7);
type_dd = create_control_panel(physical.grid, 'dropdown', 'domain', {'rect','circ','annulus'}, 'rect', [], ...
    'rect uses a four-edge ULDR boundary string; circ and annulus use the dropdown below.');
rect_boundary = create_control_panel(physical.grid, 'text', 'rect boundary ULDR', 'FFFF', [], ...
    'Four letters in up-left-down-right order; each letter is C, S, or F. Examples: CFSF, SSSS, FFFF.');
circ_boundary = create_control_panel(physical.grid, 'dropdown', 'circ / annulus boundary', ...
    chladni_input_helpers('boundary_items','circ'), 'C', [], ...
    'Circ uses C/S/F. Annulus uses ordered outer-inner pairs such as CC, CF, FS.');
nu_edit = create_control_panel(physical.grid, 'numeric', 'nu', 0.225, [], 'Poisson ratio, with 0 < nu < 0.5.');
mode_count = create_control_panel(physical.grid, 'numeric', 'number of modes', 10, [], 'How many mode images to compute.');
grid_n = create_control_panel(physical.grid, 'numeric', 'grid size', 240, [], 'Grid resolution used for mode-shape rendering.');
xi0_edit = create_control_panel(physical.grid, 'numeric', 'xi_0', 0.45, [], ...
    'For rect, xi_0=b/a with a=2 and b=2*xi_0. For annulus, xi_0=R0/R. Disabled for circ.');

actions = create_control_panel(ui.control_grid, 'section', 'actions', 1);
state = struct('png_paths', {{}}, 'params', struct());

bind_workflow(actions.grid, app_figure, @run_callback, @reset_callback, @export_callback, 'GenerateText', 'Run');
type_dd.ValueChangedFcn = @(~,~) on_domain_changed();
rect_boundary.ValueChangedFcn = @(~,~) refresh_notes();
circ_boundary.ValueChangedFcn = @(~,~) refresh_notes();
xi0_edit.ValueChangedFcn = @(~,~) refresh_notes();

install_boundary_items();
refresh_notes();
image_output('bind_preview_list', ui.preview_list, ui.preview_axes, {});

    function on_domain_changed()
        install_boundary_items();
        refresh_notes();
    end

    function install_boundary_items()
        domain = char(string(type_dd.Value));
        is_rect = strcmp(domain, 'rect');
        is_circ = strcmp(domain, 'circ');
        rect_boundary.Parent.Visible = chladni_input_helpers('onoff', is_rect);
        circ_boundary.Parent.Visible = chladni_input_helpers('onoff', ~is_rect);
        if is_rect
            if isempty(strtrim(char(string(rect_boundary.Value))))
                rect_boundary.Value = 'FFFF';
            else
                rect_boundary.Value = upper(strtrim(char(string(rect_boundary.Value))));
            end
            xi0_edit.Enable = 'on';
            physical.grid.RowHeight = {'fit','fit',0,'fit','fit','fit','fit'};
        elseif is_circ
            circ_boundary.Items = chladni_input_helpers('boundary_items','circ');
            if ~any(strcmp(circ_boundary.Items, circ_boundary.Value)), circ_boundary.Value = 'C'; end
            xi0_edit.Enable = 'off';
            physical.grid.RowHeight = {'fit',0,'fit','fit','fit','fit','fit'};
        else
            circ_boundary.Items = chladni_input_helpers('boundary_items','annulus');
            if ~any(strcmp(circ_boundary.Items, circ_boundary.Value)), circ_boundary.Value = 'CF'; end
            xi0_edit.Enable = 'on';
            physical.grid.RowHeight = {'fit',0,'fit','fit','fit','fit','fit'};
        end
    end

    function refresh_notes()
        boundary = current_boundary_value();
        ui.set_notes(local_mode_notes(type_dd.Value, boundary));
    end

    function value = current_boundary_value()
        if strcmp(char(string(type_dd.Value)), 'rect')
            value = char(string(rect_boundary.Value));
        else
            value = char(string(circ_boundary.Value));
        end
    end

    function params = read_params()
        params = struct();
        params.type = char(lower(string(type_dd.Value)));
        params.boundary = chladni_input_helpers('normalize_boundary', params.type, current_boundary_value());
        params.nu = nu_edit.Value;
        params.k = max(1, round(mode_count.Value));
        params.n = max(32, round(grid_n.Value));
        params.normalize = true;
        params.xi0 = 0;
        params.a = 1.0;
        params.b = 1.0;

        if ~isfinite(params.nu) || params.nu <= 0 || params.nu >= 0.5
            error('nu must be in (0, 0.5).');
        end
        switch params.type
            case 'rect'
                params.xi0 = xi0_edit.Value;
                if ~isfinite(params.xi0) || params.xi0 <= 0
                    error('For rect, xi_0=b/a must be positive.');
                end
                params.a = 2.0;
                params.b = 2.0 * params.xi0;
            case 'annulus'
                params.xi0 = xi0_edit.Value;
                if ~isfinite(params.xi0) || params.xi0 <= 0 || params.xi0 >= 1
                    error('For annulus, xi_0=R0/R must satisfy 0 < xi_0 < 1.');
                end
        end
    end

    function run_callback()
        params = read_params();
        cache_dir = image_output('clear_cache', project_root, 'chladni_modes');
        result = compute_chladni_modes(params);
        png_paths = render_result('render', result, cache_dir, 'Prefix', sprintf('chladni_%s_%s', params.type, params.boundary));
        image_output('bind_preview_list', ui.preview_list, ui.preview_axes, png_paths);
        state.png_paths = png_paths;
        state.params = params;
    end

    function reset_callback()
        type_dd.Value = 'rect';
        rect_boundary.Value = 'FFFF';
        nu_edit.Value = 0.225;
        mode_count.Value = 10;
        grid_n.Value = 240;
        xi0_edit.Value = 0.45;
        install_boundary_items();
        refresh_notes();
        state.png_paths = {};
        state.params = struct();
        image_output('bind_preview_list', ui.preview_list, ui.preview_axes, {});
    end

    function export_callback()
        if isempty(state.png_paths)
            error('Generate images before exporting.');
        end
        paths = image_output('selected_preview_paths', ui.preview_list, state.png_paths);
        layout = image_output('preview_layout', ui, 'auto');
        code = strjoin({ ...
            'project_root = fileparts(mfilename(''fullpath''));', ...
            'addpath(genpath(fullfile(project_root,''app'')));', ...
            'addpath(genpath(fullfile(project_root,''core'')));', ...
            params_output('reproduce_code', 'compute_chladni_modes', state.params)}, newline);
        image_output('export_bundle', project_root, sprintf('chladni_%s_%s', state.params.type, state.params.boundary), paths, ...
            'Params', state.params, 'ReproduceCode', code, ...
            'Composite', true, 'Layout', layout);
    end
end

function lines = local_mode_notes(domain_type, boundary_code)
lines = { ...
    'This tab computes free-vibration Chladni eigenmodes of a thin plate.', ...
    sprintf('domain = %s: rect uses a rectangle; circ uses a disk; annulus uses a ring with inner radius ratio xi_0.', char(string(domain_type))), ...
    sprintf('boundary = %s: C means clamped edge, S simply supported edge, F free edge. Rect strings are ULDR = Up Left Down Right.', char(string(boundary_code))), ...
    'nu is Poisson ratio of the plate material; typical stable values are 0.2--0.35, and the solver requires 0 < nu < 0.5.', ...
    'xi_0 means b/a for a rectangle, and R0/R for an annulus. For a disk xi_0 is ignored.', ...
    'number of modes controls how many eigenmodes are rendered; grid N controls image resolution and runtime.', ...
    'The color map shows normalized transverse deflection w/w_max. Dark/bright sign changes reveal nodal curves.', ...
    'Use the preview list to select, reorder, preview-combine, and export selected mode images.'};
end
