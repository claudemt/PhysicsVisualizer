function tab = create_tomography_tab(tab_group, project_root)
%CREATE_TOMOGRAPHY_TAB Build the tomography tab.

app_figure = ancestor(tab_group, 'figure');

tab = uitab(tab_group, 'Title', 'tomography');
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
physical_grid = uigridlayout(physical_panel, [2 1]);
physical_grid.RowHeight = {'fit','fit'};
physical_grid.Padding = [8 8 8 8];
physical_grid.RowSpacing = 5;
phantom_dd = create_dropdown_control(physical_grid, 'phantom', {'shepp_logan', 'three_disks'}, 'shepp_logan', 'Analytic 2D phantom.');
filter_dd = create_dropdown_control(physical_grid, 'filter', {'none', 'ram_lak', 'shepp_logan'}, 'ram_lak', 'FBP reconstruction filter.');

numerical_panel = uipanel(left_grid, 'Title', 'numerical / display parameters');
numerical_panel.Layout.Row = 2;
numerical_panel.Layout.Column = 1;
numerical_grid = uigridlayout(numerical_panel, [4 1]);
numerical_grid.RowHeight = {'fit','fit','fit','fit'};
numerical_grid.Padding = [8 8 8 8];
numerical_grid.RowSpacing = 5;
grid_n = create_numeric_control(numerical_grid, 'image size', 128, 'Phantom grid size.');
angle_count = create_numeric_control(numerical_grid, 'number of angles', 90, 'Uniform projection angles over [0,180).');
detector_count = create_numeric_control(numerical_grid, 'detector bins', 128, 'Parallel-beam detector samples.');
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
preview_grid.Padding = [2 2 2 2];
preview_grid.RowSpacing = 3;
preview_grid.ColumnSpacing = 3;

ax_phantom = uiaxes(preview_grid); ax_phantom.Layout.Row = 1; ax_phantom.Layout.Column = 1;
ax_sino = uiaxes(preview_grid); ax_sino.Layout.Row = 1; ax_sino.Layout.Column = 2;
ax_recon = uiaxes(preview_grid); ax_recon.Layout.Row = 2; ax_recon.Layout.Column = 1;
ax_error = uiaxes(preview_grid); ax_error.Layout.Row = 2; ax_error.Layout.Column = 2;
all_axes = [ax_phantom, ax_sino, ax_recon, ax_error];
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
            dlg = create_progress_dialog(app_figure, 'running tomography');
        end
        try
            update_progress_dialog(dlg, 0.10, 'reading parameters');
            n = round(max(64, grid_n.Value));
            theta = linspace(0, 180, round(max(10, angle_count.Value)) + 1);
            theta(end) = [];
            scaling_mode = display_scale_dd.Value;

            update_progress_dialog(dlg, 0.38, 'generating projections');
            phantom = make_phantom_slice(n, phantom_dd.Value);
            [sinogram, detector_positions] = parallel_radon_transform(phantom, theta, round(max(32, detector_count.Value)));

            internal_filter = filter_dd.Value;
            update_progress_dialog(dlg, 0.62, 'reconstructing image');
            [reconstruction, filtered_sinogram, ~] = filtered_backprojection(sinogram, detector_positions, theta, n, internal_filter);
            error_map = phantom - reconstruction;
            rmse = sqrt(mean(error_map(:).^2));
            max_error = max(abs(error_map(:)));

            update_progress_dialog(dlg, 0.80, 'rendering preview');
            apply_image_display(ax_phantom, phantom, 'gray', scaling_mode, [0 1], 'image');
            title(ax_phantom, '$\mathrm{phantom}$', 'Interpreter', 'latex');
            ax_phantom.XTick = [];
            ax_phantom.YTick = [];

            cla(ax_sino);
            imagesc(ax_sino, theta, detector_positions, sinogram);
            ax_sino.YDir = 'normal';
            colormap(ax_sino, 'hot');
            if strcmpi(scaling_mode, 'fixed')
                clim(ax_sino, [0, max(sinogram(:)) + eps]);
            else
                clim(ax_sino, 'auto');
            end
            axis(ax_sino, 'tight');
            apply_square_plot_box(ax_sino);
            title(ax_sino, '$\mathrm{sinogram}$', 'Interpreter', 'latex');
            xlabel(ax_sino, '$\theta\ \mathrm{(deg)}$', 'Interpreter', 'latex');
            ylabel(ax_sino, '$s$', 'Interpreter', 'latex');
            xlim(ax_sino, [min(theta), max(theta)]);
            ylim(ax_sino, [min(detector_positions), max(detector_positions)]);

            apply_image_display(ax_recon, reconstruction, 'gray', scaling_mode, [0 1], 'image');
            title(ax_recon, latex_text(['reconstruction (' internal_filter ')']), 'Interpreter', 'latex');
            ax_recon.XTick = [];
            ax_recon.YTick = [];

            apply_image_display(ax_error, error_map, 'parula', scaling_mode, [-max_error max_error], 'image');
            title(ax_error, '$\mathrm{error\ map}$', 'Interpreter', 'latex');
            ax_error.XTick = [];
            ax_error.YTick = [];

            notes_box.Value = notes_catalog('tomography', internal_filter);
            status_box.Value = { ...
                sprintf('phantom            : %s', phantom_dd.Value), ...
                sprintf('filter             : %s', internal_filter), ...
                sprintf('angles             : %d', numel(theta)), ...
                sprintf('detector bins      : %d', round(max(32, detector_count.Value))), ...
                sprintf('display scaling    : %s', scaling_mode), ...
                sprintf('rmse               : %.4f', rmse), ...
                sprintf('sinogram peak      : %.3f', max(filtered_sinogram(:)))};

            for ax_iter = all_axes
                apply_square_plot_box(ax_iter);
            end

            update_progress_dialog(dlg, 1.00, 'run complete');
            pause(0.08);
            close_progress_dialog(dlg);
            if show_alert
                uialert(app_figure, 'Tomography preview updated successfully.', 'Run complete', 'Icon', 'info');
            end
        catch ME
            close_progress_dialog(dlg);
            uialert(app_figure, sprintf('Tomography run failed:\n%s', ME.message), 'Run failed', 'Icon', 'error');
            warning('%s', getReport(ME, 'extended', 'hyperlinks', 'off'));
        end
    end

    function reset_defaults(~, ~)
        phantom_dd.Value = 'shepp_logan';
        filter_dd.Value = 'ram_lak';
        grid_n.Value = 128;
        angle_count.Value = 90;
        detector_count.Value = 128;
        display_scale_dd.Value = 'fixed';
        execute_run(false);
    end

    function export_result(~, ~)
        dlg = create_progress_dialog(app_figure, 'exporting tomography');
        try
            param_lines = { ...
                sprintf('phantom = %s', phantom_dd.Value), ...
                sprintf('filter = %s', filter_dd.Value), ...
                sprintf('image_size = %d', round(grid_n.Value)), ...
                sprintf('number_of_angles = %d', round(angle_count.Value)), ...
                sprintf('detector_bins = %d', round(detector_count.Value)), ...
                sprintf('image_scaling = %s', display_scale_dd.Value)};
            export_info = export_preview_bundle(project_root, 'tomography', all_axes, ...
                {'phantom','sinogram','reconstruction','error'}, [2 2], param_lines, notes_box.Value, status_box.Value, dlg);
            close_progress_dialog(dlg);
            uialert(app_figure, sprintf('Tomography export saved to:\n%s', export_info.bundle_dir), 'Export complete', 'Icon', 'info');
        catch ME
            close_progress_dialog(dlg);
            uialert(app_figure, sprintf('Tomography export failed:\n%s', ME.message), 'Export failed', 'Icon', 'error');
            warning('%s', getReport(ME, 'extended', 'hyperlinks', 'off'));
        end
    end
end
