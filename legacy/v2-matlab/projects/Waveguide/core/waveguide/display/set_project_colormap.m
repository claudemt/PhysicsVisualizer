function set_project_colormap(ax, mapName)
%SET_PROJECT_COLORMAP Apply a named project colormap with safe fallbacks.
if nargin < 2 || isempty(mapName)
    mapName = 'project';
end
if isstring(mapName)
    mapName = char(mapName);
end
mapName = lower(strtrim(mapName));
try
    switch mapName
        case {'project', 'visible', 'spectrum', 'vis'}
            cmap = studio_style('visible_colormap', 256);
        case {'parula', 'turbo', 'gray', 'hot', 'jet', 'hsv', 'cool', 'spring', 'summer', 'autumn', 'winter'}
            cmap = feval(mapName, 256);
        otherwise
            warning('set_project_colormap:UnknownMap', ...
                'Unknown colormap "%s"; using project colormap.', mapName);
            cmap = studio_style('visible_colormap', 256);
    end
catch
    try
        cmap = parula(256);
    catch
        cmap = gray(256);
    end
end
colormap(ax, cmap);
end
