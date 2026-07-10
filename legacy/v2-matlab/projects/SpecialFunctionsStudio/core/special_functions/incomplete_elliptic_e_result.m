function result = incomplete_elliptic_e_result(params)
phi = linspace(params.xmin,params.xmax,450);
m_list = render_result('column',params,1,0.5);
curves = cell(1,numel(m_list));
for k = 1:numel(m_list)
    m = m_list(k);
    y = arrayfun(@(x)ellipticE_scalar(x,m),phi);
    curves{k} = struct('x',phi,'y',y,'label',sprintf('$E(\\phi\\,|\\,%g)$',m));
end
result = render_result('make_curve_result',curves,'Incomplete elliptic integral $E(\phi|m)$','$\phi$','$E(\phi|m)$');
end
function val = ellipticE_scalar(phi,m)
sgn = sign(phi); upper = abs(phi);
f = @(t) sqrt(max(1-m.*sin(t).^2,0));
val = sgn*integral(f,0,upper,'ArrayValued',true,'RelTol',1e-8,'AbsTol',1e-10);
end
