function out = phase_thin_lens(X, Y, params)
%PHASE_THIN_LENS Thin-lens quadratic phase.
if nargin == 1 && ischar(X) && strcmpi(X, 'info')
    out = struct('Name', 'Thin lens', ...
        'Description', 'Quadratic thin-lens phase term exp[-i pi (x^2+y^2)/(lambda f)] inside a finite circular pupil.');
    return
end
out = -(pi ./ max(params.lambda_m * params.f_m, eps)) .* (X.^2 + Y.^2);
mask = hypot(X, Y) <= max(params.phase_radius_m, eps);
out(~mask) = 0;
end
