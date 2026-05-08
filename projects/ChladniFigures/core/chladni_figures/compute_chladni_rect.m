function result = compute_chladni_rect(params)
if ~isfield(params, 'boundary') || isempty(params.boundary), params.boundary = 'FFFF'; end
if ~isfield(params, 'a') || isempty(params.a), params.a = 2.0; end
if ~isfield(params, 'b') || isempty(params.b), params.b = 1.0; end

meta = rect_boundary_meta(params.boundary);
if meta.is_all_simply
    sol = solve_rect_navier_ssss(params.k, params.n, params.a, params.b);
else
    sol = solve_rect_ritz_general(params.nu, params.k, params.n, params.a, params.b, meta.code);
end

x = sol.x;
y = sol.y;
modesU = sol.modesU;
modesLamDisp = sol.lamDisp;
if isfield(sol, 'modeTags') && numel(sol.modeTags) >= numel(modesU)
    modeTags = sol.modeTags;
else
    modeTags = arrayfun(@(j) sprintf('mode%d', j), 1:numel(modesU), 'UniformOutput', false);
end

items = cell(1, numel(modesU));
for j = 1:numel(modesU)
    modeTag = modeTags{j};
    xi0 = params.b / params.a;
    titleText = sprintf('$\\nu=%.6g,\\ \\xi_0=%.6g,\\ \\mathrm{%s}\\ %s,\\ \\Lambda=%.4g$', ...
        params.nu, xi0, upper(meta.title_tag), local_mode_title_text(modeTag), modesLamDisp(j));
    item = render_result('heatmap', x, y, modesU{j}, ...
        'Title', titleText, ...
        'XLabel', '$x$', 'YLabel', '$y$', ...
        'ColorbarLabel', '$w/w_{max}$', ...
        'Normalize', 'signed', ...
        'ZeroContour', true);
    item.boundaryZeroEdges = boundary_zero_edges(meta.code);
    item.filename = sprintf('chladni_rect_%s_%s.png', lower(meta.title_tag), local_mode_file_tag(modeTag));
    items{j} = item;
end

result = struct();
result.kind = 'bundle';
result.items = items;
result.solution = sol;
result.params = params;
end

function edges = boundary_zero_edges(boundaryCode)
meta = rect_boundary_meta(boundaryCode);
edges = struct();
edges.left = meta.left ~= 'F';
edges.right = meta.right ~= 'F';
edges.bottom = meta.bottom ~= 'F';
edges.top = meta.top ~= 'F';
end

function modeText = local_mode_title_text(modeTag)
tokens = regexp(modeTag, '^mode(\d+),(\d+)$', 'tokens', 'once');
if ~isempty(tokens)
    modeText = sprintf('(m=%s, s=%s)', tokens{1}, tokens{2});
    return;
end
tokens = regexp(modeTag, '^mode(\d+)$', 'tokens', 'once');
if ~isempty(tokens)
    modeText = sprintf('(\\mathrm{mode}=%s)', tokens{1});
    return;
end
modeText = modeTag;
end

function tag = local_num_tag(x)
tag = regexprep(sprintf('%.6g', x), '[^0-9A-Za-z\-]+', 'p');
end

function tag = local_mode_file_tag(modeTag)
tag = lower(char(string(modeTag)));
tag = regexprep(tag, '^mode(\d+),(\d+)$', 'm$1_s$2');
tag = regexprep(tag, '^mode(\d+)$', 'mode_$1');
tag = regexprep(tag, '[^a-z0-9]+', '_');
tag = regexprep(tag, '^_|_$', '');
end
