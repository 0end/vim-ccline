function! ccline#complete#augroup#complete (A, L, P)
  return sort(filter(split(ccline#complete#capture('augroup')), 'v:val =~ ''^'' . a:A'))
endfunction
