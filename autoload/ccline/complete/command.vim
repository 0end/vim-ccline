function! ccline#complete#command#complete(A, L, P)
  return sort(filter(keys(ccline#command#command()), 'v:val =~ ''^'' . a:A'))
endfunction
