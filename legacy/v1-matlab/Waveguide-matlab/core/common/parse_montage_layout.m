function row_counts = parse_montage_layout(layout_value, total_count)
%PARSE_MONTAGE_LAYOUT Parse multi-panel layout text robustly.
%
% Supported forms:
%   auto      -> four panels per row
%   4         -> four panels per row, final row may contain fewer
%   4+4+2     -> exact row counts; sum must equal TOTAL_COUNT
%
% The parser deliberately avoids strtrim(char(string(x))) because MATLAB can
% create non-2-D char arrays for some UI/string/cell inputs. Everything is
% first normalized to a scalar row char vector.

if nargin < 2 || ~isscalar(total_count) || ~isfinite(total_count) || total_count < 1
    error('Total plot count must be a positive integer.');
end
total_count = round(total_count);

layout_text = local_scalar_text(layout_value);

if isempty(layout_text) || strcmpi(layout_text, 'auto')
    row_counts = rows_from_panels_per_row(4, total_count);
    return;
end

tokens = regexp(layout_text, '\d+', 'match');
if isempty(tokens)
    error('Layout must be auto, a number like 4, or a row pattern like 4+4+2.');
end

values = str2double(tokens);
if any(~isfinite(values) | values < 1 | abs(values - round(values)) > 1e-10)
    error('Layout entries must be positive integers.');
end
values = round(values(:)).';

% If the user typed one integer, interpret it as panels per row.
% If the user typed plus/comma/space-separated values, interpret them as
% explicit row counts.
has_separator = ~isempty(regexp(layout_text, '[+,\s;]', 'once'));

if numel(values) == 1 && ~has_separator
    row_counts = rows_from_panels_per_row(values(1), total_count);
else
    row_counts = values;
    if sum(row_counts) ~= total_count
        error('Layout %s contains %d panels, but %d plot(s) were requested.', layout_text, sum(row_counts), total_count);
    end
end
end

function txt = local_scalar_text(value)
%LOCAL_SCALAR_TEXT Convert UI/string/cell/numeric input to one row char vector.

if nargin < 1 || isempty(value)
    txt = '';
    return;
end

if isnumeric(value)
    if isscalar(value)
        txt = sprintf('%d', round(value));
    else
        txt = sprintf('%d+', round(value(:)));
        if ~isempty(txt), txt(end) = []; end
    end
    txt = strtrim(txt);
    return;
end

if iscell(value)
    if isempty(value)
        txt = '';
    else
        txt = local_scalar_text(value{1});
    end
    return;
end

if isstring(value)
    if isempty(value)
        txt = '';
    else
        value = value(1);
        txt = char(value);
    end
elseif ischar(value)
    if isempty(value)
        txt = '';
    else
        % UI text should be scalar. If a char matrix somehow arrives, use the
        % first row instead of passing the matrix to strtrim.
        if ndims(value) > 2
            value = value(:, :, 1);
        end
        if size(value, 1) > 1
            value = value(1, :);
        end
        txt = value;
    end
else
    % Last-resort conversion for objects with a displayable string value.
    try
        s = string(value);
        if isempty(s)
            txt = '';
        else
            txt = char(s(1));
        end
    catch
        error('Layout must be text such as auto, 4, or 4+4+2.');
    end
end

txt = regexprep(txt, '^\s+|\s+$', '');
end

function row_counts = rows_from_panels_per_row(per_row, total_count)
per_row = max(1, round(per_row));
full_rows = floor(total_count / per_row);
remainder = mod(total_count, per_row);

row_counts = repmat(per_row, 1, full_rows);
if remainder > 0
    row_counts(end + 1) = remainder;
end
if isempty(row_counts)
    row_counts = total_count;
end
end
