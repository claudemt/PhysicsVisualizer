function result = bessel_y_result(params)
x = linspace(max(params.xmin,0.02),params.xmax,1400);
orders = result_data('column',params,1,0);
curves = cell(1,numel(orders));
for k = 1:numel(orders)
    n = orders(k);
    y = bessely(n,x);
    curves{k} = struct('x',x,'y',y,'label',sprintf('$Y_{%g}(x)$',n));
end
result = result_data('make_curve_result',curves,'Bessel function $Y_n(x)$','$x$','$f(x)$');
end
