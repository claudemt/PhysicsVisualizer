function S = spiral_array ( thick, base )

%*****************************************************************************80
%
%% spiral_array() produces a 2*thick+1 x 2*thick+1 spiral array of integers.
%
%  Licensing:
%
%    This code is distributed under the MIT license.
%
%  Modified:
%
%    29 December 2022
%
%  Author:
%
%    John Burkardt
%
%  Input:
%
%    integer thick: the "radius" of the array, which can be 0 or more.
%
%    integer base: the starting value at the center of the spiral.
%    This is usually 1.
%
%  Output:
%
%    integer S[2*thick+1,2*thick+1]: an array of sequential integers, 
%    spiraling out from a central value of base.
%
  n = 2 * thick + 1;
  S = zeros ( n, n );

  row = thick + 1;
  col = thick;
  k = base - 1;

  for t = 0 : thick

    col = col + 1;
    k = k + 1;
    S(row,col) = k;
    done = false;

    while ( ~ done )

      if ( row == t + thick + 1 && col == t + thick + 1 )
        done = true;
        break
      elseif ( col == t + thick + 1 && - t + thick + 1 < row )
        row = row - 1;
      elseif ( row == - t + thick + 1 && - t + thick + 1 < col )
        col = col - 1;
      elseif ( col == - t + thick + 1 && row < t + thick + 1 )
        row = row + 1;
      elseif ( row == t + thick + 1 && col < t + thick + 1 )
        col = col + 1;
      end
      k = k + 1;
      S(row,col) = k;

    end

  end

  return
end

