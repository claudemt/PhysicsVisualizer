function result = airy_ai_result(params)
x = linspace(params.xmin,params.xmax,1400);
y = airy(0,x);
curves = {struct('x',x,'y',y,'label','$Ai(x)$')};
result = result_data('make_curve_result',curves,'Airy function $Ai(x)$','$x$','$f(x)$');
end
