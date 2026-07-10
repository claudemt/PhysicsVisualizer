function d = xy2d ( m, x, y )

%*****************************************************************************80
%
%% xy2d() converts a 2D Cartesian coordinate to a 1D Hilbert coordinate.
%
%  Discussion:
%
%    It is assumed that a square has been divided into an NxN array of cells,
%    where N=2^M is a power of 2.
%
%    Cell (0,0) is in the lower left corner, and (N-1,N-1) in the upper 
%    right corner.
%
%  Licensing:
%
%    This code is distributed under the MIT license.
%
%  Modified:
%
%    05 October 2017
%
%  Author:
%
%    John Burkardt
%
%  Input:
%
%    integer M, the index of the Hilbert curve.
%    The number of cells is N=2^M.
%    0 < M.
%
%    integer X, Y, the Cartesian coordinates of a cell.
%    0 <= X, Y < N.
%
%  Output:
%
%    integer D, the Hilbert coordinate of the cell.
%    0 <= D < N * N.
%
  if ( m <= 0 )
    fprintf ( 1, '\n' );
    fprintf ( 1, 'xy2d(): Fatal error!\n' );
    fprintf ( 1, '  0 < M required.\n' );
    fprintf ( 1, '  M = %d\n', m );
    error ( 'xy2d(): Fatal error!' );
  end

  n = 2 ^ m;

  if ( x < 0 | n <= x )
    fprintf ( 1, '\n' );
    fprintf ( 1, 'xy2d(): Fatal error!\n' );
    fprintf ( 1, '  0 <= X < N required.\n' );
    fprintf ( 1, '  N = %d\n', n );
    fprintf ( 1, '  X = %d\n', x );
    error ( 'xy2d(): Fatal error!' );
  end

  if ( y < 0 | n <= y )
    fprintf ( 1, '\n' );
    fprintf ( 1, 'xy2d(): Fatal error!\n' );
    fprintf ( 1, '  0 <= Y < N required.\n' );
    fprintf ( 1, '  N = %d\n', n );
    fprintf ( 1, '  Y = %d\n', y );
    error ( 'xy2d(): Fatal error!' );
  end

  xcopy = x;
  ycopy = y;

  d = 0;

  s = floor ( n / 2 );

  while ( 0 < s )

    if ( 0 < bitand ( uint32 ( abs ( xcopy ) ), uint32 ( s ) ) )
      rx = 1;
    else
      rx = 0;
    end

    if ( 0 < bitand ( uint32 ( abs ( ycopy ) ), uint32 ( s ) ) )
      ry = 1;
    else
      ry = 0;
    end

    d = d + s * s * ( bitxor ( uint32 ( 3 * rx ), uint32 ( ry ) ) );
    
    [ xcopy, ycopy ] = rot ( s, xcopy, ycopy, rx, ry );

    s = floor ( s / 2 );

  end

  return
end
