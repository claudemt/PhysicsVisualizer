function tab = create_imaging_tab(tab_group, project_root)
%CREATE_IMAGING_TAB Build the imaging and aberrations tab.

app_figure = ancestor(tab_group, 'figure');

tab = uitab(tab_group, 'Title', 'imaging and aberrations');
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
physical_grid = uigridlayout(physical_panel, [5 1]);
physical_grid.RowHeight = {'fit','fit','fit','fit','fit'};
physical_grid.Padding = [8 8 8 8];
physical_grid.RowSpacing = 5;
mode_dd = create_dropdown_control(physical_grid, 'mode', {'widefield', 'confocal', 'sted'}, 'widefield', 'Choose the effective imaging model.');
aberration_dd = create_dropdown_control(physical_grid, 'aberration', {'none', 'tilt_x', 'defocus', 'astigmatism', 'coma', 'spherical'}, 'defocus', 'Pupil phase basis.');
coeff_edit = create_numeric_control(physical_grid, 'coefficient (waves)', 0.35, 'Phase coefficient in waves.');
pinhole_edit = create_numeric_control(physical_grid, 'pinhole factor', 0.60, 'Detection pinhole factor for confocal mode.');
sted_edit = create_numeric_control(physical_grid, 'sted strength', 4.0, 'Depletion strength in exp(-s h_sted).');

numerical_panel = uipanel(left_grid, 'Title', 'numerical / display parameters');
numerical_panel.Layout.Row = 2;
numerical_panel.Layout.Column = 1;
numerical_grid = uigridlayout(numerical_panel, [2 1]);
numerical_grid.RowHeight = {'fit','fit'};
numerical_grid.Padding = [8 8 8 8];
numerical_grid.RowSpacing = 5;
grid_n = create_numeric_control(numerical_grid, 'grid size', 256, 'Pupil and image grid size.');
display_scale_dd = create_dropdown_control(numerical_grid, 'image scaling', {'fixed', 'auto'}, 'fixed', 'Fixed uses consistent color limits; auto stretches each image.');

action_panel = uipanel(left_grid, 'Title', 'actions');
action_panel.Layout.Row = 3;
action_panel.Layout.Column = 1;
action_grid = uigridlayout(action_panel, [1 1]);
action_grid.RowHeight = {28};
action_grid.Padding = [8 8 8 8];
create_button_row(action_grid, @run_simulation, @reset_defaults, @export_result);

status_box = uitextarea(left_grid, 'Editable', 'off', 'FontName', 'Courier New', 'Value', {'status: ready'});
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

ax_pupil = uiaxes(preview_grid); ax_pupil.Layout.Row = 1; ax_pupil.Layout.Column = 1;
ax_psf = uiaxes(preview_grid); ax_psf.Layout.Row = 1; ax_psf.Layout.Column = 2;
ax_otf = uiaxes(preview_grid); ax_otf.Layout.Row = 2; ax_otf.Layout.Column = 1;
ax_profile = uiaxes(preview_grid); ax_profile.Layout.Row = 2; ax_profile.Layout.Column = 2;
all_axes = [ax_pupil, ax_psf, ax_otf, ax_profile];
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
            dlg = create_progress_dialog(app_figure, 'running imaging');
        end
        try
            update_progress_dialog(dlg, 0.10, 'reading parameters');
            n = round(max(64, grid_n.Value));
            mode_key = mode_dd.Value;
            coeff = coeff_edit.Value;
            scaling_mode = display_scale_dd.Value;

            update_progress_dialog(dlg, 0.40, 'computing PSF and OTF');
            [psf_wf, pupil_field, wavefront] = compute_psf_2d(n, aberration_dd.Value, coeff, 0);
            effective_psf = psf_wf;
            profile_label_1 = '$\mathrm{widefield}$';
            profile_label_2 = '$\mathrm{effective}$';

            switch mode_key
                case 'confocal'
                    pinhole_factor = max(0.05, pinhole_edit.Value);
                    detector_psf = normalize_array(psf_wf .^ (1 / pinhole_factor));
                    effective_psf = normalize_array(psf_wf .* detector_psf);
                case 'sted'
                    [~, ~, phi] = make_circular_pupil(n);
                    vortex_phase = phi;
                    psf_sted = compute_psf_2d(n, aberration_dd.Value, coeff, vortex_phase);
                    effective_psf = normalize_array(psf_wf .* exp(-max(sted_edit.Value, 0) * psf_sted));
                otherwise
            end

            effective_otf = compute_otf(effective_psf);
            center_idx = round((n + 1) / 2);
            profile_x = 1:n;
            wide_profile = psf_wf(center_idx, :);
            eff_profile = effective_psf(center_idx, :);

            update_progress_dialog(dlg, 0.72, 'rendering preview');
            apply_image_display(ax_pupil, angle(pupil_field) .* (abs(pupil_field) > 0), 'hsv', scaling_mode, [-pi pi], 'image');
            title(ax_pupil, '$\mathrm{pupil\ phase}$', 'Interpreter', 'latex');

            apply_image_display(ax_psf, effective_psf, 'hot', scaling_mode, [0 1], 'image');
            title(ax_psf, latex_text([mode_key ' PSF']), 'Interpreter', 'latex');

            apply_image_display(ax_otf, effective_otf, 'parula', scaling_mode, [0 1], 'image');
            title(ax_otf, '$|\mathrm{OTF}|$', 'Interpreter', 'latex');

            cla(ax_profile);
            plot(ax_profile, profile_x, wide_profile, 'LineWidth', 1.4, 'DisplayName', profile_label_1); hold(ax_profile, 'on');
            plot(ax_profile, profile_x, eff_profile, 'LineWidth', 1.4, 'DisplayName', profile_label_2);
            hold(ax_profile, 'off');
            legend(ax_profile, 'show', 'Location', 'northeast', 'Interpreter', 'latex');
            title(ax_profile, '$\mathrm{central\ profile}$', 'Interpreter', 'latex');
            xlabel(ax_profile, '$x\ \mathrm{(pixel)}$', 'Interpreter', 'latex');
            ylabel(ax_profile, '$I/I_{\max}$', 'Interpreter', 'latex');
            grid(ax_profile, 'on');

            notes_box.Value = notes_catalog('imaging', mode_key);
            status_box.Value = { ...
                sprintf('mode                : %s', mode_key), ...
                sprintf('aberration          : %s', aberration_dd.Value), ...
                sprintf('coefficient         : %.3f waves', coeff), ...
                sprintf('display scaling     : %s', scaling_mode), ...
                sprintf('strehl proxy        : %.3f', max(effective_psf(:)) / max(psf_wf(:))), ...
                sprintf('phase rms           : %.3f', std(wavefront(abs(pupil_field) > 0))), ...
                sprintf('effective OTF peak  : %.3f', max(effective_otf(:)))};

            for ax_iter = all_axes
                apply_square_plot_box(ax_iter);
            end

            update_progress_dialog(dlg, 1.00, 'run complete');
            pause(0.08);
            close_progress_dialog(dlg);
            if show_alert
                uialert(app_figure, 'Imaging preview updated successfully.', 'Run complete', 'Icon', 'info');
            end
        catch ME
            close_progress_dialog(dlg);
            uialert(app_figure, sprintf('Imaging run failed:\n%s', ME.message), 'Run failed', 'Icon', 'error');
            warning('%s', getReport(ME, 'extended', 'hyperlinks', 'off'));
        end
    end

    function reset_defaults(~, ~)
        mode_dd.Value = 'widefield';
        aberration_dd.Value = 'defocus';
        coeff_edit.Value = 0.35;
        pinhole_edit.Value = 0.60;
        sted_edit.Value = 4.0;
        grid_n.Value = 256;
        display_scale_dd.Value = 'fixed';
        execute_run(false);
    end

    function export_result(~, ~)
        dlg = create_progress_dialog(app_figure, 'exporting imaging');
        try
            param_lines = { ...
                sprintf('mode = %s', mode_dd.Value), ...
                sprintf('aberration = %s', aberration_dd.Value), ...
                sprintf('coefficient_waves = %.6f', coeff_edit.Value), ...
                sprintf('pinhole_factor = %.6f', pinhole_edit.Value), ...
                sprintf('sted_strength = %.6f', sted_edit.Value), ...
                sprintf('grid_size = %d', round(grid_n.Value)), ...
                sprintf('image_scaling = %s', display_scale_dd.Value)};
            export_info = export_preview_bundle(project_root, 'imaging', all_axes, ...
                {'pupil','psf','otf','profile'}, [2 2], param_lines, notes_box.Value, status_box.Value, dlg);
            close_progress_dialog(dlg);
            uialert(app_figure, sprintf('Imaging export saved to:\n%s', export_info.bundle_dir), 'Export complete', 'Icon', 'info');
        catch ME
            close_progress_dialog(dlg);
            uialert(app_figure, sprintf('Imaging export failed:\n%s', ME.message), 'Export failed', 'Icon', 'error');
            warning('%s', getReport(ME, 'extended', 'hyperlinks', 'off'));
        end
    end
end
