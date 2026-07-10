function export_dir = export_fourier_results(result, output_root)
%EXPORT_FOURIER_RESULTS Export a static PNG bundle and a parameter summary.
if nargin < 2 || isempty(output_root)
    output_root = fullfile(fileparts(mfilename('fullpath')), 'fourier_optics_output');
end
if ~exist(output_root, 'dir')
    mkdir(output_root);
end

plot_style_set('defaults');
timestamp = datestr(now, 'yyyymmdd_HHMMSS');
export_dir = fullfile(output_root, timestamp);
mkdir(export_dir);
plot_opts = localPlotOptions(result.params, result.phase_support);

fig = figure('Color', [1, 1, 1], 'Units', 'pixels', 'Position', [80, 80, 1600, 900], 'Visible', 'off');
tl = tiledlayout(fig, 2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

ax1 = nexttile(tl); plot_style_set('draw_map', ax1, result.x_mm, result.y_mm, result.object_amp, 'object', ...
    ['Object: ', escape_latex(result.object_name)], '$A_o$', plot_opts.object);
xlabel(ax1, '$y$ (mm)'); ylabel(ax1, '$x$ (mm)');

ax2 = nexttile(tl); plot_style_set('draw_map', ax2, result.x_mm, result.y_mm, result.phase_wrapped, 'phase', ...
    ['Phase: ', escape_latex(result.phase_name)], '$\phi$ (rad)', plot_opts.phase);
xlabel(ax2, '$y$ (mm)'); ylabel(ax2, '$x$ (mm)');

ax3 = nexttile(tl); plot_style_set('draw_map', ax3, result.x_mm, result.y_mm, result.after_phase_amp, 'amplitude', ...
    'Amplitude after phase plane', '$|U_p|$', plot_opts.phase);
xlabel(ax3, '$y$ (mm)'); ylabel(ax3, '$x$ (mm)');

ax4 = nexttile(tl); plot_style_set('draw_map', ax4, result.xf_mm, result.yf_mm, result.spectrum_intensity, 'spectrum', ...
    'Fourier-plane intensity', 'enhanced intensity', plot_opts.fourier);
xlabel(ax4, '$y_f$ (mm)'); ylabel(ax4, '$x_f$ (mm)');

ax5 = nexttile(tl); plot_style_set('draw_map', ax5, result.xf_mm, result.yf_mm, result.filter_amp, 'filter', ...
    ['Filter: ', escape_latex(result.filter_name)], '$H$', plot_opts.fourier);
xlabel(ax5, '$y_f$ (mm)'); ylabel(ax5, '$x_f$ (mm)');

ax6 = nexttile(tl); plot_style_set('draw_map', ax6, result.x_mm, result.y_mm, result.output_intensity, 'intensity', ...
    'Image-plane intensity', 'enhanced intensity', plot_opts.object);
xlabel(ax6, '$y$ (mm)'); ylabel(ax6, '$x$ (mm)');

sgtitle(tl, escape_latex(result.summary), 'Interpreter', 'latex', 'FontSize', 17);

png_path = fullfile(export_dir, 'fourier_optics_overview.png');
exportgraphics(fig, png_path, 'Resolution', result.params.export_dpi);
close(fig);

write_params_file(result, fullfile(export_dir, 'fourier_optics_run_parameters.txt'));
end

function opts = localPlotOptions(params, phase_support)
opts = struct();
opts.object = struct('auto_adjust_range', params.auto_adjust_plot_range, ...
    'fixed_half_range', params.object_plot_half_range_mm);
opts.phase = struct('auto_adjust_range', params.auto_adjust_plot_range, ...
    'fixed_half_range', params.object_plot_half_range_mm, ...
    'support_mask', phase_support);
opts.fourier = struct('auto_adjust_range', params.auto_adjust_plot_range, ...
    'fixed_half_range', params.fourier_plot_half_range_mm);
end

function write_params_file(result, path)
fid = fopen(path, 'w');
assert(fid >= 0, 'Failed to open parameter log file for writing.');
cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
p = result.params;
fprintf(fid, 'summary = %s\n', result.summary);
fprintf(fid, 'object_name = %s\n', p.object_name);
fprintf(fid, 'phase_name = %s\n', p.phase_name);
fprintf(fid, 'filter_name = %s\n', p.filter_name);
fprintf(fid, 'wavelength_nm = %.6f\n', p.wavelength_nm);
fprintf(fid, 'focal_length_mm = %.6f\n', p.focal_length_mm);
fprintf(fid, 'window_mm = %.6f\n', p.window_mm);
fprintf(fid, 'n_samples = %d\n', p.n_samples);
fprintf(fid, 'object_scale_mm = %.6f\n', p.object_scale_mm);
fprintf(fid, 'secondary_scale_mm = %.6f\n', p.secondary_scale_mm);
fprintf(fid, 'phase_radius_mm = %.6f\n', p.phase_radius_mm);
fprintf(fid, 'zernike_coeff_waves = %.6f\n', p.zernike_coeff_waves);
fprintf(fid, 'filter_scale_ratio = %.6f\n', p.filter_scale_ratio);
fprintf(fid, 'topological_charge = %d\n', p.topological_charge);
fprintf(fid, 'auto_adjust_plot_range = %d\n', logical(p.auto_adjust_plot_range));
fprintf(fid, 'object_plot_half_range_mm = %.6f\n', p.object_plot_half_range_mm);
fprintf(fid, 'fourier_plot_half_range_mm = %.6f\n', p.fourier_plot_half_range_mm);
end

function out = escape_latex(str)
out = char(string(str));
out = strrep(out, '_', '\_');
out = strrep(out, '%', '\%');
out = strrep(out, '&', '\&');
end
