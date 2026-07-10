function nonlinear_more_math_pick(ax, category, pickName, variant)
%PLOT_MORE_MATH_PICK Additional fractal / nonlinear physics gallery.
if nargin < 1 || isempty(ax), figure('Color','w'); ax = gca; end
if nargin < 2 || isempty(category), category = 'Advanced Fractals'; end
if nargin < 3 || isempty(pickName), pickName = 'Multibrot Cubic'; end
if nargin < 4 || isempty(variant), variant = 'default'; end
category = char(category); pickName = char(pickName); variant = char(variant);

switch lower(strtrim(pickName))
    case 'multibrot cubic', draw_multibrot(ax,variant);
    case 'celtic mandelbrot', draw_celtic(ax,variant);
    case 'perpendicular burning ship', draw_perp_ship(ax,variant);
    case 'nova cubic basin', draw_nova(ax,variant);
    case 'orbit trap pearls', draw_orbit_trap(ax,variant);
    case 'koch snowflake', draw_koch(ax,variant);
    case 'levy c curve', draw_levy(ax,variant);
    case 'pythagoras tree', draw_pythagoras(ax,variant);
    case 'vicsek fractal', draw_vicsek(ax,variant);
    case 'dla cluster', draw_dla(ax,variant);
    case 'aizawa attractor', draw_aizawa(ax,variant);
    case 'thomas attractor', draw_thomas(ax,variant);
    case 'dadras attractor', draw_dadras(ax,variant);
    case 'de jong attractor', draw_dejong(ax,variant);
    case 'hopalong attractor', draw_hopalong(ax,variant);
    case 'logistic bifurcation', draw_logistic(ax,variant);
    case 'circle map tongues', draw_circlemap(ax,variant);
    case 'ikeda map', draw_ikeda(ax,variant);
    case 'fitzhugh-nagumo spiral', draw_fhn(ax,variant);
    otherwise, draw_duffing(ax,variant);
end
end

function cm = local_map(stops,n)
if nargin < 2, n = 256; end
x = linspace(0,1,size(stops,1));
q = linspace(0,1,n);
cm = [interp1(x,stops(:,1),q)', interp1(x,stops(:,2),q)', interp1(x,stops(:,3),q)'];
cm = max(0,min(1,cm));
end

function set_title(ax,txt)
if exist('safe_title','file')
    safe_title(ax,txt);
else
    style = studio_style('tokens');
    title(ax, txt, 'Interpreter', 'none', 'FontName', style.axesFontName, 'FontWeight', 'bold');
end
end

function finish_image(ax,txt,cmap)
axis(ax,'image'); axis(ax,'off');
if nargin >= 3, colormap(ax,cmap); end
set_title(ax,txt);
end

% ------------------------ complex fractals ----------------------------
function draw_multibrot(ax,variant)
clear_ax(ax); N=620; maxIter=170;
if strcmpi(variant,'zoom'), xr=[-0.77 -0.61]; yr=[-0.10 0.10]; maxIter=260; else, xr=[-1.65 1.25]; yr=[-1.45 1.45]; end
[x,y]=meshgrid(linspace(xr(1),xr(2),N),linspace(yr(1),yr(2),N));
C=x+1i*y; Z=zeros(size(C)); E=zeros(size(C)); mask=true(size(C));
for k=1:maxIter
    Z(mask)=Z(mask).^3+C(mask);
    esc=mask & abs(Z)>2.4; E(esc)=k-log2(log(abs(Z(esc))+eps)); mask(esc)=false;
end
E(mask)=maxIter; imagesc(ax,E);
finish_image(ax,'Multibrot Cubic',local_map([.05 .02 .07;.48 .10 .55;.96 .48 .20;1 .95 .70],256));
end

function draw_celtic(ax,variant)
clear_ax(ax); N=620; maxIter=170;
if strcmpi(variant,'zoom'), xr=[-0.55 -0.25]; yr=[-0.15 0.15]; maxIter=230; else, xr=[-2.2 1.2]; yr=[-1.6 1.6]; end
[x,y]=meshgrid(linspace(xr(1),xr(2),N),linspace(yr(1),yr(2),N));
C=x+1i*y; Z=zeros(size(C)); E=zeros(size(C)); mask=true(size(C));
for k=1:maxIter
    Z2=Z(mask).^2; Z(mask)=abs(real(Z2))+1i*imag(Z2)+C(mask);
    esc=mask & abs(Z)>2; E(esc)=k-log2(log(abs(Z(esc))+eps)); mask(esc)=false;
end
E(mask)=maxIter; imagesc(ax,E);
finish_image(ax,'Celtic Mandelbrot',local_map([.02 .02 .04;.08 .22 .48;.18 .70 .76;.95 .95 .70],256));
end

function draw_perp_ship(ax,variant)
clear_ax(ax); N=620; maxIter=170;
if strcmpi(variant,'zoom'), xr=[-1.05 -0.75]; yr=[-0.20 0.20]; maxIter=240; else, xr=[-2.25 1.25]; yr=[-1.75 1.75]; end
[x,y]=meshgrid(linspace(xr(1),xr(2),N),linspace(yr(1),yr(2),N));
C=x+1i*y; Z=zeros(size(C)); E=zeros(size(C)); mask=true(size(C));
for k=1:maxIter
    Z(mask)=(abs(real(Z(mask)))+1i*imag(Z(mask))).^2+C(mask);
    esc=mask & abs(Z)>2; E(esc)=k-log2(log(abs(Z(esc))+eps)); mask(esc)=false;
end
E(mask)=maxIter; imagesc(ax,E);
finish_image(ax,'Perpendicular Burning Ship',local_map([.01 .01 .02;.22 .05 .10;.80 .22 .25;1 .76 .32],256));
end

function draw_nova(ax,variant)
clear_ax(ax); N=610; maxIter=48;
[x,y]=meshgrid(linspace(-2,2,N),linspace(-2,2,N)); Z=x+1i*y;
if strcmpi(variant,'zoom'), alpha=.6+.25i; else, alpha=1; end
rootsSet=exp(1i*2*pi*(0:2)/3); convIter=zeros(size(Z));
for k=1:maxIter
    dz=alpha*(Z.^3-1)./(3*Z.^2+eps); Z=Z-dz;
    convIter(convIter==0 & abs(dz)<1e-5)=k;
end
D=zeros([size(Z),numel(rootsSet)]);
for r=1:numel(rootsSet), D(:,:,r)=abs(Z-rootsSet(r)); end
[~,idx]=min(D,[],3); V=idx+0.08*convIter;
imagesc(ax,V); finish_image(ax,'Nova Cubic Basin',local_map([.04 .03 .10;.30 .10 .55;.92 .40 .25;.98 .90 .60],256));
end

function draw_orbit_trap(ax,variant)
clear_ax(ax); N=620; maxIter=110;
if strcmpi(variant,'zoom'), xr=[-1.2 -0.6]; yr=[-.35 .35]; else, xr=[-2.1 .8]; yr=[-1.4 1.4]; end
[x,y]=meshgrid(linspace(xr(1),xr(2),N),linspace(yr(1),yr(2),N));
C=x+1i*y; Z=zeros(size(C)); trap=inf(size(C));
for k=1:maxIter
    Z=Z.^2+C; trap=min(trap,abs(abs(Z)-.5)+.2*abs(real(Z)));
end
imagesc(ax,log(trap+1e-5));
finish_image(ax,'Orbit Trap Pearls',local_map([.02 .02 .05;.10 .30 .55;.78 .94 .95;1 .82 .62],256));
end

% ------------------------ recursive geometry --------------------------
function draw_koch(ax,variant)
clear_ax(ax); hold(ax,'on'); axis(ax,'equal'); axis(ax,'off');
pts=[0 0;1 0;.5 sqrt(3)/2;0 0]; level=5; if strcmpi(variant,'minimal'), level=4; end
for k=1:level, pts=koch_refine(pts); end
cm=local_map([.12 .20 .65;.25 .78 .96;.97 .95 .80],size(pts,1));
for k=1:size(pts,1)-1, plot(ax,pts(k:k+1,1),pts(k:k+1,2),'Color',cm(k,:),'LineWidth',1.4); end
set_title(ax,'Koch Snowflake');
end

function out=koch_refine(pts)
out=[];
for k=1:size(pts,1)-1
    p1=pts(k,:); p5=pts(k+1,:); v=(p5-p1)/3; p2=p1+v; p4=p1+2*v; R=[cos(pi/3) -sin(pi/3); sin(pi/3) cos(pi/3)]; p3=p2+(R*v')';
    out=[out;p1;p2;p3;p4]; %#ok<AGROW>
end
out=[out;pts(end,:)];
end

function draw_levy(ax,variant)
clear_ax(ax); hold(ax,'on'); axis(ax,'equal'); axis(ax,'off');
pts=[0 0;1 0]; level=15; if strcmpi(variant,'minimal'), level=13; end
for i=1:level
    np=zeros(size(pts,1)*2-1,2); np(1:2:end,:)=pts;
    for k=1:size(pts,1)-1
        mid=(pts(k,:)+pts(k+1,:))/2; v=pts(k+1,:)-pts(k,:); n=[-v(2),v(1)]/2; if mod(k+i,2)==0, n=-n; end
        np(2*k,:)=mid+n;
    end
    pts=np;
end
cm=local_map([.10 .08 .18;.58 .22 .72;.96 .78 .45],size(pts,1));
for k=1:size(pts,1)-1, plot(ax,pts(k:k+1,1),pts(k:k+1,2),'Color',cm(k,:),'LineWidth',1.0); end
set_title(ax,'Levy C Curve');
end

function draw_pythagoras(ax,variant)
clear_ax(ax); hold(ax,'on'); axis(ax,'equal'); axis(ax,'off'); ax.Color=[.985 .985 .985];
depth=10; if strcmpi(variant,'minimal'), depth=8; end
recurse([0 0],1,pi/2,depth); set_title(ax,'Pythagoras Tree');
    function recurse(p,s,theta,d)
        if d<=0 || s<.01, return; end
        R=[cos(theta) -sin(theta); sin(theta) cos(theta)]; base=[0 0;s 0;s s;0 s]; verts=(R*base')'+p;
        c=[.15+.06*d,.38+.03*d,.12+.02*d]; c(c>1)=1; patch(ax,verts(:,1),verts(:,2),c,'EdgeColor','none','FaceAlpha',.95);
        pL=verts(4,:); pR=verts(3,:); sL=s*cos(pi/4); sR=s*sin(pi/4);
        recurse(pL,sL,theta+pi/4,d-1); recurse(pR+(R*[0;sR])',sR,theta-pi/4,d-1);
    end
end

function draw_vicsek(ax,variant)
clear_ax(ax); level=5; if strcmpi(variant,'minimal'), level=4; end
M=1; seed=[0 1 0;1 1 1;0 1 0]; for k=1:level, M=kron(M,seed); end
imagesc(ax,M); finish_image(ax,'Vicsek Fractal',local_map([.02 .02 .02;.90 .92 .95],256));
end

function draw_dla(ax,variant)
clear_ax(ax); N=221; c=ceil(N/2); A=false(N,N); A(c,c)=true;
nP=650; if strcmpi(variant,'vibrant'), nP=1000; elseif strcmpi(variant,'minimal'), nP=500; end
Rkill=floor(N/2)-2; Rlaunch=10;
for p=1:nP
    a=2*pi*rand; x=c+round(Rlaunch*cos(a)); y=c+round(Rlaunch*sin(a));
    for it=1:6000
        d=randi(4); x=x+(d==1)-(d==2); y=y+(d==3)-(d==4);
        if x<2 || x>N-1 || y<2 || y>N-1 || hypot(x-c,y-c)>Rkill
            a=2*pi*rand; rr=min(Rlaunch+5,Rkill-2); x=c+round(rr*cos(a)); y=c+round(rr*sin(a));
        end
        if any(any(A(x-1:x+1,y-1:y+1)))
            A(x,y)=true; Rlaunch=min(max(Rlaunch,ceil(hypot(x-c,y-c))+6),Rkill-2); break;
        end
    end
end
[I,J]=ndgrid(1:N,1:N); D=sqrt((I-c).^2+(J-c).^2);
imagesc(ax,D.*A); finish_image(ax,'DLA Cluster',local_map([.02 .02 .06;.25 .12 .45;.25 .75 .92;.98 .90 .65],256));
end

% ------------------------ chaotic attractors --------------------------
function setup3(ax), axis(ax,'vis3d'); axis(ax,'off'); grid(ax,'off'); view(ax,[-32 20]); camlight(ax,'headlight'); camlight(ax,'right'); lighting(ax,'gouraud'); end

function draw_aizawa(ax,variant)
clear_ax(ax); tspan=linspace(0,210,24000);
[~,U]=ode45(@(t,u)[(u(3)-.7)*u(1)-3.5*u(2);3.5*u(1)+(u(3)-.7)*u(2);.6+.95*u(3)-u(3)^3/3-(u(1)^2+u(2)^2)*(1+.25*u(3))+.1*u(3)*u(1)^3],tspan,[.1;0;0]);
U=U(3500:end,:); setup3(ax); view(ax,[32 18]); plot3(ax,U(:,1),U(:,2),U(:,3),'Color',[.20 .72 .95],'LineWidth',.7); ax.Color=[.02 .03 .06]; set_title(ax,'Aizawa Attractor');
end

function draw_thomas(ax,variant)
clear_ax(ax); b=.19; if strcmpi(variant,'neon'), b=.208186; end
tspan=linspace(0,500,36000); [~,U]=ode45(@(t,u)[sin(u(2))-b*u(1);sin(u(3))-b*u(2);sin(u(1))-b*u(3)],tspan,[.1;0;-.1]);
U=U(9000:end,:); setup3(ax); view(ax,[24 18]); plot3(ax,U(:,1),U(:,2),U(:,3),'Color',[.96 .52 .28],'LineWidth',.55); ax.Color=[.015 .015 .02]; set_title(ax,'Thomas Attractor');
end

function draw_dadras(ax,variant)
clear_ax(ax); m=9; if strcmpi(variant,'neon'), m=7; end; c=3; e=2.7; r=1.7; d=2;
tspan=linspace(0,110,20000); [~,U]=ode45(@(t,u)[u(2)-c*u(1)+d*u(2)*u(3); r*u(2)-u(1)*u(3)+u(3); m*u(1)*u(2)-e*u(3)],tspan,[1;1;1]);
U=U(2800:end,:); setup3(ax); view(ax,[-40 18]); plot3(ax,U(:,1),U(:,2),U(:,3),'Color',[.72 .42 .96],'LineWidth',.55); ax.Color=[.01 .01 .04]; set_title(ax,'Dadras Attractor');
end

function draw_dejong(ax,variant)
clear_ax(ax); hold(ax,'on'); axis(ax,'equal'); axis(ax,'off');
if strcmpi(variant,'neon'), a=1.7; b=1.7; c=.6; d=1.2; else, a=-2; b=-2.5; c=-1.2; d=2; end
N=150000; x=0; y=0; P=zeros(N,2);
for k=1:N, xn=sin(a*y)-cos(b*x); yn=sin(c*x)-cos(d*y); x=xn; y=yn; P(k,:)=[x,y]; end
scatter(ax,P(:,1),P(:,2),1,linspace(0,1,N),'filled','MarkerFaceAlpha',.12); colormap(ax,local_map([.02 .02 .06;.22 .42 .92;.92 .40 .88;1 .90 .60],256)); ax.Color=[.02 .02 .04]; set_title(ax,'De Jong Attractor');
end

function draw_hopalong(ax,variant)
clear_ax(ax); hold(ax,'on'); axis(ax,'equal'); axis(ax,'off');
if strcmpi(variant,'neon'), a=2; b=.5; c=1; else, a=.7; b=1.3; c=.1; end
N=140000; x=0; y=0; P=zeros(N,2);
for k=1:N, xn=y-sign(x)*sqrt(abs(b*x-c)); yn=a-x; x=xn; y=yn; P(k,:)=[x,y]; end
scatter(ax,P(:,1),P(:,2),1,linspace(0,1,N),'filled','MarkerFaceAlpha',.11); colormap(ax,local_map([.02 .02 .02;.70 .20 .35;.98 .70 .38;1 .95 .72],256)); ax.Color=[.015 .012 .012]; set_title(ax,'Hopalong Attractor');
end

% ------------------------ nonlinear structures -----------------------
function draw_logistic(ax,variant)
clear_ax(ax); hold(ax,'on'); r=linspace(2.6,4,2200); if strcmpi(variant,'detailed'), r=linspace(2.6,4,3200); end
x=.5*ones(size(r)); for k=1:400, x=r.*x.*(1-x); end
RR=[]; XX=[]; for k=1:110, x=r.*x.*(1-x); RR=[RR,r]; XX=[XX,x]; end %#ok<AGROW>
plot(ax,RR,XX,'.','MarkerSize',1,'Color',[.12 .12 .12]); ax.Color=[.985 .985 .975]; ax.XLabel.String='r'; ax.YLabel.String='x'; style_axes_latex(ax); grid(ax,'on'); box(ax,'on'); set_title(ax,'Logistic Bifurcation');
end

function draw_circlemap(ax,variant)
clear_ax(ax); Nw=260; Nk=200; if strcmpi(variant,'detailed'), Nw=320; Nk=260; end
O=linspace(0,1,Nw); Kvals=linspace(0,2.2,Nk); rot=zeros(Nk,Nw);
for i=1:Nk
    K=Kvals(i); th=zeros(1,Nw); s=zeros(1,Nw);
    for n=1:290
        thn=th+O-K/(2*pi)*sin(2*pi*th); if n>110, s=s+(thn-th); end; th=mod(thn,1);
    end
    rot(i,:)=s/180;
end
imagesc(ax,O,Kvals,rot); set(ax,'YDir','normal'); colormap(ax,local_map([.01 .01 .04;.15 .25 .75;.22 .75 .72;.98 .92 .70],256)); ax.XLabel.String='\Omega'; ax.YLabel.String='K'; style_axes_latex(ax); box(ax,'on'); set_title(ax,'Circle Map Tongues');
end

function draw_ikeda(ax,variant)
clear_ax(ax); hold(ax,'on'); axis(ax,'equal'); axis(ax,'off'); u=.918; if strcmpi(variant,'bright'), u=.92; end
N=150000; x=.1; y=.1; P=zeros(N,2);
for k=1:N, t=.4-6/(1+x^2+y^2); xn=1+u*(x*cos(t)-y*sin(t)); yn=u*(x*sin(t)+y*cos(t)); x=xn; y=yn; P(k,:)=[x,y]; end
scatter(ax,P(:,1),P(:,2),1,linspace(0,1,N),'filled','MarkerFaceAlpha',.10); colormap(ax,local_map([.02 .02 .05;.16 .52 .80;.96 .78 .35;1 .95 .75],256)); ax.Color=[.01 .01 .02]; set_title(ax,'Ikeda Map');
end

function draw_fhn(ax,variant)
clear_ax(ax); n=115; if strcmpi(variant,'detailed'), n=135; end
u=-ones(n); v=zeros(n); u(round(n/2-5):round(n/2+5),round(n/2-5):round(n/2+5))=1.2; u(1:12,:)=1.0;
a=.75; b=.06; tau=12.5; Du=1; Dv=.2; dt=.02; steps=250; if strcmpi(variant,'detailed'), steps=320; end
K=[0 1 0;1 -4 1;0 1 0];
for t=1:steps
    Lu=conv2(u,K,'same'); Lv=conv2(v,K,'same'); du=u-u.^3/3-v+Du*Lu; dv=(u+a-b*v)/tau+Dv*Lv; u=u+dt*du; v=v+dt*dv;
end
imagesc(ax,u); finish_image(ax,'FitzHugh-Nagumo Spiral',local_map([.04 .02 .12;.22 .15 .42;.82 .28 .70;.96 .86 .60],256));
end

function draw_duffing(ax,variant)
clear_ax(ax); hold(ax,'on'); delta=.2; alpha=-1; beta=1; omega=1.2; gvals=linspace(.18,.45,145); if strcmpi(variant,'detailed'), gvals=linspace(.18,.50,210); end
period=2*pi/omega; dt=.045; spp=round(period/dt); totalP=190; sampleP=52; Xall=[]; Gall=[];
for gamma=gvals
    x=.1; y=0; sample=[];
    for p=1:totalP
        for s=1:spp
            tt=((p-1)*spp+s)*dt; [x,y]=rk4_duff(x,y,tt,dt,delta,alpha,beta,gamma,omega);
        end
        if p>totalP-sampleP, sample(end+1)=x; end %#ok<AGROW>
    end
    Xall=[Xall,sample]; Gall=[Gall,gamma*ones(size(sample))]; %#ok<AGROW>
end
plot(ax,Gall,Xall,'.','MarkerSize',3,'Color',[.08 .08 .08]); ax.Color=[.985 .985 .975]; ax.XLabel.String='\gamma'; ax.YLabel.String='Stroboscopic x'; style_axes_latex(ax); grid(ax,'on'); box(ax,'on'); set_title(ax,'Duffing Sweep');
end

function [xn,yn]=rk4_duff(x,y,t,dt,delta,alpha,beta,gamma,omega)
f=@(xx,yy,tt)[yy; gamma*cos(omega*tt)-delta*yy-alpha*xx-beta*xx^3];
k1=f(x,y,t); k2=f(x+dt*k1(1)/2,y+dt*k1(2)/2,t+dt/2); k3=f(x+dt*k2(1)/2,y+dt*k2(2)/2,t+dt/2); k4=f(x+dt*k3(1),y+dt*k3(2),t+dt);
xn=x+dt*(k1(1)+2*k2(1)+2*k3(1)+k4(1))/6; yn=y+dt*(k1(2)+2*k2(2)+2*k3(2)+k4(2))/6;
end
