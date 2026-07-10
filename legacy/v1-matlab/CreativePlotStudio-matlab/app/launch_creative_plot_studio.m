function fig = launch_creative_plot_studio(project_root)
%LAUNCH_CREATIVE_PLOT_STUDIO Create the unified GUI shell.

if nargin < 1 || isempty(project_root)
    project_root = fileparts(fileparts(mfilename('fullpath')));
end

if ~exist(fullfile(project_root,'.cache'),'dir')
    mkdir(fullfile(project_root,'.cache'));
end
if ~exist(fullfile(project_root,'output'),'dir')
    mkdir(fullfile(project_root,'output'));
end

fig = uifigure( ...
    'Name', 'Creative Plot Studio', ...
    'Position', [80 40 1540 1080], ...
    'Color', [0.94 0.94 0.94]);

center_figure(fig);

main_grid = uigridlayout(fig, [1 1]);
main_grid.RowHeight = {'1x'};
main_grid.ColumnWidth = {'1x'};
main_grid.Padding = [0 0 0 0];
main_grid.RowSpacing = 0;
main_grid.ColumnSpacing = 0;

tab_group = uitabgroup(main_grid);
tab_group.Layout.Row = 1;
tab_group.Layout.Column = 1;

create_domain_tab(tab_group, project_root, 'art', 'Art', ...
    'Visual, decorative, and scene-based MATLAB artworks.');
create_domain_tab(tab_group, project_root, 'fractals', 'Fractals', ...
    'Escape-time fractals, recursive geometry, IFS forms, and fractal fields.');
create_domain_tab(tab_group, project_root, 'nonlinear', 'Nonlinear', ...
    'Nonlinear dynamics, chaotic attractors, maps, oscillators, and reaction waves.');
end

function center_figure(fig)
drawnow;
old_units = fig.Units;
fig.Units = 'pixels';
pos = fig.Position;
scr = get(groot, 'ScreenSize');
fig.Position = [max(1, (scr(3) - pos(3)) / 2), ...
                max(1, (scr(4) - pos(4)) / 2), ...
                pos(3), pos(4)];
fig.Units = old_units;
end
