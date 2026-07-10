function result = spherical_bessel_j_result(params)
x = linspace(max(params.xmin,0.02),params.xmax,1400);
orders = result_data('column',params,1,0);
curves = cell(1,numel(orders));
for k = 1:numel(orders)
    n = round(orders(k));
    y = sqrt(pi./(2*x)).*besselj(n+0.5,x);
    curves{k} = struct('x',x,'y',y,'label',sprintf('$j_{%d}(x)$',n));
end
result = result_data('make_curve_result',curves,'Spherical Bessel function $j_n(x)$','$x$','$f(x)$');
end
