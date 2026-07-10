function result = lane_emden_result(params)
indices = render_result('column',params,1,3);
curves = cell(1,numel(indices));
for k = 1:numel(indices)
    n = indices(k);
    sol = solve_lane_emden(n,params.xmax);
    curves{k} = struct('x',sol.xi,'y',sol.theta,'label',sprintf('$n=%g$',n));
end
result = render_result('make_curve_result',curves,'Lane--Emden solutions $\theta_n(\xi)$','$\xi$','$\theta(\xi)$');
end

function sol = solve_lane_emden(n,xi_max)
x0 = 1e-6;
y0 = [1-x0^2/6; -x0/3];
opts = odeset('Events',@(x,y)stop_at_zero(x,y),'RelTol',1e-8,'AbsTol',1e-10);
[xx,yy,xe] = ode45(@(x,y)rhs(x,y,n),[x0 xi_max],y0,opts); %#ok<ASGLU>
xi = [0; xx]; theta = [1; yy(:,1)];
if ~isempty(xe), xi(end+1,1)=xe(1); theta(end+1,1)=0; end
sol = struct('xi',xi(:).','theta',theta(:).');
end

function dydx = rhs(x,y,n)
theta = y(1); v = y(2);
if theta >= 0, src = theta.^n; else, src = 0; end
dydx = [v; -src - 2*v/max(x,eps)];
end

function [value,isterminal,direction] = stop_at_zero(x,y)
value = y(1);
if x < 1e-5, value = 1; end
isterminal = 1; direction = -1;
end
