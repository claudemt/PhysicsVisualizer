function fig = launch_gui_studio(project_root, tab_builders, varargin)
%LAUNCH_GUI_STUDIO Shared studio launcher.
%
% fig = launch_gui_studio(project_root, tab_builders, 'StudioName', name)
%
% This is the only standard app entry helper.  Projects should keep main.m
% minimal: set project_root, add app/core/docs, define tab_builders, then call
% this function.

% Force English UI language so MATLAB runtime messages (validation, warnings)
% appear in English regardless of system locale.
try
    matlab.internal.language.LanguageManager.setLanguage('en');
catch
end

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
p.addParameter('StudioName', 'MATLAB Physics Studio', @(s) ischar(s) || isstring(s));
p.addParameter('Name', '', @(s) ischar(s) || isstring(s));
p.addParameter('Position', [80 60 1280 820], @(v) isnumeric(v) && numel(v) == 4);
p.addParameter('Maximized', true, @(v) islogical(v) || isnumeric(v));
p.addParameter('BackgroundColor', [], @(v) isempty(v) || (isnumeric(v) && numel(v) == 3));
p.parse(varargin{:});
opt = p.Results;
if strlength(string(opt.Name)) > 0
    opt.StudioName = opt.Name;
end

local_add_path(fullfile(project_root, 'app'));
local_add_path(fullfile(project_root, 'core'));
local_add_path(fullfile(project_root, 'docs'));

set(groot, 'defaultTextInterpreter', 'latex');
set(groot, 'defaultAxesTickLabelInterpreter', 'latex');
set(groot, 'defaultLegendInterpreter', 'latex');
set(groot, 'defaultColorbarTickLabelInterpreter', 'latex');

style = studio_style('tokens');
if isempty(opt.BackgroundColor)
    opt.BackgroundColor = style.background;
end

fig = uifigure('Name', char(string(opt.StudioName)), ...
    'Position', opt.Position, ...
    'Color', opt.BackgroundColor);
fig.CloseRequestFcn = @(src, evt) local_close_request(src, project_root);

root = uigridlayout(fig, [1 1]);
root.RowHeight = {'1x'};
root.ColumnWidth = {'1x'};
root.Padding = style.tightPadding;
root.RowSpacing = 0;
root.ColumnSpacing = 0;

tab_group = uitabgroup(root);
tab_group.Layout.Row = 1;
tab_group.Layout.Column = 1;

for i = 1:numel(tab_builders)
    f = tab_builders{i};
    if isa(f, 'function_handle')
        f(tab_group, project_root);
    end
end

drawnow;
if opt.Maximized
    try
        fig.WindowState = 'maximized';
    catch
    end
end
end

function local_add_path(path_text)
if exist(path_text, 'dir') == 7
    addpath(genpath(path_text));
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
