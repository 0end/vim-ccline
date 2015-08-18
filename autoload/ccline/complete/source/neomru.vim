let s:source = {}

function! ccline#complete#source#neomru#define() abort
  return deepcopy(s:source)
endfunction

function! s:source.init() abort
  let s:mru = neomru#_get_mrus().file
  call neomru#_reload()
  let self.candidates = s:mru.candidates
endfunction

function! s:source.complete(cmdline, arg, line, pos) abort
  return s:matcher(self.candidates, a:arg)
endfunction

function! s:source.display(candidate) abort
  return pathshorten(a:candidate)
endfunction

function! s:matcher(list, arg) abort
  let result = []
  for e in a:list
    if stridx(fnamemodify(e, ':t'), a:arg) == 0
      call add(result, e)
    endif
  endfor
  return result
endfunction
