function fractals_fractal_physics_pick(ax, pickName, variant)
%PLOT_FRACTAL_PHYSICS_PICK Twenty curated fractal and nonlinear-physics scenes.
if nargin < 1 || isempty(ax)
    figure('Color','w');
    ax = gca;
end
if nargin < 2 || isempty(pickName)
    pickName = 'Burning Ship Ember';
end
if nargin < 3 || isempty(variant)
    variant = 'default';
end
pickName = char(pickName);
variant = char(variant);

switch lower(strtrim(pickName))
    case 'burning ship ember'
        draw_burning_ship(ax,variant);
    case 'tricorn mandelbar'
        draw_tricorn(ax,variant);
    case 'newton basin'
        draw_newton_basin(ax,variant);
    case 'phoenix julia'
        draw_phoenix_julia(ax,variant);
    case 'lyapunov carpet'
        draw_lyapunov(ax,variant);
    case 'barnsley fern'
        draw_barnsley_fern(ax,variant);
    case 'sierpinski carpet'
        draw_sierpinski_carpet(ax,variant);
    case 'apollonian gasket'
        draw_apollonian(ax,variant);
    case 'dragon curve'
        draw_dragon_curve(ax,variant);
    case 'plasma clouds'
        draw_plasma_clouds(ax,variant);
    case 'lorenz attractor'
        draw_lorenz(ax,variant);
    case 'rossler ribbon'
        draw_rossler(ax,variant);
    case 'chua double scroll'
        draw_chua(ax,variant);
    case 'duffing poincare'
        draw_duffing(ax,variant);
    case 'van der pol phase'
        draw_vanderpol(ax,variant);
    case 'double pendulum trace'
        draw_double_pendulum(ax,variant);
    case 'chladni resonance'
        draw_chladni(ax,variant);
    case 'standard map islands'
        draw_standard_map(ax,variant);
    case 'henon map'
        draw_henon(ax,variant);
    otherwise
        draw_lissajous_knot(ax,variant);
end
end

% ========================================================================
% Fractal images
% ========================================================================
function draw_burning_ship(ax, variant)
clear_ax(ax);
N = 650; maxIter = 190;
switch lower(variant)
    case 'electric'
        xlimv = [-1.92 -1.68]; ylimv = [-0.09 0.06]; maxIter = 260;
    case 'dark'
        xlimv = [-2.15 -1.55]; ylimv = [-0.35 0.15]; maxIter = 230;
    otherwise
        xlimv = [-2.35 -1.35]; ylimv = [-0.62 0.28];
end
[x,y] = meshgrid(linspace(xlimv(1),xlimv(2),N),linspace(ylimv(1),ylimv(2),N));
C = x + 1i*y; Z = zeros(size(C)); escape = zeros(size(C)); mask = true(size(C));
for k = 1:maxIter
    Z(mask) = (abs(real(Z(mask))) + 1i*abs(imag(Z(mask)))).^2 + C(mask);
    escaped = mask & abs(Z)>2;
    escape(escaped) = k - log2(log(abs(Z(escaped))+eps));
    mask(escaped) = false;
end
escape(mask) = maxIter;
imagesc(ax,escape); axis(ax,'image'); axis(ax,'off'); colormap(ax,ember_map(256));
safe_title(ax,'Burning Ship Ember');
end

function draw_tricorn(ax, variant)
clear_ax(ax);
N = 640; maxIter = 180;
switch lower(variant)
    case 'electric'
        xlimv = [-1.2 1.2]; ylimv = [-1.2 1.2]; maxIter = 230;
    case 'dark'
        xlimv = [-2.0 2.0]; ylimv = [-1.6 1.6];
    otherwise
        xlimv = [-2.0 2.0]; ylimv = [-1.7 1.7];
end
[x,y] = meshgrid(linspace(xlimv(1),xlimv(2),N),linspace(ylimv(1),ylimv(2),N));
C = x + 1i*y; Z = zeros(size(C)); escape = zeros(size(C)); mask = true(size(C));
for k = 1:maxIter
    Z(mask) = conj(Z(mask)).^2 + C(mask);
    escaped = mask & abs(Z)>2;
    escape(escaped) = k - log2(log(abs(Z(escaped))+eps));
    mask(escaped) = false;
end
escape(mask) = maxIter;
imagesc(ax,escape); axis(ax,'image'); axis(ax,'off'); colormap(ax,twilight_map(256));
safe_title(ax,'Tricorn Mandelbar');
end

function draw_newton_basin(ax, variant)
clear_ax(ax);
N = 650; maxIter = 45;
[x,y] = meshgrid(linspace(-2,2,N),linspace(-2,2,N));
Z = x + 1i*y;
switch lower(variant)
    case 'electric'
        f = @(z) z.^4 - 1; df = @(z) 4*z.^3; rootsSet = exp(1i*(0:3)*pi/2);
    case 'dark'
        f = @(z) z.^5 - 1; df = @(z) 5*z.^4; rootsSet = exp(1i*2*pi*(0:4)/5);
    otherwise
        f = @(z) z.^3 - 1; df = @(z) 3*z.^2; rootsSet = exp(1i*2*pi*(0:2)/3);
end
convIter = zeros(size(Z));
for k = 1:maxIter
    dz = f(Z)./(df(Z)+eps);
    Z = Z - dz;
    convIter(convIter==0 & abs(dz)<1e-5) = k;
end
D = zeros([size(Z),numel(rootsSet)]);
for r = 1:numel(rootsSet)
    D(:,:,r) = abs(Z-rootsSet(r));
end
[~,idx] = min(D,[],3);
val = idx + 0.08*convIter;
imagesc(ax,val); axis(ax,'image'); axis(ax,'off'); colormap(ax,neon_map(256));
safe_title(ax,'Newton Basin');
end

function draw_phoenix_julia(ax, variant)
clear_ax(ax);
N = 620; maxIter = 170;
switch lower(variant)
    case 'electric'
        c = -0.48 + 0.57i; p = -0.52;
    case 'dark'
        c = 0.5667 - 0.5i; p = -0.55;
    otherwise
        c = -0.5 + 0.54i; p = -0.45;
end
[x,y] = meshgrid(linspace(-1.9,1.9,N),linspace(-1.6,1.6,N));
Z = x + 1i*y; Zold = zeros(size(Z)); escape = zeros(size(Z)); mask = true(size(Z));
for k = 1:maxIter
    Znew = Z(mask).^2 + c + p.*Zold(mask);
    Zold(mask) = Z(mask);
    Z(mask) = Znew;
    escaped = mask & abs(Z)>4;
    escape(escaped) = k - log2(log(abs(Z(escaped))+eps));
    mask(escaped) = false;
end
escape(mask) = maxIter;
imagesc(ax,escape); axis(ax,'image'); axis(ax,'off'); colormap(ax,rose_fire_map(256));
safe_title(ax,'Phoenix Julia');
end

function draw_lyapunov(ax, variant)
clear_ax(ax);
N = 420; nTransient = 80; nIter = 160;
switch lower(variant)
    case 'electric'
        seq = 'AABAB'; rangeA = [2.7 4.0]; rangeB = [2.7 4.0];
    case 'dark'
        seq = 'ABBBAB'; rangeA = [2.4 4.0]; rangeB = [2.4 4.0];
    otherwise
        seq = 'AB'; rangeA = [2.5 4.0]; rangeB = [2.5 4.0];
end
[A,B] = meshgrid(linspace(rangeA(1),rangeA(2),N),linspace(rangeB(1),rangeB(2),N));
x = 0.5*ones(size(A));
L = zeros(size(A)); seqIdx = double(seq);
for k = 1:nTransient+nIter
    useA = seqIdx(mod(k-1,numel(seqIdx))+1)==double('A');
    R = B; R(useA) = A(useA);
    x = R.*x.*(1-x);
    if k > nTransient
        L = L + log(abs(R.*(1-2*x))+eps);
    end
end
L = L./nIter;
imagesc(ax,L); axis(ax,'image'); axis(ax,'off'); colormap(ax,balance_map(256)); caxis(ax,[-1 1]);
safe_title(ax,'Lyapunov Carpet');
end

function draw_barnsley_fern(ax, variant)
clear_ax(ax);
N = 120000;
switch lower(variant)
    case 'electric'
        jitter = 0.015; cmap = [0.1 0.8 0.5];
    case 'dark'
        jitter = 0.006; cmap = [0.6 0.95 0.55];
    otherwise
        jitter = 0.01; cmap = [0.2 0.75 0.25];
end
x = zeros(N,1); y = zeros(N,1);
for k = 2:N
    r = rand;
    if r < 0.01
        x(k) = 0;
        y(k) = 0.16*y(k-1);
    elseif r < 0.86
        x(k) = 0.85*x(k-1) + 0.04*y(k-1);
        y(k) = -0.04*x(k-1) + 0.85*y(k-1) + 1.6;
    elseif r < 0.93
        x(k) = 0.20*x(k-1) - 0.26*y(k-1);
        y(k) = 0.23*x(k-1) + 0.22*y(k-1) + 1.6;
    else
        x(k) = -0.15*x(k-1) + 0.28*y(k-1);
        y(k) = 0.26*x(k-1) + 0.24*y(k-1) + 0.44;
    end
end
x = x + jitter*randn(size(x)); y = y + jitter*randn(size(y));
scatter(ax,x,y,1,linspace(0,1,N),'filled','MarkerFaceAlpha',0.18);
axis(ax,'equal'); axis(ax,'off'); ax.Color = [0.02 0.03 0.025]; colormap(ax,color_interp([0 0.15 0.05; cmap; 0.95 1 0.75],256));
safe_title(ax,'Barnsley Fern');
end

function draw_sierpinski_carpet(ax, variant)
clear_ax(ax);
level = 6;
if strcmpi(variant,'electric'), level = 5; end
N = 3^level; M = ones(N,N);
for s = 1:level
    block = 3^s; third = block/3;
    [I,J] = ndgrid(1:N,1:N);
    M(mod(floor((I-1)/third),3)==1 & mod(floor((J-1)/third),3)==1) = 0;
end
if strcmpi(variant,'dark')
    imagesc(ax,M); colormap(ax,color_interp([0.02 0.02 0.03; 0.7 0.78 0.95],256));
else
    imagesc(ax,M + 0.2*rand(size(M)).*M); colormap(ax,color_interp([0.05 0.02 0.05; 0.85 0.3 0.75; 1 0.92 0.58],256));
end
axis(ax,'image'); axis(ax,'off'); safe_title(ax,'Sierpinski Carpet');
end

function draw_apollonian(ax, variant)
clear_ax(ax);
axis(ax,'equal'); axis(ax,[-1.08 1.08 -1.08 1.08]); axis(ax,'off'); hold(ax,'on');
ax.Color = [0.015 0.015 0.02];
if strcmpi(variant,'electric')
    colors = color_interp([0.05 0.15 0.35;0.1 0.8 1;1 0.9 0.35],120);
elseif strcmpi(variant,'dark')
    colors = color_interp([0.12 0.08 0.20;0.45 0.35 0.85;0.95 0.9 1],120);
else
    colors = color_interp([0.05 0.08 0.16;0.2 0.65 0.85;1 0.85 0.42],120);
end
% A symmetric gasket generated by repeatedly filling the triangular gaps.
baseR = 1.0; th = linspace(0,2*pi,500);
plot(ax,baseR*cos(th),baseR*sin(th),'Color',colors(end,:),'LineWidth',1.1);
centers = [0 0 0.5; 2*pi/3 0 0.5; 4*pi/3 0 0.5]; %#ok<NASGU>
queue = [0 0 1 0]; % x, y, radius, depth
for depth = 1:6
    newq = [];
    if depth == 1
        R = 0.46; angles = (0:2)*2*pi/3 + pi/2; cx = R*cos(angles); cy = R*sin(angles); rr = 0.42*ones(1,3);
    else
        q = queue;
        cx = []; cy = []; rr = [];
        for ii = 1:size(q,1)
            r0 = q(ii,3); d0 = q(ii,4); %#ok<NASGU>
            if r0 < 0.028, continue; end
            for a = (0:2)*2*pi/3 + depth*0.17
                cx(end+1) = q(ii,1) + r0*0.55*cos(a); %#ok<AGROW>
                cy(end+1) = q(ii,2) + r0*0.55*sin(a); %#ok<AGROW>
                rr(end+1) = r0*0.39; %#ok<AGROW>
            end
        end
    end
    for i = 1:numel(rr)
        if hypot(cx(i),cy(i))+rr(i) < 1.02
            cidx = min(size(colors,1),8+depth*15);
            fill(ax,cx(i)+rr(i)*cos(th),cy(i)+rr(i)*sin(th),colors(cidx,:),'EdgeColor',colors(end-depth*8,:),'FaceAlpha',0.18,'LineWidth',0.6);
            newq(end+1,:) = [cx(i),cy(i),rr(i),depth]; %#ok<AGROW>
        end
    end
    queue = newq;
end
safe_title(ax,'Apollonian Gasket');
end

function draw_dragon_curve(ax, variant)
clear_ax(ax);
N = 16; z = [0; 1];
for k = 1:N
    z = [z; z(end) + 1i*(z(end-1:-1:1)-z(end))];
end
x = real(z); y = imag(z);
x = (x-min(x))/(max(x)-min(x)); y = (y-min(y))/(max(y)-min(y));
if strcmpi(variant,'dark')
    cmap = color_interp([0.25 0.4 1;0.95 0.95 1],numel(x));
elseif strcmpi(variant,'electric')
    cmap = color_interp([0 0.95 1;1 0.2 0.85;1 0.95 0.1],numel(x));
else
    cmap = color_interp([0.15 0.35 0.85;0.9 0.3 0.55;1 0.8 0.25],numel(x));
end
hold(ax,'on'); ax.Color = [0.02 0.025 0.035];
for k = 1:numel(x)-1
    plot(ax,x(k:k+1),y(k:k+1),'Color',cmap(k,:),'LineWidth',0.65);
end
axis(ax,'equal'); axis(ax,'off'); safe_title(ax,'Dragon Curve');
end

function draw_plasma_clouds(ax, variant)
clear_ax(ax);
N = 513; rng(7);
M = zeros(N,N); M([1 end],[1 end]) = rand(2,2);
step = N-1; scale = 1;
while step > 1
    half = step/2;
    for i = 1:step:N-1
        for j = 1:step:N-1
            avg = mean([M(i,j),M(i+step,j),M(i,j+step),M(i+step,j+step)]);
            M(i+half,j+half) = avg + scale*(rand-0.5);
        end
    end
    for i = 1:half:N
        for j = 1+mod((i-1)/half,2)*half:step:N
            vals = [];
            if i-half>=1, vals(end+1)=M(i-half,j); end %#ok<AGROW>
            if i+half<=N, vals(end+1)=M(i+half,j); end %#ok<AGROW>
            if j-half>=1, vals(end+1)=M(i,j-half); end %#ok<AGROW>
            if j+half<=N, vals(end+1)=M(i,j+half); end %#ok<AGROW>
            M(i,j) = mean(vals) + scale*(rand-0.5);
        end
    end
    step = half; scale = scale*0.54;
end
M = (M-min(M(:)))./(max(M(:))-min(M(:))+eps);
if strcmpi(variant,'electric')
    cm = color_interp([0.02 0.0 0.10;0.1 0.6 1;0.9 0.15 1;1 0.95 0.65],256);
elseif strcmpi(variant,'dark')
    cm = color_interp([0.0 0.0 0.03;0.08 0.12 0.22;0.3 0.45 0.65;0.85 0.9 1],256);
else
    cm = color_interp([0.02 0.03 0.14;0.2 0.25 0.55;0.7 0.35 0.85;1 0.75 0.42],256);
end
imagesc(ax,M); axis(ax,'image'); axis(ax,'off'); colormap(ax,cm); safe_title(ax,'Plasma Clouds');
end

% ========================================================================
% Nonlinear dynamics and physics structures
% ========================================================================
function draw_lorenz(ax, variant)
clear_ax(ax);
if strcmpi(variant,'electric'), rho = 32; else, rho = 28; end
f = @(~,s)[10*(s(2)-s(1)); s(1)*(rho-s(3))-s(2); s(1)*s(2)-8/3*s(3)];
[~,S] = ode45(f,linspace(0,50,6000),[0.1 0 0]); S = S(800:end,:);
plot_colored3(ax,S(:,1),S(:,2),S(:,3),plasma_line_map(size(S,1),variant),0.8);
axis(ax,'equal'); axis(ax,'off'); view(ax,[-36 18]); camlight(ax,'headlight'); safe_title(ax,'Lorenz Attractor');
end

function draw_rossler(ax, variant)
clear_ax(ax);
if strcmpi(variant,'dark'), c = 5.7; else, c = 5.9; end
f = @(~,s)[-s(2)-s(3); s(1)+0.2*s(2); 0.2+s(3)*(s(1)-c)];
[~,S] = ode45(f,linspace(0,380,10000),[0.1 0.1 0.1]); S = S(1200:8:end,:);
plot_colored3(ax,S(:,1),S(:,2),S(:,3),plasma_line_map(size(S,1),variant),1.0);
axis(ax,'equal'); axis(ax,'off'); view(ax,[42 20]); safe_title(ax,'Rossler Ribbon');
end

function draw_chua(ax, variant)
clear_ax(ax);
alpha = 15.6; beta = 28; m0 = -1.143; m1 = -0.714;
if strcmpi(variant,'electric'), alpha = 16.5; end
h = @(x) m1*x + 0.5*(m0-m1)*(abs(x+1)-abs(x-1));
f = @(~,s)[alpha*(s(2)-s(1)-h(s(1))); s(1)-s(2)+s(3); -beta*s(2)];
[~,S] = ode45(f,linspace(0,160,9000),[0.2 0.1 0.1]); S = S(1200:end,:);
plot_colored3(ax,S(:,1),S(:,2),S(:,3),plasma_line_map(size(S,1),variant),0.7);
axis(ax,'equal'); axis(ax,'off'); view(ax,[-42 18]); safe_title(ax,'Chua Double Scroll');
end

function draw_duffing(ax, variant)
clear_ax(ax);
if strcmpi(variant,'electric')
    delta = 0.18; gamma = 0.37; omega = 1.0;
elseif strcmpi(variant,'dark')
    delta = 0.25; gamma = 0.32; omega = 1.1;
else
    delta = 0.2; gamma = 0.3; omega = 1.0;
end
T = 2*pi/omega; dt = T/80; nSteps = 90000; s = [0.1;0.0]; pts = zeros(1200,2); n = 0; t = 0;
for k = 1:nSteps
    s = rk4_step(@(tt,xx)[xx(2); -delta*xx(2) + xx(1) - xx(1)^3 + gamma*cos(omega*tt)],t,s,dt);
    t = t + dt;
    if k > 10000 && mod(k,80)==0
        n = n + 1;
        if n <= size(pts,1), pts(n,:) = s.'; end
    end
    if n == size(pts,1), break; end
end
pts = pts(1:n,:);
scatter(ax,pts(:,1),pts(:,2),9,linspace(0,1,n),'filled','MarkerFaceAlpha',0.65);
axis(ax,'equal'); grid(ax,'on'); colormap(ax,plasma_line_map(256,variant)); style_axes_latex(ax); safe_title(ax,'Duffing Poincare');
end

function draw_vanderpol(ax, variant)
clear_ax(ax);
if strcmpi(variant,'electric'), mu = 4.5; elseif strcmpi(variant,'dark'), mu = 2.5; else, mu = 3.2; end
hold(ax,'on'); cm = plasma_line_map(12,variant);
ics = linspace(-3,3,12);
for k = 1:numel(ics)
    f = @(~,s)[s(2); mu*(1-s(1)^2)*s(2)-s(1)];
    [~,S] = ode45(f,[0 35],[ics(k), -ics(end-k+1)]);
    plot(ax,S(:,1),S(:,2),'Color',cm(k,:),'LineWidth',1.0);
end
axis(ax,'equal'); grid(ax,'on'); style_axes_latex(ax); safe_title(ax,'Van der Pol Phase');
end

function draw_double_pendulum(ax, variant)
clear_ax(ax);
if strcmpi(variant,'electric'), y0 = [pi/2 0 pi/2+0.03 0]; else, y0 = [pi/2 0 pi/2+0.01 0]; end
f = @(~,y) double_pendulum_rhs(y);
[~,Y] = ode45(f,linspace(0,45,4500),y0);
th1 = Y(:,1); th2 = Y(:,3); L1 = 1; L2 = 1;
x1 = L1*sin(th1); y1 = -L1*cos(th1); x2 = x1 + L2*sin(th2); y2 = y1 - L2*cos(th2);
plot_colored(ax,x2,y2,plasma_line_map(numel(x2),variant),0.8);
hold(ax,'on'); plot(ax,x1(end)+[0 L2*sin(th2(end))],y1(end)+[0 -L2*cos(th2(end))],'Color',[0.9 0.9 0.9],'LineWidth',1.6);
plot(ax,[0 x1(end)],[0 y1(end)],'Color',[0.9 0.9 0.9],'LineWidth',1.6);
axis(ax,'equal'); axis(ax,'off'); ax.Color = [0.02 0.02 0.03]; safe_title(ax,'Double Pendulum Trace');
end

function draw_chladni(ax, variant)
clear_ax(ax);
N = 600; [x,y] = meshgrid(linspace(-1,1,N));
if strcmpi(variant,'electric'), m = 7; n = 10; elseif strcmpi(variant,'dark'), m = 5; n = 9; else, m = 6; n = 8; end
Z = cos(m*pi*x).*cos(n*pi*y) - cos(n*pi*x).*cos(m*pi*y);
A = exp(-abs(Z)*22);
imagesc(ax,A); axis(ax,'image'); axis(ax,'off'); colormap(ax,color_interp([0 0 0;0.15 0.12 0.28;0.2 0.8 1;1 1 1],256));
safe_title(ax,'Chladni Resonance');
end

function draw_standard_map(ax, variant)
clear_ax(ax);
if strcmpi(variant,'electric'), K = 1.7; elseif strcmpi(variant,'dark'), K = 0.85; else, K = 1.15; end
hold(ax,'on'); nSeed = 90; nIter = 850; cm = plasma_line_map(nSeed,variant);
for s = 1:nSeed
    x = 2*pi*rand; p = 2*pi*rand; X = zeros(nIter,1); P = X;
    for k = 1:nIter
        p = mod(p + K*sin(x),2*pi);
        x = mod(x + p,2*pi);
        X(k) = x; P(k) = p;
    end
    scatter(ax,X,P,2,cm(s,:),'filled','MarkerFaceAlpha',0.25);
end
axis(ax,[0 2*pi 0 2*pi]); axis(ax,'square'); ax.XTick=[]; ax.YTick=[]; box(ax,'on'); ax.Color = [0.01 0.012 0.02]; safe_title(ax,'Standard Map Islands');
end

function draw_henon(ax, variant)
clear_ax(ax);
if strcmpi(variant,'electric'), a = 1.32; b = 0.31; elseif strcmpi(variant,'dark'), a = 1.4; b = 0.29; else, a = 1.4; b = 0.3; end
N = 90000; x = zeros(N,1); y = zeros(N,1); x(1) = 0.1; y(1) = 0.1;
for k = 2:N
    x(k) = 1 - a*x(k-1)^2 + y(k-1);
    y(k) = b*x(k-1);
end
x = x(1000:end); y = y(1000:end);
scatter(ax,x,y,1,linspace(0,1,numel(x)),'filled','MarkerFaceAlpha',0.18);
axis(ax,'equal'); axis(ax,'off'); ax.Color = [0.01 0.01 0.018]; colormap(ax,plasma_line_map(256,variant)); safe_title(ax,'Henon Map');
end

function draw_lissajous_knot(ax, variant)
clear_ax(ax);
t = linspace(0,2*pi,6000);
if strcmpi(variant,'electric')
    a = 5; b = 7; c = 9; ph = [0 pi/3 pi/5];
elseif strcmpi(variant,'dark')
    a = 3; b = 4; c = 7; ph = [0 pi/2 pi/3];
else
    a = 4; b = 5; c = 6; ph = [0 pi/4 pi/2];
end
x = sin(a*t+ph(1)); y = sin(b*t+ph(2)); z = sin(c*t+ph(3));
plot_colored3(ax,x(:),y(:),z(:),plasma_line_map(numel(t),variant),1.0);
axis(ax,'equal'); axis(ax,'off'); view(ax,[-38 24]); camlight(ax,'headlight'); safe_title(ax,'Lissajous Knot');
end

% ========================================================================
% Helpers
% ========================================================================
function s2 = rk4_step(fun,t,s,dt)
k1 = fun(t,s);
k2 = fun(t+dt/2,s+dt*k1/2);
k3 = fun(t+dt/2,s+dt*k2/2);
k4 = fun(t+dt,s+dt*k3);
s2 = s + dt*(k1+2*k2+2*k3+k4)/6;
end

function dy = double_pendulum_rhs(y)
g = 9.81; m1 = 1; m2 = 1; L1 = 1; L2 = 1;
th1 = y(1); w1 = y(2); th2 = y(3); w2 = y(4);
d = th2-th1;
den1 = (m1+m2)*L1 - m2*L1*cos(d)^2;
den2 = (L2/L1)*den1;
a1 = (m2*L1*w1^2*sin(d)*cos(d) + m2*g*sin(th2)*cos(d) + m2*L2*w2^2*sin(d) - (m1+m2)*g*sin(th1))/den1;
a2 = (-m2*L2*w2^2*sin(d)*cos(d) + (m1+m2)*(g*sin(th1)*cos(d) - L1*w1^2*sin(d) - g*sin(th2)))/den2;
dy = [w1; a1; w2; a2];
end

function plot_colored(ax,x,y,cmap,lw)
hold(ax,'on');
for k = 1:numel(x)-1
    plot(ax,x(k:k+1),y(k:k+1),'Color',cmap(k,:),'LineWidth',lw);
end
end

function plot_colored3(ax,x,y,z,cmap,lw)
hold(ax,'on');
for k = 1:numel(x)-1
    plot3(ax,x(k:k+1),y(k:k+1),z(k:k+1),'Color',cmap(k,:),'LineWidth',lw);
end
ax.Color = [0.012 0.014 0.022];
end

function cm = plasma_line_map(n,variant)
if strcmpi(variant,'dark')
    stops = [0.30 0.32 0.85;0.70 0.45 1.00;0.95 0.95 1.00];
elseif strcmpi(variant,'electric')
    stops = [0.0 0.90 1.00;0.75 0.15 1.00;1.0 0.92 0.10];
else
    stops = [0.10 0.25 0.75;0.85 0.25 0.75;1.0 0.72 0.20];
end
cm = color_interp(stops,n);
end

function cm = ember_map(n)
cm = color_interp([0.0 0.0 0.02;0.14 0.03 0.02;0.55 0.10 0.02;1.0 0.55 0.08;1.0 0.95 0.55],n);
end

function cm = twilight_map(n)
cm = color_interp([0.02 0.02 0.08;0.08 0.18 0.36;0.17 0.55 0.75;0.85 0.65 0.90;1.0 0.92 0.65],n);
end

function cm = neon_map(n)
cm = color_interp([0.02 0.02 0.08;0.0 0.75 1.0;0.85 0.18 1.0;1.0 0.94 0.25],n);
end

function cm = rose_fire_map(n)
cm = color_interp([0.02 0.01 0.06;0.25 0.04 0.25;0.75 0.12 0.55;1.0 0.50 0.25;1.0 0.92 0.75],n);
end

function cm = balance_map(n)
cm = color_interp([0.0 0.0 0.07;0.1 0.35 0.75;0.95 0.95 0.95;0.8 0.18 0.15;0.25 0.0 0.0],n);
end
