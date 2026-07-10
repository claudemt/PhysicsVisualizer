function art_pixel_fractal(ax, N)
if nargin < 1 || isempty(ax), figure; ax = gca; end
if nargin < 2, N = 1024; end
clear_ax(ax);
[X,Y] = meshgrid(uint16(0:N-1));
A = mod(X,Y+uint16(Y==0)); B = mod(Y,X+uint16(X==0));
P(:,:,1) = mod(bitand(A,B),255);
P(:,:,2) = mod(bitxor(A,B),255);
P(:,:,3) = mod(bitor(A,B),255);
image(ax,uint8(P)); axis(ax,'image'); axis(ax,'off');
safe_title(ax,'Bitwise pseudo-fractal');
end
