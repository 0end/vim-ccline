let s:source = {}

function! ccline#complete#source#environment#define() abort
  return deepcopy(s:source)
endfunction

let s:P = ccline#vital().import('Process')

function! s:source.init() abort
  let self.candidates = map(
  \ split(s:P.system(s:environment_command), '[\r\n]'),
  \ 'strpart(v:val, 0, stridx(v:val, "="))')
endfunction

function! s:source.complete(cmdline, arg, line, pos) abort
  return ccline#complete#forward_matcher(self.candidates, a:arg)
endfunction

let s:environment_command = has('win32') ? 'set' : 'env'
