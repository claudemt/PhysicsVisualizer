function out = create_control_panel(parent, kind, varargin)
%CREATE_CONTROL_PANEL Shared control-panel helper using the older compact layout.
%
% UI mode:
%   create_control_panel(parent, 'section', title, rows)
%   create_control_panel(parent, 'numeric'/'text'/'dropdown'/..., label, value, ...)
%
% Utility mode:
%   create_control_panel('parse_matrix', text)
%   create_control_panel('parse_range', text)
%   create_control_panel('parse_tuples', text, nParams, defaultText)
%   create_control_panel('default_tuple', defaults)

if nargin >= 1 && (ischar(parent) || isstring(parent))
    cmd = lower(strrep(char(string(parent)), ' ', '_'));
    if nargin < 2
        args = {};
    else
        args = [{kind}, varargin];
    end
    out = local_dispatch_utility(cmd, args);
    return;
elseif nargin >= 2 && isempty(parent) && (ischar(kind) || isstring(kind))
    cmd = lower(strrep(char(string(kind)), ' ', '_'));
    if local_is_utility_action(cmd)
        out = local_dispatch_utility(cmd, varargin);
        return;
    end
end

if nargin < 2
    error('create_control_panel requires at least two arguments.');
end

kind = lower(strrep(char(string(kind)), ' ', '_'));
if local_is_utility_action(kind)
    out = local_dispatch_utility(kind, varargin);
    return;
end
switch kind
    case {'section','panel'}
        out = local_section(parent, varargin{:});
    case {'numeric','number'}
        out = local_control(parent, 'numeric', varargin{:});
    case {'text','edit'}
        out = local_control(parent, 'text', varargin{:});
    case {'dropdown','popup'}
        out = local_control(parent, 'dropdown', varargin{:});
    case {'checkbox','check'}
        out = local_control(parent, 'checkbox', varargin{:});
    case {'textarea','multiline'}
        out = local_control(parent, 'textarea', varargin{:});
    case {'listbox','list'}
        out = local_control(parent, 'listbox', varargin{:});
    case {'legend'}
        label = 'legend';
        default_value = 'best';
        if ~isempty(varargin), label = varargin{1}; end
        if numel(varargin) >= 2, default_value = varargin{2}; end
        items = {'none','best','northwest','northeast','southwest','southeast','north','south','east','west'};
        out = local_control(parent, 'dropdown', label, items, default_value, 'Legend location.');
    case {'layout'}
        label = 'layout';
        default_value = 'auto';
        if ~isempty(varargin), label = varargin{1}; end
        if numel(varargin) >= 2, default_value = varargin{2}; end
        out = local_control(parent, 'text', label, default_value, [], 'Use auto, columns:N, or row syntax like 1+2+3.');
    case {'scan'}
        label = 'scan';
        default_value = {''};
        tip = 'Tuple syntax: (2), (0:5), (1:4,(2,5,7),4).';
        if ~isempty(varargin), label = varargin{1}; end
        if numel(varargin) >= 2, default_value = varargin{2}; end
        if numel(varargin) >= 3, tip = varargin{3}; end
        out = local_control(parent, 'textarea', label, default_value, [], tip);
    otherwise
        error('Unknown create_control_panel kind: %s', kind);
end
end


function tf = local_is_utility_action(cmd)
cmd = lower(strrep(char(string(cmd)), ' ', '_'));
tf = any(strcmp(cmd, {'matrix_from_text','parse_matrix','matrix', ...
    'vector_from_text','parse_vector','vector', ...
    'parse_range','range', ...
    'scan_text','parse_scan', ...
    'parse_tuples','parse_scan_tuples','parse_parameter_tuples', ...
    'default_tuple','tuple_default'}));
end

function out = local_dispatch_utility(cmd, args)
if nargin < 2, args = {}; end
cmd = lower(strrep(char(string(cmd)), ' ', '_'));
switch cmd
    case {'matrix_from_text','parse_matrix','matrix'}
        if isempty(args), args = {''}; end
        out = local_parse_matrix(args{1});
    case {'vector_from_text','parse_vector','vector'}
        if isempty(args), args = {''}; end
        out = local_parse_vector(args{1});
    case {'parse_range','range'}
        if isempty(args), args = {''}; end
        out = local_parse_range(args{1});
    case {'scan_text','parse_scan'}
        if isempty(args), args = {''}; end
        out = local_parse_scan(args{1});
    case {'parse_tuples','parse_scan_tuples','parse_parameter_tuples'}
        if isempty(args), args = {''}; end
        out = local_parse_parameter_tuples(args{:});
    case {'default_tuple','tuple_default'}
        if isempty(args), args = {''}; end
        out = local_default_tuple(args{1});
    otherwise
        error('Unknown create_control_panel utility action: %s', cmd);
end
end

function section = local_section(parent, title_text, row_heights, varargin)
if nargin < 3 || isempty(row_heights)
    row_heights = {'fit'};
end
if isnumeric(row_heights)
    row_heights = repmat({'fit'}, 1, row_heights);
elseif ischar(row_heights) || isstring(row_heights)
    row_heights = {char(row_heights)};
end

section = struct();
layout_row = local_next_row(parent);
section.panel = uipanel(parent, 'Title', char(string(title_text)));
try
    section.panel.Layout.Row = layout_row;
    section.panel.Layout.Column = 1;
catch
end
section.grid = uigridlayout(section.panel, [numel(row_heights) 1]);
section.grid.RowHeight = row_heights;
section.grid.ColumnWidth = {'1x'};
section.grid.Padding = [8 8 8 8];
section.grid.RowSpacing = 6;
section.grid.ColumnSpacing = 0;
section.title = title_text;
end

function c = local_control(parent, type, label_text, a, b, varargin)
%LOCAL_CONTROL Build one labeled control row.
% Accept both old compact calls
%   create_control_panel(parent,'numeric',label,value,tip)
% and newer calls that reserve an empty slot before the tooltip
%   create_control_panel(parent,'numeric',label,value,[],tip).
if nargin < 4, a = []; end
if nargin < 5, b = []; end
% For dropdown/listbox, b is the default Value; for most other controls the
% old compact signature used b as Tooltip.  Support both that old form and
% the newer value, [], tooltip form.
if any(strcmpi(char(string(type)), {'dropdown','listbox'}))
    tip = local_pick_tooltip(varargin{:});
else
    tip = local_pick_tooltip(b, varargin{:});
end

layout_row = local_next_row(parent);
row = uigridlayout(parent, [1 2]);
try
    row.Layout.Row = layout_row;
    row.Layout.Column = 1;
catch
end
row.Padding = [0 0 0 0];
row.ColumnSpacing = 6;
row.RowSpacing = 0;

label = uilabel(row, 'Text', char(string(label_text)), 'HorizontalAlignment', 'left');
label.Layout.Row = 1;
label.Layout.Column = 1;
if ~isempty(tip)
    try, label.Tooltip = char(string(tip)); catch, end
end

switch lower(char(string(type)))
    case 'numeric'
        row.RowHeight = {24};
        row.ColumnWidth = {'1x', 96};
        c = uieditfield(row, 'numeric', 'Value', a, 'HorizontalAlignment', 'center');

    case 'text'
        row.RowHeight = {24};
        row.ColumnWidth = {'1x', 160};
        c = uieditfield(row, 'text', 'Value', char(string(a)), 'HorizontalAlignment', 'center');

    case 'dropdown'
        row.RowHeight = {24};
        row.ColumnWidth = {'1x', 170};
        items = local_cellstr(a);
        default_value = local_dropdown_value(b, items);
        if isempty(items)
            items = {default_value};
        end
        if ~any(strcmp(default_value, items))
            % MATLAB uidropdown requires Value to be a member of Items.
            % Keep legacy project defaults safe instead of failing at tab startup.
            items = [{default_value}, items(:).'];
        end
        c = uidropdown(row, 'Items', items);
        try
            c.Value = default_value;
        catch
            c.Value = items{1};
        end

    case 'checkbox'
        row.RowHeight = {24};
        row.ColumnWidth = {'1x', 96};
        c = uicheckbox(row, 'Text', '', 'Value', logical(a));

    case 'textarea'
        row.RowHeight = {80};
        row.ColumnWidth = {110, '1x'};
        c = uitextarea(row, 'Value', local_cell_lines(a));

    case 'listbox'
        row.RowHeight = {90};
        row.ColumnWidth = {110, '1x'};
        items = local_cellstr(a);
        value = local_listbox_value(b, items);
        if isempty(items)
            items = {''};
            value = {};
        end
        c = uilistbox(row, 'Items', items, 'Multiselect', 'on');
        try
            c.Value = value;
        catch
            % Some MATLAB releases are strict about Value shape. Fall back to
            % the first legal item rather than failing during tab startup.
            if isempty(items)
                c.Value = {};
            else
                c.Value = items(1);
            end
        end

    otherwise
        error('Unsupported control type: %s', type);
end

c.Layout.Row = 1;
c.Layout.Column = 2;
if ~isempty(tip)
    try, c.Tooltip = char(string(tip)); catch, end
end
end

function tip = local_pick_tooltip(varargin)
tip = '';
for ii = 1:numel(varargin)
    v = varargin{ii};
    if isempty(v), continue; end
    if ischar(v) || isstring(v)
        tip = char(string(v));
    end
end
end

function row = local_next_row(grid)

rows = [];

try
    children = grid.Children;
    for k = 1:numel(children)
        try
            r = children(k).Layout.Row;
            if isnumeric(r) && isfinite(r)
                rows(end+1) = r; %#ok<AGROW>
            end
        catch
        end
    end
catch
end

if isempty(rows)
    row = 1;
else
    row = max(rows) + 1;
end

try
    if isprop(grid, 'RowHeight')
        rh = grid.RowHeight;

        if isempty(rh)
            rh = {};
        elseif ~iscell(rh)
            rh = num2cell(rh);
        end

        while numel(rh) < row
            rh{end+1} = 'fit'; %#ok<AGROW>
        end

        for ii = 1:numel(rh)
            if ischar(rh{ii}) || isstring(rh{ii})
                token = char(string(rh{ii}));
                if strcmpi(token, '1x')
                    rh{ii} = 'fit';
                end
            end
        end

        grid.RowHeight = rh;
    end
catch
end
end

function v = local_dropdown_value(value, items)
if isempty(items)
    v = '';
    return;
end
if isempty(value)
    v = items{1};
else
    v = char(string(value));
    if ~any(strcmp(v, items))
        v = items{1};
    end
end
end

function values = local_listbox_value(value, items)
items = local_cellstr(items);
if isempty(items)
    values = {};
    return;
end
if isempty(value)
    values = items(1);
    return;
end
if iscell(value)
    raw = cellfun(@char, value(:).', 'UniformOutput', false);
elseif isstring(value)
    raw = cellstr(value(:).');
else
    raw = {char(string(value))};
end
keep = false(size(raw));
for ii = 1:numel(raw)
    keep(ii) = any(strcmp(raw{ii}, items));
end
values = raw(keep);
if isempty(values)
    values = items(1);
end
end

function c = local_cellstr(x)
if isempty(x)
    c = {};
elseif ischar(x)
    c = {x};
elseif isstring(x)
    c = cellstr(x(:));
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
    c = cellstr(x(:));
elseif iscell(x)
    c = cellfun(@char, x, 'UniformOutput', false);
else
    c = cellstr(string(x));
end
end

function M = local_parse_matrix(txt)
if isempty(txt)
    M = [];
    return;
end
if isnumeric(txt)
    M = txt;
    return;
end
s = local_text_to_string(txt);
M = str2num(s); %#ok<ST2NM>
if isempty(M) && ~isempty(strtrim(s))
    % Fallback parser: tolerate comma/semicolon separated rows.
    s2 = regexprep(s, '[,;]+', ' ');
    rows = regexp(s2, '\r\n|\n|\r', 'split');
    vals = {};
    for i = 1:numel(rows)
        r = strtrim(rows{i});
        if isempty(r), continue; end
        nums = sscanf(r, '%f').';
        if ~isempty(nums), vals{end+1} = nums; end %#ok<AGROW>
    end
    if ~isempty(vals)
        n = max(cellfun(@numel, vals));
        M = NaN(numel(vals), n);
        for i = 1:numel(vals)
            M(i,1:numel(vals{i})) = vals{i};
        end
    else
        error('Could not parse numeric matrix.');
    end
end
end

function v = local_parse_vector(txt)
M = local_parse_matrix(txt);
v = M(:).';
end

function v = local_parse_range(txt)
s = strtrim(local_text_to_string(txt));
if isempty(s)
    v = [];
elseif contains(s, ':')
    parts = regexp(s, ':', 'split');
    nums = str2double(parts);
    if any(~isfinite(nums))
        error('Invalid range: %s', s);
    end
    if numel(nums) == 2
        v = nums(1):nums(2);
    elseif numel(nums) == 3
        v = nums(1):nums(2):nums(3);
    else
        error('Invalid range: %s', s);
    end
else
    v = sscanf(strrep(s, ',', ' '), '%f').';
end
end

function tuples = local_parse_parameter_tuples(txt, ncols, default_text)
if nargin < 2 || isempty(ncols), ncols = 1; end
if nargin < 3, default_text = ''; end
s = strtrim(local_text_to_string(txt));
if isempty(s)
    s = strtrim(local_text_to_string(default_text));
end
if isempty(s)
    tuples = zeros(0, ncols);
    return;
end

groups = local_tuple_groups(s);
if isempty(groups)
    A = local_parse_matrix(s);
    if size(A,2) ~= ncols
        error('Expected %d columns.', ncols);
    end
    tuples = A;
    return;
end

tuples = zeros(0, ncols);
for i = 1:numel(groups)
    if ncols == 1
        cols = {groups{i}};
    else
        cols = local_split_top_level(groups{i});
    end
    if numel(cols) ~= ncols
        error('Expected %d entries per tuple.', ncols);
    end
    values = cell(1, ncols);
    for j = 1:ncols
        values{j} = local_parse_tuple_component(cols{j});
    end
    rows = local_cartesian_rows(values);
    tuples = [tuples; rows]; %#ok<AGROW>
end
end

function groups = local_tuple_groups(s)
groups = {};
s = strtrim(s);
if isempty(s), return; end
depth = 0;
start_idx = 0;
for ii = 1:numel(s)
    ch = s(ii);
    if ch == '('
        if depth == 0
            start_idx = ii + 1;
        end
        depth = depth + 1;
    elseif ch == ')'
        depth = depth - 1;
        if depth == 0 && start_idx > 0
            groups{end+1} = strtrim(s(start_idx:ii-1)); %#ok<AGROW>
            start_idx = 0;
        elseif depth < 0
            error('Unbalanced tuple parentheses.');
        end
    end
end
if depth ~= 0
    error('Unbalanced tuple parentheses.');
end
if isempty(groups) && ~contains(s, '(') && ~contains(s, ')')
    groups = {s};
end
end

function parts = local_split_top_level(s)
parts = {};
depth = 0;
last = 1;
for ii = 1:numel(s)
    ch = s(ii);
    if ch == '('
        depth = depth + 1;
    elseif ch == ')'
        depth = depth - 1;
    elseif (ch == ',' || ch == ';') && depth == 0
        parts{end+1} = strtrim(s(last:ii-1)); %#ok<AGROW>
        last = ii + 1;
    end
end
parts{end+1} = strtrim(s(last:end));
parts = parts(~cellfun(@isempty, parts));
end

function vals = local_parse_tuple_component(s)
s = strtrim(s);
if startsWith(s, '(') && endsWith(s, ')')
    s = strtrim(s(2:end-1));
end
if isempty(s)
    vals = NaN;
    return;
end
vals = str2num(s); %#ok<ST2NM>
if isempty(vals)
    vals = sscanf(regexprep(s, '[,;]+', ' '), '%f').';
end
if isempty(vals)
    error('Could not parse tuple component: %s', s);
end
vals = vals(:).';
end

function rows = local_cartesian_rows(values)
ncols = numel(values);
rows = values{1}(:);
for j = 2:ncols
    a = rows;
    b = values{j}(:);
    rows = [repelem(a, numel(b), 1), repmat(b, size(a,1), 1)]; %#ok<AGROW>
end
if ncols == 1
    rows = rows(:);
end
end

function txt = local_parse_scan(kind)
switch lower(char(string(kind)))
    case {'single','one'}
        txt = '(1)';
    case {'pair','two'}
        txt = '(1,1)';
    case {'triple','three'}
        txt = '(1,1,1)';
    otherwise
        txt = '';
end
end

function txt = local_default_tuple(defaults)
%LOCAL_DEFAULT_TUPLE Convert catalog defaults into the tuple syntax shown in scans.
% Examples: {'0:5'} -> '(0:5)', {'0.2','0.5'} -> '(0.2,0.5)'.
if nargin < 1 || isempty(defaults)
    txt = '';
    return;
end
if iscell(defaults)
    parts = cellfun(@local_text_to_string, defaults(:).', 'UniformOutput', false);
    parts = parts(~cellfun(@(s) isempty(strtrim(s)), parts));
    if isempty(parts)
        txt = '';
    else
        txt = ['(' strjoin(parts, ',') ')'];
    end
elseif isstring(defaults) && numel(defaults) > 1
    parts = cellstr(defaults(:).');
    txt = ['(' strjoin(parts, ',') ')'];
else
    s = strtrim(local_text_to_string(defaults));
    if isempty(s)
        txt = '';
    elseif startsWith(s, '(') && endsWith(s, ')')
        txt = s;
    elseif any(strcmpi(s, {'single','one','pair','two','triple','three'}))
        txt = local_parse_scan(s);
    else
        txt = ['(' s ')'];
    end
end
end

function s = local_text_to_string(txt)
if iscell(txt)
    s = strjoin(cellfun(@char, txt(:), 'UniformOutput', false), newline);
elseif isstring(txt)
    s = strjoin(cellstr(txt(:)), newline);
elseif isnumeric(txt)
    s = num2str(txt);
else
    s = char(string(txt));
end
end
