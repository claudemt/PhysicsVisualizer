function R = planar_existence(modeType, Vmax, maxOrder)
%PLANAR_EXISTENCE Mode cutoff values in normalized V.
orders = 0:maxOrder;
cutoffV = orders*pi/2;
keep = cutoffV <= Vmax;
R = struct('modeType', modeType, 'orders', orders(keep), 'cutoffV', cutoffV(keep), 'Vmax', Vmax);
end
