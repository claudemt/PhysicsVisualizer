function tab = create_tomography_tab(tab_group, project_root)
%CREATE_TOMOGRAPHY_TAB Build the tomography tab.

app_figure = ancestor(tab_group, 'figure');

ui = create_tab_layout(tab_group, 'tomography', project_root, ...
    'Preview', 'axesgrid', ...
    'PreviewGridSize', [2 2], ...
    'NotesTitle', 'notes', ...
    'NotesText', local_tomography_notes('ram_lak'), ...
    'NotesFile', fullfile(project_root, 'docs', 'physical_formulas.md'), ...
    'InitialMessage', 'run to generate result');
tab = ui.tab;
left_grid = ui.control_grid;
left_grid.RowHeight = {'fit', 76, 0};
notes_box = ui.notes_area;

physical_panel = uipanel(left_grid, 'Title', 'physical parameters');
physical_panel.Layout.Row = 1;
physical_panel.Layout.Column = 1;
physical_grid = uigridlayout(physical_panel, [2 1]);
physical_grid.RowHeight = {'fit','fit'};
physical_grid.Padding = [8 8 8 8];
physical_grid.RowSpacing = 5;
phantom_dd = create_control_panel(physical_grid, 'dropdown', 'phantom', {'shepp_logan', 'three_disks'}, 'shepp_logan', 'Analytic 2D phantom.');
filter_dd = create_control_panel(physical_grid, 'dropdown', 'filter', {'none', 'ram_lak', 'shepp_logan'}, 'ram_lak', 'FBP reconstruction filter.');

numerical_panel = uipanel(left_grid, 'Title', 'numerical / display parameters');
numerical_panel.Layout.Row = 3;
numerical_panel.Layout.Column = 1;
numerical_panel.Visible = 'off';
numerical_grid = uigridlayout(numerical_panel, [4 1]);
numerical_grid.RowHeight = {'fit','fit','fit','fit'};
numerical_grid.Padding = [8 8 8 8];
numerical_grid.RowSpacing = 5;
grid_n = create_control_panel(numerical_grid, 'numeric', 'image size', 128, 'Phantom grid size.');
angle_count = create_control_panel(numerical_grid, 'numeric', 'number of angles', 90, 'Uniform projection angles over [0,180).');
detector_count = create_control_panel(numerical_grid, 'numeric', 'detector bins', 128, 'Parallel-beam detector samples.');
display_scale_dd = create_control_panel(numerical_grid, 'dropdown', 'image scaling', {'fixed', 'auto'}, 'fixed', 'Fixed uses consistent color limits; auto stretches each image.');

actions = create_control_panel(left_grid, 'section', 'actions', 1);
actions.panel.Layout.Row = 2;
actions.panel.Layout.Column = 1;
bind_workflow(actions.grid, app_figure, @run_simulation, @reset_defaults, @export_result, 'GenerateText', 'Run');

status_box = uitextarea(tab, 'Editable', 'off', 'Visible', 'off');
has_result = false;

preview_grid = ui.preview_grid;
ax_phantom = ui.preview_axes(1);
ax_sino = ui.preview_axes(2);
ax_recon = ui.preview_axes(3);
ax_error = ui.preview_axes(4);
all_axes = ui.preview_axes;
for ax = all_axes
    apply_tex_style(ax, 'FontSize', 12, 'TitleFontSize', 14, 'Box', 'on');
end



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
            n = round(max(64, grid_n.Value));
            theta = linspace(0, 180, round(max(10, angle_count.Value)) + 1);
            theta(end) = [];
            scaling_mode = display_scale_dd.Value;
            phantom = make_phantom_slice(n, phantom_dd.Value);
            [sinogram, detector_positions] = parallel_radon_transform(phantom, theta, round(max(32, detector_count.Value)));

            internal_filter = filter_dd.Value;
            [reconstruction, filtered_sinogram, ~] = filtered_backprojection(sinogram, detector_positions, theta, n, internal_filter);
            error_map = phantom - reconstruction;
            rmse = sqrt(mean(error_map(:).^2));
            max_error = max(abs(error_map(:)));
            render_result('image_display', ax_phantom, phantom, 'gray', scaling_mode, [0 1], 'image');
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
            axis(ax_sino, 'image');
            title(ax_sino, '$\mathrm{sinogram}$', 'Interpreter', 'latex');
            xlabel(ax_sino, '$\theta\ \mathrm{(deg)}$', 'Interpreter', 'latex');
            ylabel(ax_sino, '$s$', 'Interpreter', 'latex');
            xlim(ax_sino, [min(theta), max(theta)]);
            ylim(ax_sino, [min(detector_positions), max(detector_positions)]);

            render_result('image_display', ax_recon, reconstruction, 'gray', scaling_mode, [0 1], 'image');
            safe_filter_label = strrep(internal_filter, '_', '\_');
            apply_tex_style(ax_recon, 'Title', ['$\mathrm{reconstruction}\;(\mathrm{' safe_filter_label '})$']);
            ax_recon.XTick = [];
            ax_recon.YTick = [];

            render_result('image_display', ax_error, error_map, 'parula', scaling_mode, [-max_error max_error], 'image');
            title(ax_error, '$\mathrm{error\ map}$', 'Interpreter', 'latex');
            ax_error.XTick = [];
            ax_error.YTick = [];

            notes_box.Value = local_tomography_notes(internal_filter);
            status_box.Value = { ...
                sprintf('phantom            : %s', phantom_dd.Value), ...
                sprintf('filter             : %s', internal_filter), ...
                sprintf('angles             : %d', numel(theta)), ...
                sprintf('detector bins      : %d', round(max(32, detector_count.Value))), ...
                sprintf('display scaling    : %s', scaling_mode), ...
                sprintf('rmse               : %.4f', rmse), ...
                sprintf('sinogram peak      : %.3f', max(filtered_sinogram(:)))};

            for ax_iter = all_axes
                axis(ax_iter, 'image');
            end
            has_result = true;
            pause(0.08);
            if show_alert
                uialert(app_figure, 'Tomography preview updated successfully.', 'Run complete', 'Icon', 'info');
            end
        catch ME
            uialert(app_figure, sprintf('Tomography run failed:\n%s', ME.message), 'Run failed', 'Icon', 'error');
            warning('%s', getReport(ME, 'extended', 'hyperlinks', 'off'));
        end
    end

    function reset_defaults()
        phantom_dd.Value = 'shepp_logan';
        filter_dd.Value = 'ram_lak';
        grid_n.Value = 128;
        angle_count.Value = 90;
        detector_count.Value = 128;
        display_scale_dd.Value = 'fixed';
        clear_preview();
    end

    function clear_preview()
        has_result = false;
        for ax_iter = all_axes(:)'
            cla(ax_iter, 'reset');
            apply_tex_style(ax_iter, 'FontSize', 12, 'TitleFontSize', 14, 'Box', 'on');
            try, axis(ax_iter, 'off'); catch, end
        end
        image_output('reset_preview_group', preview_grid, all_axes, 'run to generate result');
        status_box.Value = {'status: ready'};
    end

    function export_result()
        dlg = [];
        try
            if ~has_result
                error('Run the simulation before exporting.');
            end
            param_lines = { ...
                sprintf('phantom = %s', phantom_dd.Value), ...
                sprintf('filter = %s', filter_dd.Value), ...
                sprintf('image_size = %d', round(grid_n.Value)), ...
                sprintf('number_of_angles = %d', round(angle_count.Value)), ...
                sprintf('detector_bins = %d', round(detector_count.Value)), ...
                sprintf('image_scaling = %s', display_scale_dd.Value)};
            export_info = image_output('export_preview_bundle', project_root, 'tomography', all_axes, ...
                {'phantom','sinogram','reconstruction','error'}, [2 2], param_lines, notes_box.Value, status_box.Value, dlg);
            uialert(app_figure, sprintf('Tomography export saved to:\n%s', export_info.bundle_dir), 'Export complete', 'Icon', 'info');
        catch ME
            uialert(app_figure, sprintf('Tomography export failed:\n%s', ME.message), 'Export failed', 'Icon', 'error');
            warning('%s', getReport(ME, 'extended', 'hyperlinks', 'off'));
        end
    end
end

function lines = local_tomography_notes(filter_key)
lines = { ...
    'This tab reconstructs an object from projections using filtered backprojection.', ...
    sprintf('filter = %s controls the frequency-domain ramp/window applied before backprojection.', char(string(filter_key))), ...
    'number of angles controls angular sampling; more angles reduce streak artifacts but increase runtime.', ...
    'detector samples control projection resolution. noise controls synthetic measurement noise.', ...
    'The sinogram is projection data p(theta,s); reconstruction is the inverse Radon result.', ...
    'Preview panels compare phantom/object, sinogram, filter response, and reconstruction. Notes gives the Radon formulas.'};
end
