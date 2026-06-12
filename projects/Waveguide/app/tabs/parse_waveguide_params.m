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
% Parse a semicolon-separated list of parenthesized integer tuples.
% Example: '(1,0);(1,1);(2,1)' -> [1 0; 1 1; 2 1]
if isstring(txt), txt = char(txt); end
txt = strtrim(txt);
if isempty(txt)
    txt = char(string(default_text));
end
M = local_parse_tuples(txt, ncols);
M = round(M);
if any(M(:) < min_val | M(:) > max_val)
    error('Mode indices must be in [%d,%d].', min_val, max_val);
end
end

function v = local_int_vector(txt, default_text, min_val, max_val)
% Parse a parenthesized comma-separated list of integers.
% Example: '(0,1,2)' -> [0 1 2]
if isstring(txt), txt = char(txt); end
txt = strtrim(txt);
if isempty(txt)
    txt = char(string(default_text));
end
M = local_parse_tuples(txt, 1);
v = unique(round(M(:))).';
if any(v < min_val | v > max_val)
    error('Orders must be in [%d,%d].', min_val, max_val);
end
end

function M = local_parse_tuples(txt, expected_cols)
% Shared tuple parser: extracts numbers from '(...);(...)' format.
txt = strtrim(txt);
if contains(txt, '(')
    pieces = regexp(txt, '\)\s*;?\s*\(', 'split');
    pieces = strtrim(pieces);
    % Count valid pieces first for pre-allocation
    nValid = 0;
    for i = 1:numel(pieces)
        p = pieces{i};
        if startsWith(p, '('), p = p(2:end); end
        if endsWith(p, ')'), p = p(1:end-1); end
        if ~isempty(strtrim(p)), nValid = nValid + 1; end
    end
    M = zeros(nValid, expected_cols);
    idx = 0;
    for i = 1:numel(pieces)
        p = pieces{i};
        if startsWith(p, '('), p = p(2:end); end
        if endsWith(p, ')'), p = p(1:end-1); end
        p = strtrim(p);
        if isempty(p), continue; end
        nums = sscanf(p, '%d,');
        if numel(nums) ~= expected_cols
            error('Each tuple must have exactly %d integers.', expected_cols);
        end
        idx = idx + 1;
        M(idx, :) = nums(:).';
    end
else
    % Bare comma-separated list (fallback)
    nums = sscanf(txt, '%d,');
    if numel(nums) >= expected_cols
        M = reshape(nums(1:floor(numel(nums)/expected_cols)*expected_cols), expected_cols, []).';
    else
        M = zeros(0, expected_cols);
    end
end
if isempty(M)
    error('Could not parse any valid tuples from: %s', txt);
end
end
