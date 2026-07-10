function result = airy_ai_derivative_result(params)
x = linspace(params.xmin,params.xmax,1400);
y = airy(1,x);
curves = {struct('x',x,'y',y,'label','$Ai''(x)$')};
result = result_data('make_curve_result',curves,'Derivative $Ai''(x)$','$x$','$f(x)$');
end
