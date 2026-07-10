function [reconstruction, filtered_sinogram, filter_profile] = filtered_backprojection(sinogram, detector_positions, theta_deg, output_size, filter_name)
%FILTERED_BACKPROJECTION Reconstruct a slice from a sinogram using FBP.

m = size(sinogram, 1);
ds = detector_positions(2) - detector_positions(1);
nfft = 2^nextpow2(2 * m);

freq = ((0:nfft-1) - floor(nfft/2)) / (nfft * ds);
base_filter = abs(freq(:));

switch lower(strtrim(filter_name))
    case 'none'
        filter_profile = ones(size(base_filter));
    case 'shepp_logan'
        omega = pi * freq(:) / max(abs(freq(:)) + eps);
        filter_profile = base_filter .* sinc(omega / pi / 2);
    otherwise
        filter_profile = base_filter;
end
filter_profile = filter_profile / max(filter_profile + eps);

projection_fft = fftshift(fft(sinogram, nfft, 1), 1);
filtered_fft = projection_fft .* filter_profile;
filtered = real(ifft(ifftshift(filtered_fft, 1), [], 1));
filtered_sinogram = filtered(1:m, :);

[x, y] = meshgrid(linspace(-1, 1, output_size));
reconstruction = zeros(output_size);

for k = 1:numel(theta_deg)
    th = deg2rad(theta_deg(k));
    s = x * cos(th) + y * sin(th);
    reconstruction = reconstruction + interp1(detector_positions, filtered_sinogram(:, k), s, 'linear', 0);
end

reconstruction = reconstruction * pi / max(numel(theta_deg), 1);
reconstruction = normalize_array(max(reconstruction, 0));
end
