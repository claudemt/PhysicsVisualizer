function app = launch_chladni_studio(project_root)
%LAUNCH_CHLADNI_STUDIO Build the main GUI window.

if nargin < 1 || isempty(project_root)
    project_root = pwd;
end

app = struct();
app.project_root = project_root;
app.figure = uifigure( ...
    'Name', 'Chladni GUI Studio', ...
    'Position', [80 80 1240 780], ...
    'Color', [0.98 0.98 0.98]);
app.figure.CloseRequestFcn = @(src, evt) local_close_request(src, project_root); %#ok<NASGU>

root_grid = uigridlayout(app.figure, [1 1]);
root_grid.RowHeight = {'1x'};
root_grid.ColumnWidth = {'1x'};
root_grid.Padding = [6 6 6 6];
root_grid.RowSpacing = 0;
root_grid.ColumnSpacing = 0;

app.tab_group = uitabgroup(root_grid);
app.tab_group.Layout.Row = 1;
app.tab_group.Layout.Column = 1;

% Keep the spectral/eigenmode page and the static-load page separate.
create_chladni_tab(app.tab_group, project_root);
create_static_tab(app.tab_group, project_root);

drawnow;
app.figure.WindowState = 'maximized';
end

function local_close_request(fig, project_root)
cache_root = fullfile(project_root, '.cache');
if exist(cache_root, 'dir')
    try
        rmdir(cache_root, 's');
    catch
    end
end

delete(fig);
end
