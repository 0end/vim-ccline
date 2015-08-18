let s:source = {}

function! ccline#complete#source#filetype#define() abort
  return deepcopy(s:source)
endfunction

function! s:source.init() abort
  call ccline#dict#filetype#refresh()
endfunction

function! s:source.complete(cmdline, arg, line, pos) abort
  return sort(ccline#complete#forward_matcher(ccline#dict#filetype#get(), a:arg))
endfunction
