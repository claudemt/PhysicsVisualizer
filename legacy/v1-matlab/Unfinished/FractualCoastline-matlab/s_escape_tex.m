function s2 = s_escape_tex ( s1 )

%*****************************************************************************80
%
%% s_escape_tex() de-escapes TeX escape sequences.
%
%  Discussion:
%
%    In particular, every occurrence of the characters '\', '_',
%    '^', '{' and '}' will be replaced by '\\', '\_', '\^',
%    '\{' and '\}'.  A TeX interpreter, on seeing these character
%    strings, is then likely to return the original characters.
%
%    The distinction in MATLAB between character vectors and strings
%    is enough to drive one mad.  Here, I preclude insanity by converting
%    any input string to a character vector, whose manipulation is 
%    so much simpler.  If a string was input, a string is returned.
%
%  Quotation:
%
%    "Sometimes an underscore is just an underscore!"
%
%  Licensing:
%
%    This code is distributed under the MIT license.
%
%  Modified:
%
%    29 August 2021
%
%  Author:
%
%    John Burkardt
%
%  Input:
%
%    character vector S1() or string S1: the text.
%
%  Output:
%
%    character vector S2() or string S2: the modified text.
%
  if ( isstring ( s1 ) )
    convert_back = true;
    s1 = char ( s1 );
  else
    convert_back = false;
  end

  s1_length = length ( s1 );

  s1_pos = 0;
  s2_pos = 0;
  s2 = [];

  while ( s1_pos < s1_length )

    s1_pos = s1_pos + 1;

    if ( s1(s1_pos) == '\' || ...
         s1(s1_pos) == '_' || ...
         s1(s1_pos) == '^' || ...
         s1(s1_pos) == '{' || ...
         s1(s1_pos) == '}' )
      s2_pos = s2_pos + 1;
      s2 = [ s2, '\' ];
    end

    s2_pos = s2_pos + 1;
    s2 = [ s2, s1(s1_pos) ];

  end

  if ( convert_back )
    s2 = string ( s2 );
  end

  return
end
