function tab = create_fourier_studio_tab(tab_group, project_root)
%CREATE_FOURIER_STUDIO_TAB Build a modular 4f Fourier optics studio tab.

app_figure = ancestor(tab_group, 'figure');
fourier_root = fullfile(project_root, 'core', 'fourier');
modules = discover_fourier_modules(fourier_root);
presets = fourier_params_preset();

current_result = [];

tab = uitab(tab_group, 'Title', 'fourier studio');
root = uigridlayout(tab, [1 2]);
root.ColumnWidth = {292, '1x'};
root.RowHeight = {'1x'};
root.Padding = [8 8 8 8];
root.ColumnSpacing = 10;

left_panel = uipanel(root, 'Title', 'controls');
left_panel.Layout.Row = 1;
left_panel.Layout.Column = 1;
left_grid = uigridlayout(left_panel, [3 1]);
left_grid.RowHeight = {'1x', 'fit', 110};
left_grid.ColumnWidth = {'1x'};
left_grid.Padding = [8 8 8 8];
left_grid.RowSpacing = 8;

subtabs = uitabgroup(left_grid);
subtabs.Layout.Row = 1;
subtabs.Layout.Column = 1;
setup_tab = uitab(subtabs, 'Title', 'setup');
basic_tab = uitab(subtabs, 'Title', 'basic');
advanced_tab = uitab(subtabs, 'Title', 'advanced');
info_tab = uitab(subtabs, 'Title', 'info');

setup_grid = uigridlayout(setup_tab, [6 1]);
setup_grid.RowHeight = {'fit','fit','fit','fit','fit','1x'};
setup_grid.Padding = [8 8 8 8];
setup_grid.RowSpacing = 5;
object_items = local_items(modules.object);
phase_items = local_items(modules.phase);
filter_items = local_items(modules.filter);
preset_dd = create_dropdown_control(setup_grid, 'preset', {presets.Name}, presets(1).Name, 'Load a curated combination of object, phase, filter, and scales.');
object_dd = create_dropdown_control(setup_grid, 'object plane', object_items, object_items{1}, 'Object-plane amplitude module.');
phase_dd = create_dropdown_control(setup_grid, 'phase plane', phase_items, phase_items{1}, 'Phase-plane module.');
filter_dd = create_dropdown_control(setup_grid, 'filter plane', filter_items, filter_items{1}, 'Fourier-plane filtering module.');
refresh_button = uibutton(setup_grid, 'push', 'Text', 'refresh descriptions', 'ButtonPushedFcn', @refresh_info);
refresh_button.Layout.Row = 5;
refresh_button.Layout.Column = 1;
setup_notes = uitextarea(setup_grid, 'Editable', 'off', 'Value', {
    'Combine any object plane, phase plane, and Fourier filter.', ...
    'This tab imports the richer modular 4f workflow from the reference project.', ...
    'Use presets for classroom-ready demonstrations, then fine-tune basic and advanced controls.'});
setup_notes.Layout.Row = 6;
setup_notes.Layout.Column = 1;

basic_grid = uigridlayout(basic_tab, [6 1]);
basic_grid.RowHeight = {'fit','fit','fit','fit','fit','fit'};
basic_grid.Padding = [8 8 8 8];
basic_grid.RowSpacing = 5;
wavelength_nm = create_numeric_control(basic_grid, 'wavelength (nm)', 632.8, 'Optical wavelength.');
focal_length_mm = create_numeric_control(basic_grid, 'focal length (mm)', 250, '4f lens focal length.');
window_mm = create_numeric_control(basic_grid, 'window size (mm)', 4.0, 'Simulation field of view in the object plane.');
grid_n = create_numeric_control(basic_grid, 'samples N', 1536, 'Simulation grid size. Use 1536--2048 for cleaner diffraction details.');
object_scale_mm = create_numeric_control(basic_grid, 'object scale (mm)', 0.55, 'Primary object size parameter reused by many object modules.');
secondary_scale_mm = create_numeric_control(basic_grid, 'secondary scale (mm)', 0.30, 'Secondary spacing / pitch parameter reused by many modules.');

advanced_grid = uigridlayout(advanced_tab, [8 1]);
advanced_grid.RowHeight = {'fit','fit','fit','fit','fit','fit','fit','fit'};
advanced_grid.Padding = [8 8 8 8];
advanced_grid.RowSpacing = 5;
phase_radius_mm = create_numeric_control(advanced_grid, 'phase radius (mm)', 1.00, 'Finite support radius for pupil-like phase modules.');
zernike_coeff_waves = create_numeric_control(advanced_grid, 'zernike coeff (waves)', 0.30, 'Strength of selected aberration phase.');
filter_scale_ratio = create_numeric_control(advanced_grid, 'filter scale ratio', 0.18, 'Relative size of Fourier-plane masks.');
topological_charge = create_numeric_control(advanced_grid, 'vortex charge', 1, 'Topological charge for vortex phase plates.');
plot_range_mode = create_dropdown_control(advanced_grid, 'plot range', {'auto', 'fixed'}, 'auto', 'Auto crops to salient content; fixed uses the two half-range fields below.');
object_half_range_mm = create_numeric_control(advanced_grid, 'object half range (mm)', 1.20, 'Manual display half-range in the object and image planes.');
fourier_half_range_mm = create_numeric_control(advanced_grid, 'fourier half range (mm)', 8.00, 'Manual display half-range in the Fourier and filter planes. Values around 6--12 mm are usually more balanced for fixed viewing.');
display_scaling_dd = create_dropdown_control(advanced_grid, 'image scaling', {'fixed', 'auto'}, 'fixed', 'Fixed uses consistent color limits; auto stretches each panel.');

info_grid = uigridlayout(info_tab, [1 1]);
info_grid.Padding = [8 8 8 8];
info_area = uitextarea(info_grid, 'Editable', 'off');
info_area.Layout.Row = 1;
info_area.Layout.Column = 1;

action_panel = uipanel(left_grid, 'Title', 'actions');
action_panel.Layout.Row = 2;
action_panel.Layout.Column = 1;
action_grid = uigridlayout(action_panel, [1 1]);
action_grid.RowHeight = {28};
action_grid.Padding = [8 8 8 8];
buttons = create_button_row(action_grid, @run_simulation, @reset_defaults, @export_result);
buttons.run.Tooltip = 'Run the modular 4f Fourier optics simulation.';

status_box = uitextarea(left_grid, 'Editable', 'off', 'FontName', 'Courier New', 'Value', {'status: ready'});
status_box.Layout.Row = 3;
status_box.Layout.Column = 1;

right_grid = uigridlayout(root, [2 1]);
right_grid.Layout.Row = 1;
right_grid.Layout.Column = 2;
right_grid.RowHeight = {'1x', 110};
right_grid.ColumnWidth = {'1x'};
right_grid.Padding = [0 0 0 0];
right_grid.RowSpacing = 8;

preview_panel = uipanel(right_grid, 'Title', 'preview');
preview_panel.Layout.Row = 1;
preview_panel.Layout.Column = 1;
preview_grid = uigridlayout(preview_panel, [2 3]);
preview_grid.RowHeight = {'1x', '1x'};
preview_grid.ColumnWidth = {'1x', '1x', '1x'};
preview_grid.Padding = [1 1 1 1];
preview_grid.RowSpacing = 2;
preview_grid.ColumnSpacing = 2;

ax_object = uiaxes(preview_grid); ax_object.Layout.Row = 1; ax_object.Layout.Column = 1;
ax_phase = uiaxes(preview_grid); ax_phase.Layout.Row = 1; ax_phase.Layout.Column = 2;
ax_amp = uiaxes(preview_grid); ax_amp.Layout.Row = 1; ax_amp.Layout.Column = 3;
ax_spectrum = uiaxes(preview_grid); ax_spectrum.Layout.Row = 2; ax_spectrum.Layout.Column = 1;
ax_filter = uiaxes(preview_grid); ax_filter.Layout.Row = 2; ax_filter.Layout.Column = 2;
ax_output = uiaxes(preview_grid); ax_output.Layout.Row = 2; ax_output.Layout.Column = 3;
all_axes = [ax_object, ax_phase, ax_amp, ax_spectrum, ax_filter, ax_output];
for ax = all_axes
    apply_axes_style(ax);
end

notes_box = uitextarea(right_grid, 'Editable', 'off');
notes_box.Layout.Row = 2;
notes_box.Layout.Column = 1;

preset_dd.ValueChangedFcn = @load_selected_preset;
object_dd.ValueChangedFcn = @refresh_info;
phase_dd.ValueChangedFcn = @refresh_info;
filter_dd.ValueChangedFcn = @refresh_info;
plot_range_mode.ValueChangedFcn = @update_range_controls;

load_preset_by_name(presets(1).Name);
execute_run(false);

    function run_simulation(~, ~)
        execute_run(true);
    end

    function execute_run(show_alert)
        dlg = [];
        if show_alert
            dlg = create_progress_dialog(app_figure, 'running fourier studio');
        end
        try
            update_progress_dialog(dlg, 0.08, 'collecting parameters');
            params = collect_params();
            obj_entry = resolve_entry(modules.object, object_dd.Value);
            ph_entry = resolve_entry(modules.phase, phase_dd.Value);
            ft_entry = resolve_entry(modules.filter, filter_dd.Value);
            params.object_name = obj_entry.DisplayName;
            params.phase_name = ph_entry.DisplayName;
            params.filter_name = ft_entry.DisplayName;

            update_progress_dialog(dlg, 0.32, 'computing 4f model');
            current_result = fourier_4f_model(params, str2func(obj_entry.FunctionName), str2func(ph_entry.FunctionName), str2func(ft_entry.FunctionName));

            update_progress_dialog(dlg, 0.72, 'rendering preview');
            render_result(current_result);
            refresh_info();
            notes_box.Value = notes_catalog('fourier_studio', 'modular_4f');

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
                apply_square_plot_box(ax_iter);
            end

            update_progress_dialog(dlg, 1.00, 'run complete');
            pause(0.08);
            close_progress_dialog(dlg);
            if show_alert
                uialert(app_figure, 'Fourier studio preview updated successfully.', 'Run complete', 'Icon', 'info');
            end
        catch ME
            close_progress_dialog(dlg);
            uialert(app_figure, sprintf('Fourier studio run failed:\n%s', ME.message), 'Run failed', 'Icon', 'error');
            warning('%s', getReport(ME, 'extended', 'hyperlinks', 'off'));
        end
    end

    function render_result(result)
        scaling_mode = display_scaling_dd.Value;
        auto_range = strcmp(plot_range_mode.Value, 'auto');
        object_range = object_half_range_mm.Value;
        fourier_range = fourier_half_range_mm.Value;

        render_map(ax_object, result.x_mm, result.y_mm, result.object_amp, 'gray', scaling_mode, [0 1], auto_range, object_range, result.object_amp > 0.05);
        title(ax_object, '$\mathrm{object\ plane}$', 'Interpreter', 'latex');
        xlabel(ax_object, '$x\,(\mathrm{mm})$', 'Interpreter', 'latex');
        ylabel(ax_object, '$y\,(\mathrm{mm})$', 'Interpreter', 'latex');

        render_map(ax_phase, result.x_mm, result.y_mm, result.phase_wrapped, 'parula', scaling_mode, [-pi pi], auto_range, object_range, result.phase_support > 0.5);
        title(ax_phase, '$\mathrm{phase\ plane}$', 'Interpreter', 'latex');
        xlabel(ax_phase, '$x\,(\mathrm{mm})$', 'Interpreter', 'latex');
        ylabel(ax_phase, '$y\,(\mathrm{mm})$', 'Interpreter', 'latex');

        render_map(ax_amp, result.x_mm, result.y_mm, result.after_phase_amp, 'gray', scaling_mode, [0 1], auto_range, object_range, result.after_phase_amp > 0.02);
        title(ax_amp, '$\mathrm{after\ phase}$', 'Interpreter', 'latex');
        xlabel(ax_amp, '$x\,(\mathrm{mm})$', 'Interpreter', 'latex');
        ylabel(ax_amp, '$y\,(\mathrm{mm})$', 'Interpreter', 'latex');

        render_map(ax_spectrum, result.xf_mm, result.yf_mm, log1p(result.spectrum_intensity), 'hot', scaling_mode, [0 log(2)], auto_range, fourier_range, result.spectrum_intensity > 0.02);
        title(ax_spectrum, '$\mathrm{fourier\ intensity}$', 'Interpreter', 'latex');
        xlabel(ax_spectrum, '$x_f\,(\mathrm{mm})$', 'Interpreter', 'latex');
        ylabel(ax_spectrum, '$y_f\,(\mathrm{mm})$', 'Interpreter', 'latex');

        render_map(ax_filter, result.xf_mm, result.yf_mm, result.filter_amp, 'gray', scaling_mode, [0 1], auto_range, fourier_range, result.filter_amp > 0.02);
        title(ax_filter, '$\mathrm{filter\ plane}$', 'Interpreter', 'latex');
        xlabel(ax_filter, '$x_f\,(\mathrm{mm})$', 'Interpreter', 'latex');
        ylabel(ax_filter, '$y_f\,(\mathrm{mm})$', 'Interpreter', 'latex');

        render_map(ax_output, result.x_mm, result.y_mm, result.output_intensity, 'hot', scaling_mode, [0 1], auto_range, object_range, result.output_intensity > 0.02);
        title(ax_output, '$\mathrm{image\ plane}$', 'Interpreter', 'latex');
        xlabel(ax_output, '$x\,(\mathrm{mm})$', 'Interpreter', 'latex');
        ylabel(ax_output, '$y\,(\mathrm{mm})$', 'Interpreter', 'latex');
    end

    function export_result(~, ~)
        dlg = create_progress_dialog(app_figure, 'exporting fourier studio');
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
            export_info = export_preview_bundle(project_root, 'fourier_studio', all_axes, ...
                {'object','phase','after_phase','spectrum','filter','output'}, [2 3], param_lines, notes_box.Value, status_box.Value, dlg);
            close_progress_dialog(dlg);
            uialert(app_figure, sprintf('Fourier studio export saved to:\n%s', export_info.bundle_dir), 'Export complete', 'Icon', 'info');
        catch ME
            close_progress_dialog(dlg);
            uialert(app_figure, sprintf('Fourier studio export failed:\n%s', ME.message), 'Export failed', 'Icon', 'error');
            warning('%s', getReport(ME, 'extended', 'hyperlinks', 'off'));
        end
    end

    function reset_defaults(~, ~)
        load_preset_by_name(presets(1).Name);
        execute_run(false);
    end

    function load_selected_preset(~, ~)
        load_preset_by_name(preset_dd.Value);
        execute_run(false);
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

function render_map(ax, x_coord_mm, y_coord_mm, map_data, cmap_name, scaling_mode, fixed_clim, auto_range, fixed_half_range, support_mask)
if nargin < 10 || isempty(support_mask)
    support_mask = abs(map_data) > 0.02 * max(abs(map_data(:)) + eps);
end

[x_vec, y_vec] = coordinate_vectors(x_coord_mm, y_coord_mm, size(map_data));
imagesc(ax, x_vec, y_vec, map_data);
axis(ax, 'tight');
apply_square_plot_box(ax);
ax.YDir = 'normal';
colormap(ax, cmap_name);
if strcmpi(scaling_mode, 'fixed') && ~isempty(fixed_clim)
    if fixed_clim(1) == fixed_clim(2)
        delta = max(1e-6, abs(fixed_clim(1)) * 1e-6 + 1e-6);
        fixed_clim = [fixed_clim(1) - delta, fixed_clim(2) + delta];
    end
    clim(ax, fixed_clim);
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
y_min = max(1, y_idx(1) - 3);
y_max = min(numel(y_vec), y_idx(end) + 3);
x_min = max(1, x_idx(1) - 3);
x_max = min(numel(x_vec), x_idx(end) + 3);
xlim_vals = [x_vec(x_min), x_vec(x_max)];
ylim_vals = [y_vec(y_min), y_vec(y_max)];
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
