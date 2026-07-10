function set_latex_title(ax, txt)

if nargin < 2
    txt = '';
end
if isstring(txt)
    txt = char(txt);
end

clean = char(txt);
clean = regexprep(clean,'[\\{}_^$%#&~]','');

try
    delete(findall(ax,'Tag','CPSPlotTitle'));
catch
end

try
    t = title(ax, clean, ...
        'Interpreter','none', ...
        'FontName','Times New Roman', ...
        'FontSize',15, ...
        'FontWeight','normal');
catch
    title(ax, clean);
    return;
end

try
    t.Units = 'normalized';
    pos = t.Position;
    pos(2) = 1.015;   
    t.Position = pos;
catch
end
end
