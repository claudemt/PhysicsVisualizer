function out = parse_chladni_params(action, varargin)
%PARSE_CHLADNI_PARAMS Compatibility facade for Chladni tab parsing.

action = lower(strrep(char(string(action)), ' ', '_'));
switch action
    case 'boundary_items'
        out = chladni_input_helpers('boundary_items', varargin{:});
    case 'normalize_boundary'
        out = chladni_input_helpers('normalize_boundary', varargin{:});
    case 'read_source_matrix'
        out = chladni_input_helpers('parse_sources', varargin{1});
    case 'reproduce_modes'
        out = "compute_chladni_modes(params);";
    case 'reproduce_static'
        out = "compute_static_sources(params);";
    otherwise
        error('Unknown parse_chladni_params action: %s', action);
end
end
