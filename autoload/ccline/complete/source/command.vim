let s:source = {}

function! ccline#complete#source#command#define() abort
  return deepcopy(s:source)
endfunction

function! s:source.init() abort
  let self.candidates = ccline#command#commands()
endfunction

function! s:source.complete(cmdline, arg, line, pos) abort
  return sort(ccline#complete#forward_matcher(self.candidates, a:arg))
endfunction

function! s:source.insert(candidate) abort
  let nargs = ccline#command#get(a:candidate).nargs
  return (nargs == '1' || nargs == '+') ? a:candidate . ' ' : a:candidate
endfunction
