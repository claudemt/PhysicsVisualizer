function result = jacobi_cn_result(params)
u = linspace(params.xmin,params.xmax,1400);
m_list = render_result('column',params,1,0.5);
curves = cell(1,numel(m_list));
for k = 1:numel(m_list)
    m = m_list(k);
    [~,cn,~] = ellipj(u,m);
    y = cn;
    curves{k} = struct('x',u,'y',y,'label',sprintf('$cn(u\\,|\\,%g)$',m));
end
result = render_result('make_curve_result',curves,'Jacobi elliptic function $cn(u|m)$','$u$','$f(u)$');
end
