function art_fireworks(ax, paletteName)
%PLOT_FIREWORKS Original-style fireworks effect based on the provided txt.
if nargin < 1 || isempty(ax)
    figure('Color','w');
    ax = gca;
end
if nargin < 2 || isempty(paletteName)
    paletteName = 'blue';
end

clear_ax(ax);
axis(ax,'off');
axis(ax,'image');
ax.Color = [0 0 0];

blackPic = uint8(zeros(800,800));
distPic = imnoise(blackPic,'gaussian',0,0.1);
distPic(distPic<254) = 0;
se = strel('square',3);
distPic = imdilate(distPic,se);

windPic = windEffect(distPic,180,0.99);
polarPic = polarTransf(windPic(:,end:-1:1)');
polarPic = imgaussfilt(polarPic,1.5);
polarPic = uint8(double(polarPic)./max(double(polarPic(:))+eps).*255);

matSize = [1600,1600];
point = [800,800];
colorList = get_palette(paletteName);
colorMat = radial_color_mat(matSize,point,colorList);

fwPic = zeros(size(colorMat),'uint8');
for ch = 1:3
    fwPic(:,:,ch) = uint8(double(colorMat(:,:,ch)).*double(polarPic)./255);
end

image(ax,fwPic);
axis(ax,'image');
axis(ax,'off');
safe_title(ax,['Fireworks -- ' strrep(paletteName,'_',' ')]);
end

function resultPic = windEffect(oriPic,len,ratio)
oriPic = double(oriPic);
for i = 1:len
    tempPic = [zeros(size(oriPic,1),1),oriPic(:,1:end-1)].*ratio;
    oriPic(oriPic<tempPic) = tempPic(oriPic<tempPic);
end
resultPic = uint8(oriPic);
end

function resultPic = polarTransf(oriPic)
oriPic = double(oriPic);
[m,n] = size(oriPic);
[t,r] = meshgrid(linspace(-pi,pi,n),1:m);
M = 2*m;
N = 2*n;
[NN,MM] = meshgrid((1:N)-n-0.5,(1:M)-m-0.5);
T = atan2(NN,MM);
R = sqrt(MM.^2+NN.^2);
resultPic = interp2(t,r,oriPic,T,R,'linear',0);
resultPic = uint8(resultPic);
end

function colorList = get_palette(name)
switch lower(name)
    case 'warm'
        colorList = [239 250 210;229 164 122;232 150 138;255 164 204;192 58 111;158 10 26;224 168 121];
    case 'gold'
        colorList = [94 41 15;177 89 22;228 155 53;255 207 116;255 242 199;255 252 239];
    otherwise
        colorList = [25 59 157;24 71 219;38 124 237;93 215 255;168 244 255;243 254 250;246 252 240];
end
end

function colorMat = radial_color_mat(matSize,point,colorList)
[xMesh,yMesh] = meshgrid(1:matSize(2),1:matSize(1));
zMesh = sqrt((xMesh-point(2)).^2+(yMesh-point(1)).^2);
zMesh = (zMesh-min(zMesh(:)))./(max(zMesh(:))-min(zMesh(:))+eps);
colorFunc = colorFuncFactory(colorList);
colorMesh = colorFunc(zMesh);
colorMat(:,:,1) = colorMesh(end:-1:1,1:matSize(1));
colorMat(:,:,2) = colorMesh(end:-1:1,matSize(1)+1:2*matSize(1));
colorMat(:,:,3) = colorMesh(end:-1:1,2*matSize(1)+1:3*matSize(1));
colorMat = uint8(colorMat);
end

function colorFunc = colorFuncFactory(colorList)
x = (0:size(colorList,1)-1)./(size(colorList,1)-1);
y1 = colorList(:,1); y2 = colorList(:,2); y3 = colorList(:,3);
colorFunc = @(X)[interp1(x,y1,X,'linear')',interp1(x,y2,X,'linear')',interp1(x,y3,X,'linear')'];
end
