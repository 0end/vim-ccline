let s:source = {}

function! ccline#complete#source#buffer#define() abort
  return deepcopy(s:source)
endfunction

function! s:source.init() abort
  let self.candidates = map(
  \ split(ccline#complete#capture('buffers'), '[\r\n]'),
  \ 'strpart(v:val, 10, stridx(v:val, ''"'', 10) - 10)')
endfunction

function! s:source.complete(cmdline, arg, line, pos) abort
  return ccline#complete#forward_matcher(self.candidates, a:arg)
endfunction
