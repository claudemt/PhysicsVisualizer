function grating = make_grating(n, spatial_frequency, angle_deg, phase_offset)
%MAKE_GRATING Generate a unit-range sinusoidal grating.

if nargin < 4
    phase_offset = 0;
end

[x, y] = meshgrid(linspace(-1, 1, n));
phase = 2 * pi * spatial_frequency * (x * cosd(angle_deg) + y * sind(angle_deg)) + phase_offset;
grating = 0.5 * (1 + cos(phase));
end
