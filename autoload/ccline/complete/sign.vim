function! ccline#complete#sign#complete(A, L, P)
  return ccline#complete#forward_matcher(s:sign_suboptions, a:A)
endfunction

let s:sign_suboptions = ['define', 'jump', 'list', 'place', 'undefine', 'unplace']
