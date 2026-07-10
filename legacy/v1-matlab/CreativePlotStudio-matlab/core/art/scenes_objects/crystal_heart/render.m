% Crystal Heart
% This script is executed by the GUI with variables: ax, style.
if ~exist('ax','var') || isempty(ax)
    figure('Color','w');
    ax = gca;
end
if ~exist('style','var') || isempty(style)
    style = 'default';
end
style = char(style);

art_crystal_heart(ax,4);

try
    art_apply_recommended_view(ax,'Crystal Heart');
catch
end

finalize_project_axes(ax,'Crystal Heart');
