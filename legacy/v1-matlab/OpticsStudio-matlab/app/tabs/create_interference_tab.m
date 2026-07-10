function tab = create_interference_tab(tab_group, project_root)
%CREATE_INTERFERENCE_TAB Build the interference and phase tab.

app_figure = ancestor(tab_group, 'figure');

tab = uitab(tab_group, 'Title', 'interference and phase');
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
physical_grid = uigridlayout(physical_panel, [8 1]);
physical_grid.RowHeight = {'fit','fit','fit','fit','fit','fit','fit','fit'};
physical_grid.Padding = [8 8 8 8];
physical_grid.RowSpacing = 5;
mode_dd = create_dropdown_control(physical_grid, 'mode', {'moire', 'shearing', 'gs_phase'}, 'moire', 'Choose the active interference or phase-retrieval demo.');
freq_1 = create_numeric_control(physical_grid, 'grating 1 frequency', 18, 'Normalized grating frequency.');
freq_2 = create_numeric_control(physical_grid, 'grating 2 frequency', 19.2, 'Normalized grating frequency.');
angle_2 = create_numeric_control(physical_grid, 'grating 2 angle (deg)', 2.5, 'Angle offset between gratings.');
aberration_dd = create_dropdown_control(physical_grid, 'aberration', {'defocus', 'astigmatism', 'coma', 'spherical'}, 'coma', 'Wavefront basis.');
coeff_edit = create_numeric_control(physical_grid, 'coefficient (waves)', 0.45, 'Wavefront coefficient.');
shear_edit = create_numeric_control(physical_grid, 'shear (px)', 10, 'Pixel shear for interferometry.');
carrier_edit = create_numeric_control(physical_grid, 'carrier frequency', 8, 'Spatial carrier fringe frequency.');

numerical_panel = uipanel(left_grid, 'Title', 'numerical / display parameters');
numerical_panel.Layout.Row = 2;
numerical_panel.Layout.Column = 1;
numerical_grid = uigridlayout(numerical_panel, [4 1]);
numerical_grid.RowHeight = {'fit','fit','fit','fit'};
numerical_grid.Padding = [8 8 8 8];
numerical_grid.RowSpacing = 5;
grid_n = create_numeric_control(numerical_grid, 'grid size', 256, 'Simulation grid size.');
iter_edit = create_numeric_control(numerical_grid, 'GS iterations', 80, 'Gerchberg-Saxton iteration count.');
alpha_edit = create_numeric_control(numerical_grid, 'GS damping', 0.85, 'Weighted pupil update.');
display_scale_dd = create_dropdown_control(numerical_grid, 'image scaling', {'fixed', 'auto'}, 'fixed', 'Fixed uses consistent color limits; auto stretches each image.');

action_panel = uipanel(left_grid, 'Title', 'actions');
action_panel.Layout.Row = 3;
action_panel.Layout.Column = 1;
action_grid = uigridlayout(action_panel, [1 1]);
action_grid.RowHeight = {28};
action_grid.Padding = [8 8 8 8];
create_button_row(action_grid, @run_simulation, @reset_defaults, @export_result);

status_box = uitextarea(left_grid, 'Editable', 'off', 'FontName', 'Courier New');
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

ax_1 = uiaxes(preview_grid); ax_1.Layout.Row = 1; ax_1.Layout.Column = 1;
ax_2 = uiaxes(preview_grid); ax_2.Layout.Row = 1; ax_2.Layout.Column = 2;
ax_3 = uiaxes(preview_grid); ax_3.Layout.Row = 2; ax_3.Layout.Column = 1;
ax_4 = uiaxes(preview_grid); ax_4.Layout.Row = 2; ax_4.Layout.Column = 2;
all_axes = [ax_1, ax_2, ax_3, ax_4];
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
            dlg = create_progress_dialog(app_figure, 'running interference');
        end
        try
            update_progress_dialog(dlg, 0.10, 'reading parameters');
            n = round(max(64, grid_n.Value));
            mode_key = mode_dd.Value;
            scaling_mode = display_scale_dd.Value;

            update_progress_dialog(dlg, 0.42, 'computing fields');
            switch mode_key
                case 'moire'
                    g1 = make_grating(n, freq_1.Value, 0, 0);
                    g2 = make_grating(n, freq_2.Value, angle_2.Value, 0);
                    moire_img = normalize_array(g1 .* g2);
                    moire_fft = normalize_array(log1p(abs(fftshift(fft2(ifftshift(moire_img))))));

                    update_progress_dialog(dlg, 0.72, 'rendering preview');
                    apply_image_display(ax_1, g1, 'gray', scaling_mode, [0 1], 'image');
                    title(ax_1, '$\mathrm{grating\ 1}$', 'Interpreter', 'latex');
                    apply_image_display(ax_2, g2, 'gray', scaling_mode, [0 1], 'image');
                    title(ax_2, '$\mathrm{grating\ 2}$', 'Interpreter', 'latex');
                    apply_image_display(ax_3, moire_img, 'gray', scaling_mode, [0 1], 'image');
                    title(ax_3, '$\mathrm{moire\ product}$', 'Interpreter', 'latex');
                    apply_image_display(ax_4, moire_fft, 'hot', scaling_mode, [0 1], 'image');
                    title(ax_4, '$\mathrm{moire\ spectrum}$', 'Interpreter', 'latex');

                    status_box.Value = { ...
                        sprintf('mode             : %s', mode_key), ...
                        sprintf('f1               : %.2f', freq_1.Value), ...
                        sprintf('f2               : %.2f', freq_2.Value), ...
                        sprintf('angle offset     : %.2f deg', angle_2.Value), ...
                        sprintf('display scaling  : %s', scaling_mode), ...
                        sprintf('beat estimate    : %.2f', abs(freq_1.Value - freq_2.Value))};

                case 'gs_phase'
                    result = gerchberg_saxton_phase(n, 3, 0.18 * n, round(max(5, iter_edit.Value)), alpha_edit.Value);
                    update_progress_dialog(dlg, 0.72, 'rendering preview');
                    apply_image_display(ax_1, result.target_amplitude, 'gray', scaling_mode, [0 1], 'image');
                    title(ax_1, '$\mathrm{target\ amplitude}$', 'Interpreter', 'latex');
                    apply_image_display(ax_2, result.final_phase, 'hsv', scaling_mode, [-pi pi], 'image');
                    title(ax_2, '$\mathrm{recovered\ phase}$', 'Interpreter', 'latex');
                    apply_image_display(ax_3, result.final_intensity, 'hot', scaling_mode, [0 1], 'image');
                    title(ax_3, '$\mathrm{focal\ intensity}$', 'Interpreter', 'latex');
                    cla(ax_4);
                    plot(ax_4, result.efficiency, 'LineWidth', 1.5, 'DisplayName', '$\eta$'); hold(ax_4, 'on');
                    plot(ax_4, result.uniformity, 'LineWidth', 1.5, 'DisplayName', '$u$'); hold(ax_4, 'off');
                    legend(ax_4, 'show', 'Location', 'southeast', 'Interpreter', 'latex');
                    title(ax_4, '$\mathrm{GS\ convergence}$', 'Interpreter', 'latex');
                    xlabel(ax_4, '$k$', 'Interpreter', 'latex');
                    ylabel(ax_4, '$\mathrm{metric}$', 'Interpreter', 'latex');
                    grid(ax_4, 'on');

                    status_box.Value = { ...
                        sprintf('mode             : %s', mode_key), ...
                        sprintf('iterations       : %d', round(iter_edit.Value)), ...
                        sprintf('damping alpha    : %.2f', alpha_edit.Value), ...
                        sprintf('display scaling  : %s', scaling_mode), ...
                        sprintf('final efficiency : %.3f', result.efficiency(end)), ...
                        sprintf('final uniformity : %.3f', result.uniformity(end))};

                otherwise
                    result = shearing_interferogram(n, aberration_dd.Value, coeff_edit.Value, shear_edit.Value, carrier_edit.Value);
                    max_wavefront = max(abs(result.wavefront(:)));
                    max_delta = max(abs(result.delta_phase(:)));
                    update_progress_dialog(dlg, 0.72, 'rendering preview');
                    apply_image_display(ax_1, result.wavefront, 'parula', scaling_mode, [-max_wavefront max_wavefront], 'image');
                    title(ax_1, '$\mathrm{wavefront}$', 'Interpreter', 'latex');
                    apply_image_display(ax_2, result.delta_phase, 'parula', scaling_mode, [-max_delta max_delta], 'image');
                    title(ax_2, '$\Delta\phi$', 'Interpreter', 'latex');
                    apply_image_display(ax_3, result.interferogram, 'gray', scaling_mode, [0 1], 'image');
                    title(ax_3, '$\mathrm{interferogram}$', 'Interpreter', 'latex');
                    apply_image_display(ax_4, normalize_array(log1p(abs(fftshift(fft2(ifftshift(result.interferogram)))))), 'hot', scaling_mode, [0 1], 'image');
                    title(ax_4, '$\mathrm{interferogram\ spectrum}$', 'Interpreter', 'latex');

                    status_box.Value = { ...
                        sprintf('mode             : %s', mode_key), ...
                        sprintf('aberration       : %s', aberration_dd.Value), ...
                        sprintf('coefficient      : %.3f waves', coeff_edit.Value), ...
                        sprintf('shear            : %.1f px', shear_edit.Value), ...
                        sprintf('carrier          : %.1f', carrier_edit.Value), ...
                        sprintf('display scaling  : %s', scaling_mode)};
            end

            notes_box.Value = notes_catalog('interference', mode_key);
            for ax = all_axes
                if ax ~= ax_4 || ~strcmp(mode_key, 'gs_phase')
                    ax.XTick = [];
                    ax.YTick = [];
                end
            end

            for ax_iter = all_axes
                apply_square_plot_box(ax_iter);
            end

            update_progress_dialog(dlg, 1.00, 'run complete');
            pause(0.08);
            close_progress_dialog(dlg);
            if show_alert
                uialert(app_figure, 'Interference preview updated successfully.', 'Run complete', 'Icon', 'info');
            end
        catch ME
            close_progress_dialog(dlg);
            uialert(app_figure, sprintf('Interference run failed:\n%s', ME.message), 'Run failed', 'Icon', 'error');
            warning('%s', getReport(ME, 'extended', 'hyperlinks', 'off'));
        end
    end

    function reset_defaults(~, ~)
        mode_dd.Value = 'moire';
        grid_n.Value = 256;
        freq_1.Value = 18;
        freq_2.Value = 19.2;
        angle_2.Value = 2.5;
        aberration_dd.Value = 'coma';
        coeff_edit.Value = 0.45;
        shear_edit.Value = 10;
        carrier_edit.Value = 8;
        iter_edit.Value = 80;
        alpha_edit.Value = 0.85;
        display_scale_dd.Value = 'fixed';
        execute_run(false);
    end

    function export_result(~, ~)
        dlg = create_progress_dialog(app_figure, 'exporting interference');
        try
            param_lines = { ...
                sprintf('mode = %s', mode_dd.Value), ...
                sprintf('grating_1_frequency = %.6f', freq_1.Value), ...
                sprintf('grating_2_frequency = %.6f', freq_2.Value), ...
                sprintf('grating_2_angle_deg = %.6f', angle_2.Value), ...
                sprintf('aberration = %s', aberration_dd.Value), ...
                sprintf('coefficient_waves = %.6f', coeff_edit.Value), ...
                sprintf('shear_px = %.6f', shear_edit.Value), ...
                sprintf('carrier_frequency = %.6f', carrier_edit.Value), ...
                sprintf('grid_size = %d', round(grid_n.Value)), ...
                sprintf('gs_iterations = %d', round(iter_edit.Value)), ...
                sprintf('gs_damping = %.6f', alpha_edit.Value), ...
                sprintf('image_scaling = %s', display_scale_dd.Value)};
            export_info = export_preview_bundle(project_root, 'interference', all_axes, ...
                {'panel_1','panel_2','panel_3','panel_4'}, [2 2], param_lines, notes_box.Value, status_box.Value, dlg);
            close_progress_dialog(dlg);
            uialert(app_figure, sprintf('Interference export saved to:\n%s', export_info.bundle_dir), 'Export complete', 'Icon', 'info');
        catch ME
            close_progress_dialog(dlg);
            uialert(app_figure, sprintf('Interference export failed:\n%s', ME.message), 'Export failed', 'Icon', 'error');
            warning('%s', getReport(ME, 'extended', 'hyperlinks', 'off'));
        end
    end
end
