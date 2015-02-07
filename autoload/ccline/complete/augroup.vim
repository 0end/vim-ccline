function! ccline#complete#augroup#complete (A, L, P)
  return sort(ccline#complete#forward_matcher(split(ccline#complete#capture('augroup')), a:A))
endfunction
