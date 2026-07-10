function conductor_circhole(a_over_lambda, z_over_lambda, mapMode)
    here = fileparts(mfilename('fullpath'));
    addpath(fullfile(here,'..','Support-matlab'));

    outDir = fullfile(here,'conductor_circhole_output');
    if exist(outDir,'dir') ~= 7
        mkdir(outDir);
    end

    if nargin < 2
        vals = ask_hole_parameters();
        if isempty(vals), return; end
        a_over_lambda = vals(1);
        z_over_lambda = vals(2);
    end

    if nargin < 3 || isempty(mapMode)
        mapMode = 'log';
    end

    if ~isscalar(a_over_lambda) || ~isfinite(a_over_lambda) || a_over_lambda <= 0
        error('a_over_lambda must be positive.');
    end
    if ~isscalar(z_over_lambda) || ~isfinite(z_over_lambda)
        error('z_over_lambda must be finite.');
    end
    if ~any(strcmp(mapMode, {'log','linear'}))
        error('mapMode must be ''log'' or ''linear''.');
    end

    typeList = {'E_t','E_z','E_mag','H_t','H_z','H_mag','show all graphs'};
    pickedType = ask_choice_dialog('Circular Hole - Plot Type', 'Choose plot type:', typeList, 7);
    if isempty(pickedType), return; end

    lambda = 1;
    a = a_over_lambda * lambda;
    z0 = z_over_lambda * lambda;

    N = 600;
    L = max(2.5*lambda, 3.2*a);
    xv = linspace(-L, L, N);
    yv = linspace(-L, L, N);
    [X,Y] = meshgrid(xv,yv);
    Z = z0 * ones(size(X));

    [Ex,Ey,Ez] = electric_field(X,Y,Z,a);
    [Hx,Hy,Hz] = magnetic_field(X,Y,Z,a);

    F.E_t   = hypot(Ex,Ey);
    F.E_z   = Ez;
    F.E_mag = sqrt(Ex.^2 + Ey.^2 + Ez.^2);
    F.H_t   = hypot(Hx,Hy);
    F.H_z   = Hz;
    F.H_mag = sqrt(Hx.^2 + Hy.^2 + Hz.^2);

    labels.E_t   = '$E_t$';
    labels.E_z   = '$E_z$';
    labels.E_mag = '$E_{mag}$';
    labels.H_t   = '$H_t$';
    labels.H_z   = '$H_z$';
    labels.H_mag = '$H_{mag}$';

    titles.E_t   = 'E_t';
    titles.E_z   = 'E_z';
    titles.E_mag = 'E_{mag}';
    titles.H_t   = 'H_t';
    titles.H_z   = 'H_z';
    titles.H_mag = 'H_{mag}';

    signed.E_t   = false;
    signed.E_z   = true;
    signed.E_mag = false;
    signed.H_t   = false;
    signed.H_z   = true;
    signed.H_mag = false;

    keys = {'E_t','E_z','E_mag','H_t','H_z','H_mag'};

    if ~strcmp(pickedType, 'show all graphs')
        key = pickedType;
        plot_and_save(F.(key), xv, yv, a_over_lambda, key, labels.(key), titles.(key), ...
            signed.(key), a_over_lambda, z_over_lambda, mapMode, outDir);
    else
        for i = 1:6
            key = keys{i};
            plot_and_save(F.(key), xv, yv, a_over_lambda, key, labels.(key), titles.(key), ...
                signed.(key), a_over_lambda, z_over_lambda, mapMode, outDir);
        end
    end

    fprintf('Images saved to: %s\n', outDir);
end

% =========================================================================
% 修改后的参数输入对话框（使用 WindowKeyPressFcn）
% =========================================================================
function vals = ask_hole_parameters()
    vals = [];
    d = dialog('Position',[420 320 420 190], ...   % 宽度增加，确保标签完整
        'Name','Circular Hole Input', ...
        'WindowStyle','normal', ...
        'WindowKeyPressFcn',@onKey);               % 统一键盘处理

    uicontrol(d,'Style','text','String','a/lambda', ...
        'Position',[30 125 100 24], ...
        'HorizontalAlignment','left','FontSize',12);

    e1 = uicontrol(d,'Style','edit','String','1.2', ...
        'Position',[140 125 240 28], 'FontSize',12);   % 无 KeyPressFcn

    uicontrol(d,'Style','text','String','z/lambda', ...
        'Position',[30 80 100 24], ...
        'HorizontalAlignment','left','FontSize',12);

    e2 = uicontrol(d,'Style','edit','String','0.1', ...
        'Position',[140 80 240 28], 'FontSize',12);

    okBtn = uicontrol(d,'Style','pushbutton','String','OK', ...
        'Position',[100 20 90 34], 'FontSize',11, ...
        'Callback',@onOK);

    uicontrol(d,'Style','pushbutton','String','Cancel', ...
        'Position',[230 20 90 34], 'FontSize',11, ...
        'Callback',@(~,~) delete(d));

    uicontrol(e1);   % 初始焦点在第一个编辑框
    uiwait(d);

    function onOK(~,~)
        a1 = str2double(get(e1,'String'));
        z1 = str2double(get(e2,'String'));
        if ~isfinite(a1) || a1 <= 0 || ~isfinite(z1)
            errordlg('Please enter valid numeric values.','Invalid Input');
            return;
        end
        vals = [a1, z1];
        delete(d);
    end

    function onKey(~,event)
        switch event.Key
            case {'return','enter'}
                onOK();
            case 'escape'
                delete(d);
        end
    end
end

% =========================================================================
% 修改后的选择对话框（使用 WindowKeyPressFcn）
% =========================================================================
function choice = ask_choice_dialog(titleStr, promptStr, options, defaultIndex)
    choice = [];
    if nargin < 4 || isempty(defaultIndex)
        defaultIndex = 1;
    end

    d = dialog('Position',[420 280 500 260], ...   % 加宽以显示长文本
        'Name',titleStr, ...
        'WindowStyle','normal', ...
        'WindowKeyPressFcn',@onKey);

    uicontrol(d,'Style','text','String',promptStr, ...
        'Position',[30 210 440 24], ...
        'HorizontalAlignment','left','FontSize',12);

    lb = uicontrol(d,'Style','listbox',...
        'String',options,...
        'Value',defaultIndex,...
        'Position',[30 75 440 130],...
        'FontSize',12,...
        'Max',1,'Min',0);   % 无 KeyPressFcn

    okBtn = uicontrol(d,'Style','pushbutton','String','OK', ...
        'Position',[150 20 100 34], 'FontSize',11, ...
        'Callback',@onOK);

    uicontrol(d,'Style','pushbutton','String','Cancel', ...
        'Position',[280 20 100 34], 'FontSize',11, ...
        'Callback',@(~,~) delete(d));

    uicontrol(lb);   % 焦点在列表框
    uiwait(d);

    function onOK(~,~)
        idx = get(lb,'Value');
        if ~isempty(idx) && idx >= 1 && idx <= numel(options)
            choice = options{idx};
        end
        delete(d);
    end

    function onKey(~,event)
        switch event.Key
            case {'return','enter'}
                onOK();
            case 'escape'
                delete(d);
        end
    end
end

function plot_and_save(F, xv, yv, a_over_lambda, type, cbLabel, ttlLabel, isSigned, a_in, z_in, mapMode, outDir)
    fig = figure('Visible','off','Color','w','Position',[100 100 900 750]);

    G = process_field(F, isSigned, mapMode);

    imagesc(xv, yv, G);
    axis image
    axis tight
    set(gca,'YDir','normal')
    hold on

    th = linspace(0,2*pi,800);
    plot(a_over_lambda*cos(th), a_over_lambda*sin(th), 'k', 'LineWidth', 1.5);

    xlabel('$x/\lambda$','Interpreter','latex','FontSize',14)
    ylabel('$y/\lambda$','Interpreter','latex','FontSize',14)
    title(sprintf('$%s,\\ a/\\lambda=%.2f,\\ z/\\lambda=%.2f$', ttlLabel, a_in, z_in), ...
        'Interpreter','latex','FontSize',18)

    set(gca,'FontSize',12)

    if isSigned
        color_bar(gca, 'AutoSymmetric', true, 'Data', G, 'Label', cbLabel);
    else
        [cmin, cmax] = finite_minmax(G);
        if ~isfinite(cmin) || ~isfinite(cmax) || cmin == cmax
            cmin = 0;
            cmax = 1;
        end
        color_bar(gca, 'Limits', [cmin cmax], 'Label', cbLabel);
    end

    fname = sprintf('%s-%.2f-%.2f-%s.png', type, a_in, z_in, mapMode);
    exportgraphics(fig, fullfile(outDir,fname), 'Resolution', 300);
    close(fig)
end

function G = process_field(F, isSigned, mapMode)
    G = F;

    if strcmp(mapMode, 'linear')
        return
    end

    if isSigned
        A = abs(G);
        mx = finite_max(A);
        if isfinite(mx) && mx > 0
            A = log1p(40*A/mx) / log1p(40);
        end
        G = sign(F) .* A;
    else
        mx = finite_max(G);
        if isfinite(mx) && mx > 0
            G = log1p(40*G/mx) / log1p(40);
        end
    end
end

function [Ex,Ey,Ez] = electric_field(X,Y,Z,a)
    d = 1e-4;

    Phi_x = electric_potential(X+d,Y,Z,a) - electric_potential(X-d,Y,Z,a);
    Phi_y = electric_potential(X,Y+d,Z,a) - electric_potential(X,Y-d,Z,a);
    Phi_z = electric_potential(X,Y,Z+d,a) - electric_potential(X,Y,Z-d,a);

    Ex = -Phi_x/(2*d);
    Ey = -Phi_y/(2*d);
    Ez = -Phi_z/(2*d);
end

function Phi = electric_potential(X,Y,Z,a)
    rho = sqrt(X.^2 + Y.^2);
    z = Z;

    lam = (z.^2 + rho.^2 - a.^2) / a^2;
    R = sqrt(lam.^2 + 4*z.^2/a^2);

    v1 = sqrt((R-lam)/2);
    v2 = sqrt((R+lam)/2);

    Phi1 = (a/pi) .* (v1 - (abs(z)/a).*atan(1./v2));

    Phi = Phi1;
    mask = z > 0;
    Phi(mask) = z(mask) + Phi1(mask);
end

function [Hx,Hy,Hz] = magnetic_field(X,Y,Z,a)
    d = 1e-4;

    Phi_x = magnetic_potential(X+d,Y,Z,a) - magnetic_potential(X-d,Y,Z,a);
    Phi_y = magnetic_potential(X,Y+d,Z,a) - magnetic_potential(X,Y-d,Z,a);
    Phi_z = magnetic_potential(X,Y,Z+d,a) - magnetic_potential(X,Y,Z-d,a);

    Hx = -Phi_x/(2*d);
    Hy = -Phi_y/(2*d);
    Hz = -Phi_z/(2*d);
end

function PhiM = magnetic_potential(X,Y,Z,a)
    rho = sqrt(X.^2 + Y.^2);
    z = Z;

    lam = (z.^2 + rho.^2 - a.^2) / a^2;
    R = sqrt(lam.^2 + 4*z.^2/a^2);

    v1 = sqrt((R-lam)/2);
    v2 = sqrt((R+lam)/2);

    rho_safe = rho;
    rho_safe(rho_safe==0) = eps;
    sinphi = Y ./ rho_safe;

    Phi1 = (a/pi) .* ((abs(z)./rho_safe).*v1 - (a./rho_safe).*v2 + (rho_safe./a).*atan(1./v2)) .* sinphi;

    PhiM = -Phi1;
    mask = z > 0;
    PhiM(mask) = -Y(mask) + Phi1(mask);
end

function m = finite_max(A)
    a = A(isfinite(A));
    if isempty(a)
        m = NaN;
    else
        m = max(a(:));
    end
end

function [mn, mx] = finite_minmax(A)
    a = A(isfinite(A));
    if isempty(a)
        mn = NaN;
        mx = NaN;
    else
        mn = min(a(:));
        mx = max(a(:));
    end
end
