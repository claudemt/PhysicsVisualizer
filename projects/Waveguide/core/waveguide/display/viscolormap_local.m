function cmapOut = viscolormap_local(N)
%VISCOLORMAP_LOCAL Visible-spectrum colormap (380-780 nm), gamma-corrected.

if nargin < 1, N = 256; end
lambda = linspace(380, 780, N);
rgb = zeros(N, 3);

for ii = 1:N
    l = lambda(ii);

    if l >= 380 && l < 440
        r = -(l - 440) / (440 - 380); g = 0; b = 1;
    elseif l >= 440 && l < 490
        r = 0; g = (l - 440) / (490 - 440); b = 1;
    elseif l >= 490 && l < 510
        r = 0; g = 1; b = -(l - 510) / (510 - 490);
    elseif l >= 510 && l < 580
        r = (l - 510) / (580 - 510); g = 1; b = 0;
    elseif l >= 580 && l < 645
        r = 1; g = -(l - 645) / (645 - 580); b = 0;
    elseif l >= 645 && l <= 780
        r = 1; g = 0; b = 0;
    else
        r = 0; g = 0; b = 0;
    end

    if l >= 380 && l < 420
        f = 0.3 + 0.7*(l - 380)/(420 - 380);
    elseif l >= 420 && l <= 700
        f = 1.0;
    elseif l > 700 && l <= 780
        f = 0.3 + 0.7*(780 - l)/(780 - 700);
    else
        f = 0.0;
    end

    gamma = 0.8;
    rgb(ii, :) = (f .* [r g b]) .^ gamma;
end

cmapOut = max(min(rgb, 1), 0);
end
