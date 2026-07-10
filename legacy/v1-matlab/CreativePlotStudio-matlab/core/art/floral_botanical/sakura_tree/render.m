% Sakura Tree
% This script is executed by the GUI with variables: ax, style.
if ~exist('ax','var') || isempty(ax)
    figure('Color','w');
    ax = gca;
end
if ~exist('style','var') || isempty(style)
    style = 'default';
end
style = char(style);

art_sakura_tree(ax,16);

try
    art_apply_recommended_view(ax,'Sakura Tree');
catch
end

finalize_project_axes(ax,'Sakura Tree');
