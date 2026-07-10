function result = complete_elliptic_k_result(params)
m = linspace(max(0,params.xmin),min(0.999999,params.xmax),1400);
[K,~] = ellipke(m);
curves = {struct('x',m,'y',K,'label','$K(m)$')};
result = result_data('make_curve_result',curves,'Complete elliptic integral $K(m)$','$m$','$K(m)$');
end
