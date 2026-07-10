function result = trace_spherical_interface_bundle(n1, n2, radius, aperture_radius, ray_count, screen_z)
%TRACE_SPHERICAL_INTERFACE_BUNDLE Exact 2D refraction at a spherical interface.

z0 = -max(2 * abs(radius), 20);
y0 = linspace(-aperture_radius, aperture_radius, ray_count);
center = [radius; 0];

pre_segments = zeros(ray_count, 4);
post_segments = zeros(ray_count, 4);
intersection = nan(ray_count, 2);
directions = nan(ray_count, 2);
tir_mask = false(ray_count, 1);
incident_angle = nan(ray_count, 1);

for k = 1:ray_count
    if abs(y0(k)) >= abs(radius)
        continue;
    end

    z_int = radius - sign(radius) * sqrt(radius^2 - y0(k)^2);
    point = [z_int; y0(k)];
    normal_12 = -(point - center) / norm(point - center);
    inc = [1; 0];
    incident_angle(k) = acos(max(min(-dot(normal_12, inc), 1), -1));

    [transmitted_dir, tir] = snell_refraction(inc, normal_12, n1, n2);
    tir_mask(k) = tir;

    pre_segments(k, :) = [z0, y0(k), point(1), point(2)];
    if abs(transmitted_dir(1)) < eps
        continue;
    end
    t_screen = (screen_z - point(1)) / transmitted_dir(1);
    screen_point = point + t_screen * transmitted_dir;
    post_segments(k, :) = [point(1), point(2), screen_point(1), screen_point(2)];
    intersection(k, :) = point.';
    directions(k, :) = transmitted_dir.';
end

result = struct();
result.pre_segments = pre_segments;
result.post_segments = post_segments;
result.intersection = intersection;
result.directions = directions;
result.tir_mask = tir_mask;
result.incident_angle = incident_angle;
result.vertex = [0, 0];
result.screen_z = screen_z;
result.radius = radius;
end
