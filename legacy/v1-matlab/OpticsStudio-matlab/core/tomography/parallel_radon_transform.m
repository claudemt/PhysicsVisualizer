function [sinogram, detector_positions] = parallel_radon_transform(image_data, theta_deg, detector_count)
%PARALLEL_RADON_TRANSFORM Compute a simple parallel-beam sinogram.

n = size(image_data, 1);
x = linspace(-1, 1, n);
y = linspace(-1, 1, n);
[s_grid, t_grid] = meshgrid(linspace(-sqrt(2), sqrt(2), detector_count), linspace(-sqrt(2), sqrt(2), detector_count));
detector_positions = s_grid(1, :).';
dt = t_grid(2, 1) - t_grid(1, 1);

sinogram = zeros(detector_count, numel(theta_deg));
for k = 1:numel(theta_deg)
    th = deg2rad(theta_deg(k));
    xq = s_grid * cos(th) - t_grid * sin(th);
    yq = s_grid * sin(th) + t_grid * cos(th);
    sampled = interp2(x, y, image_data, xq, yq, 'linear', 0);
    sinogram(:, k) = sum(sampled, 1).' * dt;
end

sinogram = normalize_array(sinogram);
end
