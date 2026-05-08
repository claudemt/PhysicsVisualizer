function tab = create_interference_tab(tab_group, project_root)
%CREATE_INTERFERENCE_TAB Build the interference and phase tab.

app_figure = ancestor(tab_group, 'figure');

ui = create_tab_layout(tab_group, 'interference and phase', project_root, ...
    'Preview', 'axesgrid', ...
    'PreviewGridSize', [2 2], ...
    'NotesTitle', 'notes', ...
    'NotesText', local_interference_notes('moire'), ...
    'NotesFile', fullfile(project_root, 'docs', 'physical_formulas.md'), ...
    'InitialMessage', 'run to generate result');
tab = ui.tab;
left_grid = ui.control_grid;
left_grid.RowHeight = {'fit', 76, 0};
notes_box = ui.notes_area;

physical_panel = uipanel(left_grid, 'Title', 'physical parameters');
physical_panel.Layout.Row = 1;
physical_panel.Layout.Column = 1;
physical_grid = uigridlayout(physical_panel, [8 1]);
physical_grid.RowHeight = {'fit','fit','fit','fit','fit','fit','fit','fit'};
physical_grid.Padding = [8 8 8 8];
physical_grid.RowSpacing = 5;
mode_dd = create_control_panel(physical_grid, 'dropdown', 'mode', {'moire', 'shearing', 'gs_phase'}, 'moire', 'Choose the active interference or phase-retrieval demo.');
freq_1 = create_control_panel(physical_grid, 'numeric', 'grating 1 frequency', 18, 'Normalized grating frequency.');
freq_2 = create_control_panel(physical_grid, 'numeric', 'grating 2 frequency', 19.2, 'Normalized grating frequency.');
angle_2 = create_control_panel(physical_grid, 'numeric', 'grating 2 angle (deg)', 2.5, 'Angle offset between gratings.');
aberration_dd = create_control_panel(physical_grid, 'dropdown', 'aberration', {'defocus', 'astigmatism', 'coma', 'spherical'}, 'coma', 'Wavefront basis.');
coeff_edit = create_control_panel(physical_grid, 'numeric', 'coefficient (waves)', 0.45, 'Wavefront coefficient.');
shear_edit = create_control_panel(physical_grid, 'numeric', 'shear (px)', 10, 'Pixel shear for interferometry.');
carrier_edit = create_control_panel(physical_grid, 'numeric', 'carrier frequency', 8, 'Spatial carrier fringe frequency.');

numerical_panel = uipanel(left_grid, 'Title', 'numerical / display parameters');
numerical_panel.Layout.Row = 3;
numerical_panel.Layout.Column = 1;
numerical_panel.Visible = 'off';
numerical_grid = uigridlayout(numerical_panel, [4 1]);
numerical_grid.RowHeight = {'fit','fit','fit','fit'};
numerical_grid.Padding = [8 8 8 8];
numerical_grid.RowSpacing = 5;
grid_n = create_control_panel(numerical_grid, 'numeric', 'grid size', 256, 'Simulation grid size.');
iter_edit = create_control_panel(numerical_grid, 'numeric', 'GS iterations', 80, 'Gerchberg-Saxton iteration count.');
alpha_edit = create_control_panel(numerical_grid, 'numeric', 'GS damping', 0.85, 'Weighted pupil update.');
display_scale_dd = create_control_panel(numerical_grid, 'dropdown', 'image scaling', {'fixed', 'auto'}, 'fixed', 'Fixed uses consistent color limits; auto stretches each image.');

actions = create_control_panel(left_grid, 'section', 'actions', 1);
actions.panel.Layout.Row = 2;
actions.panel.Layout.Column = 1;
bind_workflow(actions.grid, app_figure, @run_simulation, @reset_defaults, @export_result, 'GenerateText', 'Run');

status_box = uitextarea(tab, 'Editable', 'off', 'Visible', 'off');
has_result = false;

preview_grid = ui.preview_grid;
ax_1 = ui.preview_axes(1);
ax_2 = ui.preview_axes(2);
ax_3 = ui.preview_axes(3);
ax_4 = ui.preview_axes(4);
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
            mode_key = mode_dd.Value;
            scaling_mode = display_scale_dd.Value;
            switch mode_key
                case 'moire'
                    g1 = make_grating(n, freq_1.Value, 0, 0);
                    g2 = make_grating(n, freq_2.Value, angle_2.Value, 0);
                    moire_img = normalize_array(g1 .* g2);
                    moire_fft = normalize_array(log1p(abs(fftshift(fft2(ifftshift(moire_img))))));
                    render_result('image_display', ax_1, g1, 'gray', scaling_mode, [0 1], 'image');
                    title(ax_1, '$\mathrm{grating\ 1}$', 'Interpreter', 'latex');
                    render_result('image_display', ax_2, g2, 'gray', scaling_mode, [0 1], 'image');
                    title(ax_2, '$\mathrm{grating\ 2}$', 'Interpreter', 'latex');
                    render_result('image_display', ax_3, moire_img, 'gray', scaling_mode, [0 1], 'image');
                    title(ax_3, '$\mathrm{moire\ product}$', 'Interpreter', 'latex');
                    render_result('image_display', ax_4, moire_fft, 'hot', scaling_mode, [0 1], 'image');
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
                    render_result('image_display', ax_1, result.target_amplitude, 'gray', scaling_mode, [0 1], 'image');
                    title(ax_1, '$\mathrm{target\ amplitude}$', 'Interpreter', 'latex');
                    render_result('image_display', ax_2, result.final_phase, 'hsv', scaling_mode, [-pi pi], 'image');
                    title(ax_2, '$\mathrm{recovered\ phase}$', 'Interpreter', 'latex');
                    render_result('image_display', ax_3, result.final_intensity, 'hot', scaling_mode, [0 1], 'image');
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
                    render_result('image_display', ax_1, result.wavefront, 'parula', scaling_mode, [-max_wavefront max_wavefront], 'image');
                    title(ax_1, '$\mathrm{wavefront}$', 'Interpreter', 'latex');
                    render_result('image_display', ax_2, result.delta_phase, 'parula', scaling_mode, [-max_delta max_delta], 'image');
                    title(ax_2, '$\Delta\phi$', 'Interpreter', 'latex');
                    render_result('image_display', ax_3, result.interferogram, 'gray', scaling_mode, [0 1], 'image');
                    title(ax_3, '$\mathrm{interferogram}$', 'Interpreter', 'latex');
                    render_result('image_display', ax_4, normalize_array(log1p(abs(fftshift(fft2(ifftshift(result.interferogram)))))), 'hot', scaling_mode, [0 1], 'image');
                    title(ax_4, '$\mathrm{interferogram\ spectrum}$', 'Interpreter', 'latex');

                    status_box.Value = { ...
                        sprintf('mode             : %s', mode_key), ...
                        sprintf('aberration       : %s', aberration_dd.Value), ...
                        sprintf('coefficient      : %.3f waves', coeff_edit.Value), ...
                        sprintf('shear            : %.1f px', shear_edit.Value), ...
                        sprintf('carrier          : %.1f', carrier_edit.Value), ...
                        sprintf('display scaling  : %s', scaling_mode)};
            end

            notes_box.Value = local_interference_notes(mode_key);
            for ax = all_axes
                if ax ~= ax_4 || ~strcmp(mode_key, 'gs_phase')
                    ax.XTick = [];
                    ax.YTick = [];
                end
            end

            for ax_iter = all_axes
                axis(ax_iter, 'image');
            end
            has_result = true;
            pause(0.08);
            if show_alert
                uialert(app_figure, 'Interference preview updated successfully.', 'Run complete', 'Icon', 'info');
            end
        catch ME
            uialert(app_figure, sprintf('Interference run failed:\n%s', ME.message), 'Run failed', 'Icon', 'error');
            warning('%s', getReport(ME, 'extended', 'hyperlinks', 'off'));
        end
    end

    function reset_defaults()
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
            export_info = image_output('export_preview_bundle', project_root, 'interference', all_axes, ...
                {'panel_1','panel_2','panel_3','panel_4'}, [2 2], param_lines, notes_box.Value, status_box.Value, dlg);
            uialert(app_figure, sprintf('Interference export saved to:\n%s', export_info.bundle_dir), 'Export complete', 'Icon', 'info');
        catch ME
            uialert(app_figure, sprintf('Interference export failed:\n%s', ME.message), 'Export failed', 'Icon', 'error');
            warning('%s', getReport(ME, 'extended', 'hyperlinks', 'off'));
        end
    end
end

function lines = local_interference_notes(mode_key)
lines = { ...
    'This tab visualizes optical interference and phase-beating patterns.', ...
    sprintf('mode = %s selects the physical setup: moire, two-beam, multi-beam, or related interference geometry.', char(string(mode_key))), ...
    'wavelength controls fringe scale; angle/period/phase controls relative wave-vector or grating offset.', ...
    'contrast controls visibility of bright/dark fringes. grid size controls image resolution and runtime.', ...
    'The preview panels show intensity, phase, or component fields depending on selected mode.', ...
    'Use Notes for the interference intensity formula I = |sum E_j|^2 and mode-specific geometry definitions.'};
end
