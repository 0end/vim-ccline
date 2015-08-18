let s:source = {}

function! ccline#complete#source#user#define() abort
  return deepcopy(s:source)
endfunction

let s:P = ccline#vital().import('Process')

function! s:source.init() abort
  if filereadable('/etc/passwd')
    let self.candidates = map(split(s:P.system('cat /etc/passwd'), '[\r\n]'), 'split(v:val, ":")[0]')
  elseif executable('net')
    let self.candidates = split(split(s:P.system('net user'), '[\r\n]')[3])
  endif
endfunction

function! s:source.complete(cmdline, arg, line, pos) abort
  return sort(ccline#complete#forward_matcher(self.candidates, a:arg))
endfunction
