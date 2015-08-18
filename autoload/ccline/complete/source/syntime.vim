let s:source = {}

function! ccline#complete#source#syntime#define() abort
  return deepcopy(s:source)
endfunction

function! s:source.complete(cmdline, arg, line, pos) abort
  return ccline#complete#forward_matcher(s:syntime_suboptions, a:arg)
endfunction

let s:syntime_suboptions = ['clear', 'off', 'on', 'report']
