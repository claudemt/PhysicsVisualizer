function result = compute_chladni_modes(params)
params = fill_chladni_defaults(params);
domain_type = lower(char(string(params.type)));
switch domain_type
    case {'rect','square'}
        if ~isfield(params, 'a') || isempty(params.a), params.a = 2.0; end
        if ~isfield(params, 'b') || isempty(params.b), params.b = 2.0 * params.xi0; end
        result = compute_chladni_rect(params);
    case {'circ','circle','annulus','ring'}
        if any(strcmp(domain_type, {'circ','circle'})), params.xi0 = 0; end
        result = compute_chladni_circular(params);
    otherwise
        error('Unknown domain type: %s', params.type);
end
end

function params = fill_chladni_defaults(params)
if ~isfield(params, 'type') || isempty(params.type), params.type = 'rect'; end
if ~isfield(params, 'boundary') || isempty(params.boundary), params.boundary = 'FFFF'; end
if ~isfield(params, 'nu') || isempty(params.nu), params.nu = 0.225; end
if ~isfield(params, 'k') || isempty(params.k), params.k = 10; end
if ~isfield(params, 'n') || isempty(params.n), params.n = 240; end
if ~isfield(params, 'xi0') || isempty(params.xi0), params.xi0 = 0.45; end
end
