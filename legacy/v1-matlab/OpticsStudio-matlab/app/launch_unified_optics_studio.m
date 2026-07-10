function app = launch_unified_optics_studio(project_root)
%LAUNCH_UNIFIED_OPTICS_STUDIO Build the main GUI window.

if nargin < 1 || isempty(project_root)
    project_root = pwd;
end

app = struct();
app.project_root = project_root;
app.figure = uifigure( ...
    'Name', 'Unified Optics Studio', ...
    'Position', [80 80 1220 760], ...
    'Color', [0.98 0.98 0.98]);

root_grid = uigridlayout(app.figure, [1 1]);
root_grid.RowHeight = {'1x'};
root_grid.ColumnWidth = {'1x'};
root_grid.Padding = [6 6 6 6];
root_grid.RowSpacing = 0;
root_grid.ColumnSpacing = 0;

app.tab_group = uitabgroup(root_grid);
app.tab_group.Layout.Row = 1;
app.tab_group.Layout.Column = 1;

create_fourier_studio_tab(app.tab_group, project_root);
create_wave_optics_tab(app.tab_group, project_root);
create_imaging_tab(app.tab_group, project_root);
create_interference_tab(app.tab_group, project_root);
create_ray_optics_tab(app.tab_group, project_root);
create_tomography_tab(app.tab_group, project_root);

drawnow;
app.figure.WindowState = 'maximized';
end
