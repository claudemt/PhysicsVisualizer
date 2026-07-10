function tab = create_imaging_tab(tab_group, project_root)
%CREATE_IMAGING_TAB Build the imaging and aberrations tab.

app_figure = ancestor(tab_group, 'figure');

ui = create_tab_layout(tab_group, 'imaging and aberrations', project_root, ...
    'Preview', 'axesgrid', ...
    'PreviewGridSize', [2 2], ...
    'NotesTitle', 'notes', ...
    'NotesText', local_imaging_notes('widefield'), ...
    'NotesFile', fullfile(project_root, 'docs', 'physical_formulas.md'), ...
    'InitialMessage', 'run to generate result');
tab = ui.tab;
left_grid = ui.control_grid;
left_grid.RowHeight = {'fit', 76, 0};
notes_box = ui.notes_area;

physical_panel = uipanel(left_grid, 'Title', 'physical parameters');
studio_style('apply_panel', physical_panel);
physical_panel.Layout.Row = 1;
physical_panel.Layout.Column = 1;
physical_grid = uigridlayout(physical_panel, [5 1]);
physical_grid.RowHeight = {'fit','fit','fit','fit','fit'};
studio_style('apply_grid', physical_grid, 'panel');
mode_dd = create_control_panel(physical_grid, 'dropdown', 'mode', {'widefield', 'confocal', 'sted'}, 'widefield', 'Choose the effective imaging model.');
aberration_dd = create_control_panel(physical_grid, 'dropdown', 'aberration', {'none', 'tilt_x', 'defocus', 'astigmatism', 'coma', 'spherical'}, 'defocus', 'Pupil phase basis.');
coeff_edit = create_control_panel(physical_grid, 'numeric', 'coefficient (waves)', 0.35, 'Phase coefficient in waves.');
pinhole_edit = create_control_panel(physical_grid, 'numeric', 'pinhole factor', 0.60, 'Detection pinhole factor for confocal mode.');
sted_edit = create_control_panel(physical_grid, 'numeric', 'sted strength', 4.0, 'Depletion strength in exp(-s h_sted).');

numerical_panel = uipanel(left_grid, 'Title', 'numerical / display parameters');
studio_style('apply_panel', numerical_panel);
numerical_panel.Layout.Row = 3;
numerical_panel.Layout.Column = 1;
numerical_panel.Visible = 'off';
numerical_grid = uigridlayout(numerical_panel, [2 1]);
numerical_grid.RowHeight = {'fit','fit'};
studio_style('apply_grid', numerical_grid, 'panel');
grid_n = create_control_panel(numerical_grid, 'numeric', 'grid size', 256, 'Pupil and image grid size.');
display_scale_dd = create_control_panel(numerical_grid, 'dropdown', 'image scaling', {'fixed', 'auto'}, 'fixed', 'Fixed uses consistent color limits; auto stretches each image.');

actions = create_control_panel(left_grid, 'section', 'actions', 1);
actions.panel.Layout.Row = 2;
actions.panel.Layout.Column = 1;
bind_workflow(actions.grid, app_figure, @run_simulation, @reset_defaults, @export_result, 'GenerateText', 'Run');

status_box = uitextarea(tab, 'Editable', 'off', 'Value', {'status: ready'}, 'Visible', 'off');
studio_style('apply_component', status_box, 'mono');
has_result = false;

preview_grid = ui.preview_grid;
ax_pupil = ui.preview_axes(1);
ax_psf = ui.preview_axes(2);
ax_otf = ui.preview_axes(3);
ax_profile = ui.preview_axes(4);
all_axes = ui.preview_axes;
for ax = all_axes
    studio_style('apply_axes', ax, 'Box', 'on');
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
            coeff = coeff_edit.Value;
            scaling_mode = display_scale_dd.Value;
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
            render_result('image_display', ax_pupil, angle(pupil_field) .* (abs(pupil_field) > 0), 'hsv', scaling_mode, [-pi pi], 'image');
            title(ax_pupil, '$\mathrm{pupil\ phase}$', 'Interpreter', 'latex');

            render_result('image_display', ax_psf, effective_psf, 'hot', scaling_mode, [0 1], 'image');
            safe_mode_label = strrep(mode_key, '_', '\_');
            studio_style('apply_axes', ax_psf, 'Title', ['$\mathrm{' safe_mode_label '\ PSF}$']);

            render_result('image_display', ax_otf, effective_otf, 'parula', scaling_mode, [0 1], 'image');
            title(ax_otf, '$|\mathrm{OTF}|$', 'Interpreter', 'latex');

            cla(ax_profile);
            plot(ax_profile, profile_x, wide_profile, 'LineWidth', 1.4, 'DisplayName', profile_label_1); hold(ax_profile, 'on');
            plot(ax_profile, profile_x, eff_profile, 'LineWidth', 1.4, 'DisplayName', profile_label_2);
            hold(ax_profile, 'off');
            lgd = legend(ax_profile, 'show', 'Location', 'northeast', 'Interpreter', 'latex');
            studio_style('apply_legend', lgd);
            title(ax_profile, '$\mathrm{central\ profile}$', 'Interpreter', 'latex');
            xlabel(ax_profile, '$x\ \mathrm{(pixel)}$', 'Interpreter', 'latex');
            ylabel(ax_profile, '$I/I_{\max}$', 'Interpreter', 'latex');
            grid(ax_profile, 'on');

            notes_box.Value = local_imaging_notes(mode_key);
            status_box.Value = { ...
                sprintf('mode                : %s', mode_key), ...
                sprintf('aberration          : %s', aberration_dd.Value), ...
                sprintf('coefficient         : %.3f waves', coeff), ...
                sprintf('display scaling     : %s', scaling_mode), ...
                sprintf('strehl proxy        : %.3f', max(effective_psf(:)) / max(psf_wf(:))), ...
                sprintf('phase rms           : %.3f', std(wavefront(abs(pupil_field) > 0))), ...
                sprintf('effective OTF peak  : %.3f', max(effective_otf(:)))};

            for ax_iter = all_axes
                axis(ax_iter, 'image');
            end
            has_result = true;
            pause(0.08);
            if show_alert
                uialert(app_figure, 'Imaging preview updated successfully.', 'Run complete', 'Icon', 'info');
            end
        catch ME
            uialert(app_figure, sprintf('Imaging run failed:\n%s', ME.message), 'Run failed', 'Icon', 'error');
            warning('%s', getReport(ME, 'extended', 'hyperlinks', 'off'));
        end
    end

    function reset_defaults()
        mode_dd.Value = 'widefield';
        aberration_dd.Value = 'defocus';
        coeff_edit.Value = 0.35;
        pinhole_edit.Value = 0.60;
        sted_edit.Value = 4.0;
        grid_n.Value = 256;
        display_scale_dd.Value = 'fixed';
        clear_preview();
    end

    function clear_preview()
        has_result = false;
        for ax_iter = all_axes(:)'
            cla(ax_iter, 'reset');
            studio_style('apply_axes', ax_iter, 'Box', 'on');
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
                sprintf('aberration = %s', aberration_dd.Value), ...
                sprintf('coefficient_waves = %.6f', coeff_edit.Value), ...
                sprintf('pinhole_factor = %.6f', pinhole_edit.Value), ...
                sprintf('sted_strength = %.6f', sted_edit.Value), ...
                sprintf('grid_size = %d', round(grid_n.Value)), ...
                sprintf('image_scaling = %s', display_scale_dd.Value)};
            export_info = image_output('export_preview_bundle', project_root, 'imaging', all_axes, ...
                {'pupil','psf','otf','profile'}, [2 2], param_lines, notes_box.Value, status_box.Value, dlg);
            uialert(app_figure, sprintf('Imaging export saved to:\n%s', export_info.bundle_dir), 'Export complete', 'Icon', 'info');
        catch ME
            uialert(app_figure, sprintf('Imaging export failed:\n%s', ME.message), 'Export failed', 'Icon', 'error');
            warning('%s', getReport(ME, 'extended', 'hyperlinks', 'off'));
        end
    end
end

function lines = local_imaging_notes(mode_key)
lines = { ...
    'This tab compares imaging-system point-spread and transfer-function models.', ...
    sprintf('mode = %s. widefield, confocal, and STED change how the effective PSF is formed.', char(string(mode_key))), ...
    'aberration chooses the wavefront error type. coefficient waves is phase-error strength measured in wavelengths.', ...
    'pinhole factor controls confocal detection aperture size; smaller values reject out-of-focus light.', ...
    'STED strength controls depletion intensity in the simplified STED model; higher values narrow the effective PSF.', ...
    'grid size controls numerical sampling. Fixed scaling keeps panels comparable across runs.', ...
    'Preview panels show pupil/phase, PSF, OTF or related profiles depending on mode. Full formulas are in Notes.'};
end
