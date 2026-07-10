function coastline_display ( p, prefix )

%*****************************************************************************80
%
%% coastline_display() displays a coastline, a closed polygonal curve.
%
%  Licensing:
%
%    This code is distributed under the MIT license. 
%
%  Modified:
%
%    31 July 2023
%
%  Author:
%
%    John Burkardt
%
%  Reference:
%
%    David Kahaner, Cleve Moler, Steven Nash,
%    Numerical Methods and Software,
%    Prentice Hall, 1989,
%    ISBN: 0-13-627258-4,
%    LC: TA345.K34.
%
%  Input:
%
%    real p(n,2): the coordinates of a closed polygonal curve.
%
%    string prefix: a prefix defining the title and output filename.
%
  figure ( );
  hold ( 'on' );
    fill ( p(:,1), p(:,2), 'r' );
    plot ( p(:,1), p(:,2), 'k.', markersize = 15 );
  hold ( 'off' );
  grid ( 'on' );
  axis ( 'equal' );
  prefix_fixed = s_escape_tex ( prefix );
  title ( prefix_fixed );
  filename = strcat ( prefix, '.png' );
  print ( '-dpng', filename );
  fprintf ( 1, '  Graphics saved as "%s"\n', filename );
  close ( );

  return
end

