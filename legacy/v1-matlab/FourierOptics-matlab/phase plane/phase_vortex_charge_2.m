function out = phase_vortex_charge_2(X, Y, params)
%PHASE_VORTEX_CHARGE_2 Vortex phase with default charge 2.
if nargin == 1 && ischar(X) && strcmpi(X, 'info')
    out = struct('Name', 'Vortex charge 2', ...
        'Description', 'Azimuthal vortex phase with a charge-two default, while still obeying params.topological_charge when changed.');
    return
end
mask = hypot(X, Y) <= max(params.phase_radius_m, eps);
charge = max(2, abs(params.topological_charge));
out = charge .* atan2(Y, X);
out(~mask) = 0;
end
