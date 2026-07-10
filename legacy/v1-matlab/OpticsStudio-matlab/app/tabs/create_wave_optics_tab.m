function tab = create_wave_optics_tab(tab_group, project_root)
%CREATE_WAVE_OPTICS_TAB Build the wave optics tab.

app_figure = ancestor(tab_group, 'figure');

tab = uitab(tab_group, 'Title', 'wave optics');
root = uigridlayout(tab, [1 2]);
root.ColumnWidth = {282, '1x'};
root.RowHeight = {'1x'};
root.Padding = [8 8 8 8];
root.ColumnSpacing = 10;

left_panel = uipanel(root, 'Title', 'controls');
left_panel.Layout.Row = 1;
left_panel.Layout.Column = 1;
left_grid = uigridlayout(left_panel, [5 1]);
left_grid.RowHeight = {'fit', 'fit', 'fit', 96, '1x'};
left_grid.ColumnWidth = {'1x'};
left_grid.Padding = [8 8 8 8];
left_grid.RowSpacing = 8;

physical_panel = uipanel(left_grid, 'Title', 'physical parameters');
physical_panel.Layout.Row = 1;
physical_panel.Layout.Column = 1;
physical_grid = uigridlayout(physical_panel, [7 1]);
physical_grid.RowHeight = {'fit','fit','fit','fit','fit','fit','fit'};
physical_grid.Padding = [8 8 8 8];
physical_grid.RowSpacing = 5;
mode_dd = create_dropdown_control(physical_grid, 'mode', {'free_space', '4f_filtering'}, 'free_space', 'Choose propagation or Fourier filtering.');
object_dd = create_dropdown_control(physical_grid, 'object', {'bars', 'mesh', 'double_slit', 'aperture', 'gaussian_lattice'}, 'bars', 'Synthetic object field.');
filter_dd = create_dropdown_control(physical_grid, 'filter', {'none', 'pinhole', 'ring', 'horizontal_single', 'horizontal_double', 'vertical_single', 'vertical_double'}, 'pinhole', 'Fourier-plane mask.');
filter_scale = create_numeric_control(physical_grid, 'filter scale', 0.16, 'Dimensionless Fourier-mask scale.');
pixel_size = create_numeric_control(physical_grid, 'pixel size (um)', 6.5, 'Sample-plane pitch.');
wavelength_nm = create_numeric_control(physical_grid, 'wavelength (nm)', 532, 'Scalar wavelength.');
prop_distance = create_numeric_control(physical_grid, 'distance (mm)', 20, 'Propagation distance for free-space mode.');

numerical_panel = uipanel(left_grid, 'Title', 'numerical / display parameters');
numerical_panel.Layout.Row = 2;
numerical_panel.Layout.Column = 1;
numerical_grid = uigridlayout(numerical_panel, [3 1]);
numerical_grid.RowHeight = {'fit','fit','fit'};
numerical_grid.Padding = [8 8 8 8];
numerical_grid.RowSpacing = 5;
grid_n = create_numeric_control(numerical_grid, 'grid size', 256, 'Simulation grid size in pixels.');
use_bandlimit = create_dropdown_control(numerical_grid, 'band-limit', {'on', 'off'}, 'on', 'Apply band-limited angular-spectrum support.');
display_scale_dd = create_dropdown_control(numerical_grid, 'image scaling', {'fixed', 'auto'}, 'fixed', 'Fixed uses consistent color limits; auto stretches each image.');

action_panel = uipanel(left_grid, 'Title', 'actions');
action_panel.Layout.Row = 3;
action_panel.Layout.Column = 1;
action_grid = uigridlayout(action_panel, [1 1]);
action_grid.RowHeight = {28};
action_grid.Padding = [8 8 8 8];
button_block = create_button_row(action_grid, @run_simulation, @reset_defaults, @export_result);
button_block.run.Tooltip = 'Run current wave-optics simulation.';

status_box = uitextarea(left_grid, ...
    'Editable', 'off', ...
    'Value', {'status: ready'}, ...
    'FontName', 'Courier New');
status_box.Layout.Row = 4;
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
preview_grid = uigridlayout(preview_panel, [2 2]);
preview_grid.RowHeight = {'1x', '1x'};
preview_grid.ColumnWidth = {'1x', '1x'};
preview_grid.Padding = [3 3 3 3];
preview_grid.RowSpacing = 4;
preview_grid.ColumnSpacing = 4;

ax_input = uiaxes(preview_grid); ax_input.Layout.Row = 1; ax_input.Layout.Column = 1;
ax_aux1 = uiaxes(preview_grid); ax_aux1.Layout.Row = 1; ax_aux1.Layout.Column = 2;
ax_aux2 = uiaxes(preview_grid); ax_aux2.Layout.Row = 2; ax_aux2.Layout.Column = 1;
ax_output = uiaxes(preview_grid); ax_output.Layout.Row = 2; ax_output.Layout.Column = 2;
all_axes = [ax_input, ax_aux1, ax_aux2, ax_output];
for ax = all_axes
    apply_axes_style(ax);
end

notes_box = uitextarea(right_grid, 'Editable', 'off');
notes_box.Layout.Row = 2;
notes_box.Layout.Column = 1;

execute_run(false);

    function run_simulation(~, ~)
        execute_run(true);
    end

    function execute_run(show_alert)
        dlg = [];
        if show_alert
            dlg = create_progress_dialog(app_figure, 'running wave optics');
        end
        try
            update_progress_dialog(dlg, 0.10, 'reading parameters');
            n = round(max(64, grid_n.Value));
            object_field = make_demo_object(object_dd.Value, n);
            dx = pixel_size.Value * 1e-6;
            lambda = wavelength_nm.Value * 1e-9;
            z = prop_distance.Value * 1e-3;
            use_bl = strcmp(use_bandlimit.Value, 'on');
            mode_key = mode_dd.Value;
            scaling_mode = display_scale_dd.Value;

            update_progress_dialog(dlg, 0.35, 'computing optical fields');
            [~, ~, fx, fy] = make_coordinate_grid(n, n, dx, dx);

            if strcmp(mode_key, 'free_space')
                u0 = object_field;
                [u1, transfer] = angular_spectrum_propagation(u0, dx, lambda, z, use_bl);
                spectrum = normalize_array(log1p(abs(fftshift(fft2(ifftshift(u0))))));
                output_intensity = normalize_array(abs(u1).^2);
                output_phase = angle(u1);

                update_progress_dialog(dlg, 0.70, 'rendering preview');
                apply_image_display(ax_input, object_field, 'gray', scaling_mode, [0 1], 'image');
                title(ax_input, '$\mathrm{input\ amplitude}$', 'Interpreter', 'latex');
                apply_image_display(ax_aux1, spectrum, 'gray', scaling_mode, [0 1], 'image');
                title(ax_aux1, '$\mathrm{input\ spectrum}$', 'Interpreter', 'latex');
                apply_image_display(ax_aux2, real(transfer), 'parula', scaling_mode, [-1 1], 'image');
                title(ax_aux2, '$\Re\{H(f_x,f_y)\}$', 'Interpreter', 'latex');
                apply_image_display(ax_output, output_intensity, 'hot', scaling_mode, [0 1], 'image');
                title(ax_output, '$\mathrm{output\ intensity}$', 'Interpreter', 'latex');

                status_box.Value = { ...
                    sprintf('mode              : %s', mode_key), ...
                    sprintf('grid              : %d x %d', n, n), ...
                    sprintf('wavelength        : %.1f nm', wavelength_nm.Value), ...
                    sprintf('pixel size        : %.2f um', pixel_size.Value), ...
                    sprintf('distance          : %.2f mm', prop_distance.Value), ...
                    sprintf('band-limit        : %s', use_bandlimit.Value), ...
                    sprintf('display scaling   : %s', scaling_mode), ...
                    sprintf('max output phase  : %.3f rad', max(output_phase(:))), ...
                    sprintf('peak intensity    : %.3f', max(output_intensity(:)))};
            else
                mask = make_fourier_filter(filter_dd.Value, fx, fy, filter_scale.Value);
                spectrum = fftshift(fft2(ifftshift(object_field)));
                filtered = spectrum .* mask;
                out = fftshift(ifft2(ifftshift(filtered)));
                out_intensity = normalize_array(abs(out).^2);

                update_progress_dialog(dlg, 0.70, 'rendering preview');
                apply_image_display(ax_input, object_field, 'gray', scaling_mode, [0 1], 'image');
                title(ax_input, '$\mathrm{input\ object}$', 'Interpreter', 'latex');
                apply_image_display(ax_aux1, normalize_array(log1p(abs(spectrum))), 'gray', scaling_mode, [0 1], 'image');
                title(ax_aux1, '$|\mathcal{F}\{U_0\}|$', 'Interpreter', 'latex');
                apply_image_display(ax_aux2, mask, 'gray', scaling_mode, [0 1], 'image');
                title(ax_aux2, '$\mathrm{filter\ mask}$', 'Interpreter', 'latex');
                apply_image_display(ax_output, out_intensity, 'hot', scaling_mode, [0 1], 'image');
                title(ax_output, '$\mathrm{filtered\ image}$', 'Interpreter', 'latex');

                status_box.Value = { ...
                    sprintf('mode              : %s', mode_key), ...
                    sprintf('object            : %s', object_dd.Value), ...
                    sprintf('filter            : %s', filter_dd.Value), ...
                    sprintf('filter scale      : %.3f', filter_scale.Value), ...
                    sprintf('grid              : %d x %d', n, n), ...
                    sprintf('display scaling   : %s', scaling_mode), ...
                    sprintf('peak output       : %.3f', max(out_intensity(:))), ...
                    sprintf('mask support      : %.2f %%', 100 * mean(mask(:) > 0))};
            end

            notes_box.Value = notes_catalog('wave_optics', mode_key);
            for ax = all_axes
                ax.XTick = [];
                ax.YTick = [];
            end

            for ax_iter = all_axes
                apply_square_plot_box(ax_iter);
            end

            update_progress_dialog(dlg, 1.00, 'run complete');
            pause(0.08);
            close_progress_dialog(dlg);
            if show_alert
                uialert(app_figure, 'Wave-optics preview updated successfully.', 'Run complete', 'Icon', 'info');
            end
        catch ME
            close_progress_dialog(dlg);
            uialert(app_figure, sprintf('Wave-optics run failed:\n%s', ME.message), 'Run failed', 'Icon', 'error');
            warning('%s', getReport(ME, 'extended', 'hyperlinks', 'off'));
        end
    end

    function reset_defaults(~, ~)
        mode_dd.Value = 'free_space';
        object_dd.Value = 'bars';
        filter_dd.Value = 'pinhole';
        filter_scale.Value = 0.16;
        grid_n.Value = 256;
        pixel_size.Value = 6.5;
        wavelength_nm.Value = 532;
        prop_distance.Value = 20;
        use_bandlimit.Value = 'on';
        display_scale_dd.Value = 'fixed';
        execute_run(false);
    end

    function export_result(~, ~)
        dlg = create_progress_dialog(app_figure, 'exporting wave optics');
        try
            param_lines = { ...
                sprintf('mode = %s', mode_dd.Value), ...
                sprintf('object = %s', object_dd.Value), ...
                sprintf('filter = %s', filter_dd.Value), ...
                sprintf('filter_scale = %.6f', filter_scale.Value), ...
                sprintf('pixel_size_um = %.6f', pixel_size.Value), ...
                sprintf('wavelength_nm = %.6f', wavelength_nm.Value), ...
                sprintf('distance_mm = %.6f', prop_distance.Value), ...
                sprintf('grid_size = %d', round(grid_n.Value)), ...
                sprintf('band_limit = %s', use_bandlimit.Value), ...
                sprintf('image_scaling = %s', display_scale_dd.Value)};
            export_info = export_preview_bundle(project_root, 'wave_optics', all_axes, ...
                {'input','aux1','aux2','output'}, [2 2], param_lines, notes_box.Value, status_box.Value, dlg);
            close_progress_dialog(dlg);
            uialert(app_figure, sprintf('Wave-optics export saved to:\n%s', export_info.bundle_dir), 'Export complete', 'Icon', 'info');
        catch ME
            close_progress_dialog(dlg);
            uialert(app_figure, sprintf('Wave-optics export failed:\n%s', ME.message), 'Export failed', 'Icon', 'error');
            warning('%s', getReport(ME, 'extended', 'hyperlinks', 'off'));
        end
    end
end
