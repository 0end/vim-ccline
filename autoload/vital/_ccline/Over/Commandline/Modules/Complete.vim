scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim

let s:module = {
\	"name" : "Complete",
\}

function! s:module.priority(event)
  if a:event == "on_char_pre"
    return 1
  endif
  return 0
endfunction

function! s:_parse_line(line)
  let keyword = matchstr(a:line, '\zs\w\+\ze$')
  let pos = strchars(a:line) - strchars(keyword)
  return [pos, keyword]
endfunction

function! s:_strpart_display(src, start, ...)
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


function! s:_statusline_parts(list, count)
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
  let width = strdisplaywidth(a:list[0])
  for i in range(1, len - 1)
    let last = i
    let dw = strdisplaywidth(a:list[i])
    let width += sep_width + dw
    let temp_width = width
    if i < len - 1
      let temp_width += tail_width
    endif
    if temp_width > &columns
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
  let view = a:list[first : last]
  let select_index = l:count - first
  let select = view[select_index]
  if strdisplaywidth(select) >= &columns
    let max_len = &columns - with_head*head_width - with_tail*tail_width
    let select = s:_strpart_display(select, 0, max_len)
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

function! s:_statuslines(list, count, widths)
  let parts = s:_statusline_parts(a:list, a:count)
  call map(parts, 's:_escape_percent(v:val)')
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
    let d = s:_strpart_display(parts[p], px)
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
      let result[w] .= hl_select . s:_strpart_display(d, 0, width) . hl_none
    else
      let result[w] .= hl_none . s:_strpart_display(d, 0, width)
    endif
    let px += width
    let w += 1
    let wx = 0
  endwhile
  return result
endfunction

function! s:_bottom_windows()
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

function! s:_escape_percent(expr)
  return substitute(a:expr, '%', '%%', 'g')
endfunction

function! s:_set_statuslines(winnrs, statuslines)
  for i in range(len(a:winnrs))
    call setwinvar(a:winnrs[i], '&statusline', a:statuslines[i])
  endfor
endfunction

function! s:_get_statuslines(winnrs)
  let result = range(len(a:winnrs))
  for i in range(len(a:winnrs))
    let result[i] = getwinvar(a:winnrs[i], '&statusline')
  endfor
  return result
endfunction


function! s:module.get_complete_words(cmdline, args)
  return a:cmdline.complete_words(a:args)
endfunction


function! s:module.complete(cmdline)
  call s:_finish()
  let s:bottom_windows = s:_bottom_windows()
  let s:old_statuslines = s:_get_statuslines(s:bottom_windows)

  let backward = a:cmdline.backward()
  let [pos, keyword] = s:_parse_line(backward)

  let s:complete_list = self.get_complete_words(a:cmdline, [keyword, a:cmdline.getline(), strlen(backward)])
  if empty(s:complete_list)
    return -1
  endif

  if pos == 0
    let backward = ""
  else
    let backward = join(split(backward, '\zs')[ : pos-1 ], "")
  endif
  let s:line = backward . a:cmdline.forward()
  let s:pos = pos
  let s:keyword = keyword
  call a:cmdline.setline(s:line)

  let s:count = 0
endfunction


function! s:_finish()
  if !exists("s:old_statuslines")
    return
  endif
  call s:_set_statuslines(s:bottom_windows, s:old_statuslines)
  unlet s:old_statuslines
  unlet s:bottom_windows
  redrawstatus
endfunction


function! s:module.on_char_pre(cmdline)
  if a:cmdline.is_input("<Over>(complete)")
    if self.complete(a:cmdline) == -1
      call s:_finish()
      call a:cmdline.setchar('')
      return
    endif
    call a:cmdline.setchar('')
    call a:cmdline.tap_keyinput("Completion")
    " 	elseif a:cmdline.is_input("\<Tab>", "Completion")
  elseif a:cmdline.is_input("<Over>(complete)", "Completion")
  \		|| a:cmdline.is_input("\<Right>", "Completion")
    call a:cmdline.setchar('')
    let s:count += 1
    if s:count >= len(s:complete_list)
      let s:count = -1
    endif
  elseif a:cmdline.is_input("\<Left>", "Completion")
    call a:cmdline.setchar('')
    let s:count -= 1
    if s:count < -1
      let s:count = len(s:complete_list) - 1
    endif
  else
    if a:cmdline.untap_keyinput("Completion")
      let g:ccline_flag = 1
      call a:cmdline.callevent("on_char_pre")
      unlet! g:ccline_flag
    endif
    call s:_finish()
    return
  endif
  call a:cmdline.setline(s:line)
  if s:count >= 0
    call a:cmdline.insert(s:complete_list[s:count], s:pos)
  else
    call a:cmdline.insert(s:keyword, s:pos)
  endif
  if len(s:complete_list) > 1
    let statuslines = s:_statuslines(s:complete_list, s:count, map(copy(s:bottom_windows), 'winwidth(v:val)'))
    call s:_set_statuslines(s:bottom_windows, statuslines)
    redrawstatus
  elseif len(s:complete_list) == 1
    call a:cmdline.untap_keyinput("Completion")
  endif
endfunction


function! s:module.on_draw_pre(...)
  " 	redrawstatus
endfunction


function! s:module.on_leave(cmdline)
  call s:_finish()
endfunction

function! s:make()
  return deepcopy(s:module)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
