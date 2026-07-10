function [ c, d ] = gaussian_prime_spiral_step ( c, d )

%*****************************************************************************80
%
%% gaussian_prime_spiral_step() takes one step along a Gaussian prime spiral.
%
%  Discussion:
%
%    Let c be a Gaussian integer, a complex number of the form c = a + bi,
%    where a and b are integers.
%
%    Then c is a Gaussian prime if 
%      * a and b are integers 
%    and
%      * a is 0 and |b| is prime and |b| mod 4 is 3 or
%      * b is 0 and |a| is prime and |a| mod 4 is 3 or
%      * neither a nor b is zero, and a^2+b^2 is prime.
%
%    A Gaussian prime spiral begins at an initial Gaussian integer c, 
%    and an initial step direction d, which is 1, i, -1, or -i.
%
%    A step involves incrementing c by d.  If the new value of c
%    is a Gaussian prime, then the old direction is multiplied by i.
%
%    The spiral consists of a series of steps that eventually return
%    to the starting point.
%    
%  Licensing:
%
%    This code is distributed under the MIT license.
%
%  Modified:
%
%    27 January 2023
%
%  Author:
%
%    John Burkardt
%
%  Input:
%
%    complex c: the current location.
%
%    complex d: the current step increment, which should be 1, i, -1, or -i.
%
%  Output:
%
%    complex c: the next location.
%
%    complex d: the next step increment, which should be 1, i, -1, or -i.
%
  c = c + d;
  if ( is_gaussian_prime ( c ) )
    d = d * i;
  end

  return
end

