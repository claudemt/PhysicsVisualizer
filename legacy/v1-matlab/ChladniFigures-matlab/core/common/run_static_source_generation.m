function result = run_static_source_generation(project_root, params)
%RUN_STATIC_SOURCE_GENERATION Static-source backend for Kirchhoff--Love plates.
%
% Solves and renders the static problem
%     D * nabla^4 w = q
% as a heat map.  The load can be a set of point/Gaussian sources, a uniform
% body load, or a user-supplied function handle q = f(X,Y).  Static source
% coordinates use the same physical coordinates as the preview axes.
%
% Point source matrix format:
%     [x y P sigma]
% where sigma = 0 means an ideal point load and sigma > 0 means a normalized
% Gaussian of total resultant P.  Multiple rows are allowed.
%
% Uniform/self-weight load:
%     params.load_type = 'uniform'; params.q0 = ...
%
% Custom distributed load:
%     params.load_type = 'custom'; params.load_function = @(X,Y) ...
%

if nargin < 1 || isempty(project_root), project_root = pwd; end
if nargin < 2 || isempty(params), params = struct(); end
params = fill_static_defaults(params);

storage_root = fullfile(project_root, '.cache');
if ~exist(storage_root, 'dir'), mkdir(storage_root); end
storage_folder = fullfile(storage_root, char(local_storage_folder_name(params)));
prepare_output_folder(storage_folder);

domain_type = char(lower(string(params.type)));

% Establish the physical coordinate domain before interpreting sources.
% Rect: x in [-a/2,a/2], y in [-b/2,b/2], xi0=b/a.
% Disk/annulus: x,y are Cartesian coordinates with outer radius R=1;
% annulus material exists only for xi0 < hypot(x,y) < 1.
switch domain_type
    case {'rect', 'square'}
        if ~isfield(params, 'a') || isempty(params.a), params.a = 2.0; end
        if ~isfield(params, 'b') || isempty(params.b), params.b = 2.0 * params.xi0; end
        if params.b <= 0, params.b = 1.0; end
    case {'circ', 'circle'}
        params.xi0 = 0;
    case {'annulus', 'ring'}
        if params.xi0 <= 0 || params.xi0 >= 1
            error('For annulus runs, xi0 = R0/R must satisfy 0 < xi0 < 1.');
        end
    otherwise
        error('Unknown domain type: %s', params.type);
end

loadSpec = local_load_spec(params);
loadSpec.domain_type = domain_type;
loadSpec.xi0 = params.xi0;
loadSpec = validate_static_load_geometry(domain_type, params, loadSpec);

switch domain_type
    case {'rect', 'square'}
        result = static_source_rect_modal(params.nu, params.n, params.normalize, ...
            storage_folder, params.boundary, params.a, params.b, loadSpec, ...
            params.kmodes, params.D, params.draw_zero_contour);
    case {'circ', 'circle'}
        result = static_source_circ_green(params.nu, params.n, params.normalize, ...
            storage_folder, params.boundary, 0, loadSpec, params.mmax, params.D, ...
            params.draw_zero_contour, params.distribution_samples);
    case {'annulus', 'ring'}
        result = static_source_circ_green(params.nu, params.n, params.normalize, ...
            storage_folder, params.boundary, params.xi0, loadSpec, params.mmax, params.D, ...
            params.draw_zero_contour, params.distribution_samples);
end
end

function params = fill_static_defaults(params)
if ~isfield(params, 'type') || isempty(params.type), params.type = 'rect'; end
if ~isfield(params, 'boundary') || isempty(params.boundary), params.boundary = 'SSSS'; end
if ~isfield(params, 'nu') || isempty(params.nu), params.nu = 0.30; end
if ~isfield(params, 'n') || isempty(params.n), params.n = 300; end
if ~isfield(params, 'D') || isempty(params.D), params.D = 1.0; end
if ~isfield(params, 'normalize') || isempty(params.normalize), params.normalize = true; end
if ~isfield(params, 'xi0') || isempty(params.xi0), params.xi0 = 0; end
if ~isfield(params, 'kmodes') || isempty(params.kmodes), params.kmodes = 80; end
if ~isfield(params, 'mmax') || isempty(params.mmax), params.mmax = 50; end
if ~isfield(params, 'q0') || isempty(params.q0), params.q0 = 1.0; end
if ~isfield(params, 'draw_zero_contour') || isempty(params.draw_zero_contour), params.draw_zero_contour = false; end
if ~isfield(params, 'distribution_samples') || isempty(params.distribution_samples), params.distribution_samples = 28; end
if ~isfield(params, 'load_type') || isempty(params.load_type)
    if isfield(params, 'load_function') && ~isempty(params.load_function)
        params.load_type = 'custom';
    else
        params.load_type = 'points';
    end
end
end

function loadSpec = local_load_spec(params)
loadSpec = struct();
loadSpec.type = lower(strtrim(char(string(params.load_type))));
loadSpec.sources = local_sources(params);
loadSpec.q0 = params.q0;
loadSpec.a = get_param_default(params, 'a', 2.0);
loadSpec.b = get_param_default(params, 'b', 2.0 * max(get_param_default(params, 'xi0', 0.5), eps));
loadSpec.load_function = [];
loadSpec.label = loadSpec.type;

if isfield(params, 'load_function') && ~isempty(params.load_function)
    loadSpec.load_function = normalize_load_function(params.load_function);
end

switch loadSpec.type
    case {'point','points','source','sources'}
        loadSpec.type = 'points';
        loadSpec.label = 'point sources';
    case {'uniform','selfweight','self-weight','gravity','body'}
        loadSpec.type = 'uniform';
        loadSpec.label = 'uniform self-weight';
    case {'custom','function','distributed'}
        loadSpec.type = 'custom';
        loadSpec.label = 'custom distributed load';
        if isempty(loadSpec.load_function)
            error('Custom static load requires params.load_function, for example @(X,Y) sin(pi*X).*sin(pi*Y).');
        end
    case {'mixed'}
        loadSpec.type = 'mixed';
        loadSpec.label = 'mixed load';
    otherwise
        error('Unknown static load_type: %s', params.load_type);
end
end

function f = normalize_load_function(raw)
if isa(raw, 'function_handle')
    f = raw;
    return;
end
text = strtrim(char(string(raw)));
text = regexprep(text, '\s+', ' ');
if isempty(text)
    f = [];
    return;
end
if startsWith(text, '@')
    f = str2func(text);
else
    f = str2func(['@(X,Y) ' text]);
end
end

function sources = local_sources(params)
if isfield(params, 'sources') && ~isempty(params.sources)
    sources = params.sources;
elseif isfield(params, 'source') && ~isempty(params.source)
    sources = params.source;
else
    switch lower(char(string(params.type)))
        case 'rect'
            sources = [0 0 1 0];
        case 'annulus'
            sources = [0.5*(1+params.xi0) 0 1 0];
        otherwise
            sources = [0.35 0 1 0];
    end
end
sources = normalize_source_array(sources);
end

function loadSpec = validate_static_load_geometry(domain_type, params, loadSpec)
lt = lower(char(string(loadSpec.type)));
if ~any(strcmp(lt, {'points','mixed'})) || ~isfield(loadSpec, 'sources') || isempty(loadSpec.sources)
    return;
end
S = loadSpec.sources;
if isempty(S), return; end
if any(~isfinite(S(:)))
    error('Source matrix must contain only finite numeric values.');
end
if any(S(:,4) < 0)
    error('Source sigma must be nonnegative. Use sigma=0 for an ideal point source.');
end
switch char(lower(string(domain_type)))
    case {'rect','square'}
        a = get_param_default(params, 'a', 2.0);
        b = get_param_default(params, 'b', 2.0 * get_param_default(params, 'xi0', 1.0));
        tol = 1e-10 * max([1, a, b]);
        ok = S(:,1) >= -a/2 - tol & S(:,1) <= a/2 + tol & ...
             S(:,2) >= -b/2 - tol & S(:,2) <= b/2 + tol;
        if any(~ok)
            bad = find(~ok, 1, 'first');
            error(['Source row %d lies outside the rectangular plate. ', ...
                   'Rect coordinates must satisfy -a/2 <= x <= a/2 and -b/2 <= y <= b/2; ', ...
                   'here a=%.6g, b=%.6g.'], bad, a, b);
        end
    case {'circ','circle'}
        r = hypot(S(:,1), S(:,2));
        tol = 1e-10;
        ok = r < 1 - tol;
        if any(~ok)
            bad = find(~ok, 1, 'first');
            error(['Source row %d lies outside the disk material. ', ...
                   'Disk point-source coordinates must satisfy hypot(x,y) < 1.'], bad);
        end
    case {'annulus','ring'}
        xi0 = get_param_default(params, 'xi0', 0);
        r = hypot(S(:,1), S(:,2));
        tol = 1e-10;
        ok = r > xi0 + tol & r < 1 - tol;
        if any(~ok)
            bad = find(~ok, 1, 'first');
            error(['Source row %d is not in the annular material. ', ...
                   'Annulus point-source coordinates must satisfy xi0 < hypot(x,y) < 1; ', ...
                   'here xi0=%.6g. Points in the central hole or outside the outer circle cannot carry plate load.'], bad, xi0);
        end
end
end

function S = normalize_source_array(sources)
if isstruct(sources)
    S = zeros(numel(sources), 4);
    for i = 1:numel(sources)
        S(i,1) = getfield_default(sources(i), 'x', 0); %#ok<GFLD>
        S(i,2) = getfield_default(sources(i), 'y', 0); %#ok<GFLD>
        S(i,3) = getfield_default(sources(i), 'P', 1); %#ok<GFLD>
        S(i,4) = getfield_default(sources(i), 'sigma', 0); %#ok<GFLD>
    end
else
    S = double(sources);
    if isempty(S), S = zeros(0,4); return; end
    if isvector(S), S = S(:).'; end
    if size(S,2) == 2
        S = [S ones(size(S,1),1) zeros(size(S,1),1)];
    elseif size(S,2) == 3
        S = [S zeros(size(S,1),1)];
    elseif size(S,2) ~= 4
        error('sources must be an N-by-2, N-by-3, or N-by-4 array: [x y P sigma].');
    end
end
end

function val = getfield_default(s, name, defaultVal)
if isfield(s, name) && ~isempty(s.(name)), val = s.(name); else, val = defaultVal; end
end

function folder_name = local_storage_folder_name(params)
domain_type = char(lower(string(params.type)));
boundary_tag = upper(strtrim(char(string(params.boundary))));
nu_tag = local_num_tag(params.nu);
switch domain_type
    case {'rect', 'square'}
        xi = get_param_default(params, 'xi0', get_param_default(params, 'b', 1) / get_param_default(params, 'a', 2));
        folder_name = sprintf('static-rect-%s-nu%s-xi%s', boundary_tag, nu_tag, local_num_tag(xi));
    case {'annulus', 'ring'}
        folder_name = sprintf('static-annulus-%s-nu%s-xi%s', boundary_tag, nu_tag, local_num_tag(params.xi0));
    case {'circ', 'circle'}
        folder_name = sprintf('static-circ-%s-nu%s-xi0', boundary_tag, nu_tag);
    otherwise
        error('Unknown domain type: %s', params.type);
end
end

function x = get_param_default(params, name, defaultVal)
if isfield(params, name) && ~isempty(params.(name)), x = params.(name); else, x = defaultVal; end
end

function tag = local_num_tag(x)
% Match the eigenmode export convention: keep the decimal point in
% numeric tags, e.g. 0.225 instead of 0p225.  The file extension is
% appended separately by the caller, so internal decimal points are safe.
tag = sprintf('%.6g', x);
end

function prepare_output_folder(output_folder)
if ~exist(output_folder, 'dir'), mkdir(output_folder); return; end
png_info = dir(fullfile(output_folder, '*.png'));
for i = 1:numel(png_info), delete(fullfile(output_folder, png_info(i).name)); end
end
