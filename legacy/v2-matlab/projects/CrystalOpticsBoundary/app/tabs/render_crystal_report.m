function report_text = render_crystal_report(result)
%RENDER_CRYSTAL_REPORT Build the text output without changing its content format.

common = result.common;
single = result.single;
report_text = '';

    function addLine(varargin)
        line = sprintf(varargin{:});
        report_text = [report_text, line, newline]; %#ok<AGROW>
    end

    function s = fmt(x)
        if abs(x) < 1e-10
            s = '0';
        else
            s = sprintf('%.5f', x);
        end
    end

    function s = fmt_vec(v)
        v = v(:).';
        parts = cell(1, numel(v));
        for k = 1:numel(v)
            if isreal(v(k))
                parts{k} = fmt(v(k));
            else
                re = real(v(k));
                im = imag(v(k));
                if abs(re) < 1e-10, re = 0; end
                if abs(im) < 1e-10, im = 0; end
                if im >= 0
                    parts{k} = sprintf('%.5f+%.5fi', re, im);
                else
                    parts{k} = sprintf('%.5f%.5fi', re, im);
                end
            end
        end
        s = ['[', strjoin(parts, ', '), ']'];
    end

addLine('');
addLine('==============================================================================');
addLine('                    CRYSTAL BOUNDARY OPTICS RESULTS');
addLine('==============================================================================');

addLine('');
addLine('--- Crystal ---');
addLine('type            : %s', common.crystal_type);
addLine('eps_principal   : %s', fmt_vec(common.eps_principal(:).'));

addLine('principal_axes_lab:');
for i = 1:size(common.principal_axes_lab, 1)
    addLine('  %s', fmt_vec(common.principal_axes_lab(i, :)));
end

if ~isempty(common.optic_axes_lab)
    addLine('optic_axes_lab:');
    for i = 1:size(common.optic_axes_lab, 1)
        addLine('  %s', fmt_vec(common.optic_axes_lab(i, :)));
    end
end

addLine('');
addLine('--- Incident Geometry ---');
addLine('k_inc_hat       : %s', fmt_vec(common.k_inc_hat(:).'));
addLine('q_inc           : %s', fmt_vec(common.q_inc(:).'));
addLine('sHat            : %s', fmt_vec(common.sHat(:).'));
addLine('pHatInc         : %s', fmt_vec(common.pHatInc(:).'));
addLine('pHatRef         : %s', fmt_vec(common.pHatRef(:).'));

addLine('');
addLine('--- Incident Wave ---');
addLine('n_inc           : %s', fmt(common.n_inc));
addLine('E_inc direction : %s', formatDir(single.incident.E_linear_dir));
addLine('S_inc direction : %s', fmt_vec(single.incident.S_hat(:).'));
addLine('|S_inc|         : %s', fmt(norm(single.incident.S)));
addLine('P_inc,z         : %s', fmt(single.incident.power_z_in));

S_inc_mag = norm(single.incident.S);
S_ref_mag = norm(single.reflection.S);
S_ref_ratio = S_ref_mag / S_inc_mag;
ref = single.reflection;

addLine('');
addLine('--- Reflected Wave ---');
addLine('q_ref hat       : %s', fmt_vec(ref.q_hat(:).'));
addLine('Jones [r_s;r_p] : [%s, %s]', fmt(ref.jones_sp(1)), fmt(ref.jones_sp(2)));
addLine('E_ref direction : %s', formatDir(ref.E_linear_dir));
addLine('S_ref direction : %s', fmt_vec(ref.S_hat(:).'));
addLine('|S_ref|         : %s', fmt(S_ref_mag));
addLine('R               : %s', fmt(ref.power_ratio));
addLine('|S_ref|/|S_inc| : %s', fmt(S_ref_ratio));

addLine('');
addLine('--- Transmitted Wave(s) ---');
if single.transmission.isDegenerate
    branch = single.transmission.branch;
    S_branch_mag = norm(branch.S);
    S_branch_ratio = S_branch_mag / S_inc_mag;
    addLine('Degenerate branch:');
    addLine('q               : %s', fmt_vec(branch.q(:).'));
    addLine('E direction     : %s', formatDir(branch.E_linear_dir));
    addLine('S direction     : %s', formatSDir(branch.S_hat));
    addLine('|S|/|S_inc|     : %s', fmt(S_branch_ratio));
    addLine('power ratio     : %s', fmt(branch.power_ratio));
else
    for i = 1:numel(single.transmission.branch)
        branch = single.transmission.branch(i);
        S_branch_mag = norm(branch.S);
        S_branch_ratio = S_branch_mag / S_inc_mag;
        addLine('Branch %d:', i);
        addLine('q               : %s', fmt_vec(branch.q(:).'));
        addLine('E direction     : %s', formatDir(branch.E_linear_dir));
        addLine('S direction     : %s', formatSDir(branch.S_hat));
        addLine('|S|/|S_inc|     : %s', fmt(S_branch_ratio));
        addLine('power ratio     : %s', fmt(branch.power_ratio));
    end
end

addLine('');
addLine('--- Energy Balance ---');
addLine('R               : %s', fmt(single.energy.R));
addLine('T_total         : %s', fmt(single.energy.T_total));
addLine('R + T - 1       : %s', fmt(single.energy.balance));
addLine('==============================================================================');
addLine('');

    function str = formatDir(linear_dir)
        if all(isfinite(linear_dir)) && norm(linear_dir) > 0
            str = fmt_vec(linear_dir(:).');
        else
            str = 'elliptical';
        end
    end

    function str = formatSDir(S_hat)
        if all(isfinite(S_hat)) && norm(S_hat) > 0
            str = fmt_vec(S_hat(:).');
        else
            str = 'evanescent';
        end
    end
end
