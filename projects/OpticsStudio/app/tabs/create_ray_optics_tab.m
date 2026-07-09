function tab = create_ray_optics_tab(tab_group, project_root)
%CREATE_RAY_OPTICS_TAB Build the geometric optics tab.

app_figure = ancestor(tab_group, 'figure');

ui = create_tab_layout(tab_group, 'geometric optics', project_root, ...
    'Preview', 'axesgrid', ...
    'PreviewGridSize', [1 2], ...
    'NotesTitle', 'notes', ...
    'NotesText', local_ray_notes('thin_lens'), ...
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
physical_grid = uigridlayout(physical_panel, [8 1]);
physical_grid.RowHeight = {'fit','fit','fit','fit','fit','fit','fit','fit'};
studio_style('apply_grid', physical_grid, 'panel');
mode_dd = create_control_panel(physical_grid, 'dropdown', 'mode', {'thin_lens', 'spherical_interface'}, 'thin_lens', 'Select paraxial lens or exact single-interface refraction.');
object_distance = create_control_panel(physical_grid, 'numeric', 'object distance (mm)', 120, 'Distance from object to lens.');
focal_length = create_control_panel(physical_grid, 'numeric', 'focal length (mm)', 60, 'Thin-lens focal length.');
object_height = create_control_panel(physical_grid, 'numeric', 'object height (mm)', 10, 'Object point height.');
n1_edit = create_control_panel(physical_grid, 'numeric', 'n1', 1.0, 'Refractive index before the interface.');
n2_edit = create_control_panel(physical_grid, 'numeric', 'n2', 1.5, 'Refractive index after the interface.');
radius_edit = create_control_panel(physical_grid, 'numeric', 'radius (mm)', 40, 'Radius of the spherical surface.');
screen_z_edit = create_control_panel(physical_grid, 'numeric', 'screen z (mm)', 100, 'Observation plane after refraction.');

numerical_panel = uipanel(left_grid, 'Title', 'numerical / display parameters');
studio_style('apply_panel', numerical_panel);
numerical_panel.Layout.Row = 3;
numerical_panel.Layout.Column = 1;
numerical_panel.Visible = 'off';
numerical_grid = uigridlayout(numerical_panel, [2 1]);
numerical_grid.RowHeight = {'fit','fit'};
studio_style('apply_grid', numerical_grid, 'panel');
aperture_edit = create_control_panel(numerical_grid, 'numeric', 'aperture radius (mm)', 12, 'Ray-bundle half aperture.');
ray_count_edit = create_control_panel(numerical_grid, 'numeric', 'ray count', 13, 'Number of rays in the meridional bundle.');

actions = create_control_panel(left_grid, 'section', 'actions', 1);
actions.panel.Layout.Row = 2;
actions.panel.Layout.Column = 1;
bind_workflow(actions.grid, app_figure, @run_simulation, @reset_defaults, @export_result, 'GenerateText', 'Run');

status_box = uitextarea(tab, 'Editable', 'off', 'Visible', 'off');
studio_style('apply_component', status_box, 'mono');
has_result = false;

preview_grid = ui.preview_grid;
ax_rays = ui.preview_axes(1);
ax_coeff = ui.preview_axes(2);
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
            mode_key = mode_dd.Value;
            aperture_radius = aperture_edit.Value;
            ray_count = max(3, round(ray_count_edit.Value));

            cla(ax_rays); cla(ax_coeff);
            if strcmp(mode_key, 'thin_lens')
                result = trace_thin_lens_bundle(object_distance.Value, focal_length.Value, object_height.Value, aperture_radius, ray_count);
                hold(ax_rays, 'on');
                for k = 1:size(result.segments_in, 1)
                    plot(ax_rays, result.segments_in(k, [1 3]), result.segments_in(k, [2 4]), 'LineWidth', 1.1);
                    plot(ax_rays, result.segments_out(k, [1 3]), result.segments_out(k, [2 4]), 'LineWidth', 1.1);
                end
                plot(ax_rays, [0 0], [-1.2 * aperture_radius, 1.2 * aperture_radius], 'k-', 'LineWidth', 2.0);
                plot(ax_rays, -object_distance.Value, object_height.Value, 'ko', 'MarkerFaceColor', 'k');
                plot(ax_rays, result.image_distance, result.image_height, 'ro', 'MarkerFaceColor', 'r');
                hold(ax_rays, 'off');
                title(ax_rays, '$\mathrm{thin\ lens\ ray\ diagram}$', 'Interpreter', 'latex');
                xlabel(ax_rays, '$z\ \mathrm{(mm)}$', 'Interpreter', 'latex');
                ylabel(ax_rays, '$y\ \mathrm{(mm)}$', 'Interpreter', 'latex');
                grid(ax_rays, 'on');
                axis(ax_rays, 'tight');
                ax_rays.PlotBoxAspectRatioMode = 'auto';
                ax_rays.DataAspectRatioMode = 'auto';

                magnification_curve_x = linspace(1.1 * focal_length.Value, 4 * focal_length.Value, 200);
                magnification_curve_y = -focal_length.Value ./ max(magnification_curve_x - focal_length.Value, eps);
                plot(ax_coeff, magnification_curve_x, magnification_curve_y, 'LineWidth', 1.4, 'DisplayName', '$m(s)$');
                hold(ax_coeff, 'on');
                plot(ax_coeff, object_distance.Value, result.magnification, 'ro', 'MarkerFaceColor', 'r', 'DisplayName', '$m_{\mathrm{current}}$');
                hold(ax_coeff, 'off');
                lgd = legend(ax_coeff, 'show', 'Location', 'best', 'Interpreter', 'latex');
                studio_style('apply_legend', lgd);
                title(ax_coeff, '$\mathrm{magnification\ vs.\ object\ distance}$', 'Interpreter', 'latex');
                xlabel(ax_coeff, '$s\ \mathrm{(mm)}$', 'Interpreter', 'latex');
                ylabel(ax_coeff, '$m$', 'Interpreter', 'latex');
                grid(ax_coeff, 'on');
                ax_coeff.PlotBoxAspectRatioMode = 'auto';
                ax_coeff.DataAspectRatioMode = 'auto';

                status_box.Value = { ...
                    sprintf('mode               : %s', mode_key), ...
                    sprintf('image distance     : %.3f mm', result.image_distance), ...
                    sprintf('image height       : %.3f mm', result.image_height), ...
                    sprintf('magnification      : %.3f', result.magnification), ...
                    sprintf('ray count          : %d', ray_count)};
            else
                result = trace_spherical_interface_bundle(n1_edit.Value, n2_edit.Value, radius_edit.Value, aperture_radius, ray_count, screen_z_edit.Value);
                hold(ax_rays, 'on');
                curve_y = linspace(-min(abs(radius_edit.Value), aperture_radius), min(abs(radius_edit.Value), aperture_radius), 400);
                curve_z = radius_edit.Value - sign(radius_edit.Value) * sqrt(max(radius_edit.Value^2 - curve_y.^2, 0));
                plot(ax_rays, curve_z, curve_y, 'k-', 'LineWidth', 2.0);
                for k = 1:size(result.pre_segments, 1)
                    if all(result.pre_segments(k, :) == 0)
                        continue;
                    end
                    plot(ax_rays, result.pre_segments(k, [1 3]), result.pre_segments(k, [2 4]), 'LineWidth', 1.1);
                    if any(result.post_segments(k, :))
                        plot(ax_rays, result.post_segments(k, [1 3]), result.post_segments(k, [2 4]), 'LineWidth', 1.1);
                    end
                end
                xline(ax_rays, screen_z_edit.Value, '--');
                hold(ax_rays, 'off');
                title(ax_rays, '$\mathrm{single\ spherical\ interface}$', 'Interpreter', 'latex');
                xlabel(ax_rays, '$z\ \mathrm{(mm)}$', 'Interpreter', 'latex');
                ylabel(ax_rays, '$y\ \mathrm{(mm)}$', 'Interpreter', 'latex');
                grid(ax_rays, 'on');
                axis(ax_rays, 'tight');
                ax_rays.PlotBoxAspectRatioMode = 'auto';
                ax_rays.DataAspectRatioMode = 'auto';

                theta = linspace(0, pi/2 - 1e-3, 300);
                coeff = fresnel_coefficients(n1_edit.Value, n2_edit.Value, theta);
                plot(ax_coeff, rad2deg(theta), coeff.rs, 'LineWidth', 1.4, 'DisplayName', '$R_s$'); hold(ax_coeff, 'on');
                plot(ax_coeff, rad2deg(theta), coeff.rp, 'LineWidth', 1.4, 'DisplayName', '$R_p$');
                hold(ax_coeff, 'off');
                lgd = legend(ax_coeff, 'show', 'Location', 'northwest', 'Interpreter', 'latex');
                studio_style('apply_legend', lgd);
                title(ax_coeff, '$\mathrm{Fresnel\ reflectance}$', 'Interpreter', 'latex');
                xlabel(ax_coeff, '$\theta_i\ \mathrm{(deg)}$', 'Interpreter', 'latex');
                ylabel(ax_coeff, '$R$', 'Interpreter', 'latex');
                grid(ax_coeff, 'on');
                ax_coeff.PlotBoxAspectRatioMode = 'auto';
                ax_coeff.DataAspectRatioMode = 'auto';

                status_box.Value = { ...
                    sprintf('mode               : %s', mode_key), ...
                    sprintf('n1 -> n2           : %.3f -> %.3f', n1_edit.Value, n2_edit.Value), ...
                    sprintf('surface radius     : %.3f mm', radius_edit.Value), ...
                    sprintf('screen z           : %.3f mm', screen_z_edit.Value), ...
                    sprintf('TIR rays           : %d', sum(result.tir_mask))};
            end

            notes_box.Value = local_ray_notes(mode_key);
            has_result = true;
            pause(0.08);
            if show_alert
                uialert(app_figure, 'Geometric-optics preview updated successfully.', 'Run complete', 'Icon', 'info');
            end
        catch ME
            uialert(app_figure, sprintf('Geometric-optics run failed:\n%s', ME.message), 'Run failed', 'Icon', 'error');
            warning('%s', getReport(ME, 'extended', 'hyperlinks', 'off'));
        end
    end

    function reset_defaults()
        mode_dd.Value = 'thin_lens';
        object_distance.Value = 120;
        focal_length.Value = 60;
        object_height.Value = 10;
        n1_edit.Value = 1.0;
        n2_edit.Value = 1.5;
        radius_edit.Value = 40;
        screen_z_edit.Value = 100;
        aperture_edit.Value = 12;
        ray_count_edit.Value = 13;
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
                sprintf('object_distance_mm = %.6f', object_distance.Value), ...
                sprintf('focal_length_mm = %.6f', focal_length.Value), ...
                sprintf('object_height_mm = %.6f', object_height.Value), ...
                sprintf('n1 = %.6f', n1_edit.Value), ...
                sprintf('n2 = %.6f', n2_edit.Value), ...
                sprintf('radius_mm = %.6f', radius_edit.Value), ...
                sprintf('screen_z_mm = %.6f', screen_z_edit.Value), ...
                sprintf('aperture_radius_mm = %.6f', aperture_edit.Value), ...
                sprintf('ray_count = %d', round(ray_count_edit.Value))};
            export_info = image_output('export_preview_bundle', project_root, 'geometric_optics', [ax_rays; ax_coeff], ...
                {'rays','coefficients'}, [1 2], param_lines, notes_box.Value, status_box.Value, dlg);
            uialert(app_figure, sprintf('Geometric-optics export saved to:\n%s', export_info.bundle_dir), 'Export complete', 'Icon', 'info');
        catch ME
            uialert(app_figure, sprintf('Geometric-optics export failed:\n%s', ME.message), 'Export failed', 'Icon', 'error');
            warning('%s', getReport(ME, 'extended', 'hyperlinks', 'off'));
        end
    end
end

function lines = local_ray_notes(mode_key)
lines = { ...
    'This tab computes geometric-optics ray layouts and paraxial lens/mirror relations.', ...
    sprintf('mode = %s selects the optical element or system geometry.', char(string(mode_key))), ...
    'object distance is distance from object to first element; focal length sets lens/mirror power.', ...
    'aperture and ray count control how many rays are drawn and how wide the incoming bundle is.', ...
    'index fields are refractive indices for media when refraction is involved.', ...
    'Preview panels show ray diagram, image location, and/or aberration-style summaries. Exact sign conventions are in Notes.'};
end
