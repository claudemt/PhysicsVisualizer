function sf = art_rose(ax, kind)
if nargin < 1 || isempty(ax), figure; ax = gca; end
if nargin < 2, kind = 'blue'; end
clear_ax(ax); [X,Y,Z,C]=rose_surface_data(kind);
sf=surface(ax,X,Y,Z,C,'EdgeAlpha',0.1,'EdgeColor',[0.2 0.2 0.2],'FaceColor','interp');
if strcmpi(kind,'blue')
    cmap=color_interp([0.9176 0.9412 1;0.8353 0.8706 0.9922;0.5176 0.5882 0.9255;0.3059 0.4 0.9333;0.1216 0.2275 0.6471],128);
    ttl='Blue rose';
else
    cmap=color_interp([0.2 .0941 .3569;.5137 .149 .5059;.8706 .2902 .4314;1 .6353 .4471;.9843 .9529 .7059],128);
    ttl='Blooming rose';
end
colormap(ax,cmap); axis(ax,'equal'); view(ax,[-42 26]); camlight(ax,'headlight'); lighting(ax,'gouraud');
style_axes_latex(ax); safe_title(ax,ttl);
end
