function result = shearing_interferogram(n, aberration_name, coefficient_waves, shear_px, carrier_frequency)
%SHEARING_INTERFEROGRAM Generate a lateral shearing interferogram.

[pupil, rho, phi] = make_circular_pupil(n);
wavefront = zernike_wavefront(aberration_name, rho, phi);
phase = 2 * pi * coefficient_waves * wavefront;

[xi, yi] = meshgrid(1:n, 1:n);
phase_shifted = interp2(xi, yi, phase, xi - shear_px, yi, 'linear', 0);
pupil_shifted = interp2(xi, yi, pupil, xi - shear_px, yi, 'linear', 0);
common_mask = double((pupil > 0.5) & (pupil_shifted > 0.5));

[x_norm, ~] = meshgrid(linspace(-1, 1, n));
carrier = 2 * pi * carrier_frequency * x_norm;
delta_phase = phase_shifted - phase;
interferogram = common_mask .* (1 + cos(delta_phase + carrier));

result = struct();
result.wavefront = wavefront .* pupil;
result.delta_phase = delta_phase .* common_mask;
result.interferogram = normalize_array(interferogram);
result.mask = common_mask;
end
