# Graphite levitation model

The visualizer uses a compact checkerboard magnet array and a circular or square graphite footprint.

The field map shows

\[
B^2(x,y,z)=B_x^2+B_y^2+B_z^2.
\]

The magnetic-potential map is the graphite-footprint weighted integral

\[
U(X,Y)\propto \int_A |\chi(x,y)| B^2(X+x,Y+y,z_0)\,dA.
\]

Without laser, \(|\chi(x,y)|=|\chi_0|\). With laser, the GUI applies a Gaussian susceptibility reduction controlled by the dimensionless strength factor \(P\). Setting \(P=0\) gives the no-laser case.

Inline scans are restricted to four physical quantities: \(d\), \(W\), \(\chi\), and \(P\). Notes report displacement and tilt only.
