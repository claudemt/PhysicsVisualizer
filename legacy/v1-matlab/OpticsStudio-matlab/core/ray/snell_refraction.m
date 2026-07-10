function [transmitted_dir, tir] = snell_refraction(incident_dir, normal_12, n1, n2)
%SNELL_REFRACTION Vector Snell refraction with total internal reflection detection.

incident_dir = incident_dir(:) / norm(incident_dir);
normal_12 = normal_12(:) / norm(normal_12);

cos_theta_i = -dot(normal_12, incident_dir);
eta = n1 / n2;
kappa = 1 - eta^2 * (1 - cos_theta_i^2);

tir = kappa < 0;
if tir
    reflected_dir = incident_dir + 2 * cos_theta_i * normal_12;
    transmitted_dir = reflected_dir / norm(reflected_dir);
    return;
end

transmitted_dir = eta * incident_dir + (eta * cos_theta_i - sqrt(kappa)) * normal_12;
transmitted_dir = transmitted_dir / norm(transmitted_dir);
end
