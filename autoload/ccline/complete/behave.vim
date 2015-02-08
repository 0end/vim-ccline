function! ccline#complete#behave#complete(A, L, P)
  return ccline#complete#forward_matcher(s:behave_suboptions, a:A)
endfunction

let s:behave_suboptions = ['mswin', 'xterm']
