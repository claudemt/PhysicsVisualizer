function [Uf, climVal] = signed_field_for_display(U, doNormalize)
%SIGNED_FIELD_FOR_DISPLAY Prepare signed scalar field for plotting.

umax = max(abs(U(:)), [], 'omitnan');
if ~isfinite(umax) || umax < eps
    umax = 1.0;
end
if doNormalize
    Uf = U ./ umax;
    climVal = 1.0;
else
    Uf = U;
    climVal = umax;
end
end
