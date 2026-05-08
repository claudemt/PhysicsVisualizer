function phantom = make_phantom_slice(n, phantom_name)
%MAKE_PHANTOM_SLICE Generate small analytic 2D phantoms.

[x, y] = meshgrid(linspace(-1, 1, n));
phantom = zeros(n);

switch lower(strtrim(phantom_name))
    case 'three_disks'
        phantom = phantom + 1.0 * double((x + 0.35).^2 + (y + 0.10).^2 < 0.18^2);
        phantom = phantom + 0.8 * double((x - 0.25).^2 + (y - 0.18).^2 < 0.22^2);
        phantom = phantom + 0.6 * double((x + 0.05).^2 + (y - 0.35).^2 < 0.14^2);
    otherwise
        params = [ ...
            1.00,   0.00,   0.00,   0.69, 0.92,   0;
           -0.80,   0.00,  -0.02,   0.66, 0.88,   0;
           -0.20,   0.22,   0.00,   0.11, 0.31, -18;
           -0.20,  -0.22,   0.00,   0.16, 0.41,  18;
            0.10,   0.00,   0.35,   0.21, 0.25,   0;
            0.10,   0.00,   0.10,   0.046,0.046,  0;
            0.10,   0.00,  -0.10,   0.046,0.046,  0;
            0.10,  -0.08,  -0.605,  0.046,0.023,  0;
            0.10,   0.00,  -0.605,  0.023,0.023,  0;
            0.10,   0.06,  -0.605,  0.023,0.046,  0];
        for k = 1:size(params, 1)
            a = params(k, 1);
            x0 = params(k, 2);
            y0 = params(k, 3);
            rx = params(k, 4);
            ry = params(k, 5);
            angle = deg2rad(params(k, 6));
            xr = (x - x0) * cos(angle) + (y - y0) * sin(angle);
            yr = -(x - x0) * sin(angle) + (y - y0) * cos(angle);
            phantom = phantom + a * double((xr / rx).^2 + (yr / ry).^2 <= 1);
        end
end

phantom = normalize_array(max(phantom, 0));
end
