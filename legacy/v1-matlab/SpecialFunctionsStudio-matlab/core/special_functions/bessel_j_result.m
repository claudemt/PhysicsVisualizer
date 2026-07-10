function result = bessel_j_result(params)
x = linspace(params.xmin,params.xmax,1400);
orders = result_data('column',params,1,0);
curves = cell(1,numel(orders));
for k = 1:numel(orders)
    n = orders(k);
    y = besselj(n,x);
    curves{k} = struct('x',x,'y',y,'label',sprintf('$J_{%g}(x)$',n));
end
result = result_data('make_curve_result',curves,'Bessel function $J_n(x)$','$x$','$f(x)$');
end
