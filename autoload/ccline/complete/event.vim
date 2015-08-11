let s:source = {}

function! ccline#complete#event#define() abort
  return deepcopy(s:source)
endfunction

function! s:source.init() abort
endfunction

function! s:source.complete(cmdline, arg, line, pos) abort
  return ccline#complete#forward_matcher(ccline#dict#event#get(), a:arg)
endfunction
