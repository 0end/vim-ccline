let s:drawer = {}

function! s:drawer.init() abort
  let s:init = 1
endfunction

function! s:drawer.finish() abort
  if s:init
    return
  endif
  q!
  call setpos('.', self.save_cursor)
  let &l:cursorline = self.save_cursorline
endfunction

let s:height = 15
function! s:drawer.draw(list, index, complete) abort
  if s:init
    let self.save_cursor = getcurpos()
    let self.save_cursorline = &l:cursorline
    new
    normal! ggdG
    call append(0, map(reverse(copy(a:list)), 'a:complete.display(v:val)'))
    normal! dd
    execute 'resize' min([s:height, len(a:list)])
    normal! zb
    let s:init = 0
  endif
  if a:index < 0
    let &l:cursorline = 0
  else
    call cursor(len(a:list) - a:index, 1)
    let &l:cursorline = 1
    " normal! $0
    " redraw
  endif
endfunction

function! ccline#complete#drawer#buffer#make() abort
  return deepcopy(s:drawer)
endfunction
