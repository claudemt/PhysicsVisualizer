function out = phase_vortex_charge_1(X, Y, params)
%PHASE_VORTEX_CHARGE_1 Vortex phase with configurable topological charge.
if nargin == 1 && ischar(X) && strcmpi(X, 'info')
    out = struct('Name', 'Vortex charge 1', ...
        'Description', 'Azimuthal vortex phase exp(i l theta); the charge is controlled by params.topological_charge.');
    return
end
mask = hypot(X, Y) <= max(params.phase_radius_m, eps);
out = params.topological_charge .* atan2(Y, X);
out(~mask) = 0;
end
