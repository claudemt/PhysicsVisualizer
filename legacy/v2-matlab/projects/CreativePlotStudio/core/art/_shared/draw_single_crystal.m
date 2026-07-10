function h = draw_single_crystal(ax, p0, p1, twist, face_alpha, radius, tip_scale)
%DRAW_SINGLE_CRYSTAL Draw one tapered hexagonal crystal between two 3-D points.
% This helper is intentionally small and deterministic; it restores the public
% helper name used by the original crystal-cluster / crystal-heart artwork.
if nargin < 1 || isempty(ax), figure('Color','w'); ax = gca; end
if nargin < 2 || isempty(p0), p0 = [0 0 0]; end
if nargin < 3 || isempty(p1), p1 = [0 0 1]; end
if nargin < 4 || isempty(twist), twist = 0; end
if nargin < 5 || isempty(face_alpha), face_alpha = 0.82; end
if nargin < 6 || isempty(radius), radius = 0.12; end
if nargin < 7 || isempty(tip_scale), tip_scale = 0.18; end

p0 = double(p0(:).');
p1 = double(p1(:).');
v = p1 - p0;
L = norm(v);
if ~isfinite(L) || L <= eps
    h = gobjects(0);
    return;
end
ez = v ./ L;
base = [0 0 1];
if abs(dot(ez, base)) > 0.92
    base = [0 1 0];
end
ex = cross(base, ez); ex = ex ./ max(norm(ex), eps);
ey = cross(ez, ex); ey = ey ./ max(norm(ey), eps);

n = 6;
th = linspace(0, 2*pi, n+1); th(end) = [];
th = th + twist;
R0 = radius * L;
R1 = radius * L * max(0.35, 1 - 0.55*tip_scale);
zend = L * (1 - 0.18*tip_scale);

rings = zeros(n,3,3);
for k = 1:n
    dir = cos(th(k))*ex + sin(th(k))*ey;
    rings(k,:,1) = p0 + R0*dir;
    rings(k,:,2) = p0 + zend*ez + R1*dir;
    rings(k,:,3) = p1;
end

hold_state = ishold(ax);
hold(ax,'on');
colors = [0.78 0.93 1.00; 0.45 0.72 0.95; 0.86 0.98 1.00; 0.35 0.58 0.88; 0.70 0.88 1.00; 0.55 0.76 0.96];
h = gobjects(n+2,1);
for k = 1:n
    k2 = mod(k,n) + 1;
    quad = [squeeze(rings(k,:,1)); squeeze(rings(k2,:,1)); squeeze(rings(k2,:,2)); squeeze(rings(k,:,2))];
    h(k) = patch(ax, 'XData', quad(:,1), 'YData', quad(:,2), 'ZData', quad(:,3), ...
        'FaceColor', colors(k,:), 'EdgeColor', [0.25 0.35 0.45], 'LineWidth', 0.35, 'FaceAlpha', face_alpha);
end
base_poly = squeeze(rings(:,:,1));
h(n+1) = patch(ax, 'XData', base_poly(:,1), 'YData', base_poly(:,2), 'ZData', base_poly(:,3), ...
    'FaceColor', [0.60 0.82 0.95], 'EdgeColor', [0.25 0.35 0.45], 'LineWidth', 0.35, 'FaceAlpha', face_alpha);
for k = 1:n
    k2 = mod(k,n) + 1;
    tri = [squeeze(rings(k,:,2)); squeeze(rings(k2,:,2)); p1];
    patch(ax, 'XData', tri(:,1), 'YData', tri(:,2), 'ZData', tri(:,3), ...
        'FaceColor', colors(k,:), 'EdgeColor', [0.25 0.35 0.45], 'LineWidth', 0.35, 'FaceAlpha', min(1, face_alpha+0.08));
end
if ~hold_state, hold(ax,'off'); end
end
