function result = compute_static_sources(params)
if nargin < 1 || isempty(params), params = struct(); end
params = fill_static_defaults(params);

domain_type = char(lower(string(params.type)));
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
    case {'rect','square'}
        raw = compute_static_rect_modal(params.nu, params.n, params.boundary, ...
            params.a, params.b, loadSpec, params.kmodes, params.D, params.draw_zero_contour);
        titleText = sprintf('$\\mathrm{%s}\\quad \\nu=%.4g\\quad \\xi_0=%.4g\\quad \\mathrm{%s}$', ...
            local_tex_words(raw.loadSpec.label), params.nu, raw.xi0, upper(raw.boundary));
        item = render_result('heatmap', raw.x, raw.y, raw.U, ...
            'Title', titleText, 'XLabel', '$x$', 'YLabel', '$y$', ...
            'ColorbarLabel', '$w/w_{max}$', 'Normalize', 'signed', ...
            'ZeroContour', params.draw_zero_contour);
        item.sourcePoints = local_marker_sources(raw.loadSpec);
        item.filename = sprintf('chladni_static_rect_%s.png', local_load_file_tag(raw.loadSpec));
    case {'circ','circle','annulus','ring'}
        raw = compute_static_circ_green(params.nu, params.n, params.boundary, ...
            params.xi0, loadSpec, params.mmax, params.D, params.draw_zero_contour, params.distribution_samples);
        if params.xi0 > 0
            circles = [params.xi0 1];
            prefix = 'static_annulus';
            titleText = sprintf('$\\mathrm{%s}\\quad \\nu=%.4g\\quad \\xi_0=%.4g\\quad \\mathrm{%s}$', ...
                local_tex_words(raw.loadSpec.label), params.nu, params.xi0, upper(raw.boundary));
        else
            circles = 1;
            prefix = 'static_circ';
            titleText = sprintf('$\\mathrm{%s}\\quad \\nu=%.4g\\quad \\mathrm{%s}$', ...
                local_tex_words(raw.loadSpec.label), params.nu, upper(raw.boundary));
        end
        item = render_result('heatmap', raw.x, raw.y, raw.U, ...
            'Title', titleText, 'XLabel', '$x$', 'YLabel', '$y$', ...
            'ColorbarLabel', '$w/w_{max}$', 'Normalize', 'signed', ...
            'Mask', raw.mask, 'ZeroContour', params.draw_zero_contour);
        item.circleRadii = circles;
        item.sourcePoints = local_marker_sources(raw.loadSpec);
        if params.xi0 > 0
            item.filename = sprintf('chladni_static_annulus_%s.png', local_load_file_tag(raw.loadSpec));
        else
            item.filename = sprintf('chladni_static_disk_%s.png', local_load_file_tag(raw.loadSpec));
        end
end

result = struct();
result.kind = 'bundle';
result.items = {item};
result.raw = raw;
result.params = params;
end


function S = local_marker_sources(loadSpec)
lt = '';
if isstruct(loadSpec) && isfield(loadSpec, 'type')
    lt = lower(char(string(loadSpec.type)));
end
if ~any(strcmp(lt, {'points','mixed'})) || ~isfield(loadSpec, 'sources') || isempty(loadSpec.sources)
    S = [];
else
    S = loadSpec.sources;
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
if ~any(strcmp(loadSpec.type, {'points','mixed'}))
    loadSpec.sources = [];
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


function x = get_param_default(params, name, defaultVal)
if isfield(params, name) && ~isempty(params.(name)), x = params.(name); else, x = defaultVal; end
end


function s = local_tex_words(txt)
s = char(string(txt));
s = strtrim(regexprep(s, '\s+', ' '));
s = strrep(s, ' ', '\\ ');
end

function tag = local_load_file_tag(loadSpec)
if isstruct(loadSpec) && isfield(loadSpec, 'type') && ~isempty(loadSpec.type)
    tag = lower(char(string(loadSpec.type)));
else
    tag = 'load';
end
switch tag
    case 'points'
        tag = 'point_sources';
    case 'uniform'
        tag = 'uniform_load';
    case 'custom'
        tag = 'custom_load';
    case 'mixed'
        tag = 'mixed_load';
end
tag = regexprep(tag, '[^a-z0-9]+', '_');
tag = regexprep(tag, '^_|_$', '');
end
