function caustic ( m, n )

%*****************************************************************************80
%
%% caustic() draws a caustic inside a circle.
%
%  Discussion:
%
%    caustic(m,n) connects n points, z(j), equally spaced around the unit 
%    circle, by n+1 straight lines.  The j-th line connects z(j+1) 
%    to z(mod(j*m,n)+1).
%
%    A particularly interesting plot is created by caustic(102,500).
%
%    Other good pairs include:
%      ( 88, 179)
%      ( 89, 220)
%      ( 99, 200)
%      (101, 200)
%      (111, 200)
%      (113, 188)
%      (126, 188)
%      (126, 200)
%
%  Licensing:
%
%    This code is distributed under the MIT license.
%
%  Modified:
%
%    19 December 2022
%
%  Author:
%
%    Original MATLAB version by Paul Villain, Cleve Moler.
%    This version by John Burkardt.
%
%  Reference:
%
%    Cleve Moler,
%    modfun, A Short Program Produces Impressive Graphics,
%    https://blogs.mathworks.com/cleve/2022/10/17/modfun-a-short-program-produces-impressive-graphics/
%    Posted 17 October 2022.
%
%  Input:
%
%    integer m: controls the spacing of the line endpoints.
%
%    integer n: the number of points in the circle.
%
  axis ( [ -1.0, 1.0, -1.0, 1.0 ] );
  axis ( 'square' );
  axis ( 'off' );

  z = exp ( 2i * pi * ( 0 : n ) / n );

  for j = 0 : n
    zj = [ z(j+1), z(mod(j*m,n)+1) ];
    line ( real ( zj ), imag ( zj ) );
  end

  return
end 
