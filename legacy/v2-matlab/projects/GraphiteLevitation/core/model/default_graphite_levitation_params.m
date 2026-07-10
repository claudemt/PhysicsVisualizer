function params = default_graphite_levitation_params()
%DEFAULT_GRAPHITE_LEVITATION_PARAMS Central defaults for GraphiteLevitation.
% GUI exposes only physical controls. Numerical/rendering knobs stay here.

params = struct();

params.graphite = struct( ...
    'shape', 'circle', ...              % 'circle' or 'square'
    'radius', 6.0e-3, ...               % circle radius [m]
    'side', 10e-3, ...                  % square side length [m]
    'rotationDeg', 0, ...               % square rotation in the xy plane [deg]
    'thickness', 40e-6, ...             % graphite thickness [m]
    'z0', 1.05e-3, ...                  % initial height guess above magnet top [m]
    'chiAbs', 3.05e-4, ...              % |chi|, dimensionless
    'rho', 2200);                       % density [kg/m^3]

params.array = struct( ...
    'nx', 6, ...
    'ny', 6);

params.magnet = struct( ...
    'a', 10e-3, ...                     % x size [m]
    'b', 10e-3, ...                     % y size [m]
    'c', 10e-3, ...                     % z size [m]
    'Br', 1.46);                        % remanence proxy [T]

params.laser = struct( ...
    'enabled', false, ...
    'spotX', 3.0e-3, ...                % sample-local coordinate [m]
    'spotY', 0.0, ...                   % sample-local coordinate [m]
    'alpha', 0.35, ...                  % susceptibility nonuniformity strength
    'spotDiameter', 3.0e-3);            % fixed default spot diameter [m], not in GUI

params.numerics = struct( ...
    'gridN', 221, ...                   % image grid resolution
    'kernelN', 111, ...                 % graphite kernel grid resolution
    'chiGridN', 260, ...                % susceptibility image resolution
    'mapMargin', 1.25, ...              % extra margin beyond compact array
    'mapExtraMM', 14, ...               % extra visible margin [mm]
    'mu0', 4*pi*1e-7, ...
    'fieldSourceN', 3, ...              % internal surface-charge subdivision per edge
    'fieldSoftening', 0.35e-3, ...       % internal softening for visualization [m]
    'forceKernelN', 55, ...              % hidden quadrature for force/torque diagnostics
    'forceDz', 0.035e-3);                % hidden finite-difference step for Fz diagnostics [m]         % internal softening for visualization [m]

params.tilt = struct( ...
    'torsionalStiffness', 3.0e-6);       % phenomenological N*m/rad, hidden from GUI

params.render = struct( ...
    'dpi', 320);

params.scan = struct( ...
    'parameter', 'laser.alpha', ...
    'values', [0 0.1 0.25 0.4], ...
    'valuesDisplay', [0 0.1 0.25 0.4], ...
    'highlightMetric', 'displacement');
end
