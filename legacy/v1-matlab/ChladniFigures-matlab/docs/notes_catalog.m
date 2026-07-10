function notes = notes_catalog(domain_type, boundary, a, b)
%NOTES_CATALOG Provide concise GUI notes for the current setup.

if nargin < 3 || isempty(a), a = 1.0; end
if nargin < 4 || isempty(b), b = 1.0; end

domain_type = char(lower(string(domain_type)));
boundary = char(string(boundary));

base_lines = { ...
    'nu: Poisson ratio of the plate material, with 0 < nu < 0.5.', ...
    'For rect, the horizontal side is fixed to 2 and the vertical side is 2*xi_0, so xi_0 = vertical side / top horizontal side = b/a.', ...
    'For annulus, xi_0 = R_0/R. A solid disk is the special case xi_0 = 0.', ...
    'Boundary letters: C = clamped, S = simply supported, F = free.', ...
    'Mode label: for circ/annulus, mode m,s means angular order m and radial order s; for rect, modeN is the solver ordering unless an analytic pair (m,s) is available.', ...
    'Lambda: spectral parameter of the displayed mode. Under the same material and thickness, larger Lambda means a higher natural frequency.'};

switch domain_type
    case 'rect'
        domain_lines = local_rect_boundary_note(boundary, a, b);
    case {'circ', 'circle'}
        domain_lines = {local_disk_boundary_note(boundary)};
    case {'annulus', 'ring'}
        domain_lines = {local_annulus_boundary_note(boundary)};
    otherwise
        domain_lines = {'Domain note: configuration not recognized.'};
end

notes = [base_lines, domain_lines];
end

function lines = local_rect_boundary_note(boundary, a, b)
meta = rect_boundary_meta(boundary);
xi0 = b / a;
isSquare = abs(a - b) <= 1e-12 * max(1, max(abs([a,b])));
if isSquare
    countLine = 'Square note: modulo the 8-element dihedral symmetry group, the 3^4 edge colorings reduce to 21 distinct boundary patterns.';
else
    countLine = 'Rectangle note: modulo {identity, 180-degree rotation, horizontal reflection, vertical reflection}, the 3^4 edge colorings reduce to 36 distinct boundary patterns.';
end

lines = { ...
    sprintf('Rect boundary code uses the ULDR order: up, left, down, right. Current code = %s.', meta.code), ...
    sprintf('Current aspect ratio parameter: xi_0 = vertical side / top horizontal side = b/a = %.6g.', xi0), ...
    sprintf('Edge meanings: up = %s, left = %s, down = %s, right = %s.', ...
        local_edge_name(meta.top), local_edge_name(meta.left), local_edge_name(meta.bottom), local_edge_name(meta.right)), ...
    'The GUI accepts any 4-letter rectangular code over {C,S,F}; no symmetry reduction is imposed at input time.', ...
    countLine, ...
    local_rect_solver_line(meta)};
end

function line = local_rect_solver_line(meta)
if meta.is_all_simply
    line = 'Rect solver: SSSS uses the exact Navier sine-series formula on the rectangle with horizontal side 2 and vertical side 2*xi_0.';
elseif meta.is_all_free
    line = 'Rect solver: FFFF uses a general Ritz solver, and the three rigid-body modes {1, x, y} are projected out before the bending eigenproblem is solved.';
else
    line = sprintf('Rect solver: %s uses the general Ritz formulation with the essential edge constraints built directly into the trial space.', meta.code);
end
end

function line = local_disk_boundary_note(boundary)
bc = upper(strtrim(char(string(boundary))));
switch bc
    case {'C', 'CLAMPED'}
        line = 'Circ boundary dropdown uses C/F/S. Here C means the outer edge is clamped: w = 0 and \partial_r w = 0.';
    case {'S', 'SIMPLY'}
        line = 'Circ boundary dropdown uses C/F/S. Here S means the outer edge is simply supported: w = 0 and M_{rr} = 0.';
    case {'F', 'FREE'}
        line = 'Circ boundary dropdown uses C/F/S. Here F means the outer edge is free: M_{rr} = 0 and V_r = 0.';
    otherwise
        line = 'Circ boundary dropdown uses C/F/S for the single outer-edge condition.';
end
end

function line = local_annulus_boundary_note(boundary)
boundary = upper(strtrim(char(string(boundary))));
if numel(boundary) ~= 2
    line = 'Annulus: use a two-letter outer-inner code such as CC, CF, or FS.';
    return;
end

outer_name = local_edge_name(boundary(1));
inner_name = local_edge_name(boundary(2));
line = sprintf('Annulus dropdown uses ordered outer-inner codes. Current pair %s means outer = %s, inner = %s.', ...
    boundary, outer_name, inner_name);
end

function name = local_edge_name(code)
switch upper(code)
    case 'C'
        name = 'clamped';
    case 'S'
        name = 'simply supported';
    case 'F'
        name = 'free';
    otherwise
        name = 'unknown';
end
end
