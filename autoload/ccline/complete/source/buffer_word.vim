" TODO

let s:source = {}

function! ccline#complete#source#buffer_word#define() abort
  return deepcopy(s:source)
endfunction

function! s:source.init() abort
  let self.candidates = ccline#complete#uniq(filter(
  \ split(join(getline(1, '$')), '\W'),
  \ '!empty(v:val)'))
endfunction

function! s:source.parse(cmdline) abort
  return ccline#complete#parse_by(a:cmdline.backward(), '\w\+')
endfunction

function! s:source.complete(cmdline, arg, line, pos) abort
  return sort(ccline#complete#forward_matcher(self.candidates, a:arg), 1)
endfunction
