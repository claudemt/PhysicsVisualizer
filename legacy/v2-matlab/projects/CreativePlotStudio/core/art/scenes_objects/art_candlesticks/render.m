% Art Candlesticks
% This script is executed by the GUI with variables: ax, style.
if ~exist('ax','var') || isempty(ax)
    figure('Color','w');
    ax = gca;
end
if ~exist('style','var') || isempty(style)
    style = 'default';
end
style = char(style);

theme = style; if ~any(strcmpi(theme,{'coolnight','warmmountains','monomoon'})), theme = 'coolnight'; end; art_art_candles(ax,theme);

try
    art_apply_recommended_view(ax,'Art Candlesticks');
catch
end

finalize_project_axes(ax,'Art Candlesticks');
