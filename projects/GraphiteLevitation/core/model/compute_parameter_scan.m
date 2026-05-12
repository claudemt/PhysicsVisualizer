function result = compute_parameter_scan(params)
%COMPUTE_PARAMETER_SCAN Scan one physical parameter using visualization maps.

params = validate_graphite_levitation_params(params);
parameter = parse_graphite_levitation_params('normalize_scan_parameter', params.scan.parameter);
values = params.scan.values(:).';
valuesDisplay = params.scan.valuesDisplay(:).';
if isempty(values), values = get_nested_field(params, parameter, 0); valuesDisplay = values; end

metricNames = {'xMin','yMin','UMin','UAvg','UStd','UContrast','kx','ky','barrierX','barrierY','FcxOverMg','FcyOverMg','dxLaser','dyLaser','displacement','thetaX','thetaY','thetaMag','FLaserOverMg'};
metrics = struct();
for k = 1:numel(metricNames)
    metrics.(metricNames{k}) = nan(size(values));
end

for i = 1:numel(values)
    cfg = set_nested_field(params, parameter, values(i));
    if startsWith(parameter, 'laser.')
        cfg.laser.enabled = true;
    end
    cfg = validate_graphite_levitation_params(cfg);
    r = compute_visualization_maps(cfg);
    for k = 1:numel(metricNames)
        name = metricNames{k};
        if isfield(r.metrics, name)
            metrics.(name)(i) = r.metrics.(name);
        end
    end
end

result = struct();
result.params = params;
result.scan = struct('parameter', parameter, ...
    'displayLabel', parse_graphite_levitation_params('scan_display_label', parameter), ...
    'values', values, 'valuesDisplay', valuesDisplay, ...
    'highlightMetric', params.scan.highlightMetric);
result.metrics = metrics;
end
