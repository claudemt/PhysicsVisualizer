function out = parse_waveguide_params(action, varargin)
%PARSE_WAVEGUIDE_PARAMS Shared tab-side parsing helpers for the waveguide tabs.
%
% This file is kept because three tabs use the same tuple and scalar parsing.
% It contains no notes text or layout behavior.

switch lower(char(string(action)))
    case 'legend_value'
        out = char(string(varargin{1}));
    case 'positive'
        out = local_positive(varargin{:});
    case 'integer'
        out = local_integer(varargin{:});
    case 'int_matrix'
        out = local_int_matrix(varargin{:});
    case 'int_vector'
        out = local_int_vector(varargin{:});
    otherwise
        error('Unknown parse_waveguide_params action: %s', action);
end
end

function v = local_positive(ctrl, name)
v = ctrl.Value;
if ~isscalar(v) || ~isfinite(v) || v <= 0
    error('%s must be positive.', name);
end
end

function v = local_integer(ctrl, name, min_val, max_val)
v = round(ctrl.Value);
if ~isscalar(v) || ~isfinite(v) || v < min_val || v > max_val
    error('%s must be an integer in [%d,%d].', name, min_val, max_val);
end
end

function M = local_int_matrix(txt, ncols, default_text, min_val, max_val)
M = create_control_panel('parse_tuples', txt, ncols, default_text);
M = round(M);
if any(M(:) < min_val | M(:) > max_val)
    error('Mode indices must be in [%d,%d].', min_val, max_val);
end
end

function v = local_int_vector(txt, default_text, min_val, max_val)
M = create_control_panel('parse_tuples', txt, 1, default_text);
v = unique(round(M(:))).';
if any(v < min_val | v > max_val)
    error('Orders must be in [%d,%d].', min_val, max_val);
end
end
