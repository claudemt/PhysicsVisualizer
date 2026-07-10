function [X,Y,Z] = art_softserve_shape()
%SOFTSERVESHAPE Generate a soft-serve ice-cream swirl surface.
theta = linspace(0,2*pi,160);
z = linspace(0,2.1,140);
[TH,Z] = meshgrid(theta,z);
base = 0.62*(1-Z/2.35).^0.78;
base(base<0.05) = 0.05;
ridge = 0.12*sin(5.5*TH + 8.5*Z).*(1-Z/2.45);
ridge(ridge< -0.08) = -0.08;
R = base + ridge;
X = R.*cos(TH);
Y = R.*sin(TH);
Z = Z;
end
