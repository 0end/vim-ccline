function! ccline#complete#command#complete(A, L, P)
  return sort(ccline#complete#forward_matcher(keys(ccline#command#command()), a:A))
endfunction
