function art_icecream_scene(ax, arg2, arg3, arg4, arg5)
%PLOT_ICECREAM_SCENE Draw ice cream scenes in an axes.
% New signature: plot_icecream_scene(ax, sceneName, flavor, addCone, addFlowers)
% Backward-compatible signature: plot_icecream_scene(ax, flavor, addCone, addFlowers)
if nargin < 1 || isempty(ax)
    figure('Color','w');
    ax = gca;
end

sceneList = {'Soft Serve','Sundae Cup','Bouquet'};
sceneName = 'Soft Serve';
flavor = 'chocolate';
addCone = true;
addFlowers = false;

if nargin >= 2 && ~isempty(arg2)
    if ischar(arg2) || isstring(arg2)
        if any(strcmpi(char(arg2),sceneList))
            sceneName = char(arg2);
            if nargin >= 3 && ~isempty(arg3), flavor = char(arg3); end
            if nargin >= 4 && ~isempty(arg4), addCone = logical(arg4); end
            if nargin >= 5 && ~isempty(arg5), addFlowers = logical(arg5); end
        else
            flavor = char(arg2);
            if nargin >= 3 && ~isempty(arg3), addCone = logical(arg3); end
            if nargin >= 4 && ~isempty(arg4), addFlowers = logical(arg4); end
        end
    end
end

clear_ax(ax);
hold(ax,'on');
axis(ax,'equal');
axis(ax,'off');
view(ax,[-28 18]);
ax.Color = [1 1 1];

switch lower(sceneName)
    case 'sundae cup'
        draw_sundae_cup(ax, flavor, addFlowers);
        titleText = 'Ice Cream -- Sundae Cup';
    case 'bouquet'
        draw_bouquet(ax, flavor, addFlowers);
        titleText = 'Ice Cream -- Bouquet';
    otherwise
        draw_soft_serve(ax, flavor, addCone, addFlowers);
        titleText = 'Ice Cream -- Soft Serve';
end

camlight(ax,'headlight');
lighting(ax,'gouraud');
safe_title(ax,titleText);
end

function draw_soft_serve(ax, flavor, addCone, addFlowers)
[X, Y, Z] = art_softserve_shape();
cream = flavor_color(flavor);
surf(ax,X,Y,Z+1.4,'FaceColor',cream,'EdgeColor','none');
if addCone
    [cx,cy,cz] = cylinder([0.65 0.18],96);
    cz = -cz*1.6+1.25;
    surf(ax,cx,cy,cz,'FaceColor',[228,200,142]./255,'EdgeColor',[0.45 0.25 0.1],'EdgeAlpha',0.2);
    for k = -6:6
        plot3(ax,[-0.7 0.7],[k*0.12 k*0.12]+0.15,linspace(0.7,-0.1,2),'Color',[0.45 0.25 0.1]);
    end
end
if addFlowers
    for k = 1:10
        a = 2*pi*k/10;
        draw_small_flower(ax,[1.05*cos(a),1.05*sin(a),1.08+0.15*sin(k)],a,[1 .65 .78]);
    end
end
end

function draw_sundae_cup(ax, flavor, addFlowers)
cream = flavor_color(flavor);
% Glass cup
[th,z] = meshgrid(linspace(0,2*pi,120),linspace(0,1,80));
r = 0.35 + 0.28*z + 0.05*sin(3*pi*z);
X = r.*cos(th); Y = r.*sin(th); Z = z*1.1;
surf(ax,X,Y,Z,'FaceColor',[0.85 0.93 0.98],'EdgeColor','none','FaceAlpha',0.35);
fill3(ax,0.65*cos(th(1,:)),0.65*sin(th(1,:)),ones(1,size(th,2))*1.08,[0.9 0.95 1.0],'EdgeColor','none','FaceAlpha',0.18);
% Scoops
[sx,sy,sz] = sphere(80);
surf(ax,0.45*sx-0.28,0.45*sy,0.45*sz+1.18,'FaceColor',cream,'EdgeColor','none');
surf(ax,0.42*sx+0.18,0.42*sy+0.05,0.42*sz+1.35,'FaceColor',min(cream*0.95+0.05,1),'EdgeColor','none');
% Syrup
plot3(ax,linspace(-0.4,0.35,180),0.07*sin(linspace(0,8*pi,180)),1.72+0.05*cos(linspace(0,8*pi,180)),...
    'Color',[0.35 0.18 0.05],'LineWidth',3);
% Cherry
[sx,sy,sz] = sphere(40);
surf(ax,0.12*sx,0.12*sy,0.12*sz+1.92,'FaceColor',[0.82 0.12 0.16],'EdgeColor','none');
plot3(ax,[0 0.06],[0 0.08],[2.0 2.18],'Color',[0.2 0.5 0.18],'LineWidth',2);
if addFlowers
    for k = 1:6
        a = 2*pi*k/6;
        draw_small_flower(ax,[0.78*cos(a),0.78*sin(a),1.05],a,[0.95 0.8 0.95]);
    end
end
end

function draw_bouquet(ax, flavor, addFlowers)
[Xa, Ya, Za] = art_softserve_shape();
cream = flavor_color(flavor);

rb = 0:.01:1;
tb = linspace(0,2,151);
wb = rb'*((abs((1-mod(tb*5,2))))/2+.3);
xb = wb.*cospi(tb);
yb = wb.*sinpi(tb);
zb = (-cospi(wb*1.2)+1).^.2;

if addFlowers
    colorList = [0.3300 0.3300 0.6900;0.5300 0.4000 0.6800;0.6800 0.4200 0.6300;0.7800 0.4200 0.5700;0.9100 0.4900 0.4700;0.9600 0.7300 0.4400];
else
    base = cream*0.55 + 0.35;
    colorList = [base*0.7;base*0.82;base*0.92;base;base*1.05;base*1.1];
    colorList(colorList>1) = 1;
end
colorMapb = setColorByH(zb, colorList);

yaw_z = 72*pi/180;
roll_x_1 = pi/8;
roll_x_2 = pi/9;
R_z_2 = [cos(yaw_z), -sin(yaw_z), 0; sin(yaw_z), cos(yaw_z), 0; 0, 0, 1];
R_z_1 = [cos(yaw_z/2), -sin(yaw_z/2), 0; sin(yaw_z/2), cos(yaw_z/2), 0; 0, 0, 1];
R_z_3 = [cos(yaw_z/3), -sin(yaw_z/3), 0; sin(yaw_z/3), cos(yaw_z/3), 0; 0, 0, 1];
R_x_1 = [1, 0, 0; 0, cos(roll_x_1), -sin(roll_x_1); 0, sin(roll_x_1), cos(roll_x_1)];
R_x_2 = [1, 0, 0; 0, cos(roll_x_2), -sin(roll_x_2); 0, sin(roll_x_2), cos(roll_x_2)];

surface(ax,Xa,Ya,Za+0.7,'EdgeAlpha',0.05,'EdgeColor',[0 0 0],'FaceColor',cream);
[nXr,nYr,nZr] = rotateXYZ(Xa, Ya, Za+0.7, R_x_1);
nYr = nYr-0.4;
surface(ax,nXr,nYr,nZr-0.1,'EdgeAlpha',0.05,'EdgeColor',[0 0 0],'FaceColor',cream);
drawStraw(ax,nXr,nYr,nZr-0.1);
for k = 1:4
    [nXr,nYr,nZr] = rotateXYZ(nXr,nYr,nZr,R_z_2);
    surface(ax,nXr,nYr,nZr-0.1,'EdgeAlpha',0.05,'EdgeColor',[0 0 0],'FaceColor',cream);
    drawStraw(ax,nXr,nYr,nZr-0.1);
end

place_flower_ring(ax, xb,yb,zb,colorMapb,R_x_2,R_z_2,R_z_2,-1.35,5);
place_flower_ring(ax, xb,yb,zb,colorMapb,R_x_2,R_z_1,R_z_2,-1.15,5);
place_flower_ring(ax, xb,yb,zb,colorMapb,R_x_2,R_z_3,R_z_2,-1.25,5);
place_flower_ring(ax, xb,yb,zb,colorMapb,R_x_2,R_z_3*R_z_3,R_z_2,-1.25,5);

view(ax,[-26,24]);
end

function place_flower_ring(ax, xb,yb,zb,colorMapb,R_x_2,R_initial,R_step,yOffset,nRepeat)
[nXb,nYb,nZb] = rotateXYZ(xb./2.5,yb./2.5,zb./2.5+0.32,R_x_2);
nYb = nYb + yOffset;
[nXb,nYb,nZb] = rotateXYZ(nXb,nYb,nZb,R_initial);
for k = 1:nRepeat
    [nXb,nYb,nZb] = rotateXYZ(nXb,nYb,nZb,R_step);
    SHdl = surface(ax,nXb,nYb,nZb,'EdgeColor','none','FaceColor','interp','CData',colorMapb);
    material(SHdl,'dull');
    drawStraw(ax,nXb,nYb,nZb);
end
end

function cMap = setColorByH(H,cList)
X = (H-min(H(:)))./(max(H(:))-min(H(:))+eps);
xx = (0:size(cList,1)-1)./(size(cList,1)-1);
y1 = cList(:,1); y2 = cList(:,2); y3 = cList(:,3);
cMap(:,:,1) = interp1(xx,y1,X,'linear');
cMap(:,:,2) = interp1(xx,y2,X,'linear');
cMap(:,:,3) = interp1(xx,y3,X,'linear');
end

function [nX,nY,nZ] = rotateXYZ(X,Y,Z,R)
sz = size(X);
nXYZ = [X(:),Y(:),Z(:)]*R.';
nX = reshape(nXYZ(:,1),sz);
nY = reshape(nXYZ(:,2),sz);
nZ = reshape(nXYZ(:,3),sz);
end

function drawStraw(ax,X,Y,Z)
[m,n] = find(Z==min(Z(:)),1);
x1 = X(m,n); y1 = Y(m,n); z1 = Z(m,n)+0.03;
xx = [x1,0,(x1*cos(pi/3)-y1*sin(pi/3))/3].';
yy = [y1,0,(y1*cos(pi/3)+x1*sin(pi/3))/3].';
zz = [z1,-0.7,-1.5].';
strawPnts = bezierCurve([xx,yy,zz],50);
plot3(ax,strawPnts(:,1),strawPnts(:,2),strawPnts(:,3),...
    'Color',[88,130,126]./255,'LineWidth',2);
end

function pnts = bezierCurve(pnts,N)
t = linspace(0,1,N);
p = size(pnts,1)-1;
coe1 = factorial(p)./factorial(0:p)./factorial(p:-1:0);
coe2 = ((t).^((0:p)')).*((1-t).^((p:-1:0)'));
pnts = (pnts'*(coe1'.*coe2))';
end

function draw_small_flower(ax,c,a,color)
th = linspace(0,2*pi,60);
r = 0.11 + 0.04*sin(5*th);
x = c(1)+r.*cos(th)*cos(a)-r.*sin(th)*sin(a);
y = c(2)+r.*cos(th)*sin(a)+r.*sin(th)*cos(a);
z = c(3)+0*th;
patch(ax,x,y,z,color,'EdgeColor','none','FaceAlpha',0.92);
plot3(ax,c(1),c(2),c(3),'.','Color',[0.9 0.65 0.12],'MarkerSize',12);
end

function cream = flavor_color(styleName)
switch lower(styleName)
    case 'vanilla'
        cream = [0.98 0.88 0.68];
    case 'strawberry'
        cream = [1.00 0.55 0.68];
    case 'matcha'
        cream = [0.44 0.64 0.32];
    otherwise
        cream = [0.40 0.20 0.05];
end
end
