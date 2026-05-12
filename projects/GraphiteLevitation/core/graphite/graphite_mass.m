function m = graphite_mass(graphite)
%GRAPHITE_MASS Sample mass.
m = graphite.rho * graphite_area(graphite) * graphite.thickness;
end
