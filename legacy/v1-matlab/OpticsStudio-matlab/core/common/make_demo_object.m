function object_field = make_demo_object(object_type, n)
%MAKE_DEMO_OBJECT Generate simple grayscale demo objects.

[x, y] = meshgrid(linspace(-1, 1, n));
object_field = zeros(n);

switch lower(strtrim(object_type))
    case 'mesh'
        mesh_x = double(abs(mod(8 * x + 1, 0.5)) < 0.06);
        mesh_y = double(abs(mod(8 * y + 1, 0.5)) < 0.06);
        object_field = max(mesh_x, mesh_y);
    case 'double_slit'
        object_field = double(abs(x) < 0.04 & abs(y - 0.18) < 0.25) + ...
                       double(abs(x) < 0.04 & abs(y + 0.18) < 0.25);
    case 'aperture'
        r = sqrt(x.^2 + y.^2);
        object_field = double(r < 0.55) - 0.6 * double(r < 0.22);
        object_field = max(object_field, 0);
    case 'gaussian_lattice'
        sigma = 0.08;
        centers = [-0.45 0 0.45];
        for cx = centers
            for cy = centers
                object_field = object_field + exp(-((x - cx).^2 + (y - cy).^2) / (2 * sigma^2));
            end
        end
    otherwise
        bars = double(abs(y) < 0.06) + ...
               double(abs(x - 0.32) < 0.04 & abs(y) < 0.6) + ...
               double(abs(x + 0.32) < 0.04 & abs(y) < 0.6) + ...
               double(abs(y - 0.35) < 0.05 & abs(x) < 0.35);
        disk = exp(-(x.^2 + y.^2) / (2 * 0.15^2));
        object_field = 0.8 * bars + 0.7 * disk;
end

object_field = normalize_array(max(object_field, 0));
end
