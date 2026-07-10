function y = besseljprime(m, x)
%BESSELJPRIME Derivative of J_m(x) by a stable recurrence identity.
y = 0.5 * (besselj(m-1, x) - besselj(m+1, x));
end
