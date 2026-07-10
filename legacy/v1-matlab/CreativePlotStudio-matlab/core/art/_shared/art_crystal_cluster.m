function art_crystal_cluster(ax, count)
if nargin < 1 || isempty(ax), figure; ax = gca; end
if nargin < 2, count = 50; end
clear_ax(ax); rng('shuffle');
for i=1:count
    len=rand()*8+5; v=rand(1,3)-0.5; v(3)=abs(v(3)); v=v./norm(v).*len;
    draw_single_crystal(ax,[0 0 0],v,pi/6,0.8,0.1,rand()*0.2+0.2);
end
axis(ax,[-15 15 -15 15 -2 15]); axis(ax,'vis3d'); view(ax,[-36 24]); camlight(ax,'headlight'); lighting(ax,'gouraud');
style_axes_latex(ax); safe_title(ax,'Crystal cluster');
end
