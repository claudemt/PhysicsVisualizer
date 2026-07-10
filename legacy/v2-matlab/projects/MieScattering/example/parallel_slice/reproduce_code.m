export_dir = fileparts(mfilename('fullpath'));
project_root = fileparts(fileparts(export_dir));
addpath(genpath(project_root));

% Reproduce run 01
params = struct();
params.eps1 = 2+0.2i;
params.mu1 = 0.8+0.2i;
params.R_over_lambda = 0.5;
params.nu = 1.1;
params.psi = 0.2;
params.geometry = 'cylinder';
params.mode = 'custom';
params.customSelection = {'sca_rex', 'sca_rey', 'sca_rez', 'sca_aex', 'sca_aey', 'sca_aez', 'sca_emag'};
params.gridHalfWidth = 2.5;
params.N = 500;
params.nmaxExtra = 15;
params.maskInside = true;
params.sliceType = 'xy';
params.slicePos_over_lambda = 0.1;
result_01 = compute_mie_scattering(params);
run_dir_01 = fullfile(export_dir, 'reproduce_run_01');
if exist(run_dir_01, 'dir') == 7, rmdir(run_dir_01, 's'); end
mkdir(run_dir_01);
run_files_01 = render_result('render', result_01, run_dir_01, 'Prefix', 'mie');

% Reproduce run 02
params = struct();
params.eps1 = 2+0.2i;
params.mu1 = 0.8+0.2i;
params.R_over_lambda = 0.5;
params.nu = 1.1;
params.psi = 0.2;
params.geometry = 'sphere';
params.mode = 'custom';
params.customSelection = {'sca_rex', 'sca_rey', 'sca_rez', 'sca_aex', 'sca_aey', 'sca_aez', 'sca_emag'};
params.gridHalfWidth = 2.5;
params.N = 500;
params.nmaxExtra = 15;
params.maskInside = true;
params.sliceType = 'xz';
params.slicePos_over_lambda = 0.1;
result_02 = compute_mie_scattering(params);
run_dir_02 = fullfile(export_dir, 'reproduce_run_02');
if exist(run_dir_02, 'dir') == 7, rmdir(run_dir_02, 's'); end
mkdir(run_dir_02);
run_files_02 = render_result('render', result_02, run_dir_02, 'Prefix', 'mie');

copyfile(run_files_01{1}, fullfile(export_dir, '01_cyl_sca_re_ex_slice_xy_pos_0_1.png'), 'f');
copyfile(run_files_01{2}, fullfile(export_dir, '02_cyl_sca_re_ey_slice_xy_pos_0_1.png'), 'f');
copyfile(run_files_01{3}, fullfile(export_dir, '03_cyl_sca_re_ez_slice_xy_pos_0_1.png'), 'f');
copyfile(run_files_01{4}, fullfile(export_dir, '04_cyl_sca_ex_mag_slice_xy_pos_0_1.png'), 'f');
copyfile(run_files_01{5}, fullfile(export_dir, '05_cyl_sca_ey_mag_slice_xy_pos_0_1.png'), 'f');
copyfile(run_files_01{6}, fullfile(export_dir, '06_cyl_sca_ez_mag_slice_xy_pos_0_1.png'), 'f');
copyfile(run_files_02{1}, fullfile(export_dir, '07_sph_sca_re_ex_slice_xz_pos_0_1.png'), 'f');
copyfile(run_files_02{2}, fullfile(export_dir, '08_sph_sca_re_ey_slice_xz_pos_0_1.png'), 'f');
copyfile(run_files_02{3}, fullfile(export_dir, '09_sph_sca_re_ez_slice_xz_pos_0_1.png'), 'f');
copyfile(run_files_02{4}, fullfile(export_dir, '10_sph_sca_ex_mag_slice_xz_pos_0_1.png'), 'f');
copyfile(run_files_02{5}, fullfile(export_dir, '11_sph_sca_ey_mag_slice_xz_pos_0_1.png'), 'f');
copyfile(run_files_02{6}, fullfile(export_dir, '12_sph_sca_ez_mag_slice_xz_pos_0_1.png'), 'f');
selected_files = {
    fullfile(export_dir, '01_cyl_sca_re_ex_slice_xy_pos_0_1.png');
    fullfile(export_dir, '02_cyl_sca_re_ey_slice_xy_pos_0_1.png');
    fullfile(export_dir, '03_cyl_sca_re_ez_slice_xy_pos_0_1.png');
    fullfile(export_dir, '04_cyl_sca_ex_mag_slice_xy_pos_0_1.png');
    fullfile(export_dir, '05_cyl_sca_ey_mag_slice_xy_pos_0_1.png');
    fullfile(export_dir, '06_cyl_sca_ez_mag_slice_xy_pos_0_1.png');
    fullfile(export_dir, '07_sph_sca_re_ex_slice_xz_pos_0_1.png');
    fullfile(export_dir, '08_sph_sca_re_ey_slice_xz_pos_0_1.png');
    fullfile(export_dir, '09_sph_sca_re_ez_slice_xz_pos_0_1.png');
    fullfile(export_dir, '10_sph_sca_ex_mag_slice_xz_pos_0_1.png');
    fullfile(export_dir, '11_sph_sca_ey_mag_slice_xz_pos_0_1.png');
    fullfile(export_dir, '12_sph_sca_ez_mag_slice_xz_pos_0_1.png');
};
image_output('compose_grid', selected_files, fullfile(export_dir, 'composite.png'), 'Layout', 'auto');
