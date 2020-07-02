function q = quantile_nu(x, p, alpha)
[x, I] = sort(x, 'ascend');
x = x(cumsum(p(I)) >= alpha); q = x(1);
