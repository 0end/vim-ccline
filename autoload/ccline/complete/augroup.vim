let s:source = {}

function! ccline#complete#augroup#define() abort
  return deepcopy(s:source)
endfunction

function! s:source.init() abort
  let self.candidates = split(ccline#complete#capture('augroup'))
endfunction

function! s:source.complete(cmdline, arg, line, pos) abort
  return sort(ccline#complete#forward_matcher(self.candidates, a:arg))
endfunction
