function epicycloid_plot ( k, s, x, y, filename )

%*****************************************************************************80
%
%% epicycloid_plot() plots points along an epicycloid.
%
%  Licensing:
%
%    This code is distributed under the MIT license.
%
%  Modified:
%
%    11 February 2016
%
%  Author:
%
%    John Burkardt
%
%  Input:
%
%    real K, the ratio between the large and small circles.
%
%    real S, the number of times the small circle rotates around
%    the large circle.
%
%    real X(*), Y(*), the coordinates of points along the epicycloid.
%
%    string FILENAME, the name for the PNG file to be created.
%
  plot ( x, y );
  axis equal
  w = sprintf ( 'Ratio R/r = %g, Revolutions = %d', k, s );
  title ( w );

  print ( '-dpng', filename );

  return
end
