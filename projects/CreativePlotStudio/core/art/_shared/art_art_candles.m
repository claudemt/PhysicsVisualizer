function art_art_candles(ax, theme)
%PLOT_ART_CANDLES Artistic candlestick chart closer to the original styles.
if nargin < 1 || isempty(ax)
    figure('Color','w');
    ax = gca;
end
if nargin < 2 || isempty(theme)
    theme = 'coolnight';
end

clear_ax(ax);
Data = art_simulated_stock_data(150);
x = 1:height(Data);
Y0 = [min(Data.Low), max(Data.High)];
hold(ax,'on');

switch lower(theme)
    case 'warmmountains'
        ax.Color = [249,222,203]./255;
        YLim = Y0 + [-3,1].*diff(Y0);
        minY = YLim(1)+diff(YLim)*2/5;
        maxY = YLim(1)+diff(YLim)*3/5;
        upColor = [133,168,142]./255;
        downColor = [9,28,48]./255;
        volUp = [140,141,127]./255;
        volDown = [76,79,60]./255;
        mountainColors = [107,144,136;97,103,103;57,82,86;14,23,22]./255;
        scatter(ax,x(1)+numel(x)/6,YLim(2)-diff(YLim)/8,500,'filled','CData',[254,247,241]./255);
        fill(ax,[0,numel(x)+1,numel(x)+1,0],[YLim(1),YLim(1),minY,minY],[134,168,152]./255,'EdgeColor','none');
        draw_candles(ax,Data,x,upColor,downColor);
        draw_volume(ax,Data,x,minY,maxY,volUp,volDown,false);
        draw_mountain_layers(ax,YLim,minY,mountainColors,numel(x));
        chartTitle = 'Artistic Candlesticks -- Warm Mountains';

    case 'monomoon'
        ax.Color = [0,0,0];
        YLim = Y0 + [-3,6].*diff(Y0);
        minY = YLim(1)+diff(YLim)*1.5/10;
        maxY = YLim(1)+diff(YLim)*2.5/10;
        upColor = [1,1,1];
        downColor = [9,28,48]./255;
        volUp = [10,10,10]./255;
        volDown = [76,79,60]./255;
        mountainColors = [255,255,255;10,10,10]./255;
        add_stars(ax,[0,numel(x)+1],YLim,maxY,50);
        scatter(ax,x(1)+numel(x)/6,YLim(2)-diff(YLim)/8,500,'filled','CData',[254,247,241]./255);
        fill(ax,[0,numel(x)+1,numel(x)+1,0],[YLim(1),YLim(1),minY,minY],[255,255,255]./255,'EdgeColor','none');
        draw_candles(ax,Data,x,upColor,downColor);
        draw_volume(ax,Data,x,minY,maxY,volUp,volDown,true);
        draw_mountain_layers(ax,YLim,minY,mountainColors,numel(x),true);
        chartTitle = 'Artistic Candlesticks -- Mono Moon';

    otherwise
        ax.Color = [0,0,0];
        YLim = Y0 + [-1.5,1].*diff(Y0);
        minY = YLim(1)+diff(YLim)/4.5;
        maxY = YLim(1)+diff(YLim)*1.5/3.5;
        upColor = [242,218,128]./255;
        downColor = [9,28,48]./255;
        volUp = [29,170,112]./255;
        volDown = [23,105,103]./255;
        draw_gradient_background(ax,[0,numel(x)+1],YLim,[1,1,2;16,20,49;33,42,101;37,64,119;24,99,104;24,99,104;12,148,86;1,1,2;1,1,2]./255,YLim(1),YLim(2),1.0);
        draw_gradient_background(ax,[0,numel(x)+1],[YLim(1),minY+(maxY-minY)/10],[26,110,106;26,110,106;35,72,118;33,40,95;16,22,56;1,1,1;1,1,1]./255,YLim(1),minY+(maxY-minY)/10,0.5);
        add_stars(ax,[0,numel(x)+1],YLim,maxY,20);
        draw_candles(ax,Data,x,upColor,downColor);
        draw_volume(ax,Data,x,minY,maxY,volUp,volDown,false,true);
        xq = linspace(1,numel(x),15);
        chg = Data.Close-Data.Open;
        absY = abs(chg);
        absY1 = absY./(max(absY)-min(absY)+eps).*(maxY-minY)+minY;
        yq = interp1(x,absY1,xq,'spline');
        scatter(ax,xq,yq,15,'filled','CData',[128,169,90]./255);
        chartTitle = 'Artistic Candlesticks -- Cool Night';
end

xlim(ax,[0,numel(x)+1]);
ylim(ax,YLim);
ax.PlotBoxAspectRatio = [2,1,1];
ax.TickLength = [0 0];
ax.XTick = [];
ax.YTick = [];
box(ax,'on');
style_axes_latex(ax);
grid(ax,'off');
safe_title(ax,chartTitle);
end

function draw_candles(ax,Data,x,upColor,downColor)
for i = 1:numel(x)
    if Data.Close(i) >= Data.Open(i)
        c = upColor;
    else
        c = downColor;
    end
    plot(ax,[x(i),x(i)],[Data.Low(i),Data.High(i)],'Color',c,'LineWidth',1.0);
    y = min(Data.Open(i),Data.Close(i));
    h = abs(Data.Close(i)-Data.Open(i));
    if h < 0.05
        h = 0.05;
    end
    rectangle(ax,'Position',[x(i)-0.35,y,0.7,h],'FaceColor',c,'EdgeColor',c,'LineWidth',0.6);
end
end

function draw_volume(ax,Data,x,minY,maxY,upColor,downColor,useWide,mirrorBars)
if nargin < 8
    useWide = false;
end
if nargin < 9
    mirrorBars = false;
end
chg = Data.Close-Data.Open;
absY = abs(chg);
absY1 = absY./(max(absY)-min(absY)+eps).*(maxY-minY)+minY;
barWidth = 0.8;
if useWide
    barWidth = 1;
end
for i = 1:numel(x)
    c = upColor;
    if chg(i) < 0
        c = downColor;
    end
    bar(ax,x(i),absY1(i)-minY,barWidth,'BaseValue',minY,'EdgeColor','none','FaceColor',c);
    if mirrorBars
        bar(ax,x(i),-(absY1(i)-minY),barWidth,'BaseValue',minY,'EdgeColor','none','FaceColor',c,'FaceAlpha',0.6);
    end
end
end

function draw_gradient_background(ax,xRange,yRange,colorList,yMin,yMax,faceAlpha)
matSize = [300,300];
YList = ((0:(matSize(2)-1))./(matSize(2)-1))';
XList = ones(1,matSize(1));
colorMat(:,:,1) = interp1(linspace(0,1,size(colorList,1)),colorList(:,1),YList)*XList;
colorMat(:,:,2) = interp1(linspace(0,1,size(colorList,1)),colorList(:,2),YList)*XList;
colorMat(:,:,3) = interp1(linspace(0,1,size(colorList,1)),colorList(:,3),YList)*XList;
[XMesh,YMesh] = meshgrid(linspace(xRange(1),xRange(2),300),linspace(yMax,yMin,300));
surf(ax,XMesh,YMesh,zeros(size(XMesh)),colorMat,'EdgeColor','none','FaceAlpha',faceAlpha);
end

function add_stars(ax,xRange,YLim,maxY,nStar)
Xs = diff(xRange).*rand([nStar,1])+xRange(1);
Ys = (YLim(2)-maxY).*rand([nStar,1])+maxY;
scatter(ax,Xs,Ys,3,'filled','CData',[.9,.9,.9]);
Xs = diff(xRange).*rand([nStar,1])+xRange(1);
Ys = (YLim(2)-maxY).*rand([nStar,1])+maxY;
scatter(ax,Xs,Ys,5,'filled','CData',[.7,.7,.7]);
end

function draw_mountain_layers(ax,YLim,minY,layerColor,nPts,outline)
if nargin < 6
    outline = false;
end
layerBEPos = linspace(minY,YLim(1),size(layerColor,1)+2)';
layerBEPos([1,end]) = [];
excursion = diff(YLim)/30;
if outline
    excursion = diff(YLim)/40;
end
interval = diff(YLim)/50;
pieceNum = 30;
layerPos = zeros(size(layerBEPos,1),pieceNum);
layerPos(:,1) = layerBEPos(:,1);
layerPos = [ones(1,pieceNum).*minY;layerPos];
minX = 0;
maxX = nPts+1;
for i = 2:size(layerBEPos,1)+1
    k = 2;
    for j = 1:pieceNum-1
        tempRandi = excursion*2*rand(1)-excursion;
        yPos = tempRandi+layerPos(i,k-1);
        if i>1 && yPos>=layerPos(i-1,k)-diff(YLim)/100
            yPos = layerPos(i-1,k)-interval;
        end
        yPos(yPos<YLim(1)) = YLim(1);
        layerPos(i,k) = yPos;
        k = k+1;
    end
end
for i = 2:size(layerBEPos,1)+1
    XData = linspace(minX,maxX,pieceNum);
    YData = layerPos(i,:);
    Yq = interp1(XData,YData,linspace(minX,maxX,200),'spline');
    Xq = [minX,linspace(minX,maxX,200),maxX];
    Yq = [YLim(1),Yq,YLim(1)];
    edgeColor = 'none';
    if outline
        edgeColor = [.4,.4,.4];
    end
    fill(ax,Xq,Yq,layerColor(i-1,:),'EdgeColor',edgeColor,'LineWidth',0.8);
end
end
