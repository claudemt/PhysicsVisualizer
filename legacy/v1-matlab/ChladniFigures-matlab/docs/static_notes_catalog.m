function notes = static_notes_catalog(domain_type, boundary, load_type)
%STATIC_NOTES_CATALOG GUI tips for static Kirchhoff--Love source problems.

if nargin < 1 || isempty(domain_type), domain_type = 'rect'; end
if nargin < 2 || isempty(boundary), boundary = 'SSSS'; end
if nargin < 3 || isempty(load_type), load_type = 'points'; end

domain_type = char(lower(string(domain_type)));
boundary = upper(strtrim(char(string(boundary))));
load_type = char(lower(string(load_type)));

base_lines = { ...
    'Static tab: solves D*nabla^4 w = q and displays the displacement field w as a heat map.', ...
    'This page is independent from the Chladni/eigenmode page; eigenmodes remain in the first tab.', ...
    'Boundary letters are unchanged: C = clamped, S = simply supported, F = free.'};

switch domain_type
    case 'rect'
        domain_lines = { ...
            sprintf('Rect static boundary code uses ULDR order. Current code = %s.', boundary), ...
            'Rect static solver uses the same rectangular eigen/Ritz basis as the Chladni backend and sums modal flexibilities.'};
    case {'circ', 'circle'}
        domain_lines = { ...
            sprintf('Disk static boundary = %s on the outer circle.', boundary), ...
            'Disk static solver uses the polar biharmonic Green function. A pure free disk is not unique without a rigid-mode gauge/reactions.'};
    case {'annulus', 'ring'}
        domain_lines = { ...
            sprintf('Annulus static boundary code is outer-inner. Current code = %s.', boundary), ...
            'Annulus static solver uses the polar biharmonic Green function. FF is singular without extra static compatibility/gauge conditions.'};
    otherwise
        domain_lines = {'Domain note: configuration not recognized.'};
end

point_line = 'Actual q(x,y): source contribution from the source matrix only; sigma=0 is an ideal point load, sigma>0 is a normalized Gaussian patch with resultant P. Coordinates are plotted Cartesian coordinates. Rect: -a/2<=x<=a/2, -b/2<=y<=b/2; disk: hypot(x,y)<1; annulus: xi_0<hypot(x,y)<1.';
uniform_line = 'Actual q(x,y): q0 everywhere on the material domain. In dimensional runs q0 may be rho*h*g in consistent units.';
custom_line = 'Actual q(x,y): the value returned by the custom function @(X,Y) or @(X,Y,mask), sampled only on the actual plate material. Use elementwise operators .*, ./, .^.';
custom_extra = 'For circular/annular custom loads, q is sampled on polar shells, angular Fourier moments are computed once, and radial Green solves are reused.';
trunc_line = 'Truncation: smooth loads converge rapidly; point loads or very sharp Gaussians need larger values. Increase truncation until the heat map is stable.';


switch load_type
    case 'points'
        load_lines = [{'Current load type: point/Gaussian source matrix.'}, {point_line}, {trunc_line}];
    case 'uniform'
        load_lines = [{'Current load type: uniform self-weight / constant transverse load.'}, {uniform_line}, {trunc_line}];
    case 'custom'
        load_lines = [{'Current load type: general distributed function q(X,Y).'}, {custom_line}, {custom_extra}, {trunc_line}];
    otherwise
        load_lines = [{'Current load type: mixed load.'}, {'Actual q(x,y): q0 constant component + source-matrix contribution + custom q(X,Y).'}, {point_line}, {custom_line}, {custom_extra}, {trunc_line}];
end

notes = [base_lines, domain_lines, load_lines];
end
