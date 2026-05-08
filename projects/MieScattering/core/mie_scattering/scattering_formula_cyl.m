function [X, Z, Esca_x, Esca_y, Esca_z, Etot_x, Etot_y, Etot_z] = scattering_formula_cyl(eps1, mu1, cfg)
%SCATTERING_FORMULA_CYL  Exact near-field of an infinite cylinder (kz=0) using cylindrical wave expansion.
%
% Geometry:
%   Cylinder axis: z
%   Incidence: +x direction (in x-y plane)
%   Plot plane: x-y (here we reuse X,Z mesh but interpret Z as y)
%
% Polarization:
%   Use same (nu, psi) parameterization as your sphere code,
%   but circular basis is in (y,z):
%       e± = (y ± i z)/sqrt2
%   So:
%       Ey0 = (A+ + A-)/sqrt2
%       Ez0 = i(A+ - A-)/sqrt2
%   Map to lecture coefficients:
%       A_TE = Ey0,  A_TM = Ez0
%
% Outside (rho>=R):
%   Esc from aE_m, aM_m with Hankel H_m^(1)(k rho)
% Inside (rho<R):
%   Eint from bE_m, bM_m with Bessel J_m(n k rho)

    if nargin ~= 3 || ~isstruct(cfg)
        error('Usage: scattering_formula_cyl(eps1, mu1, cfg)');
    end
    req = {'k','R','x','gridHalfWidth','N','nu','psi'};
    for i = 1:numel(req)
        if ~isfield(cfg, req{i})
            error('cfg must have field: %s', req{i});
        end
    end
    if ~isfield(cfg,'nmaxExtra'),  cfg.nmaxExtra = 15; end
    if ~isfield(cfg,'maskInside'), cfg.maskInside = true; end

    k   = cfg.k;
    R   = cfg.R;
    x   = cfg.x;     % x = kR
    nu  = cfg.nu;
    psi = cfg.psi;

    % Relative parameters
    n  = sqrt(eps1 .* mu1);        % refractive index
    zr = sqrt(mu1 ./ eps1);        % impedance ratio, same as your z1

    % Truncation for m
    mmax = ceil(x + 4*x^(1/3) + 2 + cfg.nmaxExtra);
    mmax = max(mmax, 1);

    % Grid (reuse X,Z naming; interpret Z as y)
    L = cfg.gridHalfWidth;
    Np = cfg.N;
    xv = linspace(-L, L, Np);
    yv = linspace(-L, L, Np);
    [X, Z] = meshgrid(xv, yv);  % Z is y

    rho = hypot(X, Z);
    phi = atan2(Z, X);          % [-pi, pi]
    inside  = (rho < R);
    outside = ~inside;

    % ===== Elliptical polarization in (y,z) plane =====
    Aplus  = 1 ./ sqrt(1 + nu.^2);
    Aminus = (nu ./ sqrt(1 + nu.^2)) .* exp(1i*psi);

    Ey0 = (Aplus + Aminus) ./ sqrt(2);
    Ez0 = 1i * (Aplus - Aminus) ./ sqrt(2);

    ATE = Ey0;
    ATM = Ez0;

    % Incident plane wave propagating +x
    phase = exp(1i*k*X);
    Einc_x = zeros(size(X));
    Einc_y = ATE .* phase;
    Einc_z = ATM .* phase;

    % Outputs
    Esca_x = complex(zeros(size(X)));
    Esca_y = complex(zeros(size(X)));
    Esca_z = complex(zeros(size(X)));
    Etot_x = complex(zeros(size(X)));
    Etot_y = complex(zeros(size(X)));
    Etot_z = complex(zeros(size(X)));

    % Precompute coefficients aE_m, aM_m, bE_m, bM_m (m=0..mmax)
    [aE, aM, bE, bM] = cyl_coeffs_dielectric(eps1, mu1, n, zr, x, mmax);

    % =========================
    % OUTSIDE: incident + scattered
    % =========================
    if any(outside(:))
        krho = k * rho;
        % avoid division by 0 in m/(k rho)
        den = krho; den = den + (den==0)*eps;

        % cylindrical components
        Erho_s = complex(zeros(size(rho)));
        Ephi_s = complex(zeros(size(rho)));
        Ez_s   = complex(zeros(size(rho)));

        % incident cylindrical components (we compute via series too? not needed)
        % We'll compute total as Cartesian: Einc + Esc, so only need Esc in Cartesian.
        for m = -mmax:mmax
            mm = abs(m);

            % coefficients for +/-m are equal in magnitude in this dielectric case (lecture notes)
            aE_m = aE(mm+1) * ATM;
            aM_m = aM(mm+1) * ATE;

            % basis factor i^m e^{i m phi}
            pref = (1i^m) .* exp(1i*m*phi);

            Hm   = besselh(m, 1, krho);
            Hmp  = 0.5*(besselh(m-1,1,krho) - besselh(m+1,1,krho));  % d/d(krho)

            Ez_s   = Ez_s   + pref .* ( Hm .* aE_m );
            Ephi_s = Ephi_s + pref .* ( -1i * Hmp .* aM_m );
            Erho_s = Erho_s + pref .* ( -(m./den) .* Hm .* aM_m );
        end

        % cylindrical -> Cartesian in x-y plane
        c = cos(phi); s = sin(phi);
        Ex_s = Erho_s .* c - Ephi_s .* s;
        Ey_s = Erho_s .* s + Ephi_s .* c;
        Ez_s = Ez_s;

        Esca_x(outside) = Ex_s(outside);
        Esca_y(outside) = Ey_s(outside);
        Esca_z(outside) = Ez_s(outside);

        Etot_x(outside) = Einc_x(outside) + Ex_s(outside);
        Etot_y(outside) = Einc_y(outside) + Ey_s(outside);
        Etot_z(outside) = Einc_z(outside) + Ez_s(outside);
    end

    % =========================
    % INSIDE: internal field (total = internal)
    % =========================
    if any(inside(:))
        krho1 = (n*k) * rho;
        den1  = (k*rho); den1 = den1 + (den1==0)*eps;  % note: lecture uses k rho in m/(k rho)

        Erho_i = complex(zeros(size(rho)));
        Ephi_i = complex(zeros(size(rho)));
        Ez_i   = complex(zeros(size(rho)));

        for m = -mmax:mmax
            mm = abs(m);

            bE_m = bE(mm+1) * ATM;
            bM_m = bM(mm+1) * ATE;

            pref = (1i^m) .* exp(1i*m*phi);

            Jm  = besselj(m, krho1);
            Jmp = 0.5*(besselj(m-1,krho1) - besselj(m+1,krho1)); % d/d(krho1)

            % Following lecture structure (kz=0):
            % Ez uses Jm(nk rho) bE_m
            Ez_i   = Ez_i   + pref .* ( Jm .* bE_m );

            % TE-part Ephi, Erho scale with eps_r in boundary; use lecture's 1/eps_r form:
            Ephi_i = Ephi_i + pref .* ( -1i * (n/eps1) .* Jmp .* bM_m );
            Erho_i = Erho_i + pref .* ( -(m./den1) .* (1/eps1) .* Jm .* bM_m );
        end

        c = cos(phi); s = sin(phi);
        Ex_i = Erho_i .* c - Ephi_i .* s;
        Ey_i = Erho_i .* s + Ephi_i .* c;
        Ez_i = Ez_i;

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

% ============================================================
% Cylinder coefficients for dielectric cylinder (infinite, kz=0)
% Lecture: aE,m/ATM and aM,m/ATE; internal bE,m, bM,m.
% ============================================================
function [aE, aM, bE, bM] = cyl_coeffs_dielectric(epsr, mur, n, zr, x, mmax)
    % allocate for m=0..mmax
    aE = complex(zeros(mmax+1,1));
    aM = complex(zeros(mmax+1,1));
    bE = complex(zeros(mmax+1,1));
    bM = complex(zeros(mmax+1,1));

    for m = 0:mmax
        % outside at kR = x
        Jm  = besselj(m, x);
        Nm  = bessely(m, x);
        Hm  = Jm + 1i*Nm;

        Jmp = 0.5*(besselj(m-1,x) - besselj(m+1,x));
        Nmp = 0.5*(bessely(m-1,x) - bessely(m+1,x));
        Hmp = Jmp + 1i*Nmp;

        % inside at nkR = n*x
        xn  = n*x;
        Pim  = besselj(m, xn);
        Pimp = 0.5*(besselj(m-1,xn) - besselj(m+1,xn));

        % aE,m / ATM  (TM-like, Ez)
        numE = -(zr*Pim*Jmp - Jm*Pimp);
        denE =  (zr*Pim*Hmp - Hm*Pimp);
        aE(m+1) = numE ./ denE;

        % bE,m / ATM
        % lecture: bE,m/ATM = (2i)/(pi*kR) * (zr)/(zr*Pi*H' - H*Pi')
        bE(m+1) = (2i/(pi*x)) * (zr ./ denE);

        % aM,m / ATE  (TE-like, driven by Ey)
        numM = -(Pim*Jmp - zr*Jm*Pimp);
        denM =  (Pim*Hmp - zr*Hm*Pimp);
        aM(m+1) = numM ./ denM;

        % bM,m / ATE
        bM(m+1) = (2i/(pi*x)) * (1 ./ denM);
    end
end
