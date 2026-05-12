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

if strcmpi(cfg.geometry, 'sphere')
    [X, Z, Esca_x, Esca_y, Esca_z, Etot_x, Etot_y, Etot_z] = ...
        scattering_formula_sph(cfg.eps1, cfg.mu1, solver_cfg);
else
    [X, Z, Esca_x, Esca_y, Esca_z, Etot_x, Etot_y, Etot_z] = ...
        scattering_formula_cyl(cfg.eps1, cfg.mu1, solver_cfg);
end

specs = local_resolve_specs(cfg);
items = cell(1, numel(specs));
for i = 1:numel(specs)
    spec = specs{i};
    [F, fieldLabel] = local_evaluate_spec(spec, Esca_x, Esca_y, Esca_z, Etot_x, Etot_y, Etot_z);
    titleText = local_title(spec.family_short, cfg);
    item = render_result('heatmap', X(1,:), Z(:,1), F, ...
        'Title', titleText, ...
        'XLabel', '$x/\lambda$', ...
        'YLabel', local_y_label(cfg.geometry), ...
        'ColorbarLabel', fieldLabel, ...
        'Normalize', 'none', ...
        'AutoSymmetric', spec.use_sym);
    item.circleRadii = cfg.R_over_lambda;
    item.filename = local_mie_filename(cfg, spec);
    items{i} = item;
end

result = struct();
result.kind = 'bundle';
result.items = items;
result.fields = struct('X', X, 'Z', Z, ...
    'Esca_x', Esca_x, 'Esca_y', Esca_y, 'Esca_z', Esca_z, ...
    'Etot_x', Etot_x, 'Etot_y', Etot_y, 'Etot_z', Etot_z);
result.cfg = cfg;
end

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
end

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
                F = real(Ex); fieldLabel = sprintf('%s $\\Re E_x$', spec.family_short);
            case 'y'
                F = real(Ey); fieldLabel = sprintf('%s $\\Re E_y$', spec.family_short);
            case 'z'
                F = real(Ez); fieldLabel = sprintf('%s $\\Re E_z$', spec.family_short);
        end
    case 'abs'
        switch spec.component
            case 'x'
                F = abs(Ex); fieldLabel = sprintf('%s $|E_x|$', spec.family_short);
            case 'y'
                F = abs(Ey); fieldLabel = sprintf('%s $|E_y|$', spec.family_short);
            case 'z'
                F = abs(Ez); fieldLabel = sprintf('%s $|E_z|$', spec.family_short);
        end
    case 'emag'
        F = sqrt(abs(Ex).^2 + abs(Ey).^2 + abs(Ez).^2);
        fieldLabel = sprintf('%s $E_{mag}$', spec.family_short);
    otherwise
        error('Unsupported spec kind: %s', spec.kind);
end
end

function titleStr = local_title(family_short, cfg)
titleStr = sprintf('%s-%s: $\\varepsilon_r=%s,\\ \\mu_r=%s,\\ R/\\lambda=%.6g,\\ \\nu=%.6g,\\ \\phi=%.6g$', ...
    local_geometry_short(cfg.geometry), family_short, local_cplx2tex(cfg.eps1), local_cplx2tex(cfg.mu1), ...
    cfg.R_over_lambda, cfg.nu, cfg.psi);
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
fname = sprintf('%s_%s_%s.png', geom, fam, token);
end


function ylab = local_y_label(geometry)
if strcmpi(geometry,'cyl') || strcmpi(geometry,'cylinder')
    ylab = '$y/\lambda$';
else
    ylab = '$z/\lambda$';
end
end

function t = local_cplx2tex(z)
if ischar(z) || isstring(z)
    z = str2num(char(z)); %#ok<ST2NM>
end
if abs(imag(z)) < 1e-12
    t = sprintf('%.6g', real(z));
else
    if imag(z) >= 0
        t = sprintf('%.6g+%.6gi', real(z), imag(z));
    else
        t = sprintf('%.6g%.6gi', real(z), imag(z));
    end
end
end
