function app = launch_gui_studio(project_root, tab_builders, varargin)
if nargin < 1 || isempty(project_root)
    project_root = pwd;
end
if nargin < 2 || isempty(tab_builders)
    tab_builders = {};
end
if isa(tab_builders, 'function_handle')
    tab_builders = {tab_builders};
end

p = inputParser;
p.addParameter('Name', 'GUI Studio');
p.addParameter('Position', [80 80 1240 780]);
p.addParameter('Color', [0.98 0.98 0.98]);
p.addParameter('Maximized', true);
p.parse(varargin{:});
opt = p.Results;

app = struct();
app.project_root = project_root;
app.figure = uifigure('Name', opt.Name, 'Position', opt.Position, 'Color', opt.Color);
app.figure.CloseRequestFcn = @(src, evt) local_close_request(src, project_root);

root_grid = uigridlayout(app.figure, [1 1]);
root_grid.RowHeight = {'1x'};
root_grid.ColumnWidth = {'1x'};
root_grid.Padding = [6 6 6 6];
root_grid.RowSpacing = 0;
root_grid.ColumnSpacing = 0;

app.tab_group = uitabgroup(root_grid);
app.tab_group.Layout.Row = 1;
app.tab_group.Layout.Column = 1;

for k = 1:numel(tab_builders)
    f = tab_builders{k};
    if isa(f, 'function_handle')
        f(app.tab_group, project_root);
    elseif ischar(f) || isstring(f)
        feval(char(f), app.tab_group, project_root);
    else
        error('Invalid tab builder.');
    end
end

drawnow;
if opt.Maximized
    try
        app.figure.WindowState = 'maximized';
    catch
    end
end
end

function local_close_request(fig, project_root)
cache_root = fullfile(project_root, '.cache');
if exist(cache_root, 'dir') == 7
    try
        rmdir(cache_root, 's');
    catch
    end
end
delete(fig);
end
