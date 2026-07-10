% Rose Ball
% This script is executed by the GUI with variables: ax, style.
if ~exist('ax','var') || isempty(ax)
    figure('Color','w');
    ax = gca;
end
if ~exist('style','var') || isempty(style)
    style = 'default';
end
style = char(style);

pal = style; if ~any(strcmpi(pal,{'blue','teal','sunset','violet'})), pal = 'blue'; end; art_rose_ball(ax,pal);

try
    art_apply_recommended_view(ax,'Rose Ball');
catch
end

finalize_project_axes(ax,'Rose Ball');
