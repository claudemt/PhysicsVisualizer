function tab = create_wave_optics_tab(tab_group, project_root)
%CREATE_WAVE_OPTICS_TAB Build the wave optics tab.

app_figure = ancestor(tab_group, 'figure');

ui = create_tab_layout(tab_group, 'wave optics', project_root, ...
    'Preview', 'axesgrid', ...
    'PreviewGridSize', [2 2], ...
    'NotesTitle', 'notes', ...
    'NotesText', local_wave_notes('free_space'), ...
    'NotesFile', fullfile(project_root, 'docs', 'physical_formulas.md'), ...
    'InitialMessage', 'run to generate result');
tab = ui.tab;
left_grid = ui.control_grid;
left_grid.RowHeight = {'fit', 76, 0};
notes_box = ui.notes_area;

physical_panel = uipanel(left_grid, 'Title', 'physical parameters');
physical_panel.Layout.Row = 1;
physical_panel.Layout.Column = 1;
physical_grid = uigridlayout(physical_panel, [7 1]);
physical_grid.RowHeight = {'fit','fit','fit','fit','fit','fit','fit'};
physical_grid.Padding = [8 8 8 8];
physical_grid.RowSpacing = 5;
mode_dd = create_control_panel(physical_grid, 'dropdown', 'mode', {'free_space', '4f_filtering'}, 'free_space', 'Choose propagation or Fourier filtering.');
object_dd = create_control_panel(physical_grid, 'dropdown', 'object', {'bars', 'mesh', 'double_slit', 'aperture', 'gaussian_lattice'}, 'bars', 'Synthetic object field.');
filter_dd = create_control_panel(physical_grid, 'dropdown', 'filter', {'none', 'pinhole', 'ring', 'horizontal_single', 'horizontal_double', 'vertical_single', 'vertical_double'}, 'pinhole', 'Fourier-plane mask.');
filter_scale = create_control_panel(physical_grid, 'numeric', 'filter scale', 0.16, 'Dimensionless Fourier-mask scale.');
pixel_size = create_control_panel(physical_grid, 'numeric', 'pixel size (um)', 6.5, 'Sample-plane pitch.');
wavelength_nm = create_control_panel(physical_grid, 'numeric', 'wavelength (nm)', 532, 'Scalar wavelength.');
prop_distance = create_control_panel(physical_grid, 'numeric', 'distance (mm)', 20, 'Propagation distance for free-space mode.');

numerical_panel = uipanel(left_grid, 'Title', 'numerical / display parameters');
numerical_panel.Layout.Row = 3;
numerical_panel.Layout.Column = 1;
numerical_panel.Visible = 'off';
numerical_grid = uigridlayout(numerical_panel, [3 1]);
numerical_grid.RowHeight = {'fit','fit','fit'};
numerical_grid.Padding = [8 8 8 8];
numerical_grid.RowSpacing = 5;
grid_n = create_control_panel(numerical_grid, 'numeric', 'grid size', 256, 'Simulation grid size in pixels.');
use_bandlimit = create_control_panel(numerical_grid, 'dropdown', 'band-limit', {'on', 'off'}, 'on', 'Apply band-limited angular-spectrum support.');
display_scale_dd = create_control_panel(numerical_grid, 'dropdown', 'image scaling', {'fixed', 'auto'}, 'fixed', 'Fixed uses consistent color limits; auto stretches each image.');

actions = create_control_panel(left_grid, 'section', 'actions', 1);
actions.panel.Layout.Row = 2;
actions.panel.Layout.Column = 1;
button_block = bind_workflow(actions.grid, app_figure, @run_simulation, @reset_defaults, @export_result, 'GenerateText', 'Run');
button_block.generate.Tooltip = 'Run current wave-optics simulation.';

status_box = uitextarea(tab, ...
    'Editable', 'off', ...
    'Value', {'status: ready'}, ...
    'FontName', 'Courier New', ...
    'Visible', 'off');
has_result = false;

preview_grid = ui.preview_grid;
ax_input = ui.preview_axes(1);
ax_aux1 = ui.preview_axes(2);
ax_aux2 = ui.preview_axes(3);
ax_output = ui.preview_axes(4);
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
            object_field = make_demo_object(object_dd.Value, n);
            dx = pixel_size.Value * 1e-6;
            lambda = wavelength_nm.Value * 1e-9;
            z = prop_distance.Value * 1e-3;
            use_bl = strcmp(use_bandlimit.Value, 'on');
            mode_key = mode_dd.Value;
            scaling_mode = display_scale_dd.Value;
            [~, ~, fx, fy] = make_coordinate_grid(n, n, dx, dx);

            if strcmp(mode_key, 'free_space')
                u0 = object_field;
                [u1, transfer] = angular_spectrum_propagation(u0, dx, lambda, z, use_bl);
                spectrum = normalize_array(log1p(abs(fftshift(fft2(ifftshift(u0))))));
                output_intensity = normalize_array(abs(u1).^2);
                output_phase = angle(u1);
                render_result('image_display', ax_input, object_field, 'gray', scaling_mode, [0 1], 'image');
                title(ax_input, '$\mathrm{input\ amplitude}$', 'Interpreter', 'latex');
                render_result('image_display', ax_aux1, spectrum, 'gray', scaling_mode, [0 1], 'image');
                title(ax_aux1, '$\mathrm{input\ spectrum}$', 'Interpreter', 'latex');
                render_result('image_display', ax_aux2, real(transfer), 'parula', scaling_mode, [-1 1], 'image');
                title(ax_aux2, '$\Re\{H(f_x,f_y)\}$', 'Interpreter', 'latex');
                render_result('image_display', ax_output, output_intensity, 'hot', scaling_mode, [0 1], 'image');
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
                render_result('image_display', ax_input, object_field, 'gray', scaling_mode, [0 1], 'image');
                title(ax_input, '$\mathrm{input\ object}$', 'Interpreter', 'latex');
                render_result('image_display', ax_aux1, normalize_array(log1p(abs(spectrum))), 'gray', scaling_mode, [0 1], 'image');
                title(ax_aux1, '$|\mathcal{F}\{U_0\}|$', 'Interpreter', 'latex');
                render_result('image_display', ax_aux2, mask, 'gray', scaling_mode, [0 1], 'image');
                title(ax_aux2, '$\mathrm{filter\ mask}$', 'Interpreter', 'latex');
                render_result('image_display', ax_output, out_intensity, 'hot', scaling_mode, [0 1], 'image');
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

            notes_box.Value = local_wave_notes(mode_key);
            for ax = all_axes
                ax.XTick = [];
                ax.YTick = [];
            end

            for ax_iter = all_axes
                axis(ax_iter, 'image');
            end
            has_result = true;
            pause(0.08);
            if show_alert
                uialert(app_figure, 'Wave-optics preview updated successfully.', 'Run complete', 'Icon', 'info');
            end
        catch ME
            uialert(app_figure, sprintf('Wave-optics run failed:\n%s', ME.message), 'Run failed', 'Icon', 'error');
            warning('%s', getReport(ME, 'extended', 'hyperlinks', 'off'));
        end
    end

    function reset_defaults()
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
                sprintf('object = %s', object_dd.Value), ...
                sprintf('filter = %s', filter_dd.Value), ...
                sprintf('filter_scale = %.6f', filter_scale.Value), ...
                sprintf('pixel_size_um = %.6f', pixel_size.Value), ...
                sprintf('wavelength_nm = %.6f', wavelength_nm.Value), ...
                sprintf('distance_mm = %.6f', prop_distance.Value), ...
                sprintf('grid_size = %d', round(grid_n.Value)), ...
                sprintf('band_limit = %s', use_bandlimit.Value), ...
                sprintf('image_scaling = %s', display_scale_dd.Value)};
            export_info = image_output('export_preview_bundle', project_root, 'wave_optics', all_axes, ...
                {'input','aux1','aux2','output'}, [2 2], param_lines, notes_box.Value, status_box.Value, dlg);
            uialert(app_figure, sprintf('Wave-optics export saved to:\n%s', export_info.bundle_dir), 'Export complete', 'Icon', 'info');
        catch ME
            uialert(app_figure, sprintf('Wave-optics export failed:\n%s', ME.message), 'Export failed', 'Icon', 'error');
            warning('%s', getReport(ME, 'extended', 'hyperlinks', 'off'));
        end
    end
end

function lines = local_wave_notes(mode_key)
lines = { ...
    'This tab simulates scalar wave optics propagation and diffraction.', ...
    sprintf('mode = %s selects propagation/free-space, aperture diffraction, or related scalar-wave setup.', char(string(mode_key))), ...
    'wavelength sets phase accumulation. propagation distance z controls Fresnel/Fraunhofer spreading.', ...
    'aperture width/radius and separation set the initial field support and interference structure.', ...
    'grid size/window size control numerical sampling; too small a window clips diffraction tails.', ...
    'Preview panels show initial field, phase/intensity evolution, transfer function, or propagated intensity. Notes gives Fourier propagation formulas.'};
end
