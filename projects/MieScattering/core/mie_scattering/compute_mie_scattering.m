function result = compute_mie_scattering(cfg)
cfg = local_defaults(cfg);

solver_cfg = struct();
solver_cfg.k = 2*pi;
solver_cfg.R = cfg.R_over_lambda;
solver_cfg.x = solver_cfg.k * solver_cfg.R;
solver_cfg.gridHalfWidth = cfg.gridHalfWidth;
solver_cfg.N = cfg.N;
solver_cfg.nmaxExtra = cfg.nmaxExtra;
solver_cfg.maskInside = logical(cfg.maskInside);
solver_cfg.nu = cfg.nu;
solver_cfg.psi = cfg.psi;

% Build 2-D slice grid, then embed into 3-D coordinates
L = solver_cfg.gridHalfWidth;
N = solver_cfg.N;
xv = linspace(-L, L, N);
yv = linspace(-L, L, N);
[U, V] = meshgrid(xv, yv);
[X3d, Y3d, Z3d] = make_slice_grid(U, V, cfg.sliceType, cfg.slicePos_over_lambda);

if strcmpi(cfg.geometry, 'sphere')
    [Esca_x, Esca_y, Esca_z, Etot_x, Etot_y, Etot_z] = ...
        scattering_formula_sph(cfg.eps1, cfg.mu1, solver_cfg, X3d, Y3d, Z3d);
else
    [Esca_x, Esca_y, Esca_z, Etot_x, Etot_y, Etot_z] = ...
        scattering_formula_cyl(cfg.eps1, cfg.mu1, solver_cfg, X3d, Y3d, Z3d);
end

[boundaryRadii, boundaryLines] = local_boundary(cfg);

specs = local_resolve_specs(cfg);
items = cell(1, numel(specs));
for i = 1:numel(specs)
    spec = specs{i};
    [F, fieldLabel] = local_evaluate_spec(spec, Esca_x, Esca_y, Esca_z, Etot_x, Etot_y, Etot_z);
    titleText = local_title(cfg, fieldLabel);
    item = render_result('heatmap', U(1,:), V(:,1), F, ...
        'Title', titleText, ...
        'XLabel', local_x_label(cfg.sliceType), ...
        'YLabel', local_y_label(cfg.sliceType), ...
        'ColorbarLabel', fieldLabel, ...
        'Normalize', 'none', ...
        'AutoSymmetric', spec.use_sym);
    if ~isempty(boundaryRadii)
        item.circleRadii = boundaryRadii;
    end
    if ~isempty(boundaryLines)
        item.overlayLines = boundaryLines;
    end
    item.filename = local_mie_filename(cfg, spec);
    items{i} = item;
end

result = struct();
result.kind = 'bundle';
result.items = items;
result.fields = struct('X', X3d, 'Y', Y3d, 'Z', Z3d, ...
    'Esca_x', Esca_x, 'Esca_y', Esca_y, 'Esca_z', Esca_z, ...
    'Etot_x', Etot_x, 'Etot_y', Etot_y, 'Etot_z', Etot_z);
result.cfg = cfg;
end

% ---------------------------------------------------------------------------
% Slice grid: map 2-D meshgrid (U,V) into 3-D coordinates
% ---------------------------------------------------------------------------

function [X3d, Y3d, Z3d] = make_slice_grid(U, V, sliceType, slicePos)
switch sliceType
    case 'xy'
        X3d = U; Y3d = V; Z3d = slicePos * ones(size(U));
    case 'xz'
        X3d = U; Y3d = slicePos * ones(size(U)); Z3d = V;
    case 'yz'
        X3d = slicePos * ones(size(U)); Y3d = U; Z3d = V;
    otherwise
        error('Unknown sliceType: %s', sliceType);
end
end

% ---------------------------------------------------------------------------
% Boundary overlay: circle radius for spherical or circular sections,
% line segments for non-circular cylinder cross-sections.
% ---------------------------------------------------------------------------

function [radii, lines] = local_boundary(cfg)
radii = [];
lines = {};
R = cfg.R_over_lambda;
pos = cfg.slicePos_over_lambda;
Lg = cfg.gridHalfWidth;

if strcmpi(cfg.geometry, 'sphere')
    r_eff = sqrt(max(0, R^2 - pos^2));
    if r_eff > 1e-12
        radii = r_eff;
    end
    return;
end

% Cylinder
switch cfg.sliceType
    case 'xy'
        radii = R;
    case 'xz'
        dx = sqrt(max(0, R^2 - pos^2));
        if dx > 1e-12
            lines = {[dx, -Lg; dx, Lg], [-dx, -Lg; -dx, Lg]};
        end
    case 'yz'
        dy = sqrt(max(0, R^2 - pos^2));
        if dy > 1e-12
            lines = {[dy, -Lg; dy, Lg], [-dy, -Lg; -dy, Lg]};
        end
end
end

% ---------------------------------------------------------------------------
% Axis labels per slice type
% ---------------------------------------------------------------------------

function xl = local_x_label(sliceType)
switch sliceType
    case 'xy'
        xl = '$x/\lambda$';
    case 'xz'
        xl = '$x/\lambda$';
    case 'yz'
        xl = '$y/\lambda$';
    otherwise
        xl = '$x/\lambda$';
end
end

function yl = local_y_label(sliceType)
switch sliceType
    case 'xy'
        yl = '$y/\lambda$';
    case 'xz'
        yl = '$z/\lambda$';
    case 'yz'
        yl = '$z/\lambda$';
    otherwise
        yl = '$y/\lambda$';
end
end

% ---------------------------------------------------------------------------
% Defaults
% ---------------------------------------------------------------------------

function cfg = local_defaults(cfg)
if nargin < 1 || isempty(cfg), cfg = struct(); end
if ~isfield(cfg, 'eps1') || isempty(cfg.eps1), cfg.eps1 = 2+0.1i; end
if ~isfield(cfg, 'mu1') || isempty(cfg.mu1), cfg.mu1 = 0.8+0.05i; end
if ~isfield(cfg, 'R_over_lambda') || isempty(cfg.R_over_lambda), cfg.R_over_lambda = 0.5; end
if ~isfield(cfg, 'nu') || isempty(cfg.nu), cfg.nu = 1.1; end
if ~isfield(cfg, 'psi') || isempty(cfg.psi), cfg.psi = 0.2; end
if ~isfield(cfg, 'geometry') || isempty(cfg.geometry), cfg.geometry = 'sphere'; end
if ~isfield(cfg, 'mode') || isempty(cfg.mode), cfg.mode = 'custom'; end
if ~isfield(cfg, 'customSelection') || isempty(cfg.customSelection)
    cfg.customSelection = {'sca_rex','sca_rey','sca_rez','sca_aex','sca_aey','sca_aez','sca_emag'};
end
if ~isfield(cfg, 'gridHalfWidth') || isempty(cfg.gridHalfWidth), cfg.gridHalfWidth = 2.5; end
if ~isfield(cfg, 'N') || isempty(cfg.N), cfg.N = 500; end
if ~isfield(cfg, 'nmaxExtra') || isempty(cfg.nmaxExtra), cfg.nmaxExtra = 15; end
if ~isfield(cfg, 'maskInside') || isempty(cfg.maskInside), cfg.maskInside = true; end
if ~isfield(cfg, 'sliceType') || isempty(cfg.sliceType)
    if strcmpi(cfg.geometry, 'sphere')
        cfg.sliceType = 'xz';
    else
        cfg.sliceType = 'xy';
    end
end
if ~isfield(cfg, 'slicePos_over_lambda') || isempty(cfg.slicePos_over_lambda)
    cfg.slicePos_over_lambda = 0;
end
end

% ---------------------------------------------------------------------------
% Spec resolution (unchanged from original)
% ---------------------------------------------------------------------------

function specs = local_resolve_specs(cfg)
selected = cfg.customSelection;
if isempty(selected)
    error('At least one field must be selected.');
end
specs = cell(size(selected));
for i = 1:numel(selected)
    specs{i} = local_build_one_spec(selected{i});
end
end

function spec = local_build_one_spec(code)
parts = split(string(code), '_');
family = char(parts(1));
kind = char(parts(2));
if strcmp(family, 'sca')
    family_long = 'scattered';
else
    family_long = 'total';
end
switch kind
    case 'rex'
        spec = local_make_spec(family, family_long, 'real', 'x', true, 'rex');
    case 'rey'
        spec = local_make_spec(family, family_long, 'real', 'y', true, 'rey');
    case 'rez'
        spec = local_make_spec(family, family_long, 'real', 'z', true, 'rez');
    case 'aex'
        spec = local_make_spec(family, family_long, 'abs', 'x', false, 'aex');
    case 'aey'
        spec = local_make_spec(family, family_long, 'abs', 'y', false, 'aey');
    case 'aez'
        spec = local_make_spec(family, family_long, 'abs', 'z', false, 'aez');
    case 'emag'
        spec = struct('family_short', family, 'family_long', family_long, ...
            'kind', 'emag', 'component', '', 'use_sym', false, 'file_suffix', 'emag');
    otherwise
        error('Unsupported custom selection item: %s', code);
end
end

function spec = local_make_spec(family_short, family_long, kind, component, use_sym, file_suffix)
spec = struct('family_short', family_short, 'family_long', family_long, ...
    'kind', kind, 'component', component, 'use_sym', use_sym, 'file_suffix', file_suffix);
end

function [F, fieldLabel] = local_evaluate_spec(spec, Esca_x, Esca_y, Esca_z, Etot_x, Etot_y, Etot_z)
if strcmp(spec.family_short, 'sca')
    Ex = Esca_x; Ey = Esca_y; Ez = Esca_z;
else
    Ex = Etot_x; Ey = Etot_y; Ez = Etot_z;
end

switch spec.kind
    case 'real'
        switch spec.component
            case 'x'
                F = real(Ex); fieldLabel = sprintf('%s $\\Re E_x$', spec.family_long);
            case 'y'
                F = real(Ey); fieldLabel = sprintf('%s $\\Re E_y$', spec.family_long);
            case 'z'
                F = real(Ez); fieldLabel = sprintf('%s $\\Re E_z$', spec.family_long);
        end
    case 'abs'
        switch spec.component
            case 'x'
                F = abs(Ex); fieldLabel = sprintf('%s $|E_x|$', spec.family_long);
            case 'y'
                F = abs(Ey); fieldLabel = sprintf('%s $|E_y|$', spec.family_long);
            case 'z'
                F = abs(Ez); fieldLabel = sprintf('%s $|E_z|$', spec.family_long);
        end
    case 'emag'
        F = sqrt(abs(Ex).^2 + abs(Ey).^2 + abs(Ez).^2);
        fieldLabel = sprintf('%s $E_{mag}$', spec.family_long);
    otherwise
        error('Unsupported spec kind: %s', spec.kind);
end
end

function titleStr = local_title(cfg, fieldLabel)
titleStr = sprintf('%s %s', lower(cfg.geometry), fieldLabel);
end

function short = local_geometry_short(geometry)
if strcmpi(geometry, 'sphere')
    short = 'sph';
else
    short = 'cyl';
end
end

function fname = local_mie_filename(cfg, spec)
geom = local_geometry_short(cfg.geometry);
fam = lower(char(string(spec.family_short)));
switch char(string(spec.kind))
    case 'real'
        token = sprintf('re_E%s', upper(spec.component));
    case 'abs'
        token = sprintf('E%s_mag', upper(spec.component));
    case 'emag'
        token = 'E_mag';
    otherwise
        token = char(string(spec.file_suffix));
end
slice_token = lower(cfg.sliceType);
fname = sprintf('%s_%s_%s_slice_%s_pos_%g.png', geom, fam, token, slice_token, cfg.slicePos_over_lambda);
end


