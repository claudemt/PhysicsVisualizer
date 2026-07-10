% Blue Rose
% This script is executed by the GUI with variables: ax, style.
if ~exist('ax','var') || isempty(ax)
    figure('Color','w');
    ax = gca;
end
if ~exist('style','var') || isempty(style)
    style = 'default';
end
style = char(style);

art_rose(ax,'blue');

try
    art_apply_recommended_view(ax,'Blue Rose');
catch
end

finalize_project_axes(ax,'Blue Rose');
