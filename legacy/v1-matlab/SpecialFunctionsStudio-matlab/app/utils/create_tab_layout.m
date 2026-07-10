function ui = create_tab_layout(tab_group, tab_title, project_root, varargin)
if nargin < 3 || isempty(project_root)
    project_root = pwd;
end
p = inputParser;
p.addParameter('ControlWidth', 390);
p.addParameter('NotesHeight', 180);
p.addParameter('Padding', [8 8 8 8]);
p.addParameter('Spacing', 10);
p.addParameter('HasPreviewList', false);
p.addParameter('PreviewListWidth', 300);
p.addParameter('PreviewListMultiSelect', true);
p.addParameter('NotesKey', '');
p.addParameter('NotesSummaryFile', '');
p.addParameter('NotesMarkdownFile', '');
p.addParameter('NotesButtonText', 'Notes');
p.addParameter('NotesTitle', 'notes');
p.addParameter('PreviewTitle', 'preview');
p.addParameter('ControlTitle', 'controls');
p.addParameter('InitialPreviewText', '');
p.parse(varargin{:});
opt = p.Results;

ui = struct();
ui.project_root = project_root;
ui.tab_title = char(tab_title);
ui.app_figure = ancestor(tab_group, 'figure');
ui.tab = uitab(tab_group, 'Title', char(tab_title));

root = uigridlayout(ui.tab, [1 2]);
root.ColumnWidth = {opt.ControlWidth, '1x'};
root.RowHeight = {'1x'};
root.Padding = opt.Padding;
root.ColumnSpacing = opt.Spacing;
root.RowSpacing = 0;
ui.root_grid = root;

ui.control_panel = uipanel(root, 'Title', opt.ControlTitle);
ui.control_panel.Layout.Row = 1;
ui.control_panel.Layout.Column = 1;
ui.control_grid = uigridlayout(ui.control_panel, [1 1]);
ui.control_grid.RowHeight = {'1x'};
ui.control_grid.ColumnWidth = {'1x'};
ui.control_grid.Padding = [8 8 8 8];
ui.control_grid.RowSpacing = 8;
ui.control_grid.ColumnSpacing = 0;

right = uigridlayout(root, [2 1]);
right.Layout.Row = 1;
right.Layout.Column = 2;
right.RowHeight = {'1x', opt.NotesHeight};
right.ColumnWidth = {'1x'};
right.Padding = [0 0 0 0];
right.RowSpacing = 8;
right.ColumnSpacing = 0;
ui.right_grid = right;

ui.preview_panel = uipanel(right, 'Title', opt.PreviewTitle);
ui.preview_panel.Layout.Row = 1;
ui.preview_panel.Layout.Column = 1;

if opt.HasPreviewList
    preview_grid = uigridlayout(ui.preview_panel, [1 2]);
    preview_grid.ColumnWidth = {opt.PreviewListWidth, '1x'};
    preview_grid.RowHeight = {'1x'};
    preview_grid.Padding = [6 6 6 6];
    preview_grid.ColumnSpacing = 8;
    preview_grid.RowSpacing = 0;
    ui.preview_grid = preview_grid;

    list_panel = uipanel(preview_grid, 'Title', 'images');
    list_panel.Layout.Row = 1;
    list_panel.Layout.Column = 1;

    list_grid = uigridlayout(list_panel, [3 1]);
    list_grid.RowHeight = {'1x', 28, 28};
    list_grid.ColumnWidth = {'1x'};
    list_grid.Padding = [6 6 6 6];
    list_grid.RowSpacing = 6;
    list_grid.ColumnSpacing = 0;
    ui.preview_list_panel = list_panel;
    ui.preview_list_grid = list_grid;

    ui.preview_list = uilistbox(list_grid);
    ui.preview_list.Layout.Row = 1;
    ui.preview_list.Layout.Column = 1;
    if opt.PreviewListMultiSelect
        ui.preview_list.Multiselect = 'on';
    else
        ui.preview_list.Multiselect = 'off';
    end
    ui.preview_list.Items = {};
    ui.preview_list.UserData = struct('paths', {{}}, 'labels', {{}}, 'force_empty', false);

    order_grid = uigridlayout(list_grid, [1 4]);
    order_grid.Layout.Row = 2;
    order_grid.Layout.Column = 1;
    order_grid.ColumnWidth = {'1x','1x','1x','1x'};
    order_grid.RowHeight = {24};
    order_grid.Padding = [0 0 0 0];
    order_grid.ColumnSpacing = 4;
    order_grid.RowSpacing = 0;
    ui.preview_up_button = uibutton(order_grid, 'push', 'Text', 'Up');
    ui.preview_down_button = uibutton(order_grid, 'push', 'Text', 'Down');
    ui.preview_all_button = uibutton(order_grid, 'push', 'Text', 'All');
    ui.preview_none_button = uibutton(order_grid, 'push', 'Text', 'None');

    compose_grid = uigridlayout(list_grid, [1 3]);
    compose_grid.Layout.Row = 3;
    compose_grid.Layout.Column = 1;
    compose_grid.ColumnWidth = {45, '1x', 86};
    compose_grid.RowHeight = {24};
    compose_grid.Padding = [0 0 0 0];
    compose_grid.ColumnSpacing = 4;
    compose_grid.RowSpacing = 0;
    ui.preview_layout_label = uilabel(compose_grid, 'Text', 'layout', 'HorizontalAlignment', 'left');
    ui.preview_layout_field = uieditfield(compose_grid, 'text', 'Value', '4', 'HorizontalAlignment', 'center');
    ui.preview_composite_button = uibutton(compose_grid, 'push', 'Text', 'Preview');

    ui.preview_axes = uiaxes(preview_grid);
    ui.preview_axes.Layout.Row = 1;
    ui.preview_axes.Layout.Column = 2;
else
    ui.preview_grid = uigridlayout(ui.preview_panel, [1 1]);
    ui.preview_grid.RowHeight = {'1x'};
    ui.preview_grid.ColumnWidth = {'1x'};
    ui.preview_grid.Padding = [6 6 6 6];
    ui.preview_grid.RowSpacing = 0;
    ui.preview_grid.ColumnSpacing = 0;
    ui.preview_axes = uiaxes(ui.preview_grid);
    ui.preview_axes.Layout.Row = 1;
    ui.preview_axes.Layout.Column = 1;
    ui.preview_list = [];
    ui.preview_up_button = [];
    ui.preview_down_button = [];
    ui.preview_all_button = [];
    ui.preview_none_button = [];
    ui.preview_layout_field = [];
    ui.preview_composite_button = [];
end

local_reset_preview(ui.preview_axes, opt.InitialPreviewText);

ui.notes_panel = uipanel(right, 'Title', opt.NotesTitle);
ui.notes_panel.Layout.Row = 2;
ui.notes_panel.Layout.Column = 1;
notes_grid = uigridlayout(ui.notes_panel, [1 2]);
notes_grid.ColumnWidth = {'1x', 90};
notes_grid.RowHeight = {'1x'};
notes_grid.Padding = [6 6 6 6];
notes_grid.ColumnSpacing = 6;
notes_grid.RowSpacing = 0;
ui.notes_grid = notes_grid;
ui.notes_text = uitextarea(notes_grid, 'Editable', 'off');
ui.notes_text.Layout.Row = 1;
ui.notes_text.Layout.Column = 1;
ui.notes_text.Value = local_read_summary(project_root, tab_title, opt);
ui.notes_button = uibutton(notes_grid, 'push', 'Text', opt.NotesButtonText);
ui.notes_button.Layout.Row = 1;
ui.notes_button.Layout.Column = 2;
ui.notes_button.ButtonPushedFcn = @(~,~) local_open_notes(project_root, tab_title, opt, ui.app_figure);
end

function local_reset_preview(ax, msg)
try
    cla(ax);
    apply_tex_style(ax, 'Title', msg, 'AxisMode', 'image');
    ax.XTick = [];
    ax.YTick = [];
    if ~isempty(msg)
        text(ax, 0.5, 0.5, apply_tex_style('text', msg), 'Interpreter', 'latex', 'HorizontalAlignment', 'center');
        ax.XLim = [0 1];
        ax.YLim = [0 1];
    end
catch
end
end

function lines = local_read_summary(project_root, tab_title, opt)
summary_file = char(opt.NotesSummaryFile);
if isempty(summary_file)
    key = char(opt.NotesKey);
    if isempty(key)
        key = local_key(tab_title);
    end
    summary_file = fullfile(project_root, 'docs', [key '_summary.txt']);
end
if exist(summary_file, 'file') == 2
    txt = fileread(summary_file);
    lines = regexp(strrep(txt, sprintf('\r\n'), sprintf('\n')), sprintf('\n'), 'split');
else
    lines = {''};
end
end

function local_open_notes(project_root, tab_title, opt, parent_fig)
md_file = char(opt.NotesMarkdownFile);
if isempty(md_file)
    key = char(opt.NotesKey);
    if isempty(key)
        key = local_key(tab_title);
    end
    md_file = fullfile(project_root, 'docs', [key '_notes.md']);
end
if exist(md_file, 'file') ~= 2
    uialert(parent_fig, sprintf('Notes file not found:\n%s', md_file), 'Notes');
    return;
end
md = fileread(md_file);
html = local_markdown_html(md, char(tab_title));
html_file = fullfile(tempdir, [local_key(tab_title) '_notes.html']);
fid = fopen(html_file, 'w');
if fid < 0
    uialert(parent_fig, sprintf('Cannot write notes html:\n%s', html_file), 'Notes');
    return;
end
cleaner = onCleanup(@() fclose(fid)); %#ok<NASGU>
fwrite(fid, html, 'char');
try
    web(html_file, '-browser');
catch ME
    uialert(parent_fig, ME.message, 'Notes');
end
end

function key = local_key(tab_title)
key = lower(char(tab_title));
key = regexprep(key, '[^a-zA-Z0-9]+', '_');
key = regexprep(key, '^_+|_+$', '');
if isempty(key)
    key = 'tab';
end
end

function html = local_markdown_html(md, page_title)
body = local_md_to_html(md);
css = ['<style>' ...
    'body{font-family:Times New Roman,serif;margin:34px;line-height:1.55;color:#111;font-size:17px;}' ...
    'h1,h2,h3,h4{font-weight:600;margin-top:1.25em;margin-bottom:0.35em;}' ...
    'p{margin:0.55em 0;}' ...
    'pre{background:#f5f5f5;padding:12px;border-radius:6px;overflow:auto;}' ...
    'code{font-family:Consolas,monospace;background:#f5f5f5;padding:1px 4px;border-radius:3px;}' ...
    'blockquote{border-left:4px solid #ccc;margin-left:0;padding-left:12px;color:#555;}' ...
    'table{border-collapse:collapse;}td,th{border:1px solid #ccc;padding:4px 8px;}' ...
    '.mathblock{margin:0.8em 0;text-align:center;}' ...
    '</style>'];
mathjax = ['<script>' ...
    'window.MathJax={tex:{inlineMath:[["$","$"],["\\(","\\)"]],displayMath:[["$$","$$"],["\\[","\\]"]]},startup:{typeset:true}};' ...
    '</script>' ...
    '<script defer src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-chtml.js"></script>' ...
    '<script>window.addEventListener("load",function(){if(window.MathJax&&MathJax.typesetPromise){MathJax.typesetPromise();}});</script>'];
html = ['<!doctype html><html><head><meta charset="utf-8"><title>' local_escape_html(page_title) '</title>' css mathjax '</head><body>' body '</body></html>'];
end

function html = local_md_to_html(md)
md = strrep(md, sprintf('\r\n'), sprintf('\n'));
lines = regexp(md, sprintf('\n'), 'split');
html_parts = {};
in_code = false;
code_lines = {};
in_math = false;
math_lines = {};
in_ul = false;
paragraph = {};
for i = 1:numel(lines)
    line = lines{i};
    trimmed = strtrim(line);
    if startsWith(trimmed, '```')
        [html_parts, paragraph, in_ul] = local_flush_paragraph(html_parts, paragraph, in_ul);
        if in_code
            html_parts{end+1} = ['<pre><code>' local_escape_html(strjoin(code_lines, sprintf('\n'))) '</code></pre>']; %#ok<AGROW>
            code_lines = {};
            in_code = false;
        else
            in_code = true;
        end
        continue;
    end
    if in_code
        code_lines{end+1} = line; %#ok<AGROW>
        continue;
    end
    if startsWith(trimmed, '$$')
        [html_parts, paragraph, in_ul] = local_flush_paragraph(html_parts, paragraph, in_ul);
        if in_math
            tail = strtrim(char(extractAfter(string(trimmed), 2)));
            if ~isempty(tail)
                math_lines{end+1} = tail; %#ok<AGROW>
            end
            html_parts{end+1} = ['<div class="mathblock">$$' strjoin(math_lines, sprintf('\n')) '$$</div>']; %#ok<AGROW>
            math_lines = {};
            in_math = false;
        else
            rest = strtrim(char(extractAfter(string(trimmed), 2)));
            if endsWith(rest, '$$') && strlength(string(rest)) >= 2
                rest = char(extractBefore(string(rest), strlength(string(rest))-1));
                html_parts{end+1} = ['<div class="mathblock">$$' rest '$$</div>']; %#ok<AGROW>
            else
                in_math = true;
                if ~isempty(rest)
                    math_lines{end+1} = rest; %#ok<AGROW>
                end
            end
        end
        continue;
    end
    if in_math
        math_lines{end+1} = line; %#ok<AGROW>
        continue;
    end
    if isempty(trimmed)
        [html_parts, paragraph, in_ul] = local_flush_paragraph(html_parts, paragraph, in_ul);
        continue;
    end
    if startsWith(trimmed, '#')
        [html_parts, paragraph, in_ul] = local_flush_paragraph(html_parts, paragraph, in_ul);
        n = regexp(trimmed, '^#+', 'match', 'once');
        level = min(numel(n), 4);
        content = strtrim(trimmed(numel(n)+1:end));
        html_parts{end+1} = sprintf('<h%d>%s</h%d>', level, local_inline_md(content), level); %#ok<AGROW>
        continue;
    end
    if startsWith(trimmed, '- ') || startsWith(trimmed, '* ')
        if ~isempty(paragraph)
            html_parts{end+1} = ['<p>' local_inline_md(strjoin(paragraph, ' ')) '</p>']; %#ok<AGROW>
            paragraph = {};
        end
        if ~in_ul
            html_parts{end+1} = '<ul>'; %#ok<AGROW>
            in_ul = true;
        end
        html_parts{end+1} = ['<li>' local_inline_md(strtrim(trimmed(3:end))) '</li>']; %#ok<AGROW>
        continue;
    end
    if startsWith(trimmed, '>')
        [html_parts, paragraph, in_ul] = local_flush_paragraph(html_parts, paragraph, in_ul);
        html_parts{end+1} = ['<blockquote>' local_inline_md(strtrim(trimmed(2:end))) '</blockquote>']; %#ok<AGROW>
        continue;
    end
    if in_ul
        html_parts{end+1} = '</ul>'; %#ok<AGROW>
        in_ul = false;
    end
    paragraph{end+1} = trimmed; %#ok<AGROW>
end
[html_parts, paragraph, in_ul] = local_flush_paragraph(html_parts, paragraph, in_ul);
if in_code
    html_parts{end+1} = ['<pre><code>' local_escape_html(strjoin(code_lines, sprintf('\n'))) '</code></pre>']; %#ok<AGROW>
end
if in_math
    html_parts{end+1} = ['<div class="mathblock">$$' strjoin(math_lines, sprintf('\n')) '$$</div>']; %#ok<AGROW>
end
html = strjoin(html_parts, sprintf('\n'));
end

function [html_parts, paragraph, in_ul] = local_flush_paragraph(html_parts, paragraph, in_ul)
if ~isempty(paragraph)
    html_parts{end+1} = ['<p>' local_inline_md(strjoin(paragraph, ' ')) '</p>']; %#ok<AGROW>
    paragraph = {};
end
if in_ul
    html_parts{end+1} = '</ul>'; %#ok<AGROW>
    in_ul = false;
end
end

function s = local_inline_md(s)
s = local_escape_html(s);
s = regexprep(s, '`([^`]+)`', '<code>$1</code>');
s = regexprep(s, '\*\*([^*]+)\*\*', '<strong>$1</strong>');
s = regexprep(s, '\*([^*]+)\*', '<em>$1</em>');
end

function s = local_escape_html(s)
s = char(string(s));
s = strrep(s, '&', '&amp;');
s = strrep(s, '<', '&lt;');
s = strrep(s, '>', '&gt;');
end
