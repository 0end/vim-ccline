function! ccline#complete#syntime#complete(A, L, P)
  return ccline#complete#forward_matcher(s:syntime_suboptions, a:A)
endfunction

let s:syntime_suboptions = ['clear', 'off', 'on', 'report']
