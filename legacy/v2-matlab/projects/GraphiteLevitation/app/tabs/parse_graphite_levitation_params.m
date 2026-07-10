function out = parse_graphite_levitation_params(action, varargin)
%PARSE_GRAPHITE_LEVITATION_PARAMS Small parser facade for GUI tabs.

action = lower(strrep(char(string(action)), ' ', '_'));
switch action
    case 'defaults'
        out = default_graphite_levitation_params();

    case 'shape_items'
        out = {'circle','square'};

    case 'scan_items'
        out = {'graphite.radius', 'graphite.side', 'graphite.thickness', 'graphite.chiAbs', 'laser.alpha'};

    case 'scan_labels'
        items = parse_graphite_levitation_params('scan_items');
        out = strrep(items, '.', ' / ');

    case 'normalize_scan_parameter'
        raw = char(string(varargin{1}));
        raw = strtrim(raw);
        raw = regexprep(raw, '\s*/\s*', '.');
        raw = regexprep(raw, '\s+', '');
        items = parse_graphite_levitation_params('scan_items');
        labels = parse_graphite_levitation_params('scan_labels');
        idx = find(strcmp(raw, items), 1);
        if ~isempty(idx), out = items{idx}; return; end
        idx = find(strcmp(raw, labels), 1);
        if ~isempty(idx), out = items{idx}; return; end
        out = raw;

    case 'scan_unit_scale'
        out = local_scan_unit_scale(char(string(varargin{1})));

    case 'scan_display_label'
        out = local_scan_display_label(char(string(varargin{1})));

    case 'parse_scan_values'
        raw = varargin{1};
        parameter = char(string(varargin{2}));
        [valuesDisplay, valuesSI] = local_parse_scan_values(raw, parameter);
        out = struct('display', valuesDisplay, 'si', valuesSI);

    case 'parse_size_pair'
        out = local_parse_size_tuple(varargin{1}, 2, [6 6], true);

    case 'parse_point_pair'
        out = local_parse_size_tuple(varargin{1}, 2, [0 0], false);

    case 'parse_size_triple_mm'
        out = local_parse_size_tuple(varargin{1}, 3, [10 10 10], true);

    case 'format_array_size'
        d = varargin{1}; out = sprintf('%d*%d', d.array.nx, d.array.ny);

    case 'format_magnet_size'
        d = varargin{1}; out = sprintf('%.4g*%.4g*%.4g', 1e3*d.magnet.a, 1e3*d.magnet.b, 1e3*d.magnet.c);

    case 'format_spot'
        d = varargin{1}; out = sprintf('%.4g*%.4g', 1e3*d.laser.spotX, 1e3*d.laser.spotY);

    otherwise
        error('Unknown parse_graphite_levitation_params action: %s', action);
end
end

function vals = local_parse_size_tuple(txt, n, fallback, positiveOnly)
if isnumeric(txt)
    vals = txt(:).';
else
    if iscell(txt), s = strjoin(cellfun(@char, txt(:).', 'UniformOutput', false), ' '); else, s = char(string(txt)); end
    s = strrep(s, '×', '*');
    s = regexprep(s, '[*xX，,;]+', ' ');
    vals = sscanf(s, '%f').';
end
if numel(vals) < n, vals = fallback; else, vals = vals(1:n); end
if nargin < 4, positiveOnly = true; end
if positiveOnly
    vals = max(vals, eps);
end
end

function [displayVals, siVals] = local_parse_scan_values(raw, parameter)
if isnumeric(raw)
    displayVals = raw(:).';
else
    s = char(string(raw));
    s = strtrim(s);
    s = regexprep(s, '^\((.*)\)$', '$1');
    s = regexprep(s, '^\[(.*)\]$', '$1');
    s = strrep(s, '，', ',');
    if startsWith(lower(s), 'linspace')
        nums = sscanf(regexprep(s, '[^0-9eE+\-.]+', ' '), '%f').';
        if numel(nums) >= 3
            displayVals = linspace(nums(1), nums(2), max(1, round(nums(3))));
        else
            displayVals = nums;
        end
    elseif contains(s, ':') && isempty(regexp(s, '[,;\s]', 'once'))
        nums = sscanf(regexprep(s, ':', ' '), '%f').';
        if numel(nums) == 2
            displayVals = nums(1):1:nums(2);
        elseif numel(nums) >= 3
            displayVals = nums(1):nums(2):nums(3);
        else
            displayVals = nums;
        end
    else
        displayVals = sscanf(regexprep(s, '[,;\s]+', ' '), '%f').';
    end
end
if isempty(displayVals), displayVals = 0; end
scale = local_scan_unit_scale(parameter);
siVals = displayVals * scale;
end

function scale = local_scan_unit_scale(parameter)
parameter = char(string(parameter));
switch parameter
    case {'graphite.radius','graphite.side','graphite.thickness','graphite.z0','magnet.a','magnet.b','magnet.c','laser.spotX','laser.spotY'}
        scale = 1e-3;
    case 'graphite.chiAbs'
        scale = 1e-4;
    otherwise
        scale = 1;
end
end

function label = local_scan_display_label(parameter)
parameter = char(string(parameter));
switch parameter
    case 'graphite.radius', label = 'radius R [mm]';
    case 'graphite.side', label = 'square side [mm]';
    case 'graphite.thickness', label = 'thickness [mm]';
    case 'graphite.z0', label = 'height z0 [mm]';
    case 'graphite.chiAbs', label = 'chi [1e-4]';
    case 'magnet.a', label = 'magnet x-size [mm]';
    case 'magnet.b', label = 'magnet y-size [mm]';
    case 'magnet.c', label = 'magnet z-size [mm]';
    case 'laser.spotX', label = 'laser x [mm]';
    case 'laser.spotY', label = 'laser y [mm]';
    otherwise, label = strrep(parameter, '.', ' / ');
end
end
