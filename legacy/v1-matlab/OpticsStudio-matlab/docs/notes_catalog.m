function notes_lines = notes_catalog(module_key, mode_key)
%NOTES_CATALOG Return concise mode-specific notes for the notes panel.

module_key = lower(strtrim(module_key));
mode_key = lower(strtrim(mode_key));

switch module_key

    case 'fourier_studio'
        notes_lines = {
            'Fourier studio / modular 4f system';
            '• setup: freely combine any object plane, phase plane, and Fourier filter module.';
            '• preset: loads a curated classroom-ready combination and fills the tuning fields.';
            '• object scale and secondary scale are reused by many aperture and grating modules.';
            '• phase radius and zernike coefficient control finite-support pupil aberration modules.';
            '• filter scale ratio sets the support of the Fourier mask modules.';
            '• plot range = auto crops to salient content, while fixed enforces shared spatial extents.';
            '• image scaling = auto stretches contrast per panel, while fixed preserves comparable color limits.'};

    case 'wave_optics'
        if strcmp(mode_key, '4f_filtering')
            notes_lines = {
                'Wave optics / 4F filtering';
                '• mode: choose free-space propagation or Fourier-plane filtering.';
                '• object: selects the input amplitude pattern used as the sample.';
                '• filter and filter scale: choose the Fourier mask and its support.';
                '• wavelength and pixel size: set the physical sampling scale.';
                '• grid size: purely numerical resolution; larger values are slower but cleaner.';
                '• band-limit: numerical stabilization for angular-spectrum propagation.'};
        else
            notes_lines = {
                'Wave optics / free-space propagation';
                '• wavelength: scalar wavelength of the propagated field.';
                '• distance: propagation distance along z.';
                '• pixel size: sample-plane pitch that sets the spatial-frequency grid.';
                '• object: synthetic amplitude object at the input plane.';
                '• grid size: numerical resolution only; it changes discretization, not physics.';
                '• band-limit: truncates unstable spectral content in angular-spectrum propagation.'};
        end

    case 'imaging'
        if strcmp(mode_key, 'sted')
            notes_lines = {
                'Imaging / STED';
                '• aberration and coefficient: set the pupil phase distortion in waves.';
                '• STED strength: depletion strength in the effective-PSF model.';
                '• grid size: numerical sampling of the pupil and focal plane.';
                '• the profile compares the widefield PSF and the depleted effective PSF.'};
        elseif strcmp(mode_key, 'confocal')
            notes_lines = {
                'Imaging / confocal';
                '• aberration and coefficient: set the pupil phase distortion in waves.';
                '• pinhole factor: smaller values mimic tighter detection and stronger sectioning.';
                '• grid size: numerical sampling of the pupil and focal plane.';
                '• the effective PSF is formed from excitation and detection responses.'};
        else
            notes_lines = {
                'Imaging / widefield';
                '• aberration: choose the Zernike-like phase mode applied at the pupil.';
                '• coefficient: aberration strength in waves.';
                '• grid size: numerical sampling of the pupil and PSF arrays.';
                '• the panels show pupil phase, PSF, OTF magnitude, and a central line profile.'};
        end

    case 'interference'
        if strcmp(mode_key, 'moire')
            notes_lines = {
                'Interference / moire';
                '• grating 1 frequency and grating 2 frequency set the two carrier periods.';
                '• grating 2 angle controls the angular mismatch and rotates the beat envelope.';
                '• grid size only changes numerical resolution of the displayed pattern.'};
        elseif strcmp(mode_key, 'gs_phase')
            notes_lines = {
                'Interference / Gerchberg-Saxton phase retrieval';
                '• GS iterations: number of alternating projection steps.';
                '• GS damping: weighted pupil update; smaller values are more conservative.';
                '• grid size controls numerical sampling of pupil and focal planes.';
                '• convergence curves report efficiency and uniformity over iteration.'};
        else
            notes_lines = {
                'Interference / shearing interferometry';
                '• aberration and coefficient define the underlying wavefront.';
                '• shear sets the lateral displacement between the two replicas.';
                '• carrier frequency adds a linear fringe carrier.';
                '• grid size only changes numerical resolution.'};
        end

    case 'ray_optics'
        if strcmp(mode_key, 'spherical_interface')
            notes_lines = {
                'Geometric optics / spherical interface';
                '• n1 and n2 are the refractive indices before and after the surface.';
                '• radius is the spherical-surface radius of curvature.';
                '• screen z is the observation plane after refraction.';
                '• aperture radius is the physical ray bundle half-width.';
                '• ray count is a display/sampling parameter; it changes bundle density only.'};
        else
            notes_lines = {
                'Geometric optics / thin lens';
                '• object distance, focal length, and object height set the paraxial geometry.';
                '• aperture radius controls the plotted ray bundle extent.';
                '• ray count is a display/sampling parameter; it changes bundle density only.';
                '• the lower plot shows magnification versus object distance.'};
        end

    case 'tomography'
        notes_lines = {
            'Tomography / parallel-beam reconstruction';
            '• phantom chooses the 2D object to project.';
            '• filter selects the backprojection filter.';
            '• image size sets reconstruction grid resolution.';
            '• number of angles and detector bins are numerical sampling parameters.';
            '• larger angle and detector counts reduce artifacts at higher cost.'};

    otherwise
        notes_lines = {'No notes are available for this selection.'};
end
end
