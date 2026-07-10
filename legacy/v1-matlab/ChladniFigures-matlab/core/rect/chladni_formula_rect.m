function chladni_formula_rect(nu, k, n, normalizeForDisplay, outputFolder, boundary, a, b)
%CHLADNI_FORMULA_RECT Rectangular plate modes with a fixed horizontal side a = 2.
% Rectangular boundary codes use the ULDR order: up, left, down, right.

if nargin < 6 || isempty(boundary), boundary = 'FFFF'; end
if nargin < 7 || isempty(a), a = 2.0; end
if nargin < 8 || isempty(b), b = 1.0; end
if nargin < 5 || isempty(outputFolder)
    outputFolder = fullfile(fileparts(mfilename('fullpath')), 'chladni_figures_output');
end
if ~exist(outputFolder, 'dir'), mkdir(outputFolder); end

meta = rect_boundary_meta(boundary);
nuStr = sprintf('%.6g', nu);
xi0 = b / a;
xi0Str = sprintf('%.6g', xi0);

if meta.is_all_simply
    sol = solve_rect_navier_ssss(k, n, a, b);
else
    sol = solve_rect_ritz_general(nu, k, n, a, b, meta.code);
end

x = sol.x;
y = sol.y;
modesU = sol.modesU;
modesLamDisp = sol.lamDisp;
if isfield(sol, 'modeTags') && numel(sol.modeTags) >= numel(modesU)
    modeTags = sol.modeTags;
else
    modeTags = arrayfun(@(j) sprintf('mode%d', j), 1:numel(modesU), 'UniformOutput', false);
end

for j = 1:numel(modesU)
    U = modesU{j};

    fig = figure('Visible','off', 'Color', [1 1 1]);
    set(fig, 'InvertHardcopy', 'off');
    ax = gca;
    set(ax, 'Color', [1 1 1]);

    [Uf, climVal] = signed_field_for_display(U, normalizeForDisplay);
    imagesc(ax, x, y, Uf);
    set(ax, 'YDir', 'normal');
    axis(ax, 'equal');
    axis(ax, [x(1) x(end) y(1) y(end)]);

    color_bar(ax, 'Location','eastoutside', 'Interpreter','latex', 'Limits',[-climVal climVal]);
    hold(ax, 'on');
    draw_rect_nodal_lines(ax, x, y, U, meta.code);

    apply_latex_formatting(fig, ax);
    set(ax, 'Layer', 'top');
    title(ax, local_rect_title(nu, xi0, meta.title_tag, modeTags{j}, modesLamDisp(j)), 'Interpreter','latex');

    filename = fullfile(outputFolder, sprintf('rect-%s-nu%s-xi%s-%s.png', ...
        meta.file_tag, nuStr, xi0Str, modeTags{j}));
    print(fig, '-dpng', filename);
    close(fig);
end
end

function draw_rect_nodal_lines(ax, x, y, U, boundaryCode)
umax = max(abs(U(:)), [], 'omitnan');
if ~isfinite(umax) || umax < eps
    umax = 1.0;
end
U2 = U;
U2(abs(U2) < 1e-12 * umax) = 0;
contour(ax, x, y, U2, [0 0], 'k-', 'LineWidth', 1.0);

[leftZero, rightZero, bottomZero, topZero] = boundary_zero_edges(boundaryCode);
if leftZero
    plot(ax, [x(1) x(1)], [y(1) y(end)], 'k-', 'LineWidth', 1.0);
end
if rightZero
    plot(ax, [x(end) x(end)], [y(1) y(end)], 'k-', 'LineWidth', 1.0);
end
if bottomZero
    plot(ax, [x(1) x(end)], [y(1) y(1)], 'k-', 'LineWidth', 1.0);
end
if topZero
    plot(ax, [x(1) x(end)], [y(end) y(end)], 'k-', 'LineWidth', 1.0);
end
end

function [leftZero, rightZero, bottomZero, topZero] = boundary_zero_edges(boundaryCode)
meta = rect_boundary_meta(boundaryCode);
leftZero = meta.left ~= 'F';
rightZero = meta.right ~= 'F';
bottomZero = meta.bottom ~= 'F';
topZero = meta.top ~= 'F';
end



function txt = local_rect_title(nu, xi0, boundaryTag, modeTag, lambdaVal)
modeText = local_mode_title_text(modeTag);
txt = sprintf('$\\nu=%.6g,\\ \\xi_0=%.6g,\\ \\mathrm{%s}\\ %s,\\ \\Lambda=%.4g$', ...
    nu, xi0, upper(boundaryTag), modeText, lambdaVal);
end

function modeText = local_mode_title_text(modeTag)
tokens = regexp(modeTag, '^mode(\d+),(\d+)$', 'tokens', 'once');
if ~isempty(tokens)
    modeText = sprintf('(m=%s, s=%s)', tokens{1}, tokens{2});
    return;
end

tokens = regexp(modeTag, '^mode(\d+)$', 'tokens', 'once');
if ~isempty(tokens)
    modeText = sprintf('(\\mathrm{mode}=%s)', tokens{1});
    return;
end

modeText = modeTag;
end
