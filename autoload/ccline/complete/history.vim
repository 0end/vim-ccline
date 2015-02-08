function! ccline#complete#history#complete(A, L, P)
  return ccline#complete#forward_matcher(s:history_suboptions, a:A)
endfunction

let s:history_suboptions = [
\ '/', ':', '=', '>', '?', '@',
\ 'all', 'cmd', 'debug', 'expr', 'input', 'search'
\ ]
