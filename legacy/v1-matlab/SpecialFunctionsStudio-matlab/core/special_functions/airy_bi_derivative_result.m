function result = airy_bi_derivative_result(params)
x = linspace(params.xmin,params.xmax,1400);
y = airy(3,x);
curves = {struct('x',x,'y',y,'label','$Bi''(x)$')};
result = result_data('make_curve_result',curves,'Derivative $Bi''(x)$','$x$','$f(x)$');
end
