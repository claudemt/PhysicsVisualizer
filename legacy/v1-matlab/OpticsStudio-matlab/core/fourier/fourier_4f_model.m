function result = fourier_4f_model(params, object_fun, phase_fun, filter_fun)
%FOURIER_4F_MODEL Modular 4f Fourier optics forward model.

params = finalize_params(params);
N = params.n_samples;
L = params.window_m;
dx_m = L / N;
x_m = (-N/2:N/2-1) .* dx_m;
y_m = x_m;
[X, Y] = meshgrid(x_m, y_m);

fx = (-N/2:N/2-1) ./ (N * dx_m);
fy = fx;
[FX, FY] = meshgrid(fx, fy);
XF = params.lambda_m * params.f_m .* FX;
YF = params.lambda_m * params.f_m .* FY;

object_amp = double(object_fun(X, Y, params));
phase_rad = double(phase_fun(X, Y, params));
filter_amp = double(filter_fun(XF, YF, params));

if ~isequal(size(object_amp), [N, N]) || ~isequal(size(phase_rad), [N, N]) || ~isequal(size(filter_amp), [N, N])
    error('Plane modules must return arrays of size N-by-N.');
end

phase_support = build_phase_support_mask(X, Y, params);
field_after_phase = object_amp .* phase_support .* exp(1i .* phase_rad);
field_fourier = fftshift(fft2(ifftshift(field_after_phase)));
field_image = fftshift(ifft2(ifftshift(field_fourier .* filter_amp)));

result = struct();
result.mode = 'fourier_studio';
result.params = params;
result.x_mm = x_m * 1e3;
result.y_mm = y_m * 1e3;
result.xf_mm = XF * 1e3;
result.yf_mm = YF * 1e3;
result.object_name = params.object_name;
result.phase_name = params.phase_name;
result.filter_name = params.filter_name;
result.object_amp = normalize_nonnegative(object_amp);
result.phase_rad = phase_rad;
result.phase_wrapped = angle(exp(1i .* phase_rad));
result.phase_wrapped(phase_support < 0.5) = 0;
result.phase_support = phase_support;
result.after_phase_amp = normalize_nonnegative(abs(field_after_phase));
result.spectrum_intensity = normalize_nonnegative(abs(field_fourier).^2);
result.filter_amp = normalize_nonnegative(filter_amp);
result.output_intensity = normalize_nonnegative(abs(field_image).^2);
result.field_after_phase = field_after_phase;
result.field_fourier = field_fourier;
result.field_image = field_image;
result.summary = sprintf('%s | lambda=%.1f nm | f=%.1f mm | N=%d', ...
    params.title_stub, params.wavelength_nm, params.focal_length_mm, params.n_samples);
end

function support = build_phase_support_mask(X, Y, params)
if strcmpi(string(params.phase_name), "No phase")
    support = ones(size(X));
else
    support = double(hypot(X, Y) <= max(params.phase_radius_m, eps));
end
end

function params = finalize_params(params)
required = {'wavelength_nm','focal_length_mm','window_mm','n_samples', ...
    'object_scale_mm','secondary_scale_mm','phase_radius_mm', ...
    'zernike_coeff_waves','filter_scale_ratio','topological_charge', ...
    'auto_adjust_plot_range','object_plot_half_range_mm','fourier_plot_half_range_mm', ...
    'object_name','phase_name','filter_name'};
for k = 1:numel(required)
    if ~isfield(params, required{k})
        error('Missing params.%s', required{k});
    end
end
validateattributes(params.wavelength_nm, {'numeric'}, {'scalar','positive','finite'});
validateattributes(params.focal_length_mm, {'numeric'}, {'scalar','positive','finite'});
validateattributes(params.window_mm, {'numeric'}, {'scalar','positive','finite'});
validateattributes(params.n_samples, {'numeric'}, {'scalar','integer','>=',256,'<=',4096});
validateattributes(params.object_scale_mm, {'numeric'}, {'scalar','positive','finite'});
validateattributes(params.secondary_scale_mm, {'numeric'}, {'scalar','positive','finite'});
validateattributes(params.phase_radius_mm, {'numeric'}, {'scalar','positive','finite'});
validateattributes(params.zernike_coeff_waves, {'numeric'}, {'scalar','finite'});
validateattributes(params.filter_scale_ratio, {'numeric'}, {'scalar','positive','finite','<=',1});
validateattributes(params.topological_charge, {'numeric'}, {'scalar','integer','finite'});
validateattributes(params.auto_adjust_plot_range, {'logical','numeric'}, {'scalar'});
validateattributes(params.object_plot_half_range_mm, {'numeric'}, {'scalar','positive','finite'});
validateattributes(params.fourier_plot_half_range_mm, {'numeric'}, {'scalar','positive','finite'});
params.lambda_m = params.wavelength_nm * 1e-9;
params.f_m = params.focal_length_mm * 1e-3;
params.window_m = params.window_mm * 1e-3;
params.object_scale_m = params.object_scale_mm * 1e-3;
params.secondary_scale_m = params.secondary_scale_mm * 1e-3;
params.phase_radius_m = params.phase_radius_mm * 1e-3;
params.title_stub = sprintf('%s + %s + %s', params.object_name, params.phase_name, params.filter_name);
end

function out = normalize_nonnegative(img)
img = double(img);
img = img - min(img(:));
scale = max(img(:));
if scale <= 0
    out = zeros(size(img));
else
    out = img ./ scale;
end
end
