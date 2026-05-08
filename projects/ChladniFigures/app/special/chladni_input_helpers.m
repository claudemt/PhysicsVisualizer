function out = chladni_input_helpers(action, varargin)
%CHLADNI_INPUT_HELPERS Project-level parsing and visibility helpers.
%
% These helpers intentionally stay outside shared utils because Chladni
% boundary strings and static-load expressions are project-specific.

action = lower(strrep(char(string(action)), ' ', '_'));
switch action
    case 'boundary_items'
        out = local_boundary_items(varargin{:});
    case 'normalize_boundary'
        out = local_normalize_boundary(varargin{:});
    case 'parse_sources'
        out = local_parse_sources(varargin{:});
    case 'control_text'
        out = local_control_text(varargin{:});
    case 'load_function_text'
        out = local_load_function_text(varargin{:});
    case 'onoff'
        out = local_onoff(varargin{:});
    otherwise
        error('Unknown chladni_input_helpers action: %s', action);
end
end

function items = local_boundary_items(domain)
domain = lower(char(string(domain)));
switch domain
    case {'rect','square'}
        items = rect_boundary_options();
    case {'circ','circle'}
        items = circ_boundary_options('circ');
    otherwise
        items = circ_boundary_options('annulus');
end
end

function out = local_normalize_boundary(domain_type, raw_value)
textValue = upper(strtrim(char(string(raw_value))));
domain_type = char(lower(string(domain_type)));
switch domain_type
    case {'rect','square'}
        if numel(textValue) ~= 4 || any(~ismember(textValue, 'CSF'))
            error('For rect, boundary must be a 4-letter ULDR code using C/S/F, e.g. CFSF, SSSS, or FFFF.');
        end
        out = textValue;
    case {'circ','circle'}
        if any(strcmpi(textValue, {'FREE','SIMPLY','SIMPLE','CLAMPED','F','S','C'}))
            out = upper(textValue(1));
        else
            error('For circ, boundary must be C, S, F, or the aliases clamped/simply/free.');
        end
    otherwise
        if numel(textValue) ~= 2 || any(~ismember(textValue, 'CSF'))
            error('For annulus, boundary must be a 2-letter outer-inner code such as CC, CF, SS, or FC.');
        end
        out = textValue;
end
end

function S = local_parse_sources(text_value)
txt = strtrim(local_control_text(text_value));
if isempty(txt)
    S = zeros(0, 4);
    return;
end
S = str2num(txt); %#ok<ST2NM>
if isempty(S) || ~isnumeric(S)
    error('Source matrix must be numeric, for example [0 0 1 0; 0.5 0 -0.5 0.05].');
end
if isvector(S)
    S = S(:).';
end
if size(S, 2) == 2
    S = [S ones(size(S,1),1) zeros(size(S,1),1)];
elseif size(S, 2) == 3
    S = [S zeros(size(S,1),1)];
elseif size(S, 2) ~= 4
    error('Source matrix must have 2, 3, or 4 columns: [x y P sigma].');
end
end

function txt = local_control_text(value)
if nargin < 1 || isempty(value)
    txt = '';
    return;
end
if isobject(value) && isprop(value, 'Value')
    value = value.Value;
end
if iscell(value)
    txt = strjoin(cellfun(@char, value(:).', 'UniformOutput', false), newline);
elseif isstring(value)
    txt = strjoin(cellstr(value(:).'), newline);
else
    txt = char(string(value));
end
end

function txt = local_load_function_text(value)
txt = strtrim(local_control_text(value));
if isempty(txt)
    txt = '@(X,Y) 0.*X';
elseif ~startsWith(txt, '@')
    txt = ['@(X,Y) ' txt];
end
end

function v = local_onoff(tf)
if logical(tf)
    v = 'on';
else
    v = 'off';
end
end
