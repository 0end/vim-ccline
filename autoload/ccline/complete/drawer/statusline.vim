let s:drawer = {}

function! s:drawer.init() abort
  let self.save_bottom_windows = s:bottom_windows()
  let self.save_statuslines = s:get_statuslines(self.save_bottom_windows)
endfunction

function! s:drawer.finish() abort
  call s:set_statuslines(self.save_bottom_windows, self.save_statuslines)
  redrawstatus
endfunction

function! s:drawer.draw(cmdline, list, index, complete) abort
  let statuslines = s:statuslines(a:list, a:index, map(copy(self.save_bottom_windows), 'winwidth(v:val)'), a:complete)
  call s:set_statuslines(self.save_bottom_windows, statuslines)
  redrawstatus
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

function! s:statusline_parts(list, count, columns, complete)
  if empty(a:list)
    return
  endif
  let l:count = (a:count >= 0) ? a:count : 0
  let head = "< "
  let tail = " >"
  let sep = "  "
  let head_width = strdisplaywidth(head)
  let tail_width = strdisplaywidth(tail)
  let sep_width = strdisplaywidth(sep)
  let first = 0
  let last = 0
  let len = len(a:list)
  let width = strdisplaywidth(a:complete.display(a:list[0]))
  for i in range(1, len - 1)
    let last = i
    let dw = strdisplaywidth(a:complete.display(a:list[i]))
    let width += sep_width + dw
    let temp_width = width
    if i < len - 1
      let temp_width += tail_width
    endif
    if temp_width > a:columns
      if l:count < i
        let last = i - 1
        break
      endif
      let first = i
      let width = head_width + dw
    endif
  endfor
  let with_head = (first > 0)
  let with_tail = (last < len - 1)
  let view = map(copy(a:list[first : last]), 'a:complete.display(v:val)')
  let select_index = l:count - first
  let select = view[select_index]
  if strdisplaywidth(select) >= a:columns
    let max_len = a:columns - with_head*head_width - with_tail*tail_width
    let select = s:strpart_display(select, 0, max_len)
  endif
  let result = ['', select, '']
  if select_index > 0
    let result[0] = join(view[: select_index - 1], sep) . sep
  endif
  if select_index < len(view) - 1
    let result[2] = sep . join(view[select_index + 1 :], sep)
  endif
  if with_head
    let result[0] = head . result[0]
  endif
  if with_tail
    let result[2] .= tail
  endif
  return result
endfunction

function! s:statuslines(list, count, widths, complete)
  let parts = s:statusline_parts(a:list, a:count, &columns - (len(a:widths) - 1), a:complete)
  call map(parts, 's:escape_percent(v:val)')
  let hl_select = "%#WildMenu#"
  let hl_none = "%#StatusLine#"
  if len(a:widths) == 1
    if a:count >= 0
      let parts[1] = hl_select . parts[1] . hl_none
    endif
    return [hl_none . join(parts, '')]
  endif
  let len = len(a:widths)
  let result = map(range(len), "hl_none")
  let p = 0
  let px = 0
  let w = 0
  let wx = 0
  while w < len && p < len(parts)
    let width = a:widths[w] - wx
    let d = s:strpart_display(parts[p], px)
    let dl = strdisplaywidth(d)
    if width >= dl
      if p == 1 && a:count >= 0
        let result[w] .= hl_select . d . hl_none
      else
        let result[w] .= hl_none . d
      endif
      let wx += dl
      let p += 1
      let px = 0
      continue
    endif
    if p == 1 && a:count >= 0
      let result[w] .= hl_select . s:strpart_display(d, 0, width) . hl_none
    else
      let result[w] .= hl_none . s:strpart_display(d, 0, width)
    endif
    let px += width
    let w += 1
    let wx = 0
  endwhile
  return result
endfunction

function! s:bottom_windows()
  let save_winnr = winnr()
  let result = []
  for i in range(1, winnr("$"))
    execute i . "wincmd w"
    wincmd j
    if i == winnr()
      call add(result, i)
    endif
  endfor
  if save_winnr != winnr()
    execute save_winnr . "wincmd w"
  endif
  return result
endfunction

function! s:escape_percent(expr)
  return substitute(a:expr, '%', '%%', 'g')
endfunction

function! s:set_statuslines(winnrs, statuslines)
  for i in range(len(a:winnrs))
    call setwinvar(a:winnrs[i], '&statusline', a:statuslines[i])
  endfor
endfunction

function! s:get_statuslines(winnrs)
  let result = range(len(a:winnrs))
  for i in range(len(a:winnrs))
    let result[i] = getwinvar(a:winnrs[i], '&statusline')
  endfor
  return result
endfunction

function! ccline#complete#drawer#statusline#make() abort
  return deepcopy(s:drawer)
endfunction
