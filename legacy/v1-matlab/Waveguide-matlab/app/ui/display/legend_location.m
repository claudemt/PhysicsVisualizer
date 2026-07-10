function loc = legend_location(choice)
%LEGEND_LOCATION Convert UI legend placement choices to MATLAB legend locations.

if nargin < 1 || isempty(choice)
    choice = 'right side';
end
choice = lower(strtrim(char(string(choice))));
switch choice
    case {'right side', 'right', 'outside right', 'eastoutside', '图右边', '右边'}
        loc = 'eastoutside';
    case {'upper left', 'left upper', 'northwest', '左上'}
        loc = 'northwest';
    case {'lower left', 'left lower', 'southwest', '左下'}
        loc = 'southwest';
    case {'upper right', 'right upper', 'northeast', '右上'}
        loc = 'northeast';
    case {'lower right', 'right lower', 'southeast', '右下'}
        loc = 'southeast';
    otherwise
        loc = 'eastoutside';
end
end
