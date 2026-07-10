function art_crystal_heart(ax, density)
if nargin < 1 || isempty(ax), figure; ax = gca; end
if nargin < 2, density = 6; end
clear_ax(ax); sep=pi/8;
t=[0:0.2:sep,sep:0.05:pi-sep,pi-sep:0.2:pi+sep,pi+sep:0.05:2*pi-sep,2*pi-sep:0.2:2*pi];
x=16*sin(t).^3; y=13*cos(t)-5*cos(2*t)-2*cos(3*t)-cos(4*t); z=zeros(size(t));
plot3(ax,x,y,z,'Color',[186,110,64]./255,'LineWidth',1.4); rng('shuffle');
for i=1:length(t)
    for j=1:density
        len=rand()*2.5+1.5; v=rand(1,3)-0.5; v=v./norm(v).*len; sp=[x(i),y(i),z(i)];
        draw_single_crystal(ax,sp,sp+v,pi/6,0.8,0.14,0.2);
    end
end
axis(ax,[-22 22 -20 20 -10 10]); axis(ax,'vis3d'); view(ax,[-32 22]); camlight(ax,'headlight'); lighting(ax,'gouraud');
style_axes_latex(ax); safe_title(ax,'Crystal heart');
end
