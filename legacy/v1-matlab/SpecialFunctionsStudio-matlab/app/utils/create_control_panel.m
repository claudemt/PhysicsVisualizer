function out = create_control_panel(parent, kind, varargin)
if nargin >= 1 && (ischar(parent) || isstring(parent))
    cmd = lower(char(parent));
    switch cmd
        case {'parse_tuples','parse_scan_tuples'}
            out = local_parse_parameter_tuples(kind, varargin{:});
            return;
        case {'parse_lines'}
            out = local_cell_lines(kind);
            return;
        case {'default_tuple','tuple_default'}
            out = local_default_tuple(kind);
            return;
    end
end
kind = lower(char(kind));
section_kinds = {'section','panel','group'};
control_kinds = {'numeric','text','dropdown','checkbox','textarea','scan','legend','layout','label'};
if any(strcmp(kind, section_kinds))
    out = local_section(parent, varargin{:});
elseif any(strcmp(kind, control_kinds))
    out = local_control(parent, kind, varargin{:});
else
    out = local_section(parent, kind, varargin{:});
end
end

function section = local_section(parent, title_text, rows, varargin)
if nargin < 3 || isempty(rows)
    rows = 1;
end
p = inputParser;
p.addParameter('Padding', [8 8 8 8]);
p.addParameter('Spacing', 5);
p.addParameter('RowHeight', []);
p.addParameter('ColumnWidth', {'1x'});
p.parse(varargin{:});
opt = p.Results;
section = struct();
section.panel = uipanel(parent, 'Title', char(title_text));
section.grid = uigridlayout(section.panel, [rows 1]);
if isempty(opt.RowHeight)
    section.grid.RowHeight = repmat({'fit'}, 1, rows);
else
    section.grid.RowHeight = opt.RowHeight;
end
section.grid.ColumnWidth = opt.ColumnWidth;
section.grid.Padding = opt.Padding;
section.grid.RowSpacing = opt.Spacing;
section.grid.ColumnSpacing = 0;
end

function c = local_control(parent, kind, label_text, value, varargin)
if nargin < 4
    value = [];
end
p = inputParser;
p.addParameter('Items', {});
p.addParameter('Tooltip', '');
p.addParameter('Width', []);
p.addParameter('Height', 24);
p.addParameter('LabelWidth', '1x');
p.addParameter('InputWidth', []);
p.addParameter('Interpreter', 'latex');
p.addParameter('Editable', true);
p.parse(varargin{:});
opt = p.Results;
if isempty(opt.InputWidth)
    switch kind
        case 'numeric'
            opt.InputWidth = 82;
        case {'text','dropdown','legend','layout'}
            opt.InputWidth = 118;
        case 'checkbox'
            opt.InputWidth = 36;
        otherwise
            opt.InputWidth = 118;
    end
end

switch kind
    case {'textarea','scan'}
        if isempty(strtrim(char(string(label_text))))
            row = uigridlayout(parent, [1 1]);
            row.ColumnWidth = {'1x'};
            row.RowHeight = {max(64, opt.Height)};
            row.Padding = [0 0 0 0];
            row.RowSpacing = 0;
            c = uitextarea(row, 'Value', local_cell_lines(value));
            c.Layout.Row = 1;
            c.Layout.Column = 1;
            c.Editable = local_onoff(opt.Editable);
        else
            row = uigridlayout(parent, [2 1]);
            row.ColumnWidth = {'1x'};
            row.RowHeight = {22, max(64, opt.Height)};
            row.Padding = [0 0 0 0];
            row.RowSpacing = 3;
            label = uilabel(row, 'Text', char(label_text), 'HorizontalAlignment', 'left');
            label.Layout.Row = 1;
            label.Layout.Column = 1;
            c = uitextarea(row, 'Value', local_cell_lines(value));
            c.Layout.Row = 2;
            c.Layout.Column = 1;
            c.Editable = local_onoff(opt.Editable);
        end
    case 'label'
        c = uilabel(parent, 'Text', char(label_text), 'HorizontalAlignment', 'left');
        try
            c.Interpreter = opt.Interpreter;
        catch
        end
    otherwise
        row = uigridlayout(parent, [1 2]);
        row.ColumnWidth = {opt.LabelWidth, opt.InputWidth};
        row.RowHeight = {opt.Height};
        row.Padding = [0 0 0 0];
        row.ColumnSpacing = 6;
        row.RowSpacing = 0;
        label = uilabel(row, 'Text', char(label_text), 'HorizontalAlignment', 'left');
        label.Layout.Row = 1;
        label.Layout.Column = 1;
        try
            label.Interpreter = opt.Interpreter;
        catch
        end
        switch kind
            case 'numeric'
                if isempty(value)
                    value = 0;
                end
                c = uieditfield(row, 'numeric', 'Value', value, 'HorizontalAlignment', 'center');
            case 'text'
                c = uieditfield(row, 'text', 'Value', char(string(value)), 'HorizontalAlignment', 'center');
            case 'dropdown'
                items = opt.Items;
                if isempty(items)
                    items = value;
                end
                items = local_cellstr(items);
                c = uidropdown(row, 'Items', items, 'Value', local_dropdown_value(value, items));
            case 'legend'
                items = {'best','northwest','northeast','southwest','southeast','north','south','east','west','none'};
                c = uidropdown(row, 'Items', items, 'Value', local_dropdown_value(value, items));
            case 'layout'
                c = uieditfield(row, 'text', 'Value', char(string(value)), 'HorizontalAlignment', 'center');
            case 'checkbox'
                c = uicheckbox(row, 'Text', '', 'Value', logical(value));
        end
        c.Layout.Row = 1;
        c.Layout.Column = 2;
end

if exist('label', 'var') && ~isempty(opt.Tooltip)
    label.Tooltip = opt.Tooltip;
end
if ~strcmp(kind, 'label') && ~isempty(opt.Tooltip)
    c.Tooltip = opt.Tooltip;
end
end

function v = local_dropdown_value(value, items)
if isempty(value)
    v = items{1};
else
    v = char(string(value));
    if ~any(strcmp(v, items))
        v = items{1};
    end
end
end

function c = local_cellstr(x)
if ischar(x)
    c = {x};
elseif isstring(x)
    c = cellstr(x);
elseif iscell(x)
    c = cellfun(@char, x, 'UniformOutput', false);
else
    c = cellstr(string(x));
end
end

function c = local_cell_lines(x)
if isempty(x)
    c = {''};
elseif ischar(x)
    c = regexp(strrep(x, sprintf('\r\n'), sprintf('\n')), sprintf('\n'), 'split');
elseif isstring(x)
    c = cellstr(x);
elseif iscell(x)
    c = cellfun(@char, x, 'UniformOutput', false);
else
    c = cellstr(string(x));
end
end

function s = local_onoff(tf)
if ischar(tf) || isstring(tf)
    s = char(tf);
elseif tf
    s = 'on';
else
    s = 'off';
end
end



function txt = local_default_tuple(defaults)
if isempty(defaults)
    txt = '';
    return;
end
if ischar(defaults) || isstring(defaults)
    defaults = cellstr(string(defaults));
elseif ~iscell(defaults)
    defaults = cellstr(string(defaults));
end
parts = cell(1, numel(defaults));
for k = 1:numel(defaults)
    parts{k} = char(string(defaults{k}));
end
txt = ['(' strjoin(parts, ',') ')'];
end


function M = local_parse_parameter_tuples(txt, n_params, default_text)
if nargin < 3, default_text = ''; end
txt = strtrim(char(string(txt)));
if isempty(txt), txt = strtrim(char(string(default_text))); end
if n_params == 0
    M = zeros(1,0);
    return;
end
if isempty(txt), error('Empty parameter input.'); end
if n_params == 1 && txt(1) ~= '('
    vals = local_parse_scalar_set(txt);
    M = vals(:);
    return;
end
if n_params == 1 && startsWith(txt,'(') && endsWith(txt,')') && local_count_top_level_tuples(txt)==1
    inner = txt(2:end-1);
    if ~contains(inner,'(')
        vals = local_parse_scalar_set(inner);
        M = vals(:);
        return;
    end
end
chunks = local_extract_top_level_tuples(txt);
rows = [];
for i = 1:numel(chunks)
    inner = chunks{i}(2:end-1);
    parts = local_split_top_level(inner, ',');
    if numel(parts) ~= n_params
        error('Each tuple must have exactly %d parameter(s).', n_params);
    end
    sets = cell(1,n_params);
    for k = 1:n_params
        sets{k} = local_parse_scalar_set(parts{k});
    end
    rows = [rows; local_cartesian_product_rows(sets)]; %#ok<AGROW>
end
M = rows;
end

function tuples = local_extract_top_level_tuples(txt)
tuples = {};
i = 1; N = length(txt);
while i <= N
    while i <= N && isspace(txt(i)), i = i + 1; end
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

function n = local_count_top_level_tuples(txt)
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

function parts = local_split_top_level(txt, delimiter)
parts = {};
depth = 0; start_idx = 1;
for i = 1:length(txt)
    ch = txt(i);
    if ch == '(', depth = depth + 1; end
    if ch == ')', depth = depth - 1; end
    if ch == delimiter && depth == 0
        parts{end+1} = strtrim(txt(start_idx:i-1)); %#ok<AGROW>
        start_idx = i + 1;
    end
end
parts{end+1} = strtrim(txt(start_idx:end));
end

function values = local_parse_scalar_set(expr)
expr = strtrim(expr);
if startsWith(expr,'(') && endsWith(expr,')')
    inner = strtrim(expr(2:end-1));
    parts = local_split_top_level(inner, ',');
    values = [];
    for i = 1:numel(parts)
        vals = str2num(parts{i}); %#ok<ST2NM>
        if isempty(vals), error('Could not parse parameter set: %s', expr); end
        values = [values vals(:).']; %#ok<AGROW>
    end
else
    vals = str2num(expr); %#ok<ST2NM>
    if isempty(vals), error('Could not parse parameter expression: %s', expr); end
    values = vals(:).';
end
end

function M = local_cartesian_product_rows(sets)
grids = cell(1,numel(sets));
[grids{:}] = ndgrid(sets{:});
M = zeros(numel(grids{1}), numel(sets));
for k = 1:numel(sets)
    M(:,k) = grids{k}(:);
end
end
