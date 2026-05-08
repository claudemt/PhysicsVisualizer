function [X, Z, Esca_x, Esca_y, Esca_z, Etot_x, Etot_y, Etot_z] = scattering_formula_sph(eps1, mu1, cfg)
%SCATTERING_FORMULA  Exact near-field of a sphere using full Mie VSWF expansion.
%
% Outside (r>=R):
%   E_tot = E_inc + E_sca
%   E_sca computed by series with a_n, b_n and VSWFs (type 3): h_n^(1)(kr)
%
% Inside (r<R):
%   E_tot = E_int computed by series with c_n, d_n and VSWFs (type 1): j_n(mkr)
%
% Geometry:
%   x-z plane with phi = 0
%   Incident plane wave: propagating +z, general elliptical polarization:
%     A+ = 1/sqrt(1+nu^2),  A- = nu/sqrt(1+nu^2)*exp(i psi)
%     e± = (x ± i y)/sqrt2
%     E0x = (A+ + A-)/sqrt2
%     E0y = i(A+ - A-)/sqrt2
%
% Outputs:
%   Esca_x, Esca_y, Esca_z : scattered field components (NaN inside if cfg.maskInside=true)
%   Etot_x, Etot_y, Etot_z : total field components (inside uses internal field)

    if nargin ~= 3 || ~isstruct(cfg)
        error('Usage: scattering_formula(eps1, mu1, cfg)');
    end
    req = {'k','R','x','gridHalfWidth','N','nu','psi'};
    for i = 1:numel(req)
        if ~isfield(cfg, req{i})
            error('cfg must have field: %s', req{i});
        end
    end
    if ~isfield(cfg,'nmaxExtra'), cfg.nmaxExtra = 15; end
    if ~isfield(cfg,'maskInside'), cfg.maskInside = true; end

    k = cfg.k;
    R = cfg.R;
    x = cfg.x;

    nu  = cfg.nu;
    psi = cfg.psi;

    % Relative parameters (ambient eps=mu=1)
    m  = sqrt(eps1 .* mu1);
    z1 = sqrt(mu1 ./ eps1);

    % Truncation
    nmax = ceil(x + 4*x^(1/3) + 2 + cfg.nmaxExtra);
    nmax = max(nmax, 1);

    % Coefficients
    [an, bn] = mie2_ab_local(m, z1, x, nmax);
    [cn, dn] = mie2_cd_local(m, mu1, x, nmax);

    % Grid
    L = cfg.gridHalfWidth;
    N = cfg.N;
    xv = linspace(-L, L, N);
    zv = linspace(-L, L, N);
    [X, Z] = meshgrid(xv, zv);

    r = hypot(X, Z);
    theta = acos_safe(Z ./ max(r, eps));
    u = cos(theta);
    sinth = sin(theta);
    costh = cos(theta);

    % x-z plane => phi = 0
    cosphi = ones(size(theta));
    sinphi = zeros(size(theta));

    inside  = (r < R);
    outside = ~inside;

    % ===== Elliptical polarization from (nu, psi) =====
    % (lecture A+,A-)
    Aplus  = 1 ./ sqrt(1 + nu.^2);
    Aminus = (nu ./ sqrt(1 + nu.^2)) .* exp(1i*psi);

    % convert circular basis to (x,y) Jones vector
    E0x = (Aplus + Aminus) ./ sqrt(2);
    E0y = 1i * (Aplus - Aminus) ./ sqrt(2);

    % Incident plane wave
    phase = exp(1i*k*Z);
    Einc_x = E0x .* phase;
    Einc_y = E0y .* phase;
    Einc_z = zeros(size(Z));

    % Outputs
    Esca_x = complex(zeros(size(X)));
    Esca_y = complex(zeros(size(X)));
    Esca_z = complex(zeros(size(X)));
    Etot_x = complex(zeros(size(X)));
    Etot_y = complex(zeros(size(X)));
    Etot_z = complex(zeros(size(X)));

    % ============================================================
    % OUTSIDE: scattered field (type-3 VSWF: hankel)
    % We compute basis response for x-inc and y-inc, then superpose by (E0x,E0y)
    % ============================================================
    if any(outside(:))
        rho = k * r;  % full grid

        % spherical comps for x-inc & y-inc
        Er_x  = complex(zeros(size(r)));  Eth_x = complex(zeros(size(r)));  Eph_x = complex(zeros(size(r)));
        Er_y  = complex(zeros(size(r)));  Eth_y = complex(zeros(size(r)));  Eph_y = complex(zeros(size(r)));

        % angular recurrence
        pi_nm2 = zeros(size(u));   % pi_0
        pi_nm1 = ones(size(u));    % pi_1

        % n=1
        n = 1;
        pi_n  = pi_nm1;
        tau_n = u;

        coef = (2*n+1)/(n*(n+1));
        fn   = sph_hankel1(n, rho);
        psi_p = riccati_derivative(n, rho, fn, 'h');

        % ---- x-inc: N_e, M_o ----
        [Nr_e, Nth_e, Nph_e] = N_e1n(pi_n, tau_n, sinth, cosphi, sinphi, fn, psi_p, rho, n);
        [~,    Mth_o, Mph_o] = M_o1n(pi_n, tau_n, cosphi, sinphi, fn);

        Er_x  = Er_x  + coef * ( an(n) .* Nr_e );
        Eth_x = Eth_x + coef * ( an(n) .* Nth_e - bn(n) .* Mth_o );
        Eph_x = Eph_x + coef * ( an(n) .* Nph_e - bn(n) .* Mph_o );

        % ---- y-inc: N_o, M_e ----
        [Nr_o, Nth_o, Nph_o] = N_o1n(pi_n, tau_n, sinth, cosphi, sinphi, fn, psi_p, rho, n);
        [~,    Mth_e, Mph_e] = M_e1n(pi_n, tau_n, cosphi, sinphi, fn);

        Er_y  = Er_y  + coef * ( an(n) .* Nr_o );
        Eth_y = Eth_y + coef * ( an(n) .* Nth_o - bn(n) .* Mth_e );
        Eph_y = Eph_y + coef * ( an(n) .* Nph_o - bn(n) .* Mph_e );

        % n>=2
        for n = 2:nmax
            pi_n = ((2*n-1)/(n-1))*u.*pi_nm1 - (n/(n-1))*pi_nm2;
            tau_n = n*u.*pi_n - (n+1)*pi_nm1;

            coef = (2*n+1)/(n*(n+1));
            fn   = sph_hankel1(n, rho);
            psi_p = riccati_derivative(n, rho, fn, 'h');

            [Nr_e, Nth_e, Nph_e] = N_e1n(pi_n, tau_n, sinth, cosphi, sinphi, fn, psi_p, rho, n);
            [~,    Mth_o, Mph_o] = M_o1n(pi_n, tau_n, cosphi, sinphi, fn);

            Er_x  = Er_x  + coef * ( an(n) .* Nr_e );
            Eth_x = Eth_x + coef * ( an(n) .* Nth_e - bn(n) .* Mth_o );
            Eph_x = Eph_x + coef * ( an(n) .* Nph_e - bn(n) .* Mph_o );

            [Nr_o, Nth_o, Nph_o] = N_o1n(pi_n, tau_n, sinth, cosphi, sinphi, fn, psi_p, rho, n);
            [~,    Mth_e, Mph_e] = M_e1n(pi_n, tau_n, cosphi, sinphi, fn);

            Er_y  = Er_y  + coef * ( an(n) .* Nr_o );
            Eth_y = Eth_y + coef * ( an(n) .* Nth_o - bn(n) .* Mth_e );
            Eph_y = Eph_y + coef * ( an(n) .* Nph_o - bn(n) .* Mph_e );

            pi_nm2 = pi_nm1;
            pi_nm1 = pi_n;
        end

        % spherical -> Cartesian at phi=0:
        % Ex = Er sinθ + Eθ cosθ ; Ey = Eφ ; Ez = Er cosθ - Eθ sinθ
        Ex_s_x = Er_x .* sinth + Eth_x .* costh;
        Ey_s_x = Eph_x;
        Ez_s_x = Er_x .* costh - Eth_x .* sinth;

        Ex_s_y = Er_y .* sinth + Eth_y .* costh;
        Ey_s_y = Eph_y;
        Ez_s_y = Er_y .* costh - Eth_y .* sinth;

        % superpose
        Ex_s = E0x.*Ex_s_x + E0y.*Ex_s_y;
        Ey_s = E0x.*Ey_s_x + E0y.*Ey_s_y;
        Ez_s = E0x.*Ez_s_x + E0y.*Ez_s_y;

        Esca_x(outside) = Ex_s(outside);
        Esca_y(outside) = Ey_s(outside);
        Esca_z(outside) = Ez_s(outside);

        Etot_x(outside) = Einc_x(outside) + Ex_s(outside);
        Etot_y(outside) = Einc_y(outside) + Ey_s(outside);
        Etot_z(outside) = Einc_z(outside) + Ez_s(outside);
    end

    % ============================================================
    % INSIDE: internal field (type-1 VSWF: bessel)
    % compute x-inc & y-inc internal responses, then superpose
    % ============================================================
    if any(inside(:))
        rho1 = (m*k) * r;

        Er_x  = complex(zeros(size(r)));  Eth_x = complex(zeros(size(r)));  Eph_x = complex(zeros(size(r)));
        Er_y  = complex(zeros(size(r)));  Eth_y = complex(zeros(size(r)));  Eph_y = complex(zeros(size(r)));

        pi_nm2 = zeros(size(u));
        pi_nm1 = ones(size(u));

        % n=1
        n = 1;
        pi_n  = pi_nm1;
        tau_n = u;

        coef = (2*n+1)/(n*(n+1));
        fn   = sph_besselj(n, rho1);
        psi_p = riccati_derivative(n, rho1, fn, 'j');

        % x-inc internal: cn*M_o - dn*N_e
        [Nr_e, Nth_e, Nph_e] = N_e1n(pi_n, tau_n, sinth, cosphi, sinphi, fn, psi_p, rho1, n);
        [~,    Mth_o, Mph_o] = M_o1n(pi_n, tau_n, cosphi, sinphi, fn);

        Er_x  = Er_x  + coef * ( -dn(n) .* Nr_e );
        Eth_x = Eth_x + coef * (  cn(n) .* Mth_o - dn(n) .* Nth_e );
        Eph_x = Eph_x + coef * (  cn(n) .* Mph_o - dn(n) .* Nph_e );

        % y-inc internal: cn*M_e - dn*N_o
        [Nr_o, Nth_o, Nph_o] = N_o1n(pi_n, tau_n, sinth, cosphi, sinphi, fn, psi_p, rho1, n);
        [~,    Mth_e, Mph_e] = M_e1n(pi_n, tau_n, cosphi, sinphi, fn);

        Er_y  = Er_y  + coef * ( -dn(n) .* Nr_o );
        Eth_y = Eth_y + coef * (  cn(n) .* Mth_e - dn(n) .* Nth_o );
        Eph_y = Eph_y + coef * (  cn(n) .* Mph_e - dn(n) .* Nph_o );

        for n = 2:nmax
            pi_n = ((2*n-1)/(n-1))*u.*pi_nm1 - (n/(n-1))*pi_nm2;
            tau_n = n*u.*pi_n - (n+1)*pi_nm1;

            coef = (2*n+1)/(n*(n+1));
            fn   = sph_besselj(n, rho1);
            psi_p = riccati_derivative(n, rho1, fn, 'j');

            [Nr_e, Nth_e, Nph_e] = N_e1n(pi_n, tau_n, sinth, cosphi, sinphi, fn, psi_p, rho1, n);
            [~,    Mth_o, Mph_o] = M_o1n(pi_n, tau_n, cosphi, sinphi, fn);

            Er_x  = Er_x  + coef * ( -dn(n) .* Nr_e );
            Eth_x = Eth_x + coef * (  cn(n) .* Mth_o - dn(n) .* Nth_e );
            Eph_x = Eph_x + coef * (  cn(n) .* Mph_o - dn(n) .* Nph_e );

            [Nr_o, Nth_o, Nph_o] = N_o1n(pi_n, tau_n, sinth, cosphi, sinphi, fn, psi_p, rho1, n);
            [~,    Mth_e, Mph_e] = M_e1n(pi_n, tau_n, cosphi, sinphi, fn);

            Er_y  = Er_y  + coef * ( -dn(n) .* Nr_o );
            Eth_y = Eth_y + coef * (  cn(n) .* Mth_e - dn(n) .* Nth_o );
            Eph_y = Eph_y + coef * (  cn(n) .* Mph_e - dn(n) .* Nph_o );

            pi_nm2 = pi_nm1;
            pi_nm1 = pi_n;
        end

        Ex_i_x = Er_x .* sinth + Eth_x .* costh;
        Ey_i_x = Eph_x;
        Ez_i_x = Er_x .* costh - Eth_x .* sinth;

        Ex_i_y = Er_y .* sinth + Eth_y .* costh;
        Ey_i_y = Eph_y;
        Ez_i_y = Er_y .* costh - Eth_y .* sinth;

        Ex_i = E0x.*Ex_i_x + E0y.*Ex_i_y;
        Ey_i = E0x.*Ey_i_x + E0y.*Ey_i_y;
        Ez_i = E0x.*Ez_i_x + E0y.*Ez_i_y;

        Etot_x(inside) = Ex_i(inside);
        Etot_y(inside) = Ey_i(inside);
        Etot_z(inside) = Ez_i(inside);

        if cfg.maskInside
            Esca_x(inside) = NaN;
            Esca_y(inside) = NaN;
            Esca_z(inside) = NaN;
        end
    end
end

% ===================== VSWF (m=1) component builders ======================
function [Mr, Mth, Mph] = M_o1n(pi_n, tau_n, cosphi, sinphi, zn)
    Mr  = 0;
    Mth =  cosphi .* pi_n .* zn;
    Mph = -sinphi .* tau_n .* zn;
end

function [Mr, Mth, Mph] = M_e1n(pi_n, tau_n, cosphi, sinphi, zn)
    Mr  = 0;
    Mth = -sinphi .* pi_n .* zn;
    Mph = -cosphi .* tau_n .* zn;
end

function [Nr, Nth, Nph] = N_e1n(pi_n, tau_n, sinth, cosphi, sinphi, zn, psi_p, rho, n)
    den = rho; den = den + (den==0)*eps;
    Nr  =  cosphi .* (n*(n+1)) .* sinth .* pi_n .* (zn ./ den);
    fac = (psi_p ./ den);
    Nth =  cosphi .* tau_n .* fac;
    Nph = -sinphi .* pi_n  .* fac;
end

function [Nr, Nth, Nph] = N_o1n(pi_n, tau_n, sinth, cosphi, sinphi, zn, psi_p, rho, n)
    den = rho; den = den + (den==0)*eps;
    Nr  = -sinphi .* (n*(n+1)) .* sinth .* pi_n .* (zn ./ den);
    fac = (psi_p ./ den);
    Nth = -sinphi .* tau_n .* fac;
    Nph = -cosphi .* pi_n  .* fac;
end

% ============================================================
% Mie coefficients a_n, b_n via Dn(z) downward recurrence
% ============================================================
% ============================================================
% Mie coefficients a_n, b_n via Dn(z) downward recurrence
% (FIXED: xi_0 initial value)
% ============================================================
function [an, bn] = mie2_ab_local(m, z1, x, nmax)
    z = m * x;

    nstart = round(max(nmax, abs(z)) + 16);
    D = zeros(1, nmax);
    Dnext = 0;
    for n = nstart:-1:1
        Dcur = (n./z) - 1./(Dnext + (n./z));
        if n <= nmax
            D(n) = Dcur;
        end
        Dnext = Dcur;
    end
    Dn = D(:);

    n = (1:nmax).';

    % Riccati-Bessel functions
    psi = x .* sph_besselj(n, x);
    xi  = x .* sph_hankel1(n, x);

    % --- FIX #1 ---
    % psi_0(x) = sin(x)
    psi_m1 = [sin(x); psi(1:end-1)];

    % xi_0(x) = x*h_0^(1)(x) = -i*exp(i x)
    xi_m1  = [-1i*exp(1i*x); xi(1:end-1)];

    % derivatives: (rho f_n)' = rho f_{n-1} - n f_n  => f_n' riccati form
    psi_p = psi_m1 - (n.*psi)./x;
    xi_p  = xi_m1  - (n.*xi )./x;

    A_num = (Dn./z1).*psi - psi_p;
    A_den = (Dn./z1).*xi  - xi_p;
    B_num = (z1.*Dn).*psi - psi_p;
    B_den = (z1.*Dn).*xi  - xi_p;

    an = (A_num ./ A_den).';
    bn = (B_num ./ B_den).';
end
% ============================================================
% Internal coefficients c_n, d_n (magnetic sphere explicit form)
% (FIXED: dn formula uses eps_r properly)
% ============================================================
function [cn, dn] = mie2_cd_local(m, mu1, x, nmax)
    n = (1:nmax).';

    jx  = sph_besselj(n, x);
    hx  = sph_hankel1(n, x);

    % Riccati-derivative style:
    % (x f_n(x))' = x f_{n-1}(x) - n f_n(x)
    xjx_p = x * sph_besselj(n-1, x) - n .* sph_besselj(n, x);
    xhx_p = x * sph_hankel1(n-1, x) - n .* sph_hankel1(n, x);

    mx = m * x;
    jmx = sph_besselj(n, mx);
    mxjmx_p = mx .* sph_besselj(n-1, mx) - n .* sph_besselj(n, mx);

    mu = 1; 

    num_c = mu1 .* ( jx .* xhx_p - hx .* xjx_p );
    den_c = mu1 .* jmx .* xhx_p - mu .* hx .* mxjmx_p;
    cn = (num_c ./ den_c).';

    % --- FIX #2: d_n must use eps_r, not extra mu1/m^2 factors ---
    % eps_r = (m^2) / mu_r  (since m^2 = eps_r * mu_r, mu_r = mu1)
    epsr = (m.^2) ./ mu1;

    num_d = m .* ( jx .* xhx_p - hx .* xjx_p );
    den_d = epsr .* jmx .* xhx_p - hx .* mxjmx_p;
    dn = (num_d ./ den_d).';
end


% ============================================================
% Special functions
% ============================================================
function jn = sph_besselj(n, z)
    n = double(n);
    jn = sqrt(pi./(2*z)) .* besselj(n+0.5, z);
end

function yn = sph_bessely(n, z)
    n = double(n);
    yn = sqrt(pi./(2*z)) .* bessely(n+0.5, z);
end

function hn = sph_hankel1(n, z)
    hn = sph_besselj(n, z) + 1i*sph_bessely(n, z);
end

function psi_p = riccati_derivative(n, rho, fn, kind)
% (rho f_n)' = rho f_{n-1} - n f_n
    switch kind
        case 'j'
            f_nm1 = sph_besselj(n-1, rho);
        case 'h'
            f_nm1 = sph_hankel1(n-1, rho);
        otherwise
            error('kind must be j or h');
    end
    psi_p = rho .* f_nm1 - n .* fn;
end

function th = acos_safe(x)
    x = max(min(x, 1), -1);
    th = acos(x);
end
