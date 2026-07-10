function result = airy_bi_result(params)
x = linspace(params.xmin,params.xmax,1400);
y = airy(2,x);
curves = {struct('x',x,'y',y,'label','$Bi(x)$')};
result = result_data('make_curve_result',curves,'Airy function $Bi(x)$','$x$','$f(x)$');
end
