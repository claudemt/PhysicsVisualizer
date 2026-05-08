function [X,Y,Z,C] = rose_surface_data(kind)
%ROSE_SURFACE_DATA Parametric rose petal surface used by rose artworks.
% Kept as the original public helper name expected by the early CreativePlotStudio scripts.
if nargin < 1 || isempty(kind), kind = 'blue'; end
kind = lower(char(string(kind)));
[u,v] = meshgrid(linspace(0,2*pi,180), linspace(0,1,80));
if strcmp(kind,'bloom') || strcmp(kind,'blooming')
    petals = 6;
    wav = 0.20;
    twist = 0.70;
else
    petals = 5;
    wav = 0.14;
    twist = 0.45;
end
r = v .* (1 + 0.28*cos(petals*u)) .* (1 - 0.22*v);
petal_lift = 0.55*(1-v).^1.4 + wav*sin(petals*u + twist*v*pi).*v.*(1-v);
X = r .* cos(u + twist*v);
Y = r .* sin(u + twist*v);
Z = petal_lift + 0.12*v.*cos(petals*u);
C = v + 0.15*cos(petals*u).*(1-v);
end
