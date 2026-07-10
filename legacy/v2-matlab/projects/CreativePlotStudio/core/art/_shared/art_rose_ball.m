function art_rose_ball(ax, paletteName)
if nargin < 1 || isempty(ax), figure; ax = gca; end
if nargin < 2, paletteName='blue'; end
clear_ax(ax); [X,Y,Z,C]=rose_surface_data('blue');
Z=Z+0.35; C=(C-min(C(:)))./(max(C(:))-min(C(:)));
cm = local_palette(paletteName); cmap=color_interp(cm,128);
rotations = cat(3, eye(3), diag([1 1 -1]));
yaw=72*pi/180; roll=pi-acos(-1/sqrt(5));
Rz=[cos(yaw) -sin(yaw) 0; sin(yaw) cos(yaw) 0; 0 0 1];
Rx=[1 0 0;0 cos(roll) -sin(roll);0 sin(roll) cos(roll)];
R=Rx;
for k=1:5, rotations(:,:,end+1)=R; R=Rz*R; end %#ok<AGROW>
R=rotz_local(yaw/2)*R;
for k=1:5, rotations(:,:,end+1)=diag([1 1 -1])*(Rz^k)*R; end %#ok<AGROW>
for k=1:size(rotations,3)
    [nX,nY,nZ]=rotate_grid(X,Y,Z,rotations(:,:,k));
    surface(ax,nX,nY,nZ,C,'EdgeAlpha',0.05,'EdgeColor',[0 0 0],'FaceColor','interp');
end
colormap(ax,cmap); axis(ax,'equal'); view(ax,[-34 18]); camlight(ax,'headlight'); lighting(ax,'gouraud');
style_axes_latex(ax); safe_title(ax,'Rose ball');
end
function cm=local_palette(name)
switch lower(name)
case 'sunset', cm=[0.21 .09 .38;.55 .16 .51;.89 .32 .41;1 .69 .49;.98 .95 .71];
case 'teal', cm=[.2 .08 .43;.2 .28 .53;.19 .45 .62;.19 .75 .78;.19 .8 .81];
otherwise, cm=[.02 .04 .39;0 .09 .58;0 .13 .64;.01 .18 .85;0 .35 .99;.17 .69 1];
end
end
function R=rotz_local(a), R=[cos(a) -sin(a) 0; sin(a) cos(a) 0; 0 0 1]; end
function [nX,nY,nZ]=rotate_grid(X,Y,Z,R)
P=R*[X(:)';Y(:)';Z(:)']; nX=reshape(P(1,:),size(X)); nY=reshape(P(2,:),size(Y)); nZ=reshape(P(3,:),size(Z));
end
