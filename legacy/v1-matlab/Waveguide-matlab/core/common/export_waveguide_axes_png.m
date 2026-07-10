function file_path = export_waveguide_axes_png(folder_path, file_name, plot_fcn)
%EXPORT_WAVEGUIDE_AXES_PNG Render one axes-based plot to a PNG file.
%
% Figures are always hidden. This function also temporarily sets MATLAB's
% default figure visibility to off so nested graphics calls cannot pop up
% intermediate windows.

if ~exist(folder_path, 'dir')
    mkdir(folder_path);
end
file_path = fullfile(folder_path, sanitize_waveguide_name(file_name));

old_visibility = get(groot, 'DefaultFigureVisible');
cleanup_visibility = onCleanup(@() set(groot, 'DefaultFigureVisible', old_visibility));
set(groot, 'DefaultFigureVisible', 'off');

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
    try
        exportgraphics(fig, file_path, 'Resolution', 260);
    catch
        print(fig, file_path, '-dpng', '-r260');
    end
catch ME
    close(fig);
    rethrow(ME);
end
close(fig);
end
