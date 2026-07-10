% Ice Cream Soft Serve
% This script is executed by the GUI with variables: ax, style.
if ~exist('ax','var') || isempty(ax)
    figure('Color','w');
    ax = gca;
end
if ~exist('style','var') || isempty(style)
    style = 'default';
end
style = char(style);

flavor = style; if ~any(strcmpi(flavor,{'chocolate','vanilla','strawberry','matcha'})), flavor = 'chocolate'; end; art_icecream_scene(ax,'Soft Serve',flavor,true,false);

try
    art_apply_recommended_view(ax,'Ice Cream Soft Serve');
catch
end

finalize_project_axes(ax,'Ice Cream Soft Serve');
