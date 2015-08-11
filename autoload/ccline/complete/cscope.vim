let s:source = {}

function! ccline#complete#cscope#define() abort
  return deepcopy(s:source)
endfunction

function! s:source.init() abort
endfunction

function! s:source.complete(cmdline, arg, line, pos) abort
  return ccline#complete#forward_matcher(s:cscope_suboptions, a:arg)
endfunction

let s:cscope_suboptions = ['add', 'find', 'help', 'kill', 'reset', 'show']
