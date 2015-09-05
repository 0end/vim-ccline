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
  let name = fnamemodify(a:candidate, ':t')
  let dir = fnamemodify(a:candidate, ':h:t')
  let space = 25 - strlen(name)
  let space = space <= 0 ? 5 : space
  return name . repeat(' ', space) . dir
endfunction

function! s:source.insert(candidate) abort
  return fnameescape(a:candidate)
endfunction

function! s:matcher(list, arg) abort
  let result = []
  let a = tolower(a:arg)
  for e in a:list
    if stridx(tolower(fnamemodify(e, ':t')), a) == 0 || stridx(fnameescape(e), a:arg) == 0
      call add(result, e)
    endif
  endfor
  return result
endfunction
