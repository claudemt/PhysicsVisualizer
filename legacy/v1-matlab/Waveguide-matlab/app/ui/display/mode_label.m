function label = mode_label(modeType, varargin)
%MODE_LABEL Return a consistent LaTeX label for TE/TM-style modes.
modeType = char(string(modeType));
if nargin == 2
    label = sprintf('$\\mathrm{%s}_{%d}$', modeType, varargin{1});
elseif nargin == 3
    label = sprintf('$\\mathrm{%s}_{%d,%d}$', modeType, varargin{1}, varargin{2});
else
    label = sprintf('$\\mathrm{%s}$', modeType);
end
end
