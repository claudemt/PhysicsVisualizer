function result = gerchberg_saxton_phase(n, spot_count, separation_px, n_iter, alpha)
%GERCHBERG_SAXTON_PHASE Recover a phase-only pupil mask for a spot lattice.

[pupil, ~, ~] = make_circular_pupil(n);
pupil = double(pupil > 0);

coords = linspace(-(spot_count - 1) / 2, (spot_count - 1) / 2, spot_count) * separation_px;
[xp, yp] = meshgrid(1:n, 1:n);
center = (n + 1) / 2;
sigma = max(1.5, 0.05 * separation_px + 1.0);

target_amp = zeros(n);
for cx = coords
    for cy = coords
        target_amp = target_amp + exp(-((xp - (center + cx)).^2 + (yp - (center + cy)).^2) / (2 * sigma^2));
    end
end
target_amp = normalize_array(target_amp);
signal_mask = target_amp > 0.15;

phase = 2 * pi * rand(n);
pupil_field = pupil .* exp(1i * phase);

efficiency = zeros(1, n_iter);
uniformity = zeros(1, n_iter);

for k = 1:n_iter
    image_field = fftshift(fft2(ifftshift(pupil_field)));
    image_intensity = abs(image_field).^2;

    efficiency(k) = sum(image_intensity(signal_mask)) / max(sum(image_intensity(:)), eps);
    peak_values = image_intensity(signal_mask);
    if isempty(peak_values)
        uniformity(k) = 0;
    else
        uniformity(k) = 1 - (max(peak_values) - min(peak_values)) / (max(peak_values) + min(peak_values) + eps);
    end

    constrained_field = target_amp .* exp(1i * angle(image_field));
    back_field = fftshift(ifft2(ifftshift(constrained_field)));
    pupil_field = (1 - alpha) * pupil_field + alpha * pupil .* exp(1i * angle(back_field));
end

final_image = fftshift(fft2(ifftshift(pupil_field)));
final_intensity = normalize_array(abs(final_image).^2);
final_phase = angle(pupil_field) .* pupil;

result = struct();
result.target_amplitude = target_amp;
result.final_intensity = final_intensity;
result.final_phase = final_phase;
result.efficiency = efficiency;
result.uniformity = uniformity;
end
