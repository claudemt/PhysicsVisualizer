function art_tablecloth(ax, N)
if nargin < 1 || isempty(ax), figure; ax = gca; end
if nargin < 2, N = 1024; end
clear_ax(ax);
[i,j] = meshgrid(0:N-1); DIM = N;
s = 3./(j+99);
y = (j + sin((i.*i + (j-700).^2.*5)./100./DIM).*35).*s;
P(:,:,1) = (mod(round((i+DIM).*s+y),2)+mod(round((DIM.*2-i).*s+y),2)).*127;
P(:,:,2) = (mod(round(5.*((i+DIM).*s+y)),2)+mod(round(5.*((DIM.*2-i).*s+y)),2)).*127;
P(:,:,3) = (mod(round(29.*((i+DIM).*s+y)),2)+mod(round(29.*((DIM.*2-i).*s+y)),2)).*127;
image(ax,uint8(P)); axis(ax,'image'); axis(ax,'off');
safe_title(ax,'Perspective tablecloth');
end
