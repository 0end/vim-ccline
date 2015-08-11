let s:source = {}

function! ccline#complete#history#define() abort
  return deepcopy(s:source)
endfunction

function! s:source.complete(cmdline, arg, line, pos) abort
  return ccline#complete#forward_matcher(s:history_suboptions, a:arg)
endfunction

let s:history_suboptions = [
\ '/', ':', '=', '>', '?', '@',
\ 'all', 'cmd', 'debug', 'expr', 'input', 'search'
\ ]
