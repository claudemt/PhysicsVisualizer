function otf = compute_otf(psf)
%COMPUTE_OTF Compute the optical transfer function magnitude.

otf = fftshift(fft2(ifftshift(psf)));
otf = normalize_array(abs(otf));
end
