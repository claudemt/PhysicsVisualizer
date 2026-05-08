function file_path = export_waveguide_axes_png(folder_path, file_name, plot_fcn)
%EXPORT_WAVEGUIDE_AXES_PNG Render one axes-based plot to a PNG file.
%
% The project-specific plot function draws into an axes.  File creation is
% delegated to the shared image_output('save_figure', ...) utility so all
% projects use the same figure-export path.

if exist(folder_path, 'dir') ~= 7
    mkdir(folder_path);
end

cleanup_visibility = image_output('hidden_figures');

fig = figure( ...
    'Visible', 'off', ...
    'HandleVisibility', 'off', ...
    'IntegerHandle', 'off', ...
    'MenuBar', 'none', ...
    'ToolBar', 'none', ...
    'NumberTitle', 'off', ...
    'Name', '', ...
    'Color', 'w', ...
    'Position', [100 100 1080 780]);

ax = axes('Parent', fig, 'Units', 'normalized', 'Position', [0.09 0.11 0.76 0.80]);
try
    plot_fcn(ax);
    drawnow;
    file_path = image_output('save_figure', fig, folder_path, sanitize_waveguide_name(file_name), 260);
catch ME
    close(fig);
    rethrow(ME);
end
close(fig);
end
