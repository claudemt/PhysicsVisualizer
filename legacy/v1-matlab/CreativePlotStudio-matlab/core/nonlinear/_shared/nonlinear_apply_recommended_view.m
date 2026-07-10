function nonlinear_apply_recommended_view(ax, itemName)
if nargin < 2 || isempty(itemName) || isempty(ax) || ~isgraphics(ax)
    return;
end
item = lower(strtrim(char(itemName)));
try
    switch item
        case {'blue rose','blooming rose'}
            axis(ax,'equal'); axis(ax,'vis3d'); view(ax,[-42 26]); set_camera(ax,[0 0 0]);
        case 'rose ball'
            axis(ax,'equal'); axis(ax,'vis3d'); view(ax,[-34 18]); set_camera(ax,[0 0 0]);
        case 'crystal cluster'
            axis(ax,'vis3d'); view(ax,[-36 24]); set_camera(ax,[0 0 4]);
        case 'crystal heart'
            axis(ax,'vis3d'); view(ax,[-32 22]); set_camera(ax,[0 0 0]);
        case {'ice cream soft serve','ice cream -- soft serve'}
            axis(ax,'vis3d'); view(ax,[-28 18]); set_camera(ax,[0 0 1.1]);
        case {'ice cream bouquet','ice cream -- bouquet'}
            axis(ax,'vis3d'); view(ax,[-26 24]); set_camera(ax,[0 -0.3 0.1]);
        case {'ice cream sundae cup','ice cream -- sundae cup'}
            axis(ax,'vis3d'); view(ax,[-24 18]); set_camera(ax,[0 0 1.2]);
        case 'superformula bloom'
            axis(ax,'equal'); axis(ax,'vis3d'); view(ax,[-38 24]); set_camera(ax,[0 0 0]);
        case 'lorenz attractor'
            axis(ax,'equal'); axis(ax,'vis3d'); view(ax,[-36 18]); set_camera(ax,[0 0 25]);
        case 'rossler ribbon'
            axis(ax,'equal'); axis(ax,'vis3d'); view(ax,[42 20]); set_camera(ax,[0 0 8]);
        case 'chua double scroll'
            axis(ax,'equal'); axis(ax,'vis3d'); view(ax,[-42 18]); set_camera(ax,[0 0 0]);
        case 'lissajous knot'
            axis(ax,'equal'); axis(ax,'vis3d'); view(ax,[-38 24]); set_camera(ax,[0 0 0]);
        case 'aizawa attractor'
            axis(ax,'equal'); axis(ax,'vis3d'); view(ax,[32 18]); set_camera(ax,[0 0 0]);
        case 'thomas attractor'
            axis(ax,'equal'); axis(ax,'vis3d'); view(ax,[24 18]); set_camera(ax,[0 0 0]);
        case 'dadras attractor'
            axis(ax,'equal'); axis(ax,'vis3d'); view(ax,[-40 18]); set_camera(ax,[0 0 0]);
        otherwise
            return;
    end
    camup(ax,[0 0 1]);
    try
        camlight(ax,'headlight');
        camlight(ax,'right');
        lighting(ax,'gouraud');
    catch
    end
catch
end
end

function set_camera(ax, target)
try, camtarget(ax,target); catch, end
try, daspect(ax,[1 1 1]); catch, end
end
