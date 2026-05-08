function result = trace_thin_lens_bundle(object_distance, focal_length, object_height, aperture_radius, ray_count)
%TRACE_THIN_LENS_BUNDLE Build paraxial thin-lens rays from an object point.

ray_heights = linspace(-aperture_radius, aperture_radius, ray_count);
image_distance = 1 / (1 / focal_length - 1 / object_distance);
image_height = -image_distance / object_distance * object_height;

segments_in = zeros(ray_count, 4);
segments_out = zeros(ray_count, 4);

for k = 1:ray_count
    y_lens = ray_heights(k);
    segments_in(k, :) = [-object_distance, object_height, 0, y_lens];
    segments_out(k, :) = [0, y_lens, image_distance, image_height];
end

result = struct();
result.ray_heights = ray_heights;
result.image_distance = image_distance;
result.image_height = image_height;
result.magnification = image_height / object_height;
result.segments_in = segments_in;
result.segments_out = segments_out;
end
