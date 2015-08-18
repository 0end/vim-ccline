let s:source = {}

function! ccline#complete#source#behave#define() abort
  return deepcopy(s:source)
endfunction

function! s:source.init() abort
endfunction

function! s:source.complete(cmdline, arg, line, pos) abort
  return sort(ccline#complete#forward_matcher(s:behave_suboptions, a:arg))
endfunction

let s:behave_suboptions = ['mswin', 'xterm']
