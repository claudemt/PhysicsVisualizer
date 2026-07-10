function items = circ_boundary_options(domain_type)
%CIRC_BOUNDARY_OPTIONS Boundary presets for solid disks and annuli.

if nargin < 1 || isempty(domain_type)
    domain_type = 'circ';
end

domain_type = char(lower(string(domain_type)));

switch domain_type
    case {'circ', 'circle', 'disk'}
        items = {'C', 'F', 'S'};
    case {'annulus', 'ring'}
        items = {'CC', 'CF', 'CS', 'FC', 'FF', 'FS', 'SC', 'SF', 'SS'};
    otherwise
        error('Unknown circular domain type: %s', domain_type);
end
end
