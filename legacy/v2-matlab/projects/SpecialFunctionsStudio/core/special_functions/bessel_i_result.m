function result = bessel_i_result(params)
x = linspace(params.xmin,params.xmax,1400);
orders = render_result('column',params,1,0);
curves = cell(1,numel(orders));
for k = 1:numel(orders)
    n = orders(k);
    y = besseli(n,x);
    curves{k} = struct('x',x,'y',y,'label',sprintf('$I_{%g}(x)$',n));
end
result = render_result('make_curve_result',curves,'Modified Bessel function $I_n(x)$','$x$','$f(x)$');
end
