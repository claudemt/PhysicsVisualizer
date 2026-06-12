function varargout = rigid_common_support(action, varargin)
%RIGID_COMMON_SUPPORT Shared helpers for rigid_body_rotation.
% Dispatcher file used to keep the package compact while supporting both
% single-case runs and multi-initial-condition comparison runs.

    if nargin < 1
        error('An action string is required.');
    end

    switch lower(string(action))
        case "defaults"
            varargout{1} = local_defaults();
        case "numvec_to_text"
            varargout{1} = local_numvec_to_text(varargin{1});
        case "parse_vector"
            varargout{1} = local_parse_numeric_vector(varargin{1}, varargin{2}, varargin{3});
        case "parse_scalar"
            varargout{1} = local_parse_scalar(varargin{1}, varargin{2});
        case "parse_case_rows"
            varargout{1} = local_parse_case_rows(varargin{1}, varargin{2}, varargin{3});
        case "set_plot_config"
            local_set_plot_config(varargin{1});
        case "style_axes"
            local_style_axes(varargin{1});
        case "reset_axes"
            local_reset_axes(varargin{1});
        case "finish_2d_axes"
            local_finish_2d_axes(varargin{1});
        case "finish_3d_axes"
            if numel(varargin) >= 2
                local_finish_3d_axes(varargin{1}, varargin{2});
            else
                local_finish_3d_axes(varargin{1}, []);
            end
        case "render_preview"
            local_render_preview(varargin{1}, varargin{2});
        case "render_single_plot"
            local_render_single_plot(varargin{1}, varargin{2}, varargin{3});
        case "play_animation"
            local_play_animation(varargin{1}, varargin{2}, varargin{3}, varargin{4});
        case "export_outputs"
            varargout{1} = local_export_outputs(varargin{1}, varargin{2}, varargin{3}, varargin{4});
        case "set_empty_animation_axes"
            if numel(varargin) >= 2
                local_set_empty_animation_axes(varargin{1}, varargin{2});
            else
                local_set_empty_animation_axes(varargin{1});
            end
        case "axis_angle"
            varargout{1} = local_axis_angle(varargin{1}, varargin{2});
        case "euler313_to_quat"
            varargout{1} = local_euler313_to_quat(varargin{1});
        case "normalize_quat_array"
            varargout{1} = local_normalize_quat_array(varargin{1});
        case "omega_matrix"
            varargout{1} = local_omega_matrix(varargin{1});
        case "rotation_map"
            varargout{1} = local_rotation_map(varargin{1}, varargin{2});
        case "rotm_to_quat"
            varargout{1} = local_rotm_to_quat(varargin{1});
        case "quat_to_rotm"
            varargout{1} = local_quat_to_rotm(varargin{1});
        case "skew"
            varargout{1} = local_skew(varargin{1});
        otherwise
            error('Unknown rigid_common_support action: %s', char(string(action)));
    end
end

function presets = local_defaults()
    presets.free(1) = struct( ...
        'name', 'Tennis-racket flip', ...
        'I', [1 2 3], ...
        'w0', [0.18 2.2 0.04], ...
        'phi0', 0.0, ...
        'tEnd', 18, ...
        'nSamples', 2200);
    presets.free(2) = struct( ...
        'name', 'Near axis-1 rotation', ...
        'I', [1 2 3], ...
        'w0', [2.4 0.12 0.06], ...
        'phi0', 0.3, ...
        'tEnd', 18, ...
        'nSamples', 2200);
    presets.free(3) = struct( ...
        'name', 'Near axis-3 rotation', ...
        'I', [1 2 3], ...
        'w0', [0.08 0.14 2.0], ...
        'phi0', 0.6, ...
        'tEnd', 18, ...
        'nSamples', 2200);

    presets.fixed(1) = struct( ...
        'name', 'Regular-precession-like', ...
        'I', [1 1.4 2], ...
        'aBody', [0 0 1], ...
        'mass', 1, ...
        'g', 9.81, ...
        'euler0', [0 0.55 0], ...
        'w0', [0 0 15], ...
        'tEnd', 8, ...
        'nSamples', 2000);
    presets.fixed(2) = struct( ...
        'name', 'General top with nutation', ...
        'I', [1 1.8 2.2], ...
        'aBody', [0 0 1], ...
        'mass', 1, ...
        'g', 9.81, ...
        'euler0', [0.2 0.95 0.1], ...
        'w0', [0.8 0.1 10], ...
        'tEnd', 10, ...
        'nSamples', 2400);
    presets.fixed(3) = struct( ...
        'name', 'General heavy body', ...
        'I', [0.9 1.3 1.8], ...
        'aBody', [0.22 0.10 0.92], ...
        'mass', 1, ...
        'g', 9.81, ...
        'euler0', [0.35 1.00 0.25], ...
        'w0', [1.6 -0.5 8.5], ...
        'tEnd', 12, ...
        'nSamples', 2600);
end

function txt = local_numvec_to_text(v)
    vals = v(:).';
    if isempty(vals)
        txt = '[]';
        return;
    end
    pieces = arrayfun(@(x) sprintf('%.12g', x), vals, 'UniformOutput', false);
    txt = ['[' strjoin(pieces, ' ') ']'];
end

function v = local_parse_numeric_vector(str, n, name)
    s = strtrim(char(string(str)));
    if startsWith(s, '[') && endsWith(s, ']')
        s = s(2:end-1);
    end
    vals = sscanf(strrep(s, ',', ' '), '%f').';
    if numel(vals) ~= n || any(~isfinite(vals))
        error('Invalid vector for %s. Expected %d numbers.', name, n);
    end
    v = vals;
end

function x = local_parse_scalar(str, name)
    x = str2double(char(string(str)));
    if ~isscalar(x) || isnan(x) || ~isfinite(x)
        error('Invalid scalar for %s.', name);
    end
end

function rows = local_parse_case_rows(raw, nCols, name)
    if iscell(raw)
        parts = cellfun(@(c) char(string(c)), raw(:).', 'UniformOutput', false);
        joined = strjoin(parts, sprintf('\n'));
    else
        joined = char(string(raw));
    end
    joined = strrep(joined, sprintf('\r'), '');
    joined = strrep(joined, ';', sprintf('\n'));
    lines = regexp(joined, '\n', 'split');

    rows = zeros(0, nCols);
    for k = 1:numel(lines)
        s = strtrim(lines{k});
        if isempty(s)
            continue;
        end
        if startsWith(s, '[') && endsWith(s, ']')
            s = s(2:end-1);
        end
        vals = sscanf(strrep(s, ',', ' '), '%f').';
        if numel(vals) ~= nCols || any(~isfinite(vals))
            error('Invalid row %d for %s. Expected %d finite numbers.', k, name, nCols);
        end
        rows(end+1,:) = vals; %#ok<AGROW>
    end

    if isempty(rows)
        error('No valid rows were found for %s.', name);
    end
    if size(rows, 1) > 5
        error('At most 5 initial-condition sets are allowed in comparison mode.');
    end
end

function local_render_preview(ax, result)
    for k = 1:7
        local_reset_axes(ax{k});
        local_render_single_plot(ax{k}, result, k);
        drawnow limitrate nocallbacks;
    end
    if local_is_multi_result(result)
        local_set_empty_animation_axes(ax{8}, 'Animation is disabled in multi-IC comparison mode.');
    else
        local_play_animation(ax{8}, result, false, '');
    end
end

function local_render_single_plot(ax, result, idx)
    if local_is_multi_result(result)
        local_render_compare_plot(ax, result, idx);
        return;
    end

    t = result.t;
    wb = result.wBody;
    wl = result.wLab;
    Lb = result.LBody;
    tips = result.axisTips;
    [w3Scale, w3Legend] = local_pick_w3_scale(wb);
    w3Plot = wb(:,3) / w3Scale;

    switch idx
        case 1
            plot(ax, t, wl(:,1), 'LineWidth', 0.95, 'DisplayName', '$\omega_x$');
            hold(ax, 'on');
            plot(ax, t, wl(:,2), 'LineWidth', 0.95, 'DisplayName', '$\omega_y$');
            xlabel(ax, '$t$', 'Interpreter', 'latex');
            ylabel(ax, '$\omega$', 'Interpreter', 'latex');
            title(ax, '$\omega$ in lab frame', 'Interpreter', 'latex');
            local_apply_legend(ax);
            local_finish_2d_axes(ax);

        case 2
            if strcmp(result.mode, 'free')
                plot(ax, wl(:,1), wl(:,2), 'LineWidth', 0.90, 'HandleVisibility', 'off');
                hold(ax, 'on');
                local_plot_start_end_markers(ax, [wl(:,1), wl(:,2)]);
                xlabel(ax, '$\omega_x$', 'Interpreter', 'latex');
                ylabel(ax, '$\omega_y$', 'Interpreter', 'latex');
                title(ax, '$\omega$ in lab frame', 'Interpreter', 'latex');
                local_finish_2d_axes(ax);
            else
                plot3(ax, wl(:,1), wl(:,2), wl(:,3), 'LineWidth', 0.90, 'HandleVisibility', 'off');
                hold(ax, 'on');
                local_plot_start_end_markers(ax, wl);
                xlabel(ax, '$\omega_x$', 'Interpreter', 'latex');
                ylabel(ax, '$\omega_y$', 'Interpreter', 'latex');
                zlabel(ax, '$\omega_z$', 'Interpreter', 'latex');
                title(ax, '$\omega$ in lab frame', 'Interpreter', 'latex');
                local_finish_3d_axes(ax, wl);
            end

        case 3
            plot(ax, t, wb(:,1), 'LineWidth', 0.95, 'DisplayName', '$\omega_1$');
            hold(ax, 'on');
            plot(ax, t, wb(:,2), 'LineWidth', 0.95, 'DisplayName', '$\omega_2$');
            plot(ax, t, w3Plot, 'LineWidth', 0.95, 'DisplayName', w3Legend);
            xlabel(ax, '$t$', 'Interpreter', 'latex');
            ylabel(ax, '$\omega$', 'Interpreter', 'latex');
            title(ax, '$\omega$ in body frame', 'Interpreter', 'latex');
            local_apply_legend(ax);
            local_finish_2d_axes(ax);

        case 4
            plot3(ax, wb(:,1), wb(:,2), wb(:,3), 'LineWidth', 0.90, 'HandleVisibility', 'off');
            hold(ax, 'on');
            local_plot_start_end_markers(ax, wb);
            xlabel(ax, '$\omega_1$', 'Interpreter', 'latex');
            ylabel(ax, '$\omega_2$', 'Interpreter', 'latex');
            zlabel(ax, '$\omega_3$', 'Interpreter', 'latex');
            title(ax, '$\omega$ in body frame', 'Interpreter', 'latex');
            local_finish_3d_axes(ax, wb);

        case 5
            plot3(ax, Lb(:,1), Lb(:,2), Lb(:,3), 'LineWidth', 0.90, 'HandleVisibility', 'off');
            hold(ax, 'on');
            local_plot_start_end_markers(ax, Lb);
            xlabel(ax, '$L_1$', 'Interpreter', 'latex');
            ylabel(ax, '$L_2$', 'Interpreter', 'latex');
            zlabel(ax, '$L_3$', 'Interpreter', 'latex');
            title(ax, '$L$ in body frame', 'Interpreter', 'latex');
            local_finish_3d_axes(ax, Lb);

        case 6
            % Plot omega and L trajectories
            h_w = plot3(ax, wb(:,1), wb(:,2), wb(:,3), 'LineWidth', 0.90, 'DisplayName', '$\omega$');
            hold(ax, 'on');
            h_L = plot3(ax, Lb(:,1), Lb(:,2), Lb(:,3), 'LineWidth', 0.90, 'DisplayName', '$L$');
            % Mark start and end for both trajectories
            local_plot_start_end_markers(ax, wb, h_w.Color);
            local_plot_start_end_markers(ax, Lb, h_L.Color);
            xlabel(ax, '$e_1$', 'Interpreter', 'latex');
            ylabel(ax, '$e_2$', 'Interpreter', 'latex');
            zlabel(ax, '$e_3$', 'Interpreter', 'latex');
            title(ax, '$\omega$ and $L$ in body frame', 'Interpreter', 'latex');
            local_finish_3d_axes(ax, [wb; Lb]);
            local_apply_legend(ax, local_get_plot_config().legendLocation3D);

        case 7
            e1 = squeeze(tips(:,:,1));
            e2 = squeeze(tips(:,:,2));
            e3 = squeeze(tips(:,:,3));
            % Plot axis tips
            plot3(ax, e1(:,1), e1(:,2), e1(:,3), 'LineWidth', 0.90, 'DisplayName', '$\hat{e}_1$');
            hold(ax, 'on');
            plot3(ax, e2(:,1), e2(:,2), e2(:,3), 'LineWidth', 0.90, 'DisplayName', '$\hat{e}_2$');
            plot3(ax, e3(:,1), e3(:,2), e3(:,3), 'LineWidth', 0.90, 'DisplayName', '$\hat{e}_3$');
            local_plot_start_end_markers(ax, e1, [0 0.4470 0.7410]);
            local_plot_start_end_markers(ax, e2, [0.8500 0.3250 0.0980]);
            local_plot_start_end_markers(ax, e3, [0.9290 0.6940 0.1250]);
            xlabel(ax, '$x$', 'Interpreter', 'latex');
            ylabel(ax, '$y$', 'Interpreter', 'latex');
            zlabel(ax, '$z$', 'Interpreter', 'latex');
            title(ax, 'Axis tips in lab frame', 'Interpreter', 'latex');
            local_finish_3d_axes(ax, [e1; e2; e3]);
            local_apply_legend(ax, local_get_plot_config().legendLocation3D);
    end
end

function local_render_compare_plot(ax, result, idx)
    caseResults = result.caseResults;
    nCases = numel(caseResults);
    colors = local_get_case_colors(nCases);
    labels = local_latex_case_labels(nCases);

    switch idx
        case 1
            for k = 1:nCases
                t = caseResults{k}.t;
                wl = caseResults{k}.wLab;
                plot(ax, t, wl(:,1), '-', 'Color', colors(k,:), 'LineWidth', 0.85, 'HandleVisibility', 'off');
                hold(ax, 'on');
                plot(ax, t, wl(:,2), '--', 'Color', colors(k,:), 'LineWidth', 0.85, 'HandleVisibility', 'off');
            end
            xlabel(ax, '$t$', 'Interpreter', 'latex');
            ylabel(ax, '$\omega$', 'Interpreter', 'latex');
            local_set_title_with_note(ax, '$\omega$ in lab frame', 'solid: $\omega_x$, dashed: $\omega_y$');
            local_finish_2d_axes(ax);
            local_add_case_legend(ax, colors, labels, false, local_get_plot_config().legendLocation2D);

        case 2
            if strcmp(result.baseMode, 'free')
                pts = zeros(0, 3);
                for k = 1:nCases
                    wl = caseResults{k}.wLab;
                    plot(ax, wl(:,1), wl(:,2), '-', 'Color', colors(k,:), 'LineWidth', 0.90, 'HandleVisibility', 'off');
                    hold(ax, 'on');
                    local_plot_start_end_markers(ax, wl(:,1:2), colors(k,:));
                    pts = [pts; [wl(:,1), wl(:,2), zeros(size(wl,1),1)]]; %#ok<AGROW>
                end
                xlabel(ax, '$\omega_x$', 'Interpreter', 'latex');
                ylabel(ax, '$\omega_y$', 'Interpreter', 'latex');
                title(ax, '$\omega$ in lab frame', 'Interpreter', 'latex');
                local_finish_2d_axes(ax);
                local_add_case_legend(ax, colors, labels, false, local_get_plot_config().legendLocation2D);
            else
                pts = local_collect_compare_points(caseResults, 'wlab');
                for k = 1:nCases
                    wl = caseResults{k}.wLab;
                    plot3(ax, wl(:,1), wl(:,2), wl(:,3), '-', 'Color', colors(k,:), 'LineWidth', 0.90, 'HandleVisibility', 'off');
                    hold(ax, 'on');
                    local_plot_start_end_markers(ax, wl, colors(k,:));
                end
                xlabel(ax, '$\omega_x$', 'Interpreter', 'latex');
                ylabel(ax, '$\omega_y$', 'Interpreter', 'latex');
                zlabel(ax, '$\omega_z$', 'Interpreter', 'latex');
                title(ax, '$\omega$ in lab frame', 'Interpreter', 'latex');
                local_finish_3d_axes(ax, pts);
                local_add_case_legend(ax, colors, labels, true, local_get_plot_config().legendLocation3D);
            end

        case 3
            [w3Scale, ~, w3Symbol] = local_pick_compare_w3_scale(caseResults);
            for k = 1:nCases
                t = caseResults{k}.t;
                wb = caseResults{k}.wBody;
                plot(ax, t, wb(:,1), '-', 'Color', colors(k,:), 'LineWidth', 0.85, 'HandleVisibility', 'off');
                hold(ax, 'on');
                plot(ax, t, wb(:,2), '--', 'Color', colors(k,:), 'LineWidth', 0.85, 'HandleVisibility', 'off');
                plot(ax, t, wb(:,3) / w3Scale, '-.', 'Color', colors(k,:), 'LineWidth', 0.85, 'HandleVisibility', 'off');
            end
            xlabel(ax, '$t$', 'Interpreter', 'latex');
            ylabel(ax, '$\omega$', 'Interpreter', 'latex');
            local_set_title_with_note(ax, '$\omega$ in body frame', ['solid: $\omega_1$, dashed: $\omega_2$, dash-dot: ' local_plaintext_note_to_latex(w3Symbol)]);
            local_finish_2d_axes(ax);
            local_add_case_legend(ax, colors, labels, false, local_get_plot_config().legendLocation2D);

        case 4
            pts = local_collect_compare_points(caseResults, 'wbody');
            for k = 1:nCases
                wb = caseResults{k}.wBody;
                plot3(ax, wb(:,1), wb(:,2), wb(:,3), '-', 'Color', colors(k,:), 'LineWidth', 0.90, 'HandleVisibility', 'off');
                hold(ax, 'on');
                local_plot_start_end_markers(ax, wb, colors(k,:));
            end
            xlabel(ax, '$\omega_1$', 'Interpreter', 'latex');
            ylabel(ax, '$\omega_2$', 'Interpreter', 'latex');
            zlabel(ax, '$\omega_3$', 'Interpreter', 'latex');
            title(ax, '$\omega$ in body frame', 'Interpreter', 'latex');
            local_finish_3d_axes(ax, pts);
            local_add_case_legend(ax, colors, labels, true, local_get_plot_config().legendLocation3D);

        case 5
            pts = local_collect_compare_points(caseResults, 'lbody');
            for k = 1:nCases
                Lb = caseResults{k}.LBody;
                plot3(ax, Lb(:,1), Lb(:,2), Lb(:,3), '-', 'Color', colors(k,:), 'LineWidth', 0.90, 'HandleVisibility', 'off');
                hold(ax, 'on');
                local_plot_start_end_markers(ax, Lb, colors(k,:));
            end
            xlabel(ax, '$L_1$', 'Interpreter', 'latex');
            ylabel(ax, '$L_2$', 'Interpreter', 'latex');
            zlabel(ax, '$L_3$', 'Interpreter', 'latex');
            title(ax, '$L$ in body frame', 'Interpreter', 'latex');
            local_finish_3d_axes(ax, pts);
            local_add_case_legend(ax, colors, labels, true, local_get_plot_config().legendLocation3D);

        case 6
            pts = local_collect_compare_points(caseResults, 'wbody_lbody');
            for k = 1:nCases
                wb = caseResults{k}.wBody;
                Lb = caseResults{k}.LBody;
                plot3(ax, wb(:,1), wb(:,2), wb(:,3), '-', 'Color', colors(k,:), 'LineWidth', 0.90, 'HandleVisibility', 'off');
                hold(ax, 'on');
                plot3(ax, Lb(:,1), Lb(:,2), Lb(:,3), '--', 'Color', colors(k,:), 'LineWidth', 0.85, 'HandleVisibility', 'off');
                local_plot_start_end_markers(ax, wb, colors(k,:));
                local_plot_start_end_markers(ax, Lb, colors(k,:));
            end
            xlabel(ax, '$c_1$', 'Interpreter', 'latex');
            ylabel(ax, '$c_2$', 'Interpreter', 'latex');
            zlabel(ax, '$c_3$', 'Interpreter', 'latex');
            local_set_title_with_note(ax, '$\omega$ and $L$ in body frame', 'solid: $\omega$, dashed: $L$');
            local_finish_3d_axes(ax, pts);
            local_add_case_legend(ax, colors, labels, true, local_get_plot_config().legendLocation3D);

        case 7
            pts = local_collect_compare_points(caseResults, 'tips');
            for k = 1:nCases
                tips = caseResults{k}.axisTips;
                e1 = squeeze(tips(:,:,1));
                e2 = squeeze(tips(:,:,2));
                e3 = squeeze(tips(:,:,3));
                plot3(ax, e1(:,1), e1(:,2), e1(:,3), '-', 'Color', colors(k,:), 'LineWidth', 0.85, 'HandleVisibility', 'off');
                hold(ax, 'on');
                plot3(ax, e2(:,1), e2(:,2), e2(:,3), '--', 'Color', colors(k,:), 'LineWidth', 0.85, 'HandleVisibility', 'off');
                plot3(ax, e3(:,1), e3(:,2), e3(:,3), '-.', 'Color', colors(k,:), 'LineWidth', 0.85, 'HandleVisibility', 'off');
                local_plot_start_end_markers(ax, e1, colors(k,:));
                local_plot_start_end_markers(ax, e2, colors(k,:));
                local_plot_start_end_markers(ax, e3, colors(k,:));
            end
            xlabel(ax, '$x$', 'Interpreter', 'latex');
            ylabel(ax, '$y$', 'Interpreter', 'latex');
            zlabel(ax, '$z$', 'Interpreter', 'latex');
            local_set_title_with_note(ax, 'Axis tips in lab frame', 'solid: $e_1$, dashed: $e_2$, dash-dot: $e_3$');
            local_finish_3d_axes(ax, pts);
            local_add_case_legend(ax, colors, labels, true, local_get_plot_config().legendLocation3D);
    end
end

function pts = local_collect_compare_points(caseResults, kind)
    pts = zeros(0, 3);
    for k = 1:numel(caseResults)
        cr = caseResults{k};
        switch lower(kind)
            case 'wlab'
                pts = [pts; cr.wLab]; %#ok<AGROW>
            case 'wbody'
                pts = [pts; cr.wBody]; %#ok<AGROW>
            case 'lbody'
                pts = [pts; cr.LBody]; %#ok<AGROW>
            case 'wbody_lbody'
                pts = [pts; cr.wBody; cr.LBody]; %#ok<AGROW>
            case 'tips'
                tips = cr.axisTips;
                pts = [pts; squeeze(tips(:,:,1)); squeeze(tips(:,:,2)); squeeze(tips(:,:,3))]; %#ok<AGROW>
        end
    end
end

function outDir = local_export_outputs(result, inputData, outputRoot, mainFunctionName)
    if nargin < 4 || isempty(mainFunctionName)
        mainFunctionName = 'rigid_body_rotation';
    end
    if nargin < 3 || isempty(outputRoot)
        outputRoot = fileparts(which(mainFunctionName));
        if isempty(outputRoot)
            outputRoot = fileparts(mfilename('fullpath'));
        end
    end
    stamp = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
    if local_is_multi_result(result)
        module_key = sprintf('rigid_%s_multi', result.baseMode);
        names = { ...
            'cmp_fig1_lab_xy_vs_t.png', ...
            'cmp_fig2_lab_phase_or_path.png', ...
            'cmp_fig3_body_components_vs_t.png', ...
            'cmp_fig4_body_omega_trajectory.png', ...
            'cmp_fig5_body_L_trajectory.png', ...
            'cmp_fig6_body_omega_and_L.png', ...
            'cmp_fig7_body_axis_tips.png'};
    else
        module_key = 'rigid_body_rotation';
        names = { ...
            'fig1_lab_xy_vs_t.png', ...
            'fig2_lab_phase_or_path.png', ...
            'fig3_body_components_vs_t.png', ...
            'fig4_body_omega_trajectory.png', ...
            'fig5_body_L_trajectory.png', ...
            'fig6_body_omega_and_L.png', ...
            'fig7_body_axis_tips.png'};
    end

    cache_dir = image_output('clear_cache', outputRoot, ['export_' module_key]);
    image_paths = cell(1, numel(names));
    cfg = local_get_plot_config();
    for k = 1:7
        figSize = cfg.figureSize2D;
        if ismember(k, [2 4 5 6 7])
            figSize = cfg.figureSize3D;
        end
        f = image_output('hidden_figure', 'Position', [80 80 figSize(1) figSize(2)]);
        ax = axes(f);
        local_style_axes(ax);
        local_render_single_plot(ax, result, k);
        drawnow;
        image_paths{k} = image_output('save_figure', f, cache_dir, names{k}, 240);
        close(f);
    end

    export_info = image_output('export_bundle', outputRoot, module_key, image_paths, ...
        'Params', inputData, 'Composite', true, 'Layout', 'auto');
    outDir = export_info.output_dir;

    if ~local_is_multi_result(result)
        local_play_animation([], result, true, fullfile(outDir, 'animation.mp4'));
    end

    fid = fopen(fullfile(outDir, 'parameters.txt'), 'a');
    if fid < 0
        error('Failed to create parameters.txt.');
    end
    fprintf(fid, 'timestamp = %s\n', stamp);
    if local_is_multi_result(result)
        fprintf(fid, 'mode = %s\n', result.baseMode);
        fprintf(fid, 'compareMode = true\n');
        fprintf(fid, 'nCases = %d\n', result.nCases);
        fields = fieldnames(inputData);
        for k = 1:numel(fields)
            key = fields{k};
            if strcmp(key, 'compareCases')
                continue;
            end
            value = inputData.(key);
            if isnumeric(value) || islogical(value)
                fprintf(fid, '%s = %s\n', key, mat2str(value));
            else
                fprintf(fid, '%s = %s\n', key, char(string(value)));
            end
        end
        fprintf(fid, 'compareCasesFormat = ');
        if strcmp(result.baseMode, 'free')
            fprintf(fid, '[w1 w2 w3 phi0]\n');
        else
            fprintf(fid, '[phi theta psi w1 w2 w3]\n');
        end
        for k = 1:size(inputData.compareCases, 1)
            fprintf(fid, 'p.%d = %s\n', k, mat2str(inputData.compareCases(k,:)));
        end
    else
        fprintf(fid, 'mode = %s\n', inputData.mode);
        fields = fieldnames(inputData);
        for k = 1:numel(fields)
            value = inputData.(fields{k});
            if isnumeric(value) || islogical(value)
                fprintf(fid, '%s = %s\n', fields{k}, mat2str(value));
            else
                fprintf(fid, '%s = %s\n', fields{k}, char(string(value)));
            end
        end
    end
    fclose(fid);
end

function local_play_animation(ax, result, writeVideoFlag, videoPath)
    if local_is_multi_result(result)
        if nargin >= 1 && ~isempty(ax)
            local_set_empty_animation_axes(ax, 'Animation is disabled in multi-IC comparison mode.');
        end
        return;
    end

    tips = result.axisTips;
    wl = result.wLab;
    n = size(tips, 1);
    sampleIdx = unique(round(linspace(1, n, min(300, n))));
    tips = tips(sampleIdx,:,:);
    wl = wl(sampleIdx,:);

    [omegaScale, omegaLegend] = local_pick_animation_omega_scale(wl);
    wlPlot = wl / omegaScale;

    if writeVideoFlag
        fig = figure('Color', 'w', 'Position', [100 80 960 780], 'Visible', 'on');
        axh = axes(fig);
    else
        axh = ax;
        cla(axh);
    end

    local_style_axes(axh);
    axh.Visible = 'on';
    xlabel(axh, '$x$', 'Interpreter', 'latex');
    ylabel(axh, '$y$', 'Interpreter', 'latex');
    zlabel(axh, '$z$', 'Interpreter', 'latex');
    title(axh, 'Body axes and $\omega$ in lab frame', 'Interpreter', 'latex');

    pts = [reshape(tips, [], 3); wlPlot];
    local_finish_3d_axes(axh, pts);
    hold(axh, 'on');

    h1 = plot3(axh, [0 tips(1,1,1)], [0 tips(1,2,1)], [0 tips(1,3,1)], 'LineWidth', 1.00);
    h2 = plot3(axh, [0 tips(1,1,2)], [0 tips(1,2,2)], [0 tips(1,3,2)], 'LineWidth', 1.00);
    h3 = plot3(axh, [0 tips(1,1,3)], [0 tips(1,2,3)], [0 tips(1,3,3)], 'LineWidth', 1.00);
    hw = plot3(axh, [0 wlPlot(1,1)], [0 wlPlot(1,2)], [0 wlPlot(1,3)], 'LineWidth', 1.00);
    animLegendLocation = local_get_plot_config().legendLocation3D;
    if ~strcmpi(animLegendLocation, 'none')
        lgd = legend(axh, [h1 h2 h3 hw], {'$\hat{e}_1$', '$\hat{e}_2$', '$\hat{e}_3$', omegaLegend}, 'Interpreter', 'latex', 'Location', animLegendLocation);
        local_style_legend(lgd);
    end
    drawnow;

    if writeVideoFlag
        writerObj = VideoWriter(videoPath, 'MPEG-4');
        writerObj.FrameRate = 30;
        open(writerObj);
    else
        writerObj = [];
    end

    for k = 1:size(tips, 1)
        set(h1, 'XData', [0 tips(k,1,1)], 'YData', [0 tips(k,2,1)], 'ZData', [0 tips(k,3,1)]);
        set(h2, 'XData', [0 tips(k,1,2)], 'YData', [0 tips(k,2,2)], 'ZData', [0 tips(k,3,2)]);
        set(h3, 'XData', [0 tips(k,1,3)], 'YData', [0 tips(k,2,3)], 'ZData', [0 tips(k,3,3)]);
        set(hw, 'XData', [0 wlPlot(k,1)], 'YData', [0 wlPlot(k,2)], 'ZData', [0 wlPlot(k,3)]);
        drawnow;
        if writeVideoFlag
            writeVideo(writerObj, getframe(fig));
        end
    end

    if writeVideoFlag
        close(writerObj);
        close(fig);
    end
end

function local_set_empty_animation_axes(ax, messageText)
    if nargin < 2 || isempty(messageText)
        messageText = 'Run a simulation, then click Play.';
    end
    local_reset_axes(ax);
    ax.Visible = 'on';
    xlim(ax, [-1.2 1.2]);
    ylim(ax, [-1.2 1.2]);
    zlim(ax, [-1.2 1.2]);
    pbaspect(ax, [1.00 1.00 1.00]);
    view(ax, 3);
    if isprop(ax, 'Projection')
        ax.Projection = 'orthographic';
    end
    xlabel(ax, '$x$', 'Interpreter', 'latex');
    ylabel(ax, '$y$', 'Interpreter', 'latex');
    zlabel(ax, '$z$', 'Interpreter', 'latex');
    title(ax, 'Animation preview', 'Interpreter', 'latex');
    local_adjust_axes_layout(ax, true);
    msg = local_plaintext_to_latex(messageText);
    text(ax, 0, 0, 0, ['$\mathrm{' msg '}$'], ...
        'Interpreter', 'latex', ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'middle');
end

function local_reset_axes(ax)
    if isempty(ax) || ~isgraphics(ax)
        return;
    end
    try
        legend(ax, 'off');
    catch
    end
    try
        delete(allchild(ax));
    catch
    end
    try
        cla(ax, 'reset');
    catch
        cla(ax);
    end
    if isprop(ax, 'ColorOrderIndex')
        ax.ColorOrderIndex = 1;
    end
    if isprop(ax, 'NextPlot')
        ax.NextPlot = 'replace';
    end
    local_style_axes(ax);
end

function local_style_axes(ax)
    hold(ax, 'off');
    grid(ax, 'on');
    apply_tex_style(ax, 'FontSize', 12, 'TitleFontSize', 14, 'Box', 'on');
    ax.LineWidth = 1.0;
    if isprop(ax, 'PositionConstraint')
        ax.PositionConstraint = 'innerposition';
    end
    ax.XGrid = 'on';
    ax.YGrid = 'on';
    if isprop(ax, 'ZGrid')
        ax.ZGrid = 'on';
    end
end

function local_finish_2d_axes(ax)
    local_style_axes(ax);
    hold(ax, 'on');
    xline(ax, 0, ':k', 'HandleVisibility', 'off');
    yline(ax, 0, ':k', 'HandleVisibility', 'off');
    plot(ax, 0, 0, '.k', 'MarkerSize', 10, 'HandleVisibility', 'off');
    xr = xlim(ax);
    yr = ylim(ax);
    if diff(xr) <= 0
        xr = [-1 1];
    end
    if diff(yr) <= 0
        yr = [-1 1];
    end
    padX = 0.06 * max(diff(xr), 1e-8);
    padY = 0.08 * max(diff(yr), 1e-8);
    xlim(ax, [xr(1)-padX xr(2)+padX]);
    ylim(ax, [yr(1)-padY yr(2)+padY]);
    pbaspect(ax, [1.08 1 1]);
    local_adjust_axes_layout(ax, false);
    local_raise_title(ax);
end

function local_finish_3d_axes(ax, pts)
    local_style_axes(ax);
    ax.Visible = 'on';
    view(ax, 3);
    if isprop(ax, 'Projection')
        ax.Projection = 'orthographic';
    end

    if nargin < 2 || isempty(pts)
        pts = [-1 -1 -1; 1 1 1];
    end
    pts = reshape(pts, [], 3);
    pts = pts(all(isfinite(pts), 2), :);
    if isempty(pts)
        pts = [-1 -1 -1; 1 1 1];
    end

    mins = min(pts, [], 1);
    maxs = max(pts, [], 1);
    spans = maxs - mins;
    maxSpan = max(spans);
    if ~isfinite(maxSpan) || maxSpan < 1e-6
        maxSpan = 1.0;
    end
    spans(spans < 0.10 * maxSpan) = 0.10 * maxSpan;
    centers = 0.5 * (mins + maxs);
    halfRanges = 0.58 * spans;

    xlim(ax, centers(1) + [-halfRanges(1), halfRanges(1)]);
    ylim(ax, centers(2) + [-halfRanges(2), halfRanges(2)]);
    zlim(ax, centers(3) + [-halfRanges(3), halfRanges(3)]);
    pbaspect(ax, [1.00 1.00 1.00]);

    hold(ax, 'on');
    xl = xlim(ax);
    yl = ylim(ax);
    zl = zlim(ax);
    plot3(ax, [xl(1) xl(2)], [0 0], [0 0], ':k', 'HandleVisibility', 'off');
    plot3(ax, [0 0], [yl(1) yl(2)], [0 0], ':k', 'HandleVisibility', 'off');
    plot3(ax, [0 0], [0 0], [zl(1) zl(2)], ':k', 'HandleVisibility', 'off');
    plot3(ax, 0, 0, 0, '.k', 'MarkerSize', 12, 'HandleVisibility', 'off');

    local_adjust_axes_layout(ax, true);
    local_raise_title(ax);
end

function local_adjust_axes_layout(ax, is3D)
    if nargin < 2
        is3D = false;
    end
    try
        ax.Units = 'normalized';
        if is3D
            ax.Position = [0.11 0.15 0.79 0.61];
            if isprop(ax, 'Clipping')
                ax.Clipping = 'off';
            end
        else
            ax.Position = [0.09 0.15 0.84 0.69];
        end
    catch
    end
end

function local_raise_title(ax)
    if isempty(ax) || ~isgraphics(ax) || isempty(ax.Title) || isempty(ax.Title.String)
        return;
    end
    try
        ax.Title.Units = 'normalized';
        pos = ax.Title.Position;
        pos(1) = 0.5;
        pos(2) = 1.045;
        if numel(pos) >= 3
            pos(3) = 0;
        end
        ax.Title.Position = pos;
    catch
    end
end

function local_set_title_with_note(ax, mainText, noteText)
    if isempty(ax) || ~isgraphics(ax)
        return;
    end
    try
        delete(findall(ax, 'Tag', 'RigidAuxTitleNote'));
    catch
    end
    if nargin < 2 || isempty(mainText)
        mainText = '';
    end
    title(ax, char(string(mainText)), 'Interpreter', 'latex');
    local_raise_title(ax);
    if nargin < 3 || isempty(noteText)
        return;
    end
    noteText = char(string(noteText));
    fs = max(ax.FontSize - 1, 10);
    if local_axes_is_3d(ax)
        text(ax, 0.5, 1.008, 0, noteText, ...
            'Units', 'normalized', ...
            'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'bottom', ...
            'Interpreter', 'latex', ...
            'FontSize', fs, ...
            'Clipping', 'off', ...
            'Tag', 'RigidAuxTitleNote', ...
            'HandleVisibility', 'off');
    else
        text(ax, 0.5, 1.008, noteText, ...
            'Units', 'normalized', ...
            'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'bottom', ...
            'Interpreter', 'latex', ...
            'FontSize', fs, ...
            'Clipping', 'off', ...
            'Tag', 'RigidAuxTitleNote', ...
            'HandleVisibility', 'off');
    end
end

function local_plot_start_end_markers(ax, pts, colorValue)
    if nargin < 3 || isempty(colorValue)
        colorValue = [0 0 0];
    end
    if isempty(pts)
        return;
    end
    pts = reshape(pts, size(pts,1), []);
    pts = pts(all(isfinite(pts), 2), :);
    if isempty(pts)
        return;
    end
    p0 = pts(1,:);
    pf = pts(end,:);
    if size(pts, 2) >= 3
        plot3(ax, p0(1), p0(2), p0(3), '^', 'MarkerSize', 4.0, 'LineWidth', 0.7, ...
            'Color', colorValue, 'MarkerFaceColor', colorValue, 'HandleVisibility', 'off');
        plot3(ax, pf(1), pf(2), pf(3), 's', 'MarkerSize', 4.0, 'LineWidth', 0.7, ...
            'Color', colorValue, 'MarkerFaceColor', colorValue, 'HandleVisibility', 'off');
    else
        plot(ax, p0(1), p0(2), '^', 'MarkerSize', 4.0, 'LineWidth', 0.7, ...
            'Color', colorValue, 'MarkerFaceColor', colorValue, 'HandleVisibility', 'off');
        plot(ax, pf(1), pf(2), 's', 'MarkerSize', 4.0, 'LineWidth', 0.7, ...
            'Color', colorValue, 'MarkerFaceColor', colorValue, 'HandleVisibility', 'off');
    end
end

function [scaleFactor, legendText] = local_pick_w3_scale(wb)
    w1Amp = max(abs(wb(:,1)));
    w2Amp = max(abs(wb(:,2)));
    refAmp = max([w1Amp, w2Amp, 1e-12]);
    w3Mean = mean(abs(wb(:,3)));
    cfg = local_get_plot_config();
    if isfinite(w3Mean) && w3Mean > cfg.w3ScaleTriggerRatio * refAmp
        scaleFactor = 10;
        legendText = '$\omega_3/10$';
    else
        scaleFactor = 1;
        legendText = '$\omega_3$';
    end
end

function [scaleFactor, legendText, symbolText] = local_pick_compare_w3_scale(caseResults)
    needScale = false;
    for k = 1:numel(caseResults)
        wb = caseResults{k}.wBody;
        w1Amp = max(abs(wb(:,1)));
        w2Amp = max(abs(wb(:,2)));
        refAmp = max([w1Amp, w2Amp, 1e-12]);
        w3Mean = mean(abs(wb(:,3)));
        cfg = local_get_plot_config();
    if isfinite(w3Mean) && w3Mean > cfg.w3ScaleTriggerRatio * refAmp
            needScale = true;
            break;
        end
    end
    if needScale
        scaleFactor = 10;
        legendText = '$\omega_3/10$';
        symbolText = '\omega_3/10';
    else
        scaleFactor = 1;
        legendText = '$\omega_3$';
        symbolText = '\omega_3';
    end
end

function [scaleFactor, legendText] = local_pick_animation_omega_scale(wl)
    maxMag = max(vecnorm(wl, 2, 2));
    cfg = local_get_plot_config();
    if isfinite(maxMag) && maxMag > cfg.animationOmegaScaleTriggerNorm
        scaleFactor = 10;
        legendText = '$\omega/10$';
    else
        scaleFactor = 1;
        legendText = '$\omega$';
    end
end

function out = local_plaintext_note_to_latex(in)
    out = char(string(in));
    out = strrep(out, '\omega_3/10', '$\omega_3/10$');
    out = strrep(out, '\omega_3', '$\omega_3$');
end

function local_apply_legend(ax, location)
    cfg = local_get_plot_config();
    if nargin < 2 || isempty(location)
        if local_axes_is_3d(ax)
            location = cfg.legendLocation3D;
        else
            location = cfg.legendLocation2D;
        end
    end
    location = char(string(location));
    if strcmpi(location, 'none')
        try, legend(ax, 'off'); catch, end
        return;
    end
    h = flipud(findobj(ax, '-property', 'DisplayName'));
    if isempty(h)
        try
            legend(ax, 'off');
        catch
        end
        return;
    end
    names = get(h, {'DisplayName'});
    if ischar(names)
        names = {names};
    end
    keep = ~cellfun(@isempty, names) & ~strncmp(names, 'data', 4);
    h = h(keep);
    names = names(keep);
    if isempty(h)
        try
            legend(ax, 'off');
        catch
        end
        return;
    end
    lgd = legend(ax, h, names, 'Interpreter', 'latex', 'Location', location);
    local_style_legend(lgd);
end

function local_add_case_legend(ax, colors, labels, use3D, location)
    cfg = local_get_plot_config();
    if nargin < 5 || isempty(location)
        if use3D
            location = cfg.legendLocation3D;
        else
            location = cfg.legendLocation2D;
        end
    end
    location = char(string(location));
    if strcmpi(location, 'none')
        try, legend(ax, 'off'); catch, end
        return;
    end
    hold(ax, 'on');
    nCases = size(colors, 1);
    h = gobjects(nCases, 1);
    for k = 1:nCases
        if use3D
            h(k) = plot3(ax, nan, nan, nan, '-', 'Color', colors(k,:), 'LineWidth', 1.00);
        else
            h(k) = plot(ax, nan, nan, '-', 'Color', colors(k,:), 'LineWidth', 1.00);
        end
    end
    lgd = legend(ax, h, labels, 'Interpreter', 'latex', 'Location', location);
    local_style_legend(lgd);
end

function tf = local_axes_is_3d(ax)
    tf = false;
    try
        ztxt = ax.ZLabel.String;
        if iscell(ztxt)
            ztxt = strjoin(ztxt, '');
        end
        tf = ~isempty(char(string(ztxt)));
    catch
        tf = false;
    end
end

function local_set_plot_config(cfg)
    persistent plotCfg
    if nargin >= 1 && isstruct(cfg)
        plotCfg = cfg;
    end
end

function cfg = local_get_plot_config()
    persistent plotCfg
    if isempty(plotCfg) || ~isstruct(plotCfg)
        plotCfg = struct( ...
            'w3ScaleTriggerRatio', 3.5, ...
            'animationOmegaScaleTriggerNorm', 5.0, ...
            'figureSize2D', [840 660], ...
            'figureSize3D', [780 660], ...
            'legendLocation2D', 'northeast', ...
            'legendLocation3D', 'northeast');
    end
    cfg = plotCfg;
end

function local_place_legend_near_corner(ax, lgd)
    if isempty(ax) || ~isgraphics(ax) || isempty(lgd) || ~isgraphics(lgd)
        return;
    end
    try
        drawnow;
        ax.Units = 'normalized';
        lgd.Units = 'normalized';
        anchor = ax.Position;
        if isprop(ax, 'InnerPosition')
            anchor = ax.InnerPosition;
        end
        lp = lgd.Position;
        if local_axes_is_3d(ax)
            insetX = 0.045;
            insetY = 0.014;
        else
            insetX = 0.018;
            insetY = 0.010;
        end
        x = anchor(1) + anchor(3) - lp(3) - insetX;
        y = anchor(2) + anchor(4) - lp(4) - insetY;
        x = max(anchor(1) + 0.006, min(x, 0.99 - lp(3)));
        y = max(anchor(2) + 0.006, min(y, 0.99 - lp(4)));
        lgd.Location = 'none';
        lgd.Position = [x y lp(3) lp(4)];
    catch
    end
end

function local_style_legend(lgd)
    if isempty(lgd) || ~isgraphics(lgd)
        return;
    end
    try, lgd.Interpreter = 'latex'; catch, end
    try, lgd.FontSize = 12; catch, end
    if isprop(lgd, 'NumColumns')
        lgd.NumColumns = 1;
    end
    lgd.Box = 'on';
    if isprop(lgd, 'AutoUpdate')
        lgd.AutoUpdate = 'off';
    end
    if isprop(lgd, 'ItemTokenSize')
        lgd.ItemTokenSize = [16 9];
    end
end

function tf = local_is_multi_result(result)
    tf = isstruct(result) && isfield(result, 'isMulti') && logical(result.isMulti);
end

function colors = local_get_case_colors(nCases)
    base = lines(max(nCases, 7));
    colors = base(1:nCases, :);
end

function labels = local_latex_case_labels(nCases)
    labels = cell(nCases, 1);
    for k = 1:nCases
        labels{k} = sprintf('$\\mathrm{p.%d}$', k);
    end
end

function out = local_plaintext_to_latex(in)
    out = char(string(in));
    out = strrep(out, '\', ' ');
    out = strrep(out, '_', '\_');
    out = strrep(out, '%', '\%');
    out = strrep(out, '&', '\&');
    out = strrep(out, ' ', '\ ');
end

function R = local_axis_angle(axisv, ang)
    axisv = axisv(:) / norm(axisv);
    K = local_skew(axisv);
    R = eye(3) + sin(ang) * K + (1 - cos(ang)) * (K * K);
end

function q = local_euler313_to_quat(eul)
    eul = eul(:);
    R = local_axis_angle([0;0;1], eul(1)) * local_axis_angle([1;0;0], eul(2)) * local_axis_angle([0;0;1], eul(3));
    q = local_rotm_to_quat(R);
end

function Qn = local_normalize_quat_array(Q)
    Qn = Q;
    for k = 1:size(Q,1)
        q = Q(k,:);
        nq = norm(q);
        if nq < 1e-14
            Qn(k,:) = [1 0 0 0];
        else
            Qn(k,:) = q / nq;
        end
    end
end

function Om = local_omega_matrix(w)
    w = w(:);
    Om = [0, -w(1), -w(2), -w(3); ...
          w(1), 0,  w(3), -w(2); ...
          w(2), -w(3), 0,  w(1); ...
          w(3),  w(2), -w(1), 0];
end

function R = local_rotation_map(a, b)
    a = a(:) / norm(a);
    b = b(:) / norm(b);
    v = cross(a, b);
    c = dot(a, b);
    if c > 1 - 1e-12
        R = eye(3);
        return;
    elseif c < -1 + 1e-12
        tmp = null(a.');
        axisv = tmp(:,1);
        R = local_axis_angle(axisv, pi);
        return;
    end
    vx = local_skew(v);
    R = eye(3) + vx + vx * vx / (1 + c);
end

function q = local_rotm_to_quat(R)
    tr = trace(R);
    if tr > 0
        S = sqrt(tr + 1.0) * 2;
        qw = 0.25 * S;
        qx = (R(3,2) - R(2,3)) / S;
        qy = (R(1,3) - R(3,1)) / S;
        qz = (R(2,1) - R(1,2)) / S;
    elseif (R(1,1) > R(2,2)) && (R(1,1) > R(3,3))
        S = sqrt(1.0 + R(1,1) - R(2,2) - R(3,3)) * 2;
        qw = (R(3,2) - R(2,3)) / S;
        qx = 0.25 * S;
        qy = (R(1,2) + R(2,1)) / S;
        qz = (R(1,3) + R(3,1)) / S;
    elseif R(2,2) > R(3,3)
        S = sqrt(1.0 + R(2,2) - R(1,1) - R(3,3)) * 2;
        qw = (R(1,3) - R(3,1)) / S;
        qx = (R(1,2) + R(2,1)) / S;
        qy = 0.25 * S;
        qz = (R(2,3) + R(3,2)) / S;
    else
        S = sqrt(1.0 + R(3,3) - R(1,1) - R(2,2)) * 2;
        qw = (R(2,1) - R(1,2)) / S;
        qx = (R(1,3) + R(3,1)) / S;
        qy = (R(2,3) + R(3,2)) / S;
        qz = 0.25 * S;
    end
    q = [qw; qx; qy; qz];
    q = q / norm(q);
end

function R = local_quat_to_rotm(q)
    q = q(:);
    q = q / norm(q);
    w = q(1);
    x = q(2);
    y = q(3);
    z = q(4);
    R = [1 - 2*(y^2 + z^2),     2*(x*y - z*w),     2*(x*z + y*w); ...
             2*(x*y + z*w), 1 - 2*(x^2 + z^2),     2*(y*z - x*w); ...
             2*(x*z - y*w),     2*(y*z + x*w), 1 - 2*(x^2 + y^2)];
end

function S = local_skew(v)
    v = v(:);
    S = [0 -v(3) v(2); v(3) 0 -v(1); -v(2) v(1) 0];
end