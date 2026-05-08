function art_landscape(ax, withMoon)
%PLOT_LANDSCAPE Moonlit mountain scene with a darker night atmosphere.
% Based on the original landScape/autumoon style shared by the user.
if nargin < 1 || isempty(ax)
    figure('Color','w');
    ax = gca;
end
if nargin < 2
    withMoon = true;
end

clear_ax(ax);
ax.XTick = [];
ax.YTick = [];
ax.XLim = [0,800];
ax.YLim = [0,600];
ax.DataAspectRatio = [1 1 1];
ax.Color = [7 12 25]./255;
hold(ax,'on');
axis(ax,'manual');

% Darker night-oriented palette inspired by the original txt version.
cFurther = [225,35,70];
cCloser  = [210,70,10];
cClouds  = [250,26,43];
cSky     = [215,100,18];
cMoon    = [253,252,222]./255;

ax.Color = hsv2rgb(cFurther./[360,100,100]);
drawSky(ax,cSky,cFurther);

if withMoon
    drawMoon(ax);
end

cloudsCMesh = getCloudsCMesh(cClouds);
cloudsAlpha = getCloudsAlpha();
image(ax,[0,800],[250,600],cloudsCMesh,'AlphaData',cloudsAlpha);

drawMountains(ax,cFurther,cCloser);

% A very faint lower haze helps the mountains feel enclosed by night.
[Xh,Yh] = meshgrid(1:800,1:180);
Ch = zeros([size(Xh),3]);
Ch(:,:,1) = 12/255; Ch(:,:,2) = 18/255; Ch(:,:,3) = 30/255;
Ah = repmat(linspace(0.45,0,180)',1,800);
image(ax,[0,800],[0,180],Ch,'AlphaData',Ah);

ax.Layer = 'top';
box(ax,'on');
style_axes_latex(ax);
grid(ax,'off');
axis(ax,'off');
safe_title(ax,'Moonlit Mountains');

end

function drawSky(ax,colSky,colFurther)
colSky = hsv2rgb(colSky./[360,100,100]);
colFurther = hsv2rgb(colFurther./[360,100,100]);
[XMesh,YMesh] = meshgrid(1:800,301:600);
ZMesh = zeros(size(XMesh));
CMesh = vColorMat([800,300],[colFurther;colSky]);
surf(ax,XMesh,YMesh,ZMesh,'CData',CMesh,'EdgeColor','none');
end

function drawMoon(ax)
t1 = linspace(-pi/2,pi/2,150);
t2 = linspace(pi/2,3*pi/2,150);
X1 = cos(t1).*35; Y1 = sin(t1).*35;
X2 = cos(t2).*35; Y2 = sin(t2).*35;
fill(ax,[X1,X2]+600,[Y1,Y2]+500,[253,252,222]./255,'EdgeColor','none','FaceAlpha',0.95);
end

function CMesh = getCloudsCMesh(colClouds)
colClouds = hsv2rgb(colClouds./[360,100,100]);
CMesh = zeros([500,500,3]);
CMesh(:,:,1) = colClouds(1);
CMesh(:,:,2) = colClouds(2);
CMesh(:,:,3) = colClouds(3);
end

function Alpha = getCloudsAlpha()
[X,Y] = meshgrid(linspace(0,1,500));
CLX = (-cos(X.*2.*pi)+1).^.2;
CLY = (-cos(Y.*2.*pi)+1).^.2;
r = (X-.5).^2+(Y-.5).^2;
r(r==0) = eps;
alp = abs(ifftn(exp(3i*rand(500))./r.^.8)).*(CLX.*CLY);
alp = alp./max(alp,[],'all');
dy = (1:500)./500.*0.8+0.2;
Alpha = alp.*(dy');
end

function drawMountains(ax,colFurther,colCloser)
[X,Y] = meshgrid(linspace(0,1,800));
CLX = (-cos(X.*2.*pi)+1).^.2;
CLY = (-cos(Y.*2.*pi)+1).^.2;
r = (X-.5).^2+(Y-.5).^2;
r(r==0) = eps;
for i = 1:8
    h = abs(ifftn(exp(5i*rand(800))./r.^1.05)).*(CLX.*CLY).*10;
    nh = (8-i)*30+h(400,:);
    if i==1
        nh = nh.*.8;
    end
    hm = ceil(max(nh));
    CMesh = zeros([hm,800,3]);
    tcol = colFurther+(colCloser-colFurther)./8.*i;
    tcol = hsv2rgb(tcol./[360,100,100]);
    CMesh(:,:,1) = tcol(1);
    CMesh(:,:,2) = tcol(2);
    CMesh(:,:,3) = tcol(3);
    alp = ones(hm,800);
    alp((1:hm)'>nh) = nan;
    image(ax,[-50,850],[0,hm],CMesh,'AlphaData',alp.*0.985);
end
end

function colorMat = vColorMat(matSize,colorList)
yList = ((0:(matSize(2)-1))./(matSize(2)-1))';
xList = ones(1,matSize(1));
colorMat(:,:,1) = (colorList(1,1)+yList.*(colorList(2,1)-colorList(1,1)))*xList;
colorMat(:,:,2) = (colorList(1,2)+yList.*(colorList(2,2)-colorList(1,2)))*xList;
colorMat(:,:,3) = (colorList(1,3)+yList.*(colorList(2,3)-colorList(1,3)))*xList;
end
