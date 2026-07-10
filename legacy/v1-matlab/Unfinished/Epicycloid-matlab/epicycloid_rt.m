function [ r, t ] = epicycloid_rt ( k, s, n )

%*****************************************************************************80
%
%% epicycloid_rt() computes (r,t) points along an epicycloid.
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
%    integer N, the number of points to compute.
%
%    real R(*), T(*), the polar coordinates of points along the epicycloid.
%
  rsmall = 1.0;

  t = linspace ( 0.0, 2.0 * pi * s, n );
  x = rsmall * ( k + 1 ) * cos ( t ) - rsmall * cos ( ( k + 1 ) * t );
  y = rsmall * ( k + 1 ) * sin ( t ) - rsmall * sin ( ( k + 1 ) * t );
  r = sqrt ( x.^2 + y.^2 );

  return
end
