function nonlinear_online_pick(ax, pickName, variant)
%PLOT_ONLINE_PICK Six curated generative-art inspired MATLAB scenes.
if nargin < 1 || isempty(ax)
    figure('Color','w');
    ax = gca;
end
if nargin < 2 || isempty(pickName)
    pickName = 'Mandelbrot Garden';
end
if nargin < 3 || isempty(variant)
    variant = 'default';
end

switch lower(strtrim(pickName))
    case 'mandelbrot garden'
        draw_mandelbrot(ax, variant);
    case 'julia nebula'
        draw_julia(ax, variant);
    case 'phyllotaxis sunflower'
        draw_phyllotaxis(ax, variant);
    case 'gray-scott coral'
        draw_gray_scott(ax, variant);
    case 'clifford attractor'
        draw_clifford(ax, variant);
    otherwise
        draw_superformula(ax, variant);
end
end

function draw_mandelbrot(ax, variant)
clear_ax(ax);
N = 600;
maxIter = 170;
switch lower(variant)
    case 'deep zoom'
        xlimv = [-0.78 -0.70]; ylimv = [0.06 0.14]; maxIter = 230;
    case 'seahorse valley'
        xlimv = [-0.86 -0.70]; ylimv = [0.03 0.18]; maxIter = 220;
    otherwise
        xlimv = [-2.25 0.75]; ylimv = [-1.35 1.35];
end
[x,y] = meshgrid(linspace(xlimv(1),xlimv(2),N),linspace(ylimv(1),ylimv(2),N));
C = x + 1i*y;
Z = zeros(size(C));
escape = zeros(size(C));
mask = true(size(C));
for k = 1:maxIter
    Z(mask) = Z(mask).^2 + C(mask);
    escaped = mask & abs(Z)>2;
    escape(escaped) = k - log2(log(abs(Z(escaped))+eps));
    mask(escaped) = false;
end
escape(mask) = maxIter;
imagesc(ax,escape);
axis(ax,'image'); axis(ax,'off');
colormap(ax,twilight_map(256));
safe_title(ax,'Mandelbrot Garden');
end

function draw_julia(ax, variant)
clear_ax(ax);
N = 620;
maxIter = 190;
switch lower(variant)
    case 'dragon'
        c = -0.835 - 0.2321i;
    case 'spiral'
        c = -0.8 + 0.156i;
    otherwise
        c = -0.70176 - 0.3842i;
end
[x,y] = meshgrid(linspace(-1.55,1.55,N),linspace(-1.55,1.55,N));
Z = x + 1i*y;
escape = zeros(size(Z));
mask = true(size(Z));
for k = 1:maxIter
    Z(mask) = Z(mask).^2 + c;
    escaped = mask & abs(Z)>2;
    escape(escaped) = k - log2(log(abs(Z(escaped))+eps));
    mask(escaped) = false;
end
escape(mask) = maxIter;
imagesc(ax,escape);
axis(ax,'image'); axis(ax,'off');
colormap(ax,nebula_map(256));
safe_title(ax,'Julia Nebula');
end

function draw_phyllotaxis(ax, variant)
clear_ax(ax);
N = 1600;
phi = (1+sqrt(5))/2;
angle = 2*pi/phi^2;
switch lower(variant)
    case 'dense'
        N = 2400; c = 0.075;
    case 'loose'
        N = 1000; c = 0.095;
    otherwise
        c = 0.082;
end
n = (1:N)';
r = c*sqrt(n);
t = n*angle;
x = r.*cos(t); y = r.*sin(t);
sz = 6 + 42*(n./N).^1.7;
petal = 0.5 + 0.5*sin(n*0.08);
C = [0.35+0.60*n/N, 0.18+0.70*petal, 0.02+0.18*(1-n/N)];
scatter(ax,x,y,sz,C,'filled','MarkerFaceAlpha',0.92,'MarkerEdgeAlpha',0.10);
axis(ax,'equal'); axis(ax,'off');
ax.Color = [0.035 0.035 0.025];
safe_title(ax,'Phyllotaxis Sunflower');
end

function draw_gray_scott(ax, variant)
clear_ax(ax);
N = 220;
steps = 1500;
Du = 0.16; Dv = 0.08;
switch lower(variant)
    case 'mitosis'
        F = 0.0367; K = 0.0649;
    case 'worms'
        F = 0.078; K = 0.061;
    otherwise
        F = 0.035; K = 0.060;
end
U = ones(N,N);
V = zeros(N,N);
mid = floor(N/2);
V(mid-18:mid+18,mid-18:mid+18) = 1;
U(mid-18:mid+18,mid-18:mid+18) = 0.5;
rng(4);
U = U + 0.015*randn(N,N);
V = V + 0.015*randn(N,N);
for k = 1:steps
    Lu = lap(U); Lv = lap(V);
    uvv = U.*V.*V;
    U = U + Du*Lu - uvv + F*(1-U);
    V = V + Dv*Lv + uvv - (F+K)*V;
    if mod(k,200)==0
        U = min(max(U,0),1.2);
        V = min(max(V,0),1.2);
    end
end
P = V;
imagesc(ax,P);
axis(ax,'image'); axis(ax,'off');
colormap(ax,coral_map(256));
safe_title(ax,'Gray-Scott Coral');
end

function L = lap(A)
L = -A + 0.2*(circshift(A,[1 0])+circshift(A,[-1 0])+circshift(A,[0 1])+circshift(A,[0 -1])) ...
      + 0.05*(circshift(A,[1 1])+circshift(A,[1 -1])+circshift(A,[-1 1])+circshift(A,[-1 -1]));
end

function draw_clifford(ax, variant)
clear_ax(ax);
switch lower(variant)
    case 'violet'
        a = -1.7; b = 1.8; c = -1.9; d = -0.4;
    case 'ember'
        a = 1.7; b = 1.7; c = 0.6; d = 1.2;
    otherwise
        a = -1.4; b = 1.6; c = 1.0; d = 0.7;
end
N = 260000;
x = zeros(N,1); y = zeros(N,1);
for k = 2:N
    x(k) = sin(a*y(k-1)) + c*cos(a*x(k-1));
    y(k) = sin(b*x(k-1)) + d*cos(b*y(k-1));
end
x = x(2000:end); y = y(2000:end);
scatter(ax,x,y,1,linspace(0,1,numel(x))','filled','MarkerFaceAlpha',0.025,'MarkerEdgeAlpha',0.025);
axis(ax,'equal'); axis(ax,'off');
ax.Color = [0.01 0.01 0.018];
colormap(ax,nebula_map(256));
safe_title(ax,'Clifford Attractor');
end

function draw_superformula(ax, variant)
clear_ax(ax);
switch lower(variant)
    case 'starfish'
        m = 5; n1 = 0.22; n2 = 1.7; n3 = 1.7;
    case 'orchid'
        m = 7; n1 = 0.35; n2 = 0.65; n3 = 1.25;
    otherwise
        m = 6; n1 = 0.28; n2 = 1.15; n3 = 1.70;
end
theta = linspace(-pi,pi,540);
phi = linspace(-pi/2,pi/2,270);
[TH,PH] = meshgrid(theta,phi);
R1 = super_r(TH,m,n1,n2,n3);
R2 = super_r(PH,m,n1,n2,n3);
X = R1.*cos(TH).*R2.*cos(PH);
Y = R1.*sin(TH).*R2.*cos(PH);
Z = R2.*sin(PH);
C = 0.65*Z + 0.35*sin(4*TH).*cos(3*PH);
surf(ax,X,Y,Z,C,'EdgeColor','none','FaceColor','interp');
axis(ax,'equal'); axis(ax,'off');
view(ax,[-38 24]);
camlight(ax,'headlight'); lighting(ax,'gouraud');
colormap(ax,twilight_map(256));
safe_title(ax,'Superformula Bloom');
end

function r = super_r(t,m,n1,n2,n3)
a = 1; b = 1;
r = (abs(cos(m*t/4)./a).^n2 + abs(sin(m*t/4)./b).^n3).^(-1./n1);
r(~isfinite(r)) = 0;
end

function cm = twilight_map(n)
stops = [8 14 36; 31 35 91; 58 83 164; 76 159 178; 245 199 117; 218 84 77; 62 12 54]./255;
cm = color_interp(stops,n);
end

function cm = nebula_map(n)
stops = [3 4 20; 36 18 82; 94 35 145; 212 78 132; 255 172 112; 246 246 211]./255;
cm = color_interp(stops,n);
end

function cm = coral_map(n)
stops = [9 13 31; 19 76 88; 31 139 116; 222 178 110; 255 237 184; 255 136 115]./255;
cm = color_interp(stops,n);
end
