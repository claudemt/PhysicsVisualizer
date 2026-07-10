function [psf, pupil_field, wavefront] = compute_psf_2d(n, aberration_name, coefficient_waves, extra_phase)
%COMPUTE_PSF_2D Compute a normalized diffraction PSF from a pupil field.

if nargin < 4
    extra_phase = 0;
end

[pupil, rho, phi] = make_circular_pupil(n);
wavefront = zernike_wavefront(aberration_name, rho, phi);
pupil_phase = 2 * pi * coefficient_waves * wavefront + extra_phase;
pupil_field = pupil .* exp(1i * pupil_phase);

field_image = fftshift(fft2(ifftshift(pupil_field)));
psf = abs(field_image).^2;
psf = normalize_array(psf);
end
