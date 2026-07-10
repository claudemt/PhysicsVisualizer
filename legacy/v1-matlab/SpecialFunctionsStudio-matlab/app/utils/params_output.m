function out = params_output(action, varargin)
switch lower(char(action))
    case 'lines'
        out = local_param_lines(varargin{:});
    case 'write'
        out = local_write_params(varargin{:});
    case 'write_lines'
        out = local_write_lines(varargin{:});
    case 'reproduce_code'
        out = local_reproduce_code(varargin{:});
    case 'write_reproduce'
        out = local_write_reproduce(varargin{:});
    case 'write_all'
        out = local_write_all(varargin{:});
    case 'expand_scan'
        out = local_expand_scan(varargin{:});
    otherwise
        error('Unknown params_output action.');
end
end

function lines = local_param_lines(params, varargin)
p = inputParser;
p.addParameter('Prefix', '');
p.parse(varargin{:});
opt = p.Results;
lines = local_struct_lines(params, char(opt.Prefix));
end

function path = local_write_params(output_dir, params, varargin)
p = inputParser;
p.addParameter('FileName', 'parameters.txt');
p.addParameter('Header', {});
p.parse(varargin{:});
opt = p.Results;
if exist(output_dir, 'dir') ~= 7
    mkdir(output_dir);
end
lines = [local_cell_lines(opt.Header), local_param_lines(params)];
path = fullfile(output_dir, char(opt.FileName));
local_write_text(path, lines);
end

function path = local_write_lines(output_dir, lines, varargin)
p = inputParser;
p.addParameter('FileName', 'parameters.txt');
p.parse(varargin{:});
opt = p.Results;
if exist(output_dir, 'dir') ~= 7
    mkdir(output_dir);
end
path = fullfile(output_dir, char(opt.FileName));
local_write_text(path, local_cell_lines(lines));
end

function code = local_reproduce_code(params, varargin)
p = inputParser;
p.addParameter('RunFunction', '');
p.addParameter('ProjectRoot', '');
p.addParameter('OutputVariable', 'result');
p.addParameter('ParamsVariable', 'params');
p.addParameter('ExtraCode', '');
p.addParameter('AssignOnly', false);
p.parse(varargin{:});
opt = p.Results;
params_var = char(opt.ParamsVariable);
out_var = char(opt.OutputVariable);
code_lines = {};
if ~isempty(opt.ProjectRoot)
    code_lines{end+1} = sprintf('project_root = %s;', local_matlab_literal(char(opt.ProjectRoot)));
    code_lines{end+1} = 'addpath(genpath(project_root));';
end
code_lines{end+1} = sprintf('%s = struct();', params_var);
code_lines = [code_lines, local_struct_assignment_lines(params, params_var)];
extra = char(string(opt.ExtraCode));
if ~isempty(strtrim(extra))
    code_lines = [code_lines, local_cell_lines(extra)];
end
if ~opt.AssignOnly && ~isempty(opt.RunFunction)
    code_lines{end+1} = sprintf('%s = %s(%s);', out_var, char(opt.RunFunction), params_var);
end
code = strjoin(code_lines, sprintf('\n'));
end

function path = local_write_reproduce(output_dir, code, varargin)
p = inputParser;
p.addParameter('FileName', 'reproduce_code.m');
p.parse(varargin{:});
opt = p.Results;
if exist(output_dir, 'dir') ~= 7
    mkdir(output_dir);
end
path = fullfile(output_dir, char(opt.FileName));
local_write_text(path, local_cell_lines(code));
end

function info = local_write_all(output_dir, params, varargin)
p = inputParser;
p.addParameter('RunFunction', '');
p.addParameter('ProjectRoot', '');
p.addParameter('ExtraCode', '');
p.addParameter('ParamFileName', 'parameters.txt');
p.addParameter('ReproduceFileName', 'reproduce_code.m');
p.parse(varargin{:});
opt = p.Results;
info = struct();
info.parameters_path = local_write_params(output_dir, params, 'FileName', opt.ParamFileName);
code = local_reproduce_code(params, 'RunFunction', opt.RunFunction, 'ProjectRoot', opt.ProjectRoot, 'ExtraCode', opt.ExtraCode);
info.reproduce_path = local_write_reproduce(output_dir, code, 'FileName', opt.ReproduceFileName);
info.reproduce_code = code;
end

function param_list = local_expand_scan(base_params, scan_text)
lines = local_cell_lines(scan_text);
scan = struct();
for k = 1:numel(lines)
    line = strtrim(lines{k});
    if isempty(line) || startsWith(line, '#') || startsWith(line, '%')
        continue;
    end
    if endsWith(line, ';')
        line = line(1:end-1);
    end
    tok = regexp(line, '^([A-Za-z]\w*)\s*=\s*(.+)$', 'tokens', 'once');
    if isempty(tok)
        error('Invalid scan line: %s', line);
    end
    name = tok{1};
    expr = tok{2};
    value = eval(expr);
    if ischar(value) || isstring(value)
        values = cellstr(string(value));
    elseif iscell(value)
        values = value;
    else
        values = num2cell(value(:).');
    end
    scan.(name) = values;
end
names = fieldnames(scan);
if isempty(names)
    param_list = base_params;
    return;
end
counts = cellfun(@(n) numel(scan.(n)), names);
subs = cell(1, numel(names));
[subs{:}] = ndgrid_array(counts);
n = numel(subs{1});
param_list = repmat(base_params, 1, n);
for i = 1:n
    for k = 1:numel(names)
        vals = scan.(names{k});
        param_list(i).(names{k}) = vals{subs{k}(i)};
    end
end
end

function varargout = ndgrid_array(counts)
inputs = cell(1, numel(counts));
for k = 1:numel(counts)
    inputs{k} = 1:counts(k);
end
[varargout{1:numel(counts)}] = ndgrid(inputs{:});
end

function lines = local_struct_lines(s, prefix)
lines = {};
if nargin < 2
    prefix = '';
end
if ~isstruct(s)
    lines = {sprintf('%s%s', prefix, local_value_to_text(s))};
    return;
end
fields = fieldnames(s);
for k = 1:numel(fields)
    name = fields{k};
    value = s.(name);
    key = name;
    if ~isempty(prefix)
        key = [prefix '.' name];
    end
    if isstruct(value) && isscalar(value)
        lines = [lines, local_struct_lines(value, key)];
    else
        lines{end+1} = sprintf('%s = %s', key, local_value_to_text(value));
    end
end
end

function lines = local_struct_assignment_lines(s, varname)
lines = {};
fields = fieldnames(s);
for k = 1:numel(fields)
    name = fields{k};
    value = s.(name);
    lhs = sprintf('%s.%s', varname, name);
    if isstruct(value) && isscalar(value)
        lines{end+1} = sprintf('%s = struct();', lhs);
        lines = [lines, local_struct_assignment_lines(value, lhs)];
    else
        lines{end+1} = sprintf('%s = %s;', lhs, local_matlab_literal(value));
    end
end
end

function txt = local_value_to_text(v)
if isnumeric(v) || islogical(v)
    if isscalar(v)
        if islogical(v)
            txt = char(string(v));
        else
            txt = sprintf('%.15g', v);
        end
    else
        txt = mat2str(v);
    end
elseif ischar(v)
    txt = v;
elseif isstring(v)
    if isscalar(v)
        txt = char(v);
    else
        txt = strjoin(cellstr(v), ', ');
    end
elseif iscell(v)
    parts = cellfun(@local_value_to_text, v, 'UniformOutput', false);
    txt = ['{' strjoin(parts, ', ') '}'];
else
    try
        txt = char(string(v));
    catch
        txt = '<value>';
    end
end
end

function lit = local_matlab_literal(v)
if isnumeric(v)
    lit = mat2str(v);
elseif islogical(v)
    if isscalar(v)
        if v
            lit = 'true';
        else
            lit = 'false';
        end
    else
        lit = mat2str(v);
    end
elseif ischar(v)
    lit = ['''' strrep(v, '''', '''''') ''''];
elseif isstring(v)
    if isscalar(v)
        lit = ['"' strrep(char(v), '"', '""') '"'];
    else
        parts = arrayfun(@(x) ['"' strrep(char(x), '"', '""') '"'], v, 'UniformOutput', false);
        lit = ['[' strjoin(parts, ' ') ']'];
    end
elseif iscell(v)
    parts = cellfun(@local_matlab_literal, v, 'UniformOutput', false);
    lit = ['{' strjoin(parts, ', ') '}'];
elseif isstruct(v)
    lit = 'struct()';
else
    lit = ['''' strrep(char(string(v)), '''', '''''') ''''];
end
end

function c = local_cell_lines(x)
if isempty(x)
    c = {};
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

function local_write_text(path, lines)
lines = local_cell_lines(lines);
fid = fopen(path, 'w');
if fid < 0
    error('Cannot write file.');
end
cleanup_obj = onCleanup(@() fclose(fid));
for k = 1:numel(lines)
    fprintf(fid, '%s\n', lines{k});
end
clear cleanup_obj;
end
