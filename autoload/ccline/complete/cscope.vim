function! ccline#complete#cscope#complete(A, L, P)
  return ccline#complete#forward_matcher(s:cscope_suboptions, a:A)
endfunction

let s:cscope_suboptions = ['add', 'find', 'help', 'kill', 'reset', 'show']
