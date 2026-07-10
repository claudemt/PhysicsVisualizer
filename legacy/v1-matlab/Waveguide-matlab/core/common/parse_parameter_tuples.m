function M = parse_parameter_tuples(txt,n_params,default_text)
%PARSE_PARAMETER_TUPLES Parse integrated tuple syntax into matrix.

if nargin < 3, default_text = ''; end
txt = strtrim(char(string(txt)));
if isempty(txt), txt = strtrim(char(string(default_text))); end

if n_params == 0
    M = zeros(1,0);
    return
end
if isempty(txt), error('Empty parameter input.'); end

if n_params == 1 && txt(1) ~= '('
    vals = parse_scalar_set(txt);
    M = vals(:);
    return
end

if n_params == 1 && startsWith(txt,'(') && endsWith(txt,')') && count_top_level_tuples(txt)==1
    inner = txt(2:end-1);
    if ~contains(inner,'(')
        vals = parse_scalar_set(inner);
        M = vals(:);
        return
    end
end

chunks = extract_top_level_tuples(txt);
rows = [];
for i = 1:numel(chunks)
    inner = chunks{i}(2:end-1);
    parts = split_top_level(inner,',');
    if numel(parts) ~= n_params
        error('Each tuple must have exactly %d parameter(s).',n_params);
    end
    sets = cell(1,n_params);
    for k = 1:n_params
        sets{k} = parse_scalar_set(parts{k});
    end
    rows = [rows; cartesian_product_rows(sets)]; %#ok<AGROW>
end
M = rows;
end

function tuples = extract_top_level_tuples(txt)
tuples = {};
i = 1; N = length(txt);
while i <= N
    while i <= N && isspace(txt(i)), i = i+1; end
    if i > N, break; end
    if txt(i) ~= '(', error('Expected tuple starting with "(".'); end
    depth = 0; j = i;
    while j <= N
        if txt(j) == '(', depth = depth + 1; end
        if txt(j) == ')'
            depth = depth - 1;
            if depth == 0, break; end
        end
        j = j + 1;
    end
    if depth ~= 0, error('Unmatched parentheses.'); end
    tuples{end+1} = strtrim(txt(i:j)); %#ok<AGROW>
    i = j + 1;
end
end

function n = count_top_level_tuples(txt)
n = 0; i = 1; N = length(txt);
while i <= N
    while i <= N && isspace(txt(i)), i = i+1; end
    if i > N, break; end
    if txt(i) == '('
        depth = 0;
        while i <= N
            if txt(i) == '(', depth = depth + 1; end
            if txt(i) == ')'
                depth = depth - 1;
                if depth == 0, n = n+1; i = i+1; break; end
            end
            i = i+1;
        end
    else
        i = i+1;
    end
end
end

function parts = split_top_level(txt,delimiter)
parts = {};
depth = 0; start_idx = 1;
for i = 1:length(txt)
    ch = txt(i);
    if ch == '(', depth = depth + 1; end
    if ch == ')', depth = depth - 1; end
    if ch == delimiter && depth == 0
        parts{end+1} = strtrim(txt(start_idx:i-1)); %#ok<AGROW>
        start_idx = i+1;
    end
end
parts{end+1} = strtrim(txt(start_idx:end));
end

function values = parse_scalar_set(expr)
expr = strtrim(expr);
if startsWith(expr,'(') && endsWith(expr,')')
    inner = strtrim(expr(2:end-1));
    parts = split_top_level(inner,',');
    values = [];
    for i = 1:numel(parts)
        vals = str2num(parts{i}); %#ok<ST2NM>
        if isempty(vals), error('Could not parse parameter set: %s',expr); end
        values = [values vals(:).']; %#ok<AGROW>
    end
else
    vals = str2num(expr); %#ok<ST2NM>
    if isempty(vals), error('Could not parse parameter expression: %s',expr); end
    values = vals(:).';
end
end

function M = cartesian_product_rows(sets)
grids = cell(1,numel(sets));
[grids{:}] = ndgrid(sets{:});
M = zeros(numel(grids{1}),numel(sets));
for k = 1:numel(sets), M(:,k) = grids{k}(:); end
end
