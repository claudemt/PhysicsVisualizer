function tab = create_fourier_studio_tab(tab_group, project_root)
%CREATE_FOURIER_STUDIO_TAB Build a modular 4f Fourier optics studio tab.

app_figure = ancestor(tab_group, 'figure');
fourier_root = fullfile(project_root, 'core', 'fourier');
modules = discover_fourier_modules(fourier_root);
presets = fourier_params_preset();

current_result = [];

ui = create_tab_layout(tab_group, 'fourier studio', project_root, ...
    'Preview', 'axesgrid', ...
    'PreviewGridSize', [2 3], ...
    'NotesTitle', 'notes', ...
    'NotesText', local_fourier_notes(), ...
    'NotesFile', fullfile(project_root, 'docs', 'physical_formulas.md'), ...
    'InitialMessage', 'run to generate result');
tab = ui.tab;
left_grid = ui.control_grid;
left_grid.RowHeight = {430, 76, '1x'};
notes_box = ui.notes_area;

subtabs = uitabgroup(left_grid);
subtabs.Layout.Row = 1;
subtabs.Layout.Column = 1;
setup_tab = uitab(subtabs, 'Title', 'setup');
basic_tab = uitab(subtabs, 'Title', 'basic');
advanced_tab = uitab(subtabs, 'Title', 'advanced');

setup_grid = uigridlayout(setup_tab, [5 1]);
setup_grid.RowHeight = {'fit','fit','fit','fit', 118};
studio_style('apply_grid', setup_grid, 'panel');
object_items = local_items(modules.object);
phase_items = local_items(modules.phase);
filter_items = local_items(modules.filter);
preset_dd = create_control_panel(setup_grid, 'dropdown', 'preset', {presets.Name}, presets(1).Name, 'Load a curated combination of object, phase, filter, and scales.');
object_dd = create_control_panel(setup_grid, 'dropdown', 'object plane', object_items, object_items{1}, 'Object-plane amplitude module.');
phase_dd = create_control_panel(setup_grid, 'dropdown', 'phase plane', phase_items, phase_items{1}, 'Phase-plane module.');
filter_dd = create_control_panel(setup_grid, 'dropdown', 'filter plane', filter_items, filter_items{1}, 'Fourier-plane filtering module.');
basic_grid = uigridlayout(basic_tab, [6 1]);
basic_grid.RowHeight = {'fit','fit','fit',0,'fit','fit'};
studio_style('apply_grid', basic_grid, 'panel');
wavelength_nm = create_control_panel(basic_grid, 'numeric', 'wavelength (nm)', 632.8, 'Optical wavelength.');
focal_length_mm = create_control_panel(basic_grid, 'numeric', 'focal length (mm)', 250, '4f lens focal length.');
window_mm = create_control_panel(basic_grid, 'numeric', 'window size (mm)', 4.0, 'Simulation field of view in the object plane.');
grid_n = create_control_panel(basic_grid, 'numeric', 'samples N', 1536, 'Simulation grid size.');
try, grid_n.Parent.Visible = 'off'; catch, end
object_scale_mm = create_control_panel(basic_grid, 'numeric', 'object scale (mm)', 0.55, 'Primary object size parameter reused by many object modules.');
secondary_scale_mm = create_control_panel(basic_grid, 'numeric', 'secondary scale (mm)', 0.30, 'Secondary spacing / pitch parameter reused by many modules.');

advanced_grid = uigridlayout(advanced_tab, [8 1]);
advanced_grid.RowHeight = {'fit','fit','fit','fit','fit','fit','fit',0};
studio_style('apply_grid', advanced_grid, 'panel');
phase_radius_mm = create_control_panel(advanced_grid, 'numeric', 'phase radius (mm)', 1.00, 'Finite support radius for pupil-like phase modules.');
zernike_coeff_waves = create_control_panel(advanced_grid, 'numeric', 'zernike coeff (waves)', 0.30, 'Strength of selected aberration phase.');
filter_scale_ratio = create_control_panel(advanced_grid, 'numeric', 'filter scale ratio', 0.18, 'Relative size of Fourier-plane masks.');
topological_charge = create_control_panel(advanced_grid, 'numeric', 'vortex charge', 1, 'Topological charge for vortex phase plates.');
plot_range_mode = create_control_panel(advanced_grid, 'dropdown', 'plot range', {'auto', 'fixed'}, 'auto', 'Auto crops to salient content; fixed uses the two half-range fields below.');
object_half_range_mm = create_control_panel(advanced_grid, 'numeric', 'object half range (mm)', 1.20, 'Manual display half-range in the object and image planes.');
fourier_half_range_mm = create_control_panel(advanced_grid, 'numeric', 'fourier half range (mm)', 8.00, 'Manual display half-range in the Fourier and filter planes. Values around 6--12 mm are usually more balanced for fixed viewing.');
display_scaling_dd = create_control_panel(advanced_grid, 'dropdown', 'image scaling', {'fixed', 'auto'}, 'fixed', 'Fixed uses consistent color limits.');
try, display_scaling_dd.Parent.Visible = 'off'; catch, end

info_area = uitextarea(setup_grid, 'Editable', 'off');
studio_style('apply_component', info_area, 'mono');
info_area.Layout.Row = 5;
info_area.Layout.Column = 1;

actions = create_control_panel(left_grid, 'section', 'actions', 1);
actions.panel.Layout.Row = 2;
actions.panel.Layout.Column = 1;
buttons = bind_workflow(actions.grid, app_figure, @run_simulation, @reset_defaults, @export_result, 'GenerateText', 'Run');
buttons.generate.Tooltip = 'Run the modular 4f Fourier optics simulation.';

status_box = uitextarea(tab, 'Editable', 'off', 'Value', {'status: ready'}, 'Visible', 'off');
studio_style('apply_component', status_box, 'mono');

preview_grid = ui.preview_grid;
ax_object = ui.preview_axes(1);
ax_phase = ui.preview_axes(2);
ax_amp = ui.preview_axes(3);
ax_spectrum = ui.preview_axes(4);
ax_filter = ui.preview_axes(5);
ax_output = ui.preview_axes(6);
all_axes = ui.preview_axes;
for ax = all_axes
    studio_style('apply_axes', ax, 'Box', 'on');
end


preset_dd.ValueChangedFcn = @load_selected_preset;
object_dd.ValueChangedFcn = @refresh_info;
phase_dd.ValueChangedFcn = @refresh_info;
filter_dd.ValueChangedFcn = @refresh_info;
plot_range_mode.ValueChangedFcn = @update_range_controls;

load_preset_by_name(presets(1).Name);
clear_preview();

    function run_simulation()
        execute_run(false);
    end

    function execute_run(show_alert)
        dlg = [];
        if show_alert
            dlg = [];
        end
        try
            image_output('show_preview_group', preview_grid, all_axes);
            params = collect_params();
            obj_entry = resolve_entry(modules.object, object_dd.Value);
            ph_entry = resolve_entry(modules.phase, phase_dd.Value);
            ft_entry = resolve_entry(modules.filter, filter_dd.Value);
            params.object_name = obj_entry.DisplayName;
            params.phase_name = ph_entry.DisplayName;
            params.filter_name = ft_entry.DisplayName;
            current_result = fourier_4f_model(params, str2func(obj_entry.FunctionName), str2func(ph_entry.FunctionName), str2func(ft_entry.FunctionName));
            render_result(current_result);
            refresh_info();
            notes_box.Value = local_fourier_notes();

            status_box.Value = { ...
                sprintf('preset            : %s', preset_dd.Value), ...
                sprintf('object            : %s', object_dd.Value), ...
                sprintf('phase             : %s', phase_dd.Value), ...
                sprintf('filter            : %s', filter_dd.Value), ...
                sprintf('wavelength (nm)   : %.2f', wavelength_nm.Value), ...
                sprintf('focal length (mm) : %.2f', focal_length_mm.Value), ...
                sprintf('window (mm)       : %.2f', window_mm.Value), ...
                sprintf('samples N         : %d', round(grid_n.Value)), ...
                sprintf('plot range        : %s', plot_range_mode.Value), ...
                sprintf('display scaling   : %s', display_scaling_dd.Value), ...
                sprintf('mask support      : %.2f %%', 100 * mean(current_result.filter_amp(:) > 0)), ...
                sprintf('peak output       : %.3f', max(current_result.output_intensity(:)))};

            for ax_iter = all_axes
                axis(ax_iter, 'image');
            end
            pause(0.08);
            if show_alert
                uialert(app_figure, 'Fourier studio preview updated successfully.', 'Run complete', 'Icon', 'info');
            end
        catch ME
            uialert(app_figure, sprintf('Fourier studio run failed:\n%s', ME.message), 'Run failed', 'Icon', 'error');
            warning('%s', getReport(ME, 'extended', 'hyperlinks', 'off'));
        end
    end

    function clear_preview()
        current_result = [];
        for ax_iter = all_axes(:)'
            cla(ax_iter, 'reset');
            studio_style('apply_axes', ax_iter, 'Box', 'on');
            try, axis(ax_iter, 'off'); catch, end
        end
        image_output('reset_preview_group', preview_grid, all_axes, 'run to generate result');
        status_box.Value = {'status: ready'};
    end

    function render_result(result)
        scaling_mode = display_scaling_dd.Value;
        auto_range = strcmp(plot_range_mode.Value, 'auto');
        object_range = object_half_range_mm.Value;
        fourier_range = fourier_half_range_mm.Value;

        render_map(ax_object, result.x_mm, result.y_mm, result.object_amp, 'gray', scaling_mode, [0 1], auto_range, object_range, result.object_amp > 0.05, 'object');
        title(ax_object, '$\mathrm{object\ plane}$', 'Interpreter', 'latex');
        xlabel(ax_object, '$x\,(\mathrm{mm})$', 'Interpreter', 'latex');
        ylabel(ax_object, '$y\,(\mathrm{mm})$', 'Interpreter', 'latex');

        render_map(ax_phase, result.x_mm, result.y_mm, result.phase_wrapped, 'parula', scaling_mode, [-pi pi], auto_range, object_range, result.phase_support > 0.5, 'phase');
        title(ax_phase, '$\mathrm{phase\ plane}$', 'Interpreter', 'latex');
        xlabel(ax_phase, '$x\,(\mathrm{mm})$', 'Interpreter', 'latex');
        ylabel(ax_phase, '$y\,(\mathrm{mm})$', 'Interpreter', 'latex');

        render_map(ax_amp, result.x_mm, result.y_mm, result.after_phase_amp, 'gray', scaling_mode, [0 1], auto_range, object_range, result.after_phase_amp > 0.02, 'amplitude');
        title(ax_amp, '$\mathrm{after\ phase}$', 'Interpreter', 'latex');
        xlabel(ax_amp, '$x\,(\mathrm{mm})$', 'Interpreter', 'latex');
        ylabel(ax_amp, '$y\,(\mathrm{mm})$', 'Interpreter', 'latex');

        render_map(ax_spectrum, result.xf_mm, result.yf_mm, result.spectrum_intensity, 'hot', scaling_mode, [0 1], auto_range, fourier_range, result.spectrum_intensity > 0.02, 'spectrum');
        title(ax_spectrum, '$\mathrm{fourier\ intensity}$', 'Interpreter', 'latex');
        xlabel(ax_spectrum, '$x_f\,(\mathrm{mm})$', 'Interpreter', 'latex');
        ylabel(ax_spectrum, '$y_f\,(\mathrm{mm})$', 'Interpreter', 'latex');

        render_map(ax_filter, result.xf_mm, result.yf_mm, result.filter_amp, 'gray', scaling_mode, [0 1], auto_range, fourier_range, result.filter_amp > 0.02, 'filter');
        title(ax_filter, '$\mathrm{filter\ plane}$', 'Interpreter', 'latex');
        xlabel(ax_filter, '$x_f\,(\mathrm{mm})$', 'Interpreter', 'latex');
        ylabel(ax_filter, '$y_f\,(\mathrm{mm})$', 'Interpreter', 'latex');

        render_map(ax_output, result.x_mm, result.y_mm, result.output_intensity, 'hot', scaling_mode, [0 1], auto_range, object_range, result.output_intensity > 0.02, 'intensity');
        title(ax_output, '$\mathrm{image\ plane}$', 'Interpreter', 'latex');
        xlabel(ax_output, '$x\,(\mathrm{mm})$', 'Interpreter', 'latex');
        ylabel(ax_output, '$y\,(\mathrm{mm})$', 'Interpreter', 'latex');
    end

    function export_result()
        dlg = [];
        try
            if isempty(current_result)
                error('Run the simulation before exporting.');
            end
            param_lines = { ...
                sprintf('preset = %s', preset_dd.Value), ...
                sprintf('object = %s', object_dd.Value), ...
                sprintf('phase = %s', phase_dd.Value), ...
                sprintf('filter = %s', filter_dd.Value), ...
                sprintf('wavelength_nm = %.6f', wavelength_nm.Value), ...
                sprintf('focal_length_mm = %.6f', focal_length_mm.Value), ...
                sprintf('window_mm = %.6f', window_mm.Value), ...
                sprintf('samples_n = %d', round(grid_n.Value)), ...
                sprintf('object_scale_mm = %.6f', object_scale_mm.Value), ...
                sprintf('secondary_scale_mm = %.6f', secondary_scale_mm.Value), ...
                sprintf('phase_radius_mm = %.6f', phase_radius_mm.Value), ...
                sprintf('zernike_coeff_waves = %.6f', zernike_coeff_waves.Value), ...
                sprintf('filter_scale_ratio = %.6f', filter_scale_ratio.Value), ...
                sprintf('topological_charge = %d', round(topological_charge.Value)), ...
                sprintf('plot_range = %s', plot_range_mode.Value), ...
                sprintf('object_half_range_mm = %.6f', object_half_range_mm.Value), ...
                sprintf('fourier_half_range_mm = %.6f', fourier_half_range_mm.Value), ...
                sprintf('image_scaling = %s', display_scaling_dd.Value)};
            export_info = image_output('export_preview_bundle', project_root, 'fourier_studio', all_axes, ...
                {'object','phase','after_phase','spectrum','filter','output'}, [2 3], param_lines, notes_box.Value, status_box.Value, dlg);
            uialert(app_figure, sprintf('Fourier studio export saved to:\n%s', export_info.bundle_dir), 'Export complete', 'Icon', 'info');
        catch ME
            uialert(app_figure, sprintf('Fourier studio export failed:\n%s', ME.message), 'Export failed', 'Icon', 'error');
            warning('%s', getReport(ME, 'extended', 'hyperlinks', 'off'));
        end
    end

    function reset_defaults()
        load_preset_by_name(presets(1).Name);
        clear_preview();
    end

    function load_selected_preset(~, ~)
        load_preset_by_name(preset_dd.Value);
        clear_preview();
    end

    function load_preset_by_name(preset_name)
        p = fourier_params_preset(preset_name);
        preset_dd.Value = p.Name;
        object_dd.Value = best_item_match(modules.object, p.object_name);
        phase_dd.Value = best_item_match(modules.phase, p.phase_name);
        filter_dd.Value = best_item_match(modules.filter, p.filter_name);
        wavelength_nm.Value = p.wavelength_nm;
        focal_length_mm.Value = p.focal_length_mm;
        window_mm.Value = p.window_mm;
        grid_n.Value = p.n_samples;
        object_scale_mm.Value = p.object_scale_mm;
        secondary_scale_mm.Value = p.secondary_scale_mm;
        phase_radius_mm.Value = p.phase_radius_mm;
        zernike_coeff_waves.Value = p.zernike_coeff_waves;
        filter_scale_ratio.Value = p.filter_scale_ratio;
        topological_charge.Value = p.topological_charge;
        if logical(p.auto_adjust_plot_range)
            plot_range_mode.Value = 'auto';
        else
            plot_range_mode.Value = 'fixed';
        end
        object_half_range_mm.Value = p.object_plot_half_range_mm;
        fourier_half_range_mm.Value = p.fourier_plot_half_range_mm;
        if isfield(p, 'display_scaling')
            display_scaling_dd.Value = p.display_scaling;
        else
            display_scaling_dd.Value = 'fixed';
        end
        update_range_controls();
        refresh_info();
    end

    function params = collect_params()
        params = struct();
        params.wavelength_nm = wavelength_nm.Value;
        params.focal_length_mm = focal_length_mm.Value;
        params.window_mm = window_mm.Value;
        params.n_samples = round(grid_n.Value);
        params.object_scale_mm = object_scale_mm.Value;
        params.secondary_scale_mm = secondary_scale_mm.Value;
        params.phase_radius_mm = phase_radius_mm.Value;
        params.zernike_coeff_waves = zernike_coeff_waves.Value;
        params.filter_scale_ratio = filter_scale_ratio.Value;
        params.topological_charge = round(topological_charge.Value);
        params.auto_adjust_plot_range = strcmp(plot_range_mode.Value, 'auto');
        params.object_plot_half_range_mm = object_half_range_mm.Value;
        params.fourier_plot_half_range_mm = fourier_half_range_mm.Value;
        params.display_scaling = display_scaling_dd.Value;
        validateattributes(params.wavelength_nm, {'numeric'}, {'scalar','positive','finite'});
        validateattributes(params.focal_length_mm, {'numeric'}, {'scalar','positive','finite'});
        validateattributes(params.window_mm, {'numeric'}, {'scalar','positive','finite'});
        validateattributes(params.n_samples, {'numeric'}, {'scalar','integer','>=',256,'<=',4096});
        validateattributes(params.object_scale_mm, {'numeric'}, {'scalar','positive','finite'});
        validateattributes(params.secondary_scale_mm, {'numeric'}, {'scalar','positive','finite'});
        validateattributes(params.phase_radius_mm, {'numeric'}, {'scalar','positive','finite'});
        validateattributes(params.zernike_coeff_waves, {'numeric'}, {'scalar','finite'});
        validateattributes(params.filter_scale_ratio, {'numeric'}, {'scalar','positive','finite','<=',1});
        validateattributes(params.topological_charge, {'numeric'}, {'scalar','integer','finite'});
        validateattributes(params.object_plot_half_range_mm, {'numeric'}, {'scalar','positive','finite'});
        validateattributes(params.fourier_plot_half_range_mm, {'numeric'}, {'scalar','positive','finite'});
    end

    function refresh_info(~, ~)
        obj = resolve_entry(modules.object, object_dd.Value);
        ph = resolve_entry(modules.phase, phase_dd.Value);
        ft = resolve_entry(modules.filter, filter_dd.Value);
        info_area.Value = { ...
            ['object plane: ' obj.DisplayName], ...
            fallback_text(obj.Description), ...
            ' ', ...
            ['phase plane: ' ph.DisplayName], ...
            fallback_text(ph.Description), ...
            ' ', ...
            ['filter plane: ' ft.DisplayName], ...
            fallback_text(ft.Description)};
    end

    function update_range_controls(~, ~)
        manual_on = strcmp(plot_range_mode.Value, 'fixed');
        object_half_range_mm.Enable = onoff_state(manual_on);
        fourier_half_range_mm.Enable = onoff_state(manual_on);
    end
end

function render_map(ax, x_coord_mm, y_coord_mm, map_data, cmap_name, scaling_mode, fixed_clim, auto_range, fixed_half_range, support_mask, map_role)
if nargin < 10 || isempty(support_mask)
    support_mask = abs(map_data) > 0.02 * max(abs(map_data(:)) + eps);
end
if nargin < 11 || isempty(map_role)
    map_role = 'map';
end

[x_vec, y_vec] = coordinate_vectors(x_coord_mm, y_coord_mm, size(map_data));
[display_map, support_mask] = prepare_display_map(map_data, map_role, support_mask);
imagesc(ax, x_vec, y_vec, display_map);
axis(ax, 'tight');
axis(ax, 'image');
ax.YDir = 'normal';
colormap(ax, cmap_name);
if strcmpi(scaling_mode, 'fixed') && ~isempty(fixed_clim)
    if strcmpi(map_role, 'spectrum') || strcmpi(map_role, 'intensity')
        clim(ax, [0 1]);
    elseif fixed_clim(1) == fixed_clim(2)
        delta = max(1e-6, abs(fixed_clim(1)) * 1e-6 + 1e-6);
        clim(ax, [fixed_clim(1) - delta, fixed_clim(2) + delta]);
    else
        clim(ax, fixed_clim);
    end
else
    clim(ax, 'auto');
end

if auto_range
    [xlim_vals, ylim_vals] = compute_auto_limits(x_vec, y_vec, support_mask);
    xlim(ax, sanitize_axis_limits(xlim_vals, x_vec));
    ylim(ax, sanitize_axis_limits(ylim_vals, y_vec));
else
    fixed_half_range = sanitize_half_range(fixed_half_range, x_vec, y_vec);
    xlim(ax, [-fixed_half_range, fixed_half_range]);
    ylim(ax, [-fixed_half_range, fixed_half_range]);
end
end

function [display_map, support_mask] = prepare_display_map(map_data, map_role, support_mask)
map_role = lower(char(string(map_role)));
display_map = double(map_data);
scale = max(abs(display_map(:))) + eps;
if ismember(map_role, {'spectrum','intensity'})
    display_map = max(display_map, 0);
    display_map = display_map ./ max(display_map(:) + eps);
    gain = 72;
    display_map = log1p(gain * display_map) ./ log1p(gain + 1);
    support_mask = local_support_mask(double(map_data), support_mask, 0.012);
elseif ismember(map_role, {'object','filter','amplitude'})
    display_map = max(display_map, 0);
    display_map = display_map ./ max(display_map(:) + eps);
    support_mask = local_support_mask(double(map_data), support_mask, 0.01);
elseif strcmp(map_role, 'phase')
    support_mask = logical(support_mask);
else
    display_map = display_map ./ scale;
    support_mask = logical(support_mask);
end
support_mask = local_expand_mask(logical(support_mask), 2);
end

function mask = local_support_mask(map_data, fallback_mask, threshold)
d = abs(double(map_data));
d = d ./ max(d(:) + eps);
mask = d > threshold;
if nargin >= 2 && ~isempty(fallback_mask)
    mask = mask | logical(fallback_mask);
end
end

function mask = local_expand_mask(mask, steps)
mask = logical(mask);
for ii = 1:max(0, round(steps))
    mask = mask | circshift(mask, [1 0]) | circshift(mask, [-1 0]) | circshift(mask, [0 1]) | circshift(mask, [0 -1]);
end
end

function [x_vec, y_vec] = coordinate_vectors(x_coord, y_coord, data_size)
x_vec = extract_axis_vector(x_coord, data_size(2), 'x');
y_vec = extract_axis_vector(y_coord, data_size(1), 'y');
end

function vec = extract_axis_vector(coord, n_expected, axis_role)
coord = double(coord);
if isvector(coord)
    vec = coord(:);
    if numel(vec) ~= n_expected
        error('Coordinate vector length mismatch for %s axis.', axis_role);
    end
else
    first_row = coord(1, :).';
    first_col = coord(:, 1);
    switch lower(axis_role)
        case 'x'
            vec = choose_candidate(first_row, first_col, n_expected);
        case 'y'
            vec = choose_candidate(first_col, first_row, n_expected);
        otherwise
            error('Unknown axis role: %s', axis_role);
    end
end
vec = vec(:);
if numel(vec) >= 2 && vec(2) < vec(1)
    vec = flipud(vec);
end
end

function vec = choose_candidate(primary_candidate, fallback_candidate, n_expected)
primary_candidate = primary_candidate(:);
fallback_candidate = fallback_candidate(:);
primary_good = numel(primary_candidate) == n_expected && range(primary_candidate) > 0;
fallback_good = numel(fallback_candidate) == n_expected && range(fallback_candidate) > 0;
if primary_good
    vec = primary_candidate;
elseif fallback_good
    vec = fallback_candidate;
elseif numel(primary_candidate) == n_expected
    vec = primary_candidate;
elseif numel(fallback_candidate) == n_expected
    vec = fallback_candidate;
else
    error('Could not extract a valid coordinate vector of length %d.', n_expected);
end
end

function [xlim_vals, ylim_vals] = compute_auto_limits(x_vec, y_vec, support_mask)
mask = logical(support_mask);
if ~any(mask(:))
    xlim_vals = [min(x_vec), max(x_vec)];
    ylim_vals = [min(y_vec), max(y_vec)];
    return
end
row_any = any(mask, 2);
col_any = any(mask, 1);
y_idx = find(row_any);
x_idx = find(col_any);
if isempty(x_idx) || isempty(y_idx)
    xlim_vals = [min(x_vec), max(x_vec)];
    ylim_vals = [min(y_vec), max(y_vec)];
    return
end
x_lo = x_vec(max(1, x_idx(1)));
x_hi = x_vec(min(numel(x_vec), x_idx(end)));
y_lo = y_vec(max(1, y_idx(1)));
y_hi = y_vec(min(numel(y_vec), y_idx(end)));
r = max(abs([x_lo, x_hi, y_lo, y_hi]));
r = 1.18 * max(r, eps);
max_r = max([abs(x_vec(:)); abs(y_vec(:)); r]);
r = min(r, max_r);
xlim_vals = [-r, r];
ylim_vals = [-r, r];
end

function lims = sanitize_axis_limits(lims, fallback_vec)
lims = double(lims(:).');
if numel(lims) ~= 2 || ~all(isfinite(lims))
    lims = [min(fallback_vec), max(fallback_vec)];
end
lims = sort(lims, 'ascend');
if lims(1) == lims(2)
    center = lims(1);
    span = max(abs(center) * 1e-6, 1e-6);
    lims = [center - span, center + span];
end
end

function half_range = sanitize_half_range(half_range, x_vec, y_vec)
half_range = double(half_range);
if ~isscalar(half_range) || ~isfinite(half_range) || half_range <= 0
    half_range = max([abs(x_vec(1)), abs(x_vec(end)), abs(y_vec(1)), abs(y_vec(end)), 1e-6]);
end
end

function items = local_items(entries)
if isempty(entries)
    items = {'<none>'};
else
    items = {entries.DisplayName};
end
end

function entry = resolve_entry(entries, display_name)
idx = find(strcmpi({entries.DisplayName}, char(string(display_name))), 1, 'first');
if isempty(idx)
    error('Could not resolve module: %s', char(string(display_name)));
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

function out = fallback_text(txt)
if isempty(txt)
    out = 'No additional description.';
else
    out = txt;
end
end

function state = onoff_state(tf)
if tf
    state = 'on';
else
    state = 'off';
end
end

function lines = local_fourier_notes()
lines = { ...
    'Fourier studio models a modular 4f optical system: object plane -> phase plane -> Fourier filter -> image plane.', ...
    'preset fills a consistent object/phase/filter combination. object plane controls amplitude mask U0(x,y).', ...
    'phase plane adds phase phi(x,y) in radians; phase radius is finite pupil/support radius for many phase modules.', ...
    'filter plane is H(fx,fy), a mask in the Fourier plane. filter scale ratio controls its relative cutoff/slit size.', ...
    'wavelength and focal length set Fourier-plane coordinates x_f = lambda f f_x. window size sets real-space field of view.', ...
    'object scale and secondary scale tune aperture size, slit spacing, lattice pitch, or other module-specific sizes.', ...
    'plot range auto crops salient support; fixed uses object/fourier half-range fields. Fourier intensity uses enhanced log display.', ...
    'The six panels show object amplitude, phase, after-phase amplitude, Fourier intensity, filter, and final image intensity.'};
end
