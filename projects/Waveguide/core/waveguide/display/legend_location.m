function loc = legend_location(choice)
%LEGEND_LOCATION Convert UI legend placement choices to MATLAB legend locations.

if nargin < 1 || isempty(choice)
    choice = 'right side';
end
choice = lower(strtrim(char(string(choice))));
switch choice
    case {'right side', 'right', 'outside right', 'eastoutside'}
        loc = 'eastoutside';
    case {'upper left', 'left upper', 'northwest'}
        loc = 'northwest';
    case {'lower left', 'left lower', 'southwest'}
        loc = 'southwest';
    case {'upper right', 'right upper', 'northeast'}
        loc = 'northeast';
    case {'lower right', 'right lower', 'southeast'}
        loc = 'southeast';
    otherwise
        loc = 'eastoutside';
end
end
