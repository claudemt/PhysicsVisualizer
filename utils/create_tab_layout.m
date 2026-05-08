function ui = create_tab_layout(tab_group, tab_title, project_root, varargin)
p = inputParser;
p.addParameter('ControlWidth', 420);
p.addParameter('Preview', 'list');
p.addParameter('PreviewGridSize', [1 1]);
p.addParameter('PreviewAxesNames', {});
p.addParameter('PreviewPadding', [6 6 6 6]);
p.addParameter('PreviewSpacing', 6);
p.addParameter('PreviewListWidth', 300);
p.addParameter('NotesTitle', 'notes');
p.addParameter('NotesText', '');
p.addParameter('NotesFile', '');
p.addParameter('NotesFunction', '');
p.addParameter('NotesHeight', 180);
p.addParameter('InitialMessage', 'run to generate result');
p.parse(varargin{:});
opt = p.Results;

tab = uitab(tab_group, 'Title', tab_title);
root = uigridlayout(tab, [1 2]);
root.ColumnWidth = {opt.ControlWidth, '1x'};
root.RowHeight = {'1x'};
root.Padding = [8 8 8 8];
root.ColumnSpacing = 10;

control_panel = uipanel(root, 'Title', 'controls');
control_panel.Layout.Row = 1;
control_panel.Layout.Column = 1;

control_grid = uigridlayout(control_panel, [1 1]);
control_grid.RowHeight = {'1x'};
control_grid.ColumnWidth = {'1x'};
control_grid.Padding = [8 8 8 8];
control_grid.RowSpacing = 8;

right_grid = uigridlayout(root, [2 1]);
right_grid.Layout.Row = 1;
right_grid.Layout.Column = 2;
right_grid.RowHeight = {'1x', opt.NotesHeight};
right_grid.ColumnWidth = {'1x'};
right_grid.Padding = [0 0 0 0];
right_grid.RowSpacing = 8;

preview_panel = uipanel(right_grid, 'Title', 'preview');
preview_panel.Layout.Row = 1;
preview_panel.Layout.Column = 1;

preview_mode = lower(char(string(opt.Preview)));
preview_grid = [];
preview_axes_grid = [];
preview_empty_label = [];
preview_list = [];
preview_axes = [];
preview_text = [];
preview_toolbar = [];
preview_layout_edit = [];
preview_layout_field = [];
preview_layout_label = [];
preview_list_panel = [];
preview_list_grid = [];
preview_all_button = [];
preview_none_button = [];
preview_up_button = [];
preview_down_button = [];
preview_composite_button = [];

switch preview_mode
    case {'list','images','multi'}
        preview_grid = uigridlayout(preview_panel, [1 2]);
        preview_grid.Padding = [6 6 6 6];
        preview_grid.RowHeight = {'1x'};
        preview_grid.ColumnWidth = {opt.PreviewListWidth, '1x'};
        preview_grid.RowSpacing = 0;
        preview_grid.ColumnSpacing = 8;

        preview_list_panel = uipanel(preview_grid, 'Title', 'images');
        preview_list_panel.Layout.Row = 1;
        preview_list_panel.Layout.Column = 1;

        preview_list_grid = uigridlayout(preview_list_panel, [3 1]);
        preview_list_grid.RowHeight = {'1x', 28, 28};
        preview_list_grid.ColumnWidth = {'1x'};
        preview_list_grid.Padding = [6 6 6 6];
        preview_list_grid.RowSpacing = 6;
        preview_list_grid.ColumnSpacing = 0;
        preview_toolbar = preview_list_grid;

        preview_list = uilistbox(preview_list_grid, 'Multiselect', 'on');
        preview_list.Layout.Row = 1;
        preview_list.Layout.Column = 1;

        order_grid = uigridlayout(preview_list_grid, [1 4]);
        order_grid.Layout.Row = 2;
        order_grid.Layout.Column = 1;
        order_grid.RowHeight = {24};
        order_grid.ColumnWidth = {'1x','1x','1x','1x'};
        order_grid.Padding = [0 0 0 0];
        order_grid.ColumnSpacing = 4;
        order_grid.RowSpacing = 0;

        preview_up_button = uibutton(order_grid, 'push', 'Text', 'Up');
        preview_up_button.Layout.Row = 1;
        preview_up_button.Layout.Column = 1;
        preview_down_button = uibutton(order_grid, 'push', 'Text', 'Down');
        preview_down_button.Layout.Row = 1;
        preview_down_button.Layout.Column = 2;
        preview_all_button = uibutton(order_grid, 'push', 'Text', 'All');
        preview_all_button.Layout.Row = 1;
        preview_all_button.Layout.Column = 3;
        preview_none_button = uibutton(order_grid, 'push', 'Text', 'None');
        preview_none_button.Layout.Row = 1;
        preview_none_button.Layout.Column = 4;

        compose_grid = uigridlayout(preview_list_grid, [1 3]);
        compose_grid.Layout.Row = 3;
        compose_grid.Layout.Column = 1;
        compose_grid.RowHeight = {24};
        compose_grid.ColumnWidth = {45, '1x', 86};
        compose_grid.Padding = [0 0 0 0];
        compose_grid.ColumnSpacing = 4;
        compose_grid.RowSpacing = 0;

        preview_layout_label = uilabel(compose_grid, 'Text', 'layout', 'HorizontalAlignment', 'left');
        preview_layout_label.Layout.Row = 1;
        preview_layout_label.Layout.Column = 1;
        preview_layout_edit = uieditfield(compose_grid, 'text', 'Value', 'auto', 'HorizontalAlignment', 'center');
        preview_layout_edit.Layout.Row = 1;
        preview_layout_edit.Layout.Column = 2;
        preview_layout_field = preview_layout_edit;
        preview_composite_button = uibutton(compose_grid, 'push', 'Text', 'Preview');
        try, preview_composite_button.Tooltip = 'Compose the selected preview images into the right-hand canvas.'; catch, end
        preview_composite_button.Layout.Row = 1;
        preview_composite_button.Layout.Column = 3;

        preview_axes = uiaxes(preview_grid);
        preview_axes.Layout.Row = 1;
        preview_axes.Layout.Column = 2;
        image_output('reset_preview', preview_axes, opt.InitialMessage);

        preview_all_button.ButtonPushedFcn = @(~,~) image_output('select_all', preview_list);
        preview_none_button.ButtonPushedFcn = @(~,~) image_output('select_none', preview_list);
        preview_up_button.ButtonPushedFcn = @(~,~) image_output('move_selection', preview_list, -1);
        preview_down_button.ButtonPushedFcn = @(~,~) image_output('move_selection', preview_list, 1);
        preview_composite_button.ButtonPushedFcn = @(~,~) image_output('preview_composite', preview_axes, preview_list, project_root, tab_title, preview_layout_edit.Value);
    case {'axesgrid','grid','multi_axes','multiaxes'}
        sz = opt.PreviewGridSize;
        if isempty(sz) || numel(sz) ~= 2
            sz = [1 1];
        end
        nrows = max(1, round(sz(1)));
        ncols = max(1, round(sz(2)));
        preview_grid = uigridlayout(preview_panel, [1 1]);
        preview_grid.Padding = [0 0 0 0];
        preview_grid.RowHeight = {'1x'};
        preview_grid.ColumnWidth = {'1x'};
        preview_grid.RowSpacing = 0;
        preview_grid.ColumnSpacing = 0;

        preview_axes_grid = uigridlayout(preview_grid, [nrows ncols]);
        preview_axes_grid.Layout.Row = 1;
        preview_axes_grid.Layout.Column = 1;
        preview_axes_grid.RowHeight = repmat({'1x'}, 1, nrows);
        preview_axes_grid.ColumnWidth = repmat({'1x'}, 1, ncols);
        preview_axes_grid.Padding = opt.PreviewPadding;
        preview_axes_grid.RowSpacing = opt.PreviewSpacing;
        preview_axes_grid.ColumnSpacing = opt.PreviewSpacing;

        preview_axes = gobjects(1, nrows*ncols);
        for k = 1:numel(preview_axes)
            r = ceil(k / ncols);
            c = k - (r-1) * ncols;
            preview_axes(k) = uiaxes(preview_axes_grid);
            preview_axes(k).Layout.Row = r;
            preview_axes(k).Layout.Column = c;
            apply_tex_style(preview_axes(k), 'FontSize', 12, 'TitleFontSize', 14, 'Box', 'on');
        end

        preview_empty_label = uilabel(preview_grid, ...
            'Text', char(string(opt.InitialMessage)), ...
            'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'center', ...
            'FontSize', 12, ...
            'FontColor', [0.35 0.35 0.35]);
        preview_empty_label.Layout.Row = 1;
        preview_empty_label.Layout.Column = 1;
        preview_grid.UserData = struct('empty_label', preview_empty_label, 'axes_grid', preview_axes_grid);
        image_output('reset_preview_group', preview_grid, preview_axes, opt.InitialMessage);
    case {'single','axis','axes'}
        preview_grid = uigridlayout(preview_panel, [1 1]);
        preview_grid.Padding = opt.PreviewPadding;
        preview_grid.RowHeight = {'1x'};
        preview_grid.ColumnWidth = {'1x'};
        preview_grid.RowSpacing = 0;
        preview_grid.ColumnSpacing = 0;
        preview_axes = uiaxes(preview_grid);
        preview_axes.Layout.Row = 1;
        preview_axes.Layout.Column = 1;
        image_output('reset_preview', preview_axes, opt.InitialMessage);
    case {'text','report'}
        preview_grid = uigridlayout(preview_panel, [1 1]);
        preview_grid.Padding = [6 6 6 6];
        preview_grid.RowHeight = {'1x'};
        preview_grid.ColumnWidth = {'1x'};
        preview_text = uitextarea(preview_grid, 'Editable', 'off', 'FontName', 'Courier New');
        preview_text.Layout.Row = 1;
        preview_text.Layout.Column = 1;
        preview_text.Value = splitlines(char(string(opt.InitialMessage)));
    otherwise
        preview_grid = uigridlayout(preview_panel, [1 1]);
        preview_grid.Padding = [6 6 6 6];
        preview_grid.RowHeight = {'1x'};
        preview_grid.ColumnWidth = {'1x'};
        preview_axes = uiaxes(preview_grid);
        preview_axes.Layout.Row = 1;
        preview_axes.Layout.Column = 1;
        image_output('reset_preview', preview_axes, opt.InitialMessage);
end

notes_panel = uipanel(right_grid, 'Title', opt.NotesTitle);
notes_panel.Layout.Row = 2;
notes_panel.Layout.Column = 1;
notes_grid = uigridlayout(notes_panel, [1 2]);
notes_grid.RowHeight = {'1x'};
notes_grid.ColumnWidth = {'1x', 112};
notes_grid.Padding = [6 6 6 6];
notes_grid.ColumnSpacing = 8;
notes_grid.RowSpacing = 0;

notes_title = [];

notes_area = uitextarea(notes_grid, 'Editable', 'off');
notes_area.Layout.Row = 1;
notes_area.Layout.Column = 1;

notes_button = uibutton(notes_grid, 'push', 'Text', 'Notes');
notes_button.Layout.Row = 1;
notes_button.Layout.Column = 2;
try, notes_button.Tooltip = 'Open the full Markdown formula notes in a browser.'; catch, end

short_notes = local_short_notes(opt.NotesText);
long_notes = local_long_notes(short_notes, opt.NotesFile, opt.NotesFunction);
local_set_notes(notes_area, short_notes);
notes_button.ButtonPushedFcn = @(~,~) local_render_notes_browser(project_root, long_notes, tab_title);

ui = struct();
ui.tab = tab;
ui.root = root;
ui.control_panel = control_panel;
ui.control_grid = control_grid;
ui.preview_panel = preview_panel;
ui.preview_grid = preview_grid;
ui.preview_axes_grid = preview_axes_grid;
ui.preview_empty_label = preview_empty_label;
ui.preview_list = preview_list;
ui.preview_axes = preview_axes;
ui.preview_text = preview_text;
ui.preview_toolbar = preview_toolbar;
ui.preview_layout_edit = preview_layout_edit;
ui.preview_layout_field = preview_layout_field;
ui.preview_layout_label = preview_layout_label;
ui.preview_list_panel = preview_list_panel;
ui.preview_list_grid = preview_list_grid;
ui.preview_all_button = preview_all_button;
ui.preview_none_button = preview_none_button;
ui.preview_up_button = preview_up_button;
ui.preview_down_button = preview_down_button;
ui.preview_composite_button = preview_composite_button;
ui.notes_panel = notes_panel;
ui.notes_area = notes_area;
ui.notes_button = notes_button;
ui.set_notes = @(txt) local_set_notes(notes_area, txt);
ui.project_root = project_root;
ui.title = tab_title;
end

function txt = local_short_notes(txt0)
if isempty(txt0)
    txt = 'Select parameters on the left, then click Generate. Click Notes for the full Markdown formula notes.';
elseif isstruct(txt0)
    if isfield(txt0, 'Summary')
        txt = local_notes_value_to_text(txt0.Summary);
    elseif isfield(txt0, 'Text')
        txt = local_notes_value_to_text(txt0.Text);
    else
        names = fieldnames(txt0);
        lines = cell(1, numel(names));
        for i = 1:numel(names)
            v = txt0.(names{i});
            lines{i} = sprintf('%s: %s', names{i}, local_notes_value_to_text(v));
        end
        txt = strjoin(lines, newline);
    end
elseif iscell(txt0)
    txt = strjoin(cellfun(@local_notes_value_to_text, txt0(:), 'UniformOutput', false), newline);
else
    txt = char(string(txt0));
end
txt = local_plain_notes(txt);
end

function txt = local_notes_value_to_text(v)
if isempty(v)
    txt = '';
elseif iscell(v)
    parts = cellfun(@local_notes_value_to_text, v(:), 'UniformOutput', false);
    txt = strjoin(parts, newline);
elseif isstruct(v)
    if isfield(v, 'Summary')
        txt = local_notes_value_to_text(v.Summary);
    elseif isfield(v, 'Text')
        txt = local_notes_value_to_text(v.Text);
    else
        names = fieldnames(v);
        parts = cell(1, numel(names));
        for i = 1:numel(names)
            parts{i} = sprintf('%s: %s', names{i}, local_notes_value_to_text(v.(names{i})));
        end
        txt = strjoin(parts, newline);
    end
elseif isstring(v)
    txt = char(join(v(:), newline));
elseif ischar(v)
    txt = v;
elseif isnumeric(v) || islogical(v)
    txt = mat2str(v);
else
    try
        txt = char(string(v));
    catch
        txt = '<unrenderable notes>';
    end
end
end

function txt = local_plain_notes(txt)
if isempty(txt)
    txt = '';
    return;
end
lines = splitlines(char(string(txt)));
for i = 1:numel(lines)
    line = char(lines(i));
    line = regexprep(line, '^\s*#{1,6}\s*', '');
    line = regexprep(line, '^\s*[-*+]\s+', '- ');
    line = strrep(line, '**', '');
    line = strrep(line, '__', '');
    line = strrep(line, '`', '');
    lines{i} = line;
end
txt = strjoin(lines, newline);
end

function txt = local_long_notes(fallback, file0, fcn)
txt = '';
if ~isempty(file0)
    file0 = char(string(file0));
    if exist(file0, 'file') == 2
        txt = fileread(file0);
    end
end
if isempty(txt) && ~isempty(fcn)
    try
        if isa(fcn, 'function_handle')
            raw = fcn();
        else
            raw = feval(char(string(fcn)));
        end
        if iscell(raw)
            txt = strjoin(raw(:), newline);
        else
            txt = char(string(raw));
        end
    catch ME
        txt = sprintf('Could not load notes: %s', ME.message);
    end
end
if isempty(txt)
    txt = fallback;
end
end

function local_set_notes(notes_area, txt)
if isempty(txt)
    txt = '';
end
if iscell(txt)
    lines = txt(:);
else
    lines = splitlines(char(string(txt)));
end
notes_area.Value = lines;
end

function local_render_notes_browser(project_root, txt, title_text)
cache_dir = fullfile(project_root, '.cache', 'notes');
if exist(cache_dir, 'dir') ~= 7
    mkdir(cache_dir);
end
slug = regexprep(lower(char(string(title_text))), '[^a-z0-9]+', '_');
html_path = fullfile(cache_dir, [slug '_notes.html']);
html = local_markdown_html(txt, title_text);
fid = fopen(html_path, 'w');
if fid == -1
    error('Could not write notes html file.');
end
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, '%s', html);
clear cleanup
web(html_path, '-browser');
end

function html = local_markdown_html(md, title_text)
body = local_markdown_to_html(md);
title_safe = local_html_escape(char(string(title_text)));
html = ['<!doctype html><html><head><meta charset="utf-8">' newline ...
    '<title>' title_safe '</title>' newline ...
    '<script>' newline ...
    'window.MathJax={tex:{inlineMath:[["$","$"],["\\(","\\)"]],displayMath:[["$$","$$"],["\\[","\\]"]]},svg:{fontCache:"global"}};' newline ...
    '</script>' newline ...
    '<script src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-svg.js"></script>' newline ...
    '<style>' newline ...
    'body{font-family:Times New Roman,Georgia,serif;max-width:980px;margin:38px auto;padding:0 28px;line-height:1.62;color:#1f2933;background:#fff;}' newline ...
    'h1,h2,h3{line-height:1.25;margin-top:1.4em;border-bottom:1px solid #e5e7eb;padding-bottom:.25em;}' newline ...
    'code,pre{font-family:Consolas,Menlo,monospace;background:#f6f8fa;border-radius:6px;}' newline ...
    'pre{padding:12px;overflow:auto;} code{padding:2px 4px;}' newline ...
    'table{border-collapse:collapse;margin:1em 0;min-width:55%;} th,td{border:1px solid #d0d7de;padding:6px 10px;vertical-align:top;} th{background:#f6f8fa;} blockquote{border-left:4px solid #d0d7de;margin-left:0;padding-left:1em;color:#57606a;}' newline ...
    '</style></head><body>' newline ...
    body newline ...
    '</body></html>'];
end

function html = local_markdown_to_html(md)
lines = splitlines(char(md));
html_lines = {};
in_code = false;
para = {};
in_ul = false;
skip_until = 0;

for i = 1:numel(lines)
    if i <= skip_until
        continue;
    end
    line = char(lines(i));
    if startsWith(strtrim(line), '```')
        if ~isempty(para)
            html_lines{end+1} = ['<p>' local_inline_markdown(strjoin(para, ' ')) '</p>']; %#ok<AGROW>
            para = {};
        end
        if in_ul
            html_lines{end+1} = '</ul>'; %#ok<AGROW>
            in_ul = false;
        end
        if ~in_code
            html_lines{end+1} = '<pre><code>'; %#ok<AGROW>
            in_code = true;
        else
            html_lines{end+1} = '</code></pre>'; %#ok<AGROW>
            in_code = false;
        end
        continue;
    end

    if in_code
        html_lines{end+1} = local_html_escape(line); %#ok<AGROW>
        continue;
    end

    s = strtrim(line);
    if startsWith(s, '<!--') && endsWith(s, '-->')
        continue;
    end
    if isempty(s)
        if ~isempty(para)
            html_lines{end+1} = ['<p>' local_inline_markdown(strjoin(para, ' ')) '</p>']; %#ok<AGROW>
            para = {};
        end
        if in_ul
            html_lines{end+1} = '</ul>'; %#ok<AGROW>
            in_ul = false;
        end
        continue;
    end

    if i < numel(lines) && local_is_table_separator(char(lines(i+1))) && contains(s, '|')
        if ~isempty(para)
            html_lines{end+1} = ['<p>' local_inline_markdown(strjoin(para, ' ')) '</p>']; %#ok<AGROW>
            para = {};
        end
        if in_ul
            html_lines{end+1} = '</ul>'; %#ok<AGROW>
            in_ul = false;
        end
        j = i + 2;
        while j <= numel(lines)
            row_text = strtrim(char(lines(j)));
            if isempty(row_text) || ~contains(row_text, '|')
                break;
            end
            j = j + 1;
        end
        html_lines{end+1} = local_table_to_html(lines(i:j-1)); %#ok<AGROW>
        skip_until = j - 1;
        continue;
    end

    h = regexp(s, '^(#{1,4})\s+(.*)$', 'tokens', 'once');
    if ~isempty(h)
        if ~isempty(para)
            html_lines{end+1} = ['<p>' local_inline_markdown(strjoin(para, ' ')) '</p>']; %#ok<AGROW>
            para = {};
        end
        if in_ul
            html_lines{end+1} = '</ul>'; %#ok<AGROW>
            in_ul = false;
        end
        level = numel(h{1});
        html_lines{end+1} = sprintf('<h%d>%s</h%d>', level, local_inline_markdown(h{2}), level); %#ok<AGROW>
        continue;
    end

    if startsWith(s, '- ')
        if ~isempty(para)
            html_lines{end+1} = ['<p>' local_inline_markdown(strjoin(para, ' ')) '</p>']; %#ok<AGROW>
            para = {};
        end
        if ~in_ul
            html_lines{end+1} = '<ul>'; %#ok<AGROW>
            in_ul = true;
        end
        html_lines{end+1} = ['<li>' local_inline_markdown(extractAfter(s, 2)) '</li>']; %#ok<AGROW>
        continue;
    end

    para{end+1} = s; %#ok<AGROW>
end

if ~isempty(para)
    html_lines{end+1} = ['<p>' local_inline_markdown(strjoin(para, ' ')) '</p>'];
end
if in_ul
    html_lines{end+1} = '</ul>';
end
if in_code
    html_lines{end+1} = '</code></pre>';
end
html = strjoin(html_lines, newline);
end


function tf = local_is_table_separator(line)
s = strtrim(char(line));
if ~contains(s, '|')
    tf = false;
    return;
end
cells = local_split_table_row(s);
if isempty(cells)
    tf = false;
    return;
end
tf = true;
for ii = 1:numel(cells)
    c = strtrim(cells{ii});
    if isempty(regexp(c, '^:?-{3,}:?$', 'once'))
        tf = false;
        return;
    end
end
end

function html = local_table_to_html(table_lines)
header = local_split_table_row(char(table_lines(1)));
sep = local_split_table_row(char(table_lines(2)));
cols = min(numel(header), numel(sep));
if cols == 0
    html = '';
    return;
end
align = cell(1, cols);
for c = 1:cols
    token = strtrim(sep{c});
    if startsWith(token, ':') && endsWith(token, ':')
        align{c} = 'center';
    elseif endsWith(token, ':')
        align{c} = 'right';
    else
        align{c} = 'left';
    end
end
parts = {'<table><thead><tr>'};
for c = 1:cols
    parts{end+1} = sprintf('<th style="text-align:%s">%s</th>', align{c}, local_inline_markdown(strtrim(header{c}))); %#ok<AGROW>
end
parts{end+1} = '</tr></thead><tbody>';
for r = 3:numel(table_lines)
    row = local_split_table_row(char(table_lines(r)));
    if isempty(row), continue; end
    parts{end+1} = '<tr>'; %#ok<AGROW>
    for c = 1:cols
        cell_text = '';
        if c <= numel(row)
            cell_text = strtrim(row{c});
        end
        parts{end+1} = sprintf('<td style="text-align:%s">%s</td>', align{c}, local_inline_markdown(cell_text)); %#ok<AGROW>
    end
    parts{end+1} = '</tr>'; %#ok<AGROW>
end
parts{end+1} = '</tbody></table>';
html = strjoin(parts, newline);
end

function cells = local_split_table_row(line)
s = strtrim(char(line));
if startsWith(s, '|')
    s = s(2:end);
end
if endsWith(s, '|')
    s = s(1:end-1);
end
raw = regexp(char(s), '\|', 'split');
cells = cellfun(@strtrim, raw, 'UniformOutput', false);
end

function out = local_inline_markdown(s)
out = local_html_escape(char(s));
out = regexprep(out, '\*\*(.*?)\*\*', '<strong>$1</strong>');
out = regexprep(out, '`([^`]+)`', '<code>$1</code>');
end

function out = local_html_escape(s)
out = strrep(s, '&', '&amp;');
out = strrep(out, '<', '&lt;');
out = strrep(out, '>', '&gt;');
out = strrep(out, '"', '&quot;');
end
