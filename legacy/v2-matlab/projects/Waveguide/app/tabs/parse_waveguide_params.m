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
% Supports colon ranges: (1:3,0:2) expands to (1,0),(1,1),(1,2),(2,0),...
txt = strtrim(txt);
if contains(txt, '(')
    pieces = regexp(txt, '\)\s*;?\s*\(', 'split');
    pieces = strtrim(pieces);
    M = zeros(0, expected_cols);
    for i = 1:numel(pieces)
        p = pieces{i};
        if startsWith(p, '('), p = p(2:end); end
        if endsWith(p, ')'), p = p(1:end-1); end
        p = strtrim(p);
        if isempty(p), continue; end
        cols = local_parse_range(p);
        if size(cols,2) ~= expected_cols
            error('Each tuple must have exactly %d integers.', expected_cols);
        end
        M = [M; cols]; %#ok<AGROW>
    end
else
    % Bare comma-separated list (fallback)
    cols = local_parse_range(txt);
    if size(cols,2) < expected_cols
        M = zeros(0, expected_cols);
    else
        M = cols;
    end
end
if isempty(M)
    error('Could not parse any valid tuples from: %s', txt);
end
end

function M = local_parse_range(txt)
% Parse a comma-separated list where each element may be a colon range.
% Example: '1:3,0:2' -> all combos of [1 2 3] x [0 1 2]
parts = strtrim(strsplit(txt, ','));
parts(cellfun(@isempty, parts)) = [];
ranges = cell(1, numel(parts));
for i = 1:numel(parts)
    c = strtrim(parts{i});
    if contains(c, ':')
        lim = sscanf(c, '%d:%d');
        if numel(lim) ~= 2
            error('Invalid range: %s', c);
        end
        ranges{i} = (lim(1):lim(2)).';
    else
        ranges{i} = sscanf(c, '%d');
    end
end
% Cartesian product of all dimensions
M = local_cartesian_product(ranges);
end

function M = local_cartesian_product(ranges)
% Build all combinations from a cell array of column vectors.
n = numel(ranges);
counts = cellfun(@numel, ranges);
total = prod(counts);
M = zeros(total, n);
if total == 0, return; end
repeats = 1;
for i = n:-1:1
    col = repmat(kron(ranges{i}, ones(repeats, 1)), total / (repeats * counts(i)), 1);
    M(:, i) = col;
    repeats = repeats * counts(i);
end
end
