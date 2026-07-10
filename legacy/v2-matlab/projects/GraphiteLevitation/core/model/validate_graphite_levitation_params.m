function params = validate_graphite_levitation_params(params)
%VALIDATE_GRAPHITE_LEVITATION_PARAMS Fill missing fields and clamp values.

if nargin < 1 || isempty(params) || ~isstruct(params)
    params = struct();
end
params = local_merge(default_graphite_levitation_params(), params);

params.graphite.shape = validatestring(char(string(params.graphite.shape)), {'circle','square'});
params.graphite.radius = max(params.graphite.radius, 0.1e-3);
params.graphite.side = max(params.graphite.side, 0.1e-3);
params.graphite.thickness = max(params.graphite.thickness, 0.1e-6);
params.graphite.z0 = max(params.graphite.z0, 0.02e-3);
params.graphite.chiAbs = max(params.graphite.chiAbs, eps);
params.graphite.rho = max(params.graphite.rho, 1);
if ~isfinite(params.graphite.rotationDeg), params.graphite.rotationDeg = 0; end

params.array.nx = max(1, round(params.array.nx));
params.array.ny = max(1, round(params.array.ny));

params.magnet.a = max(params.magnet.a, 0.2e-3);
params.magnet.b = max(params.magnet.b, 0.2e-3);
params.magnet.c = max(params.magnet.c, 0.2e-3);
params.magnet.Br = max(params.magnet.Br, 1e-6);

params.laser.enabled = logical(params.laser.enabled);
params.laser.alpha = max(params.laser.alpha, 0);
params.laser.spotDiameter = max(params.laser.spotDiameter, 0.05e-3);

params.numerics.gridN = max(81, round(params.numerics.gridN));
if mod(params.numerics.gridN, 2) == 0, params.numerics.gridN = params.numerics.gridN + 1; end
params.numerics.kernelN = max(25, round(params.numerics.kernelN));
if mod(params.numerics.kernelN, 2) == 0, params.numerics.kernelN = params.numerics.kernelN + 1; end
params.numerics.chiGridN = max(80, round(params.numerics.chiGridN));
params.numerics.mapMargin = max(params.numerics.mapMargin, 1.0);
params.numerics.mapExtraMM = max(params.numerics.mapExtraMM, 0);
params.numerics.fieldSourceN = max(1, round(params.numerics.fieldSourceN));
params.numerics.fieldSoftening = max(params.numerics.fieldSoftening, 1e-6);

params.tilt.torsionalStiffness = max(params.tilt.torsionalStiffness, 1e-15);

if ~isfield(params, 'scan') || ~isstruct(params.scan)
    d0 = default_graphite_levitation_params();
    params.scan = d0.scan;
end
end

function out = local_merge(defaults, user)
out = defaults;
if ~isstruct(user), return; end
names = fieldnames(user);
for k = 1:numel(names)
    name = names{k};
    if isfield(out, name) && isstruct(out.(name)) && isstruct(user.(name))
        out.(name) = local_merge(out.(name), user.(name));
    else
        out.(name) = user.(name);
    end
end
end
