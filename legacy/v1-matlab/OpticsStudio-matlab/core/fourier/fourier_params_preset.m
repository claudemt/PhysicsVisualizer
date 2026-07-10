function presets = fourier_params_preset(name)
%FOURIER_PARAMS_PRESET Built-in presets for the modular Fourier studio tab.

p1 = local_default();
p1.Name = 'HeNe classroom preview';
p1.object_name = 'Double slit';
p1.phase_name = 'No phase';
p1.filter_name = 'Circular low-pass';
p1.filter_scale_ratio = 0.18;
p1.n_samples = 1536;

p2 = p1;
p2.Name = 'Rich 4f low-pass demo';
p2.object_name = 'Hex lattice circles';
p2.phase_name = 'No phase';
p2.filter_name = 'Circular low-pass';
p2.object_scale_mm = 0.22;
p2.secondary_scale_mm = 0.38;
p2.filter_scale_ratio = 0.12;
p2.fourier_plot_half_range_mm = 6.0;
p2.n_samples = 1536;

p3 = p1;
p3.Name = 'Coma plus ring filter';
p3.object_name = 'Star aperture';
p3.phase_name = 'Zernike coma x';
p3.filter_name = 'Ring band-pass';
p3.zernike_coeff_waves = 0.45;
p3.filter_scale_ratio = 0.34;
p3.fourier_plot_half_range_mm = 16.0;
p3.n_samples = 1536;

p4 = p1;
p4.Name = 'Astigmatic slit selection';
p4.object_name = 'Rectangular aperture';
p4.phase_name = 'Zernike astigmatism 0 deg';
p4.filter_name = 'Horizontal slit';
p4.zernike_coeff_waves = 0.32;
p4.object_scale_mm = 0.60;
p4.secondary_scale_mm = 0.22;
p4.filter_scale_ratio = 0.12;
p4.fourier_plot_half_range_mm = 10.0;

p5 = p1;
p5.Name = 'Thin lens focusing';
p5.object_name = 'Circular aperture';
p5.phase_name = 'Thin lens';
p5.filter_name = 'No filter';
p5.phase_radius_mm = 1.10;
p5.object_scale_mm = 1.00;
p5.focal_length_mm = 250;
p5.window_mm = 4.0;
p5.n_samples = 1536;
p5.fourier_plot_half_range_mm = 12.0;

p6 = p1;
p6.Name = 'Vortex and mesh';
p6.object_name = 'Cross aperture';
p6.phase_name = 'Vortex charge 1';
p6.filter_name = 'Mesh';
p6.topological_charge = 1;
p6.filter_scale_ratio = 0.22;
p6.object_scale_mm = 1.25;
p6.n_samples = 1536;
p6.fourier_plot_half_range_mm = 10.0;

p7 = p1;
p7.Name = 'Five-slit directional filtering';
p7.object_name = 'Five slits';
p7.phase_name = 'No phase';
p7.filter_name = 'Vertical double slit';
p7.object_scale_mm = 0.45;
p7.secondary_scale_mm = 0.18;
p7.filter_scale_ratio = 0.18;
p7.n_samples = 1536;
p7.fourier_plot_half_range_mm = 10.0;

p8 = p1;
p8.Name = 'Tilted lattice selection';
p8.object_name = 'Finite 2D grating';
p8.phase_name = 'Zernike tilt x';
p8.filter_name = 'Diagonal slit';
p8.zernike_coeff_waves = 0.18;
p8.object_scale_mm = 0.55;
p8.secondary_scale_mm = 0.20;
p8.filter_scale_ratio = 0.16;
p8.n_samples = 1536;
p8.fourier_plot_half_range_mm = 10.0;

p9 = p1;
p9.Name = 'Dual-circle astigmatic focus';
p9.object_name = 'Two circular apertures';
p9.phase_name = 'Zernike astigmatism 45 deg';
p9.filter_name = 'No filter';
p9.zernike_coeff_waves = 0.28;
p9.object_scale_mm = 0.28;
p9.secondary_scale_mm = 0.38;
p9.phase_radius_mm = 1.20;
p9.n_samples = 1536;
p9.fourier_plot_half_range_mm = 12.0;

presets = [p1, p2, p3, p4, p5, p6, p7, p8, p9];
presets = arrayfun(@finalize_single, presets);

if nargin < 1 || isempty(name)
    return
end

idx = find(strcmpi({presets.Name}, char(string(name))), 1, 'first');
if isempty(idx)
    error('Unknown Fourier preset: %s', char(string(name)));
end
presets = presets(idx);
end

function p = local_default()
p = struct( ...
    'Name', 'HeNe classroom preview', ...
    'wavelength_nm', 632.8, ...
    'focal_length_mm', 250.0, ...
    'window_mm', 4.0, ...
    'n_samples', 1536, ...
    'object_scale_mm', 0.55, ...
    'secondary_scale_mm', 0.30, ...
    'phase_radius_mm', 1.00, ...
    'zernike_coeff_waves', 0.30, ...
    'filter_scale_ratio', 0.18, ...
    'topological_charge', 1, ...
    'auto_adjust_plot_range', true, ...
    'object_plot_half_range_mm', 1.2, ...
    'fourier_plot_half_range_mm', 8.00, ...
    'object_name', 'Double slit', ...
    'phase_name', 'No phase', ...
    'filter_name', 'Circular low-pass', ...
    'display_scaling', 'fixed');
end

function p = finalize_single(p)
validateattributes(p.wavelength_nm, {'numeric'}, {'scalar','positive','finite'});
validateattributes(p.focal_length_mm, {'numeric'}, {'scalar','positive','finite'});
validateattributes(p.window_mm, {'numeric'}, {'scalar','positive','finite'});
validateattributes(p.n_samples, {'numeric'}, {'scalar','integer','>=',256,'<=',4096});
validateattributes(p.object_scale_mm, {'numeric'}, {'scalar','positive','finite'});
validateattributes(p.secondary_scale_mm, {'numeric'}, {'scalar','positive','finite'});
validateattributes(p.phase_radius_mm, {'numeric'}, {'scalar','positive','finite'});
validateattributes(p.zernike_coeff_waves, {'numeric'}, {'scalar','finite'});
validateattributes(p.filter_scale_ratio, {'numeric'}, {'scalar','positive','finite','<=',1});
validateattributes(p.topological_charge, {'numeric'}, {'scalar','integer','finite'});
validateattributes(p.auto_adjust_plot_range, {'logical','numeric'}, {'scalar'});
validateattributes(p.object_plot_half_range_mm, {'numeric'}, {'scalar','positive','finite'});
validateattributes(p.fourier_plot_half_range_mm, {'numeric'}, {'scalar','positive','finite'});
p.lambda_m = p.wavelength_nm * 1e-9;
p.f_m = p.focal_length_mm * 1e-3;
p.window_m = p.window_mm * 1e-3;
p.object_scale_m = p.object_scale_mm * 1e-3;
p.secondary_scale_m = p.secondary_scale_mm * 1e-3;
p.phase_radius_m = p.phase_radius_mm * 1e-3;
p.title_stub = sprintf('%s + %s + %s', p.object_name, p.phase_name, p.filter_name);
end
