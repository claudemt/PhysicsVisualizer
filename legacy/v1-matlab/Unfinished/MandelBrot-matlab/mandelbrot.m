function mandelbrot ( m, n, count_max )

%*****************************************************************************80
%
%% mandelbrot() computes an image of the Mandelbrot set.
%
%  Licensing:
%
%    This code is distributed under the MIT license. 
%
%  Modified:
%
%    09 May 2017
%
%  Author:
%
%    John Burkardt
%
%  Input:
%
%    integer M, the number of pixels in the X direction.
%
%    integer N, the number of pixels in the Y direction.
%
%    integer COUNT_MAX, the number of iterations.  While 10 or
%    20 is a reasonable value, increasing COUNT_MAX gives a sharper image.
%
  if ( nargin == 0 )
    m = 101;
  end

  if ( nargin <= 1 )
    n = m;
  end

  if ( nargin <= 2 )
    count_max = 20;
  end
%
%  The whole thing.
%
% x_min = - 2.25;
% x_max =   1.25;
% y_min = - 1.75;
% y_max =   1.75;
%
%  Extreme close up of the lower "neck".
%
% x_min = - 0.76;
% x_max = - 0.74;
% y_min = - 0.05;
% y_max = - 0.03;
%
%  Closeup of the upper neck.
%
  x_min = - 1.00;
  x_max = - 0.60; 
  y_min =   0.00;
  y_max =   0.40;

  fprintf ( 1, '\n' );
  fprintf ( 1, 'mandelbrot():\n' );
  fprintf ( 1, '  Create an image of the Mandelbrot set.\n' );
  fprintf ( 1, '\n' );
  fprintf ( 1, '  For each point C = X + i*Y\n' );
  fprintf ( 1, '  with X range [%f,%f]\n', x_min, x_max );
  fprintf ( 1, '  and  Y range [%f,%f]\n', y_min, y_max );
  fprintf ( 1, '  carry out %d iterations of the map\n', count_max );
  fprintf ( 1, '  Z(n+1) = Z(n)^2 + C.\n' );
  fprintf ( 1, '  If the iterates stay bounded\n' );
  fprintf ( 1, '  then C is a member of the Mandelbrot set.\n' );
  fprintf ( 1, '\n' );
  fprintf ( 1, '  An image of the set is created using\n' );
  fprintf ( 1, '    M = %d pixels in the X direction and\n', m );
  fprintf ( 1, '    N = %d pixels in the Y direction.\n', n );
  fprintf ( 1, '    COUNT_MAX = %d = number of iterations.\n', count_max );
%
%  Create an array of complex sample points in [x_min,x_max] + [y_min,y_max]*i.
%
  I = ( 1 : m );
  J = ( 1 : n );
  X = ( ( I - 1 ) * x_max + ( m - I ) * x_min ) / ( m - 1 );
  Y = ( ( J - 1 ) * y_max + ( n - J ) * y_min ) / ( n - 1 );
  [ Zr, Zi ] = meshgrid ( X, Y );
  C = complex ( Zr, Zi );
%
%  Carry out the iteration.
%
  Z = C;
  ieps = 1 : numel ( C );
  d(ieps) = count_max + 1;

  for i = 1 : count_max
    Z(ieps) = Z(ieps) .* Z(ieps) + C(ieps);
    U(ieps) = abs ( Z(ieps) );
    neps = ieps ( find ( 2.0 < U(ieps) ) );
    d(neps) = i;
    ieps = ieps ( find ( U(ieps) <= 2.0 ) );
  end

  clf ( );
%
%  Display the data.
%
  t = delaunay ( Zr, Zi );
%
%  Set a nonsmooth color map.
%  colorcube, flag, lines, prism.
%
  colormap ( 'prism');
%
%  Make a color contour plot.
%
  h = trisurf ( t, Zr, Zi, d, 'FaceColor', 'interp', 'EdgeColor', 'interp' );

  view ( 2 );
  axis ( 'equal' );
  axis ( 'tight' );
  xtitle = sprintf ( '%g <---X---> %g', x_min, x_max );
  xlabel ( xtitle );
  ytitle = sprintf ( '%g <---Y---> %g', y_min, y_max );
  ylabel ( ytitle );
  title_string = sprintf ( 'Mandelbrot set, %d x %d pixels, %d iterations', ...
    m, n, count_max );
  title ( title_string );
  set ( gca, 'xticklabel', [] );
  set ( gca, 'yticklabel', [] );

  return
end

