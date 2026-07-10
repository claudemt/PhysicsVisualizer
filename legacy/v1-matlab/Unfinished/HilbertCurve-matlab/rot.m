function [ x, y ] = rot ( n, x, y, rx, ry ) 

%*****************************************************************************80
%
%% rot() rotates and flips a quadrant appropriately.
%
%  Licensing:
%
%    This code is distributed under the MIT license.
%
%  Modified:
%
%    05 December 2015
%
%  Author:
%
%    John Burkardt
%
%  Input:
%
%    integer N, the length of a side of the square.  
%    N must be a power of 2.
%
%    integer X, Y, the coordinates of a point.
%
%    integer RX, RY, values of 0 or 1, which indicate whether a flip
%    or rotation should occur.
%
%  Output:
%
%    integer X, Y: the new coordinates of the point.
%
  if ( ry == 0 )
%
%  Reflect.
%
    if ( rx == 1 )
      x = n - 1 - x;
      y = n - 1 - y;
    end
%
%  Flip.
%
    t = x;
    x = y;
    y = t;

  end

  return
end
