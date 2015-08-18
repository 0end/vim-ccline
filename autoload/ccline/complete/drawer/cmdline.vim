let s:drawer = {}

function! s:drawer.init() abort
  let self.draw_command = ''
  let self.list = []
endfunction

function! s:drawer.finish() abort
endfunction

let s:height = 15
function! s:drawer.draw(list, index, complete) abort
  let begin = s:begin(len(a:list), a:index, s:height)
  let self.list = map(a:list[begin : begin + s:height - 1], 'a:complete.display(v:val)')
  let l = []
  for i in range(len(self.list) - 1, 0, -1)
    let e = self.list[i]
    if i == a:index - begin
      let e .= repeat(' ', &columns - strdisplaywidth(e) - 1)
    endif
    let e = 'echo ' . string(e)
    if i == a:index - begin
      let e = 'echohl CursorLine | ' . e . ' | echohl None'
    endif
    call add(l, e)
  endfor
  if empty(l)
    let self.draw_command = ''
    return
  endif
  let self.draw_command = join(l, ' | ') . ' | echon "\n" | '
endfunction

function! s:begin(len, index, height) abort
  let threshold = (a:height - 1)/2
  if a:index <= threshold
    return 0
  endif
  if a:index >= a:len - 1 - threshold
    return max([a:len - a:height, 0])
  endif
  return a:index - threshold
endfunction

function! s:drawer.on_draw(cmdline) abort
  let a:cmdline._draw_command = self.draw_command . a:cmdline._draw_command
  let a:cmdline._lines += self.list
endfunction

function! ccline#complete#drawer#cmdline#make() abort
  return deepcopy(s:drawer)
endfunction
