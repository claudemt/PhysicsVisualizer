function result = jacobi_sn_result(params)
u = linspace(params.xmin,params.xmax,1400);
m_list = render_result('column',params,1,0.5);
curves = cell(1,numel(m_list));
for k = 1:numel(m_list)
    m = m_list(k);
    [sn,cn,dn] = ellipj(u,m);
    switch 'sn'
        case 'sn', y = sn;
        case 'cn', y = cn;
        case 'dn', y = dn;
    end
    curves{k} = struct('x',u,'y',y,'label',sprintf('$sn(u\\,|\\,%g)$',m));
end
result = render_result('make_curve_result',curves,'Jacobi elliptic function $sn(u|m)$','$u$','$f(u)$');
end
