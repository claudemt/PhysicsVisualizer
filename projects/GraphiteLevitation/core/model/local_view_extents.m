function [halfX, halfY, sampleExtent] = local_view_extents(params)
%LOCAL_VIEW_EXTENTS Visible map half widths.
% The 2-D maps show the compact magnet array itself full-screen. No extra
% a/2 or b/2 border is added, because the experiment-relevant information is
% the small local modulation above the magnet array, not the trivial decay in
% the exterior field.

params = validate_graphite_levitation_params(params);
sampleExtent = graphite_extent(params.graphite);
halfX = params.array.nx * params.magnet.a / 2;
halfY = params.array.ny * params.magnet.b / 2;
end
