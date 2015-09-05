let s:source = {}

function! ccline#complete#source#locale#define() abort
  return deepcopy(s:source)
endfunction

let s:P = ccline#vital().import('Process')

if executable('locale')
  function! s:source.init() abort
    let self.candidates = split(s:P.system('locale -a'), '[\r\n]')
  endfunction
else
  function! s:source.init() abort
    let self.candidates = []
  endfunction
endif

function! s:source.complete(cmdline, arg, line, pos) abort
  return ccline#complete#forward_matcher(self.candidates, a:arg)
endfunction
