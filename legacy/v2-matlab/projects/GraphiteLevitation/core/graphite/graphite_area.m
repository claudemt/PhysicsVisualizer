function A = graphite_area(graphite)
%GRAPHITE_AREA Area of circle or square graphite footprint.
shape = lower(char(string(graphite.shape)));
switch shape
    case 'circle'
        A = pi * graphite.radius.^2;
    case 'square'
        A = graphite.side.^2;
    otherwise
        error('Unsupported graphite shape: %s', shape);
end
end
