let s:source = {}

function! ccline#complete#sign#define() abort
  return deepcopy(s:source)
endfunction

function! s:source.complete(cmdline, arg, line, pos) abort
  return ccline#complete#forward_matcher(s:sign_suboptions, a:arg)
endfunction

let s:sign_suboptions = ['define', 'jump', 'list', 'place', 'undefine', 'unplace']
