function result = complete_elliptic_e_result(params)
m = linspace(max(0,params.xmin),min(0.999999,params.xmax),1400);
[~,E] = ellipke(m);
curves = {struct('x',m,'y',E,'label','$E(m)$')};
result = render_result('make_curve_result',curves,'Complete elliptic integral $E(m)$','$m$','$E(m)$');
end
