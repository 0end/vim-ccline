let s:drawer = {}

function! s:drawer.init() abort
  let self.draw_command = ''
  let self.list = []
endfunction

let s:height = 15
function! s:drawer.draw(cmdline, list, index, complete) abort
  let begin = s:begin(len(a:list), a:index, s:height)
  let line = a:cmdline.get_prompt() . a:cmdline.getline() . repeat(' ', empty(a:cmdline.line.pos_char()))
  let linelen = (strdisplaywidth(line) - 1)/&columns + 1
  let list = map(a:list[begin : begin + s:height - linelen], 's:strpart_display(a:complete.display(v:val), 0, &columns)')
  let self.list = []
  for i in range(len(list) - 1, 0, -1)
    if i == a:index - begin
      let e = [{'group': 'CursorLine', 'value': list[i] . repeat(' ', &columns - strdisplaywidth(list[i]))}]
    else
      let e = [{'group': 'None', 'value': list[i]}]
    endif
    call add(self.list, e)
  endfor
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

function! s:strpart_display(src, start, ...)
  let default_len = strdisplaywidth(a:src) - a:start
  let len = get(a:000, 0, default_len)
  if len <= 0 || default_len <= 0
    return ''
  endif
  let chars = split(a:src, '\zs')
  let loss = 0
  if a:start > 0
    let temp_len = 0
    let start_char_index = len(chars) - 1
    for i in range(len(chars))
      let temp_len += strdisplaywidth(chars[i])
      if temp_len >= a:start
        let loss = temp_len - a:start
        let start_char_index = i
        break
      endif
    endfor
    call remove(chars, 0, start_char_index)
  endif
  let temp_len = loss
  let end_char_index = -1
  let over = -1
  for i in range(len(chars))
    let temp_len += strdisplaywidth(chars[i])
    if temp_len >= len
      let over = temp_len - len
      let end_char_index = i
      break
    endif
  endfor
  if end_char_index >= 0
    if over > 0
      let end_char_index -= 1
    endif
    if end_char_index < len(chars) - 1
      call remove(chars, end_char_index + 1, len(chars) - 1)
    endif
  endif
  return join(chars, '')
endfunction

function! s:drawer.on_draw(cmdline) abort
  let a:cmdline._syntax.before = self.list
endfunction

function! ccline#complete#drawer#cmdline#make() abort
  return deepcopy(s:drawer)
endfunction
