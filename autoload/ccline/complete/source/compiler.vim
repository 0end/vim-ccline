let s:source = {}

function! ccline#complete#source#compiler#define() abort
  return deepcopy(s:source)
endfunction

function! s:source.init() abort
  let self.candidates = map(
  \ split(ccline#complete#capture('compiler'), '\n'),
  \ 'fnamemodify(v:val, ":t:r")')
endfunction

function! s:source.complete(cmdline, arg, line, pos) abort
  return sort(ccline#complete#forward_matcher(self.candidates, a:arg))
endfunction
