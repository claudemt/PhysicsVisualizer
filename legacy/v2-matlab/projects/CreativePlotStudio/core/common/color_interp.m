function cm = color_interp(stops,n)
%COLOR_INTERP Interpolate RGB color stops.
if nargin < 2, n = 256; end
if max(stops(:)) > 1
    stops = stops./255;
end
x = linspace(0,1,size(stops,1));
q = linspace(0,1,n);
cm = [interp1(x,stops(:,1),q,'linear')', ...
      interp1(x,stops(:,2),q,'linear')', ...
      interp1(x,stops(:,3),q,'linear')'];
cm = max(0,min(1,cm));
end
