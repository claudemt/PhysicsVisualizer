function gaussian_prime_display ( clo, chi )

%*****************************************************************************80
%
%% gaussian_prime_display() displays Gaussian primes in a rectangular range.
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
%    28 January 2023
%
%  Author:
%
%    John Burkardt
%
%  Input:
%
%    complex clo, chi: defines the lower left and upper right corners of the range.
%    Both clo and chi should be Gaussian integers.
%
  alo = round ( real ( clo ) );
  blo = round ( imag ( clo ) ); 
  ahi = round ( real ( chi ) );
  bhi = round ( imag ( chi ) );

  clf ( );
  hold ( 'on' );

  for a = alo : ahi
    for b = blo : bhi
      if ( is_gaussian_prime ( a + b*i ) )
        plot ( a, b, 'r.', 'markersize', 20 );
      else
        plot ( a, b, 'ko', 'markersize', 5 );
      end
    end
  end

  hold ( 'off' );
  axis ( 'equal' );
  grid ( 'on' );
  title ( 'Gaussian primes (red dots)' );
  filename = 'gaussian_prime_display.png';
  print ( '-dpng', filename );
  fprintf ( 1, '  Graphics saved as "%s"\n', filename );

  return
end

