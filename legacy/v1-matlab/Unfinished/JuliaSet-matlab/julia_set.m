function [ J, X, Y ] = julia_set ( h, w, xl, xr, yb, yt )

%*****************************************************************************80
%
%% julia_set() returns points in a Julia set.
%
%  Licensing:
%
%    This code is distributed under the MIT license. 
%
%  Modified:
%
%    23 December 2022
%
%  Author:
%
%    John Burkardt
%
%  Input:
%
%    integer H, W, the height and width of the region in pixels.
%
%    real XL, XR, YB, YT, the left, right, bottom and top limits.
%
%  Output:
%
%    logical J(h,w): true if the corresponding point is in the Julia set.
%
%    real X(h,w), Y(h,w): the coordinates of the points.
%

%
%  Create a hxw grid of X and Y coordinates.
%
  x = linspace ( xl, xr, w );
  y = linspace ( yb, yt, h );
  [ X, Y ] = meshgrid ( x, y );
%
%  Construct a complex copy of X + Yi.
%
  A = X + Y * i;
%
%  Repeatedly apply the following transformation:
%    A -> A * A + C
%
  c = - 0.8 + 0.156 * i;
  for k = 1 : 200
    A = A.^2 + c;
  end
%
%  Record the points that didn't diverge.
%
  J = abs ( A ) < 1000.0;

  return
end
