function art_music_score(ax, N)
if nargin < 1 || isempty(ax), figure; ax = gca; end
if nargin < 2, N = 1024; end
clear_ax(ax);
[i,j] = meshgrid(0:N-1);
P = mod(bitand(int16(fix(100.*sin(fix((i+400).*(j+100)./11115)))), int16(i)).*1021,256).*2;
image(ax,uint8(P)); colormap(ax,gray(256)); axis(ax,'image'); axis(ax,'off');
safe_title(ax,'Bitwise music score');
end
