function value = is_gaussian_prime ( c )

%*****************************************************************************80
%
%% is_gaussian_prime() reports whether a complex number is a Gaussian prime.
%
%  Discussion:
%
%    Let c be a complex number of the form c = a + bi.
%
%    Then c is a Gaussian prime if 
%      * a and b are integers 
%    and
%      * a is 0 and |b| is prime and |b| mod 4 is 3 or
%      * b is 0 and |a| is prime and |a| mod 4 is 3 or
%      * neither a nor b is zero, and a^2+b^2 is prime.
%
%  Licensing:
%
%    This code is distributed under the MIT license.
%
%  Modified:
%
%    26 January 2023
%
%  Author:
%
%    John Burkardt
%
%  Input:
%
%    complex c: the number to be tested.
%
%  Output:
%
%    logical value: true if c is a Gaussian prime.
%
  a = abs ( real ( c ) );
  b = abs ( imag ( c ) );
%
%  A and B must be integers.
%  Amazingly, integer ( a ) is NOT the way to check this!
%
  if ( a ~= round ( a ) )
    value = false;

  elseif ( b ~= round ( b ) )
    value = false;
 %
%  If one is zero, the other must be a prime with remainder 3 mod 4.
%
  elseif ( a == 0 )
    value = ( isprime ( b ) && mod ( b, 4 ) == 3 );

  elseif ( b == 0 )
    value = ( isprime ( a ) && mod ( a, 4 ) == 3 );
%
%  If both are nonzero, then a^2+b^2 must be prime.
%
  else
    value = isprime ( a^2 + b^2 );
  end

  return
end

