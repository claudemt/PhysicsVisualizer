function file_path = export_waveguide_panel_png(folder_path, file_name, plot_fcn)
%EXPORT_WAVEGUIDE_PANEL_PNG Render a panel/tiled-layout plot to a PNG file.
%
% Hidden-only legacy exporter. New montage sheets use
% export_waveguide_image_montage_png, which does not create figures.

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
    'Position', [100 100 1120 820]);
panel = uipanel(fig, 'Units', 'normalized', 'Position', [0 0 1 1], 'BorderType', 'none', 'BackgroundColor', 'w');
try
    plot_fcn(panel);
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
