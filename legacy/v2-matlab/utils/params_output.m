function out = params_output(action, varargin)
%PARAMS_OUTPUT Shared parameter serialization, reports, and reproduce code.

action = lower(char(string(action)));
switch action
    case 'lines'
        out = local_lines(varargin{:});
    case 'write'
        out = local_write(varargin{:});
    case 'reproduce_code'
        out = local_reproduce_code(varargin{:});
    case 'write_with_reproduce'
        out = local_write_with_reproduce(varargin{:});
    case 'export_text_bundle'
        out = local_export_text_bundle(varargin{:});
    case 'expand_scan'
        out = local_expand_scan(varargin{:});
    case {'notes_from_file','notes'}
        out = local_notes_from_file(varargin{:});
    case {'markdown_section','md_section'}
        out = local_markdown_section(varargin{:});
    otherwise
        error('Unknown params_output action: %s', action);
end
end

function lines = local_lines(params, prefix)
if nargin < 2, prefix = ''; end
lines = {};
if isempty(params), return; end
if isstruct(params)
    names = fieldnames(params);
    for i = 1:numel(names)
        key = names{i};
        val = params.(key);
        fullkey = key;
        if ~isempty(prefix), fullkey = [prefix '.' key]; end
        if isstruct(val) && isscalar(val)
            lines = [lines; local_lines(val, fullkey)]; %#ok<AGROW>
        else
            lines{end+1,1} = sprintf('%s = %s', fullkey, local_value_text(val)); %#ok<AGROW>
        end
    end
else
    lines = {local_value_text(params)};
end
end

function path = local_write(out_dir, params, varargin)
p = inputParser;
p.addParameter('Filename', 'parameters.txt');
p.addParameter('ExtraText', '');
p.parse(varargin{:});
opt = p.Results;

if exist(out_dir, 'dir') ~= 7, mkdir(out_dir); end
path = fullfile(out_dir, opt.Filename);
fid = fopen(path, 'w');
if fid == -1, error('Could not write %s', path); end
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, 'Generated: %s\n\n', char(datetime('now')));
lines = local_lines(params);
for i = 1:numel(lines)
    fprintf(fid, '%s\n', lines{i});
end
if ~isempty(opt.ExtraText)
    fprintf(fid, '\n%s\n', char(string(opt.ExtraText)));
end
clear cleanup
end

function code = local_reproduce_code(run_function_name, params)
if nargin < 1 || isempty(run_function_name)
    run_function_name = 'run_from_params';
end
lines = {};
lines{end+1} = 'params = struct();';
lines = [lines; local_assignment_lines('params', params)];
lines{end+1} = sprintf('%s(params);', char(string(run_function_name)));
code = strjoin(lines, newline);
end

function path = local_write_with_reproduce(out_dir, params, reproduce_code, varargin)
p = inputParser;
p.addParameter('ExtraText', '');
p.parse(varargin{:});
opt = p.Results;

if exist(out_dir, 'dir') ~= 7, mkdir(out_dir); end
path = local_write(out_dir, params, 'ExtraText', opt.ExtraText);

if nargin < 3 || isempty(reproduce_code)
    reproduce_code = local_reproduce_code('run_from_params', params);
end
code_path = fullfile(out_dir, 'reproduce_code.m');
fid = fopen(code_path, 'w');
if fid == -1, error('Could not write %s', code_path); end
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, '%s\n', char(string(reproduce_code)));
clear cleanup
end

function info = local_export_text_bundle(project_root, module_key, text_content, varargin)
p = inputParser;
p.addParameter('Params', struct());
p.addParameter('ReproduceCode', '');
p.addParameter('Filename', 'results.txt');
p.addParameter('ExtraText', '');
p.parse(varargin{:});
opt = p.Results;

out_root = fullfile(project_root, 'output');
if exist(out_root, 'dir') ~= 7, mkdir(out_root); end
stamp = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
out_dir = fullfile(out_root, [image_output('slug', module_key), '_', stamp]);
suffix = 1;
while exist(out_dir, 'dir') == 7
    out_dir = fullfile(out_root, sprintf('%s_%s_%02d', image_output('slug', module_key), stamp, suffix));
    suffix = suffix + 1;
end
mkdir(out_dir);

text_path = fullfile(out_dir, opt.Filename);
fid = fopen(text_path, 'w');
if fid == -1, error('Could not write %s', text_path); end
cleanup = onCleanup(@() fclose(fid));
if iscell(text_content)
    for i = 1:numel(text_content)
        fprintf(fid, '%s\n', char(string(text_content{i})));
    end
else
    fprintf(fid, '%s\n', char(string(text_content)));
end
clear cleanup

param_path = local_write_with_reproduce(out_dir, opt.Params, opt.ReproduceCode, 'ExtraText', opt.ExtraText);
info = struct('output_dir', out_dir, 'text', text_path, 'parameters', param_path);
end

function values = local_expand_scan(values)
if isempty(values)
    values = [];
elseif isnumeric(values)
    return;
elseif ischar(values) || isstring(values)
    values = create_control_panel('parse_range', values);
end
end

function lines = local_assignment_lines(prefix, value)
lines = {};
if isempty(value), return; end
if isstruct(value)
    names = fieldnames(value);
    for i = 1:numel(names)
        key = names{i};
        val = value.(key);
        full = sprintf('%s.%s', prefix, key);
        if isstruct(val) && isscalar(val)
            lines = [lines; local_assignment_lines(full, val)]; %#ok<AGROW>
        else
            lines{end+1,1} = sprintf('%s = %s;', full, local_matlab_literal(val)); %#ok<AGROW>
        end
    end
else
    lines{end+1,1} = sprintf('%s = %s;', prefix, local_matlab_literal(value));
end
end

function s = local_value_text(v)
if ischar(v)
    s = v;
elseif isstring(v)
    s = char(strjoin(v(:).', ", "));
elseif isnumeric(v) || islogical(v)
    if isscalar(v)
        s = num2str(v, '%.12g');
    else
        s = mat2str(v, 12);
    end
elseif iscell(v)
    parts = cellfun(@local_value_text, v, 'UniformOutput', false);
    s = ['{' strjoin(parts, ', ') '}'];
else
    s = char(string(v));
end
end

function s = local_matlab_literal(v)
if ischar(v) || (isstring(v) && isscalar(v))
    s = sprintf('''%s''', strrep(char(string(v)), '''', ''''''));
elseif isstring(v)
    cells = cellstr(v(:));
    s = ['{' strjoin(cellfun(@local_matlab_literal, cells, 'UniformOutput', false), ', ') '}'];
elseif isnumeric(v) || islogical(v)
    s = mat2str(v, 12);
elseif iscell(v)
    s = ['{' strjoin(cellfun(@local_matlab_literal, v(:).', 'UniformOutput', false), ', ') '}'];
else
    s = sprintf('''%s''', strrep(char(string(v)), '''', ''''''));
end
end


function lines = local_notes_from_file(project_root, module_key, mode_key)
%LOCAL_NOTES_FROM_FILE Read a visible Markdown block delimited by notes comments.
md_path = fullfile(project_root, 'docs', 'physical_formulas.md');
if nargin < 3, mode_key = ''; end
key = sprintf('%s:%s', lower(strtrim(char(string(module_key)))), lower(strtrim(char(string(mode_key)))));
text = local_read_text(md_path);
if isempty(text)
    lines = {'No notes file found.'};
    return;
end
pattern = ['(?s)<!--\s*notes:' regexptranslate('escape', key) '\s*-->(.*?)<!--\s*/notes\s*-->'];
tok = regexp(text, pattern, 'tokens', 'once');
if isempty(tok)
    lines = {sprintf('See docs/physical_formulas.md for %s / %s.', char(string(module_key)), char(string(mode_key)))};
else
    lines = local_text_to_lines(strtrim(tok{1}));
end
end

function lines = local_markdown_section(md_path, heading_text)
text = local_read_text(md_path);
if isempty(text)
    lines = {'No notes file found.'};
    return;
end
heading_text = strtrim(char(string(heading_text)));
expr = ['(?m)^(#{1,6})\s+' regexptranslate('escape', heading_text) '\s*$'];
[start_idx, end_idx, tok] = regexp(text, expr, 'start', 'end', 'tokens', 'once');
if isempty(start_idx)
    lines = {sprintf('Section not found: %s', heading_text)};
    return;
end
level = numel(tok{1});
rest = text(end_idx+1:end);
next = regexp(rest, sprintf('(?m)^#{1,%d}\\s+', level), 'start', 'once');
if isempty(next)
    block = rest;
else
    block = rest(1:next-1);
end
lines = local_text_to_lines(strtrim(block));
end

function text = local_read_text(path)
text = '';
if exist(path, 'file') ~= 2
    return;
end
fid = fopen(path, 'r');
if fid == -1
    return;
end
cleanup = onCleanup(@() fclose(fid));
text = fread(fid, '*char').';
clear cleanup
end

function lines = local_text_to_lines(text)
if isempty(text)
    lines = {''};
else
    lines = cellstr(splitlines(string(text)));
end
end

