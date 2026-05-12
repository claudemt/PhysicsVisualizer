function e = graphite_extent(graphite)
%GRAPHITE_EXTENT Conservative xy half-extent of the sample footprint.
shape = lower(char(string(graphite.shape)));
switch shape
    case 'circle'
        e = graphite.radius;
    case 'square'
        e = graphite.side/sqrt(2);
    otherwise
        e = graphite.radius;
end
end
