scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim

let s:module = {
\	"name" : "Complete",
\}

function! s:_parse_line(line)
  let keyword = matchstr(a:line, '\zs\w\+\ze$')
  let pos = strchars(a:line) - strchars(keyword)
  return [pos, keyword]
endfunction

function! s:_strpart_display(src, start, ...)
  let len = get(a:000, 0, strdisplaywidth(a:src) - a:start)
  if len <= 0
    return ''
  endif
  let chars = split(a:src, '\zs')

  let loss = 0
  if a:start > 0
    let temp_len = 0
    let start_char_index = 0
    for char in chars
      let temp_len += strdisplaywidth(char)
      if temp_len >= a:start
        let loss = temp_len - a:start
        break
      endif
      let start_char_index += 1
    endfor
    call remove(chars, 0, start_char_index)
  endif

  let temp_len = loss
  let end_char_index = 0
  let over = -1
  for char in chars
    let temp_len += strdisplaywidth(char)
    if temp_len >= len
      let over = temp_len - len
      break
    endif
    let end_char_index += 1
  endfor
  if over == 0
    try
      call remove(chars, end_char_index+1, len(chars)-1)
    catch
    endtry
  elseif over > 0
    call remove(chars, end_char_index, len(chars)-1)
  endif
  return join(chars, '')
endfunction

function! s:_as_statusline(list, count, columns)
  if empty(a:list)
    return
  endif
  let l:count = (a:count >= 0) ? a:count : 0
  let hl_select = "%#WildMenu#"
  let hl_none = "%#StatusLine#"
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
  for i in range(1,len-1)
    let last = i
    let dw = strdisplaywidth(a:list[i])
    let width += sep_width + dw
    let temp_width = width
    if i < len - 1
      let temp_width += tail_width
    endif
    if temp_width > a:columns
      if l:count < i
        let last = i-1
        break
      endif
      let first = i
      let width = head_width + dw
    endif
  endfor
  let view = a:list[first : last]
  let select = view[l:count - first]
  let with_head = (first > 0)
  let with_tail = (last < len - 1)
  if strdisplaywidth(select) >= a:columns
    "let select = ''
    let select_len = a:columns - with_head*head_width - with_tail*tail_width
    let select = s:_strpart_display(select, 0, select_len)
  endif
  if a:count >= 0
    let view[l:count - first] = hl_select . select . hl_none
  else
    let view[l:count - first] = select
  endif
  let result = join(view, sep)
  if with_head
    let result = head . result
  endif
  if with_tail
    let result .= tail
  endif
  return hl_none . result
endfunction


function! s:module.get_complete_words(cmdline, args)
  return a:cmdline.get_complete_words(a:args)
endfunction


function! s:module.complete(cmdline)
  call s:_finish()
  " let s:old_statusline = &statusline
  let s:old_statusline = getwinvar(winnr("$"), '&statusline')

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
  call a:cmdline.setline(s:line)

  let s:count = 0
endfunction


function! s:_finish()
  " if exists("s:old_statusline")
  "   let &statusline = s:old_statusline
  "   unlet s:old_statusline
  "   redrawstatus
  " endif
  if !exists("s:old_statusline")
    return
  endif
  call setwinvar(winnr("$"), '&statusline', s:old_statusline)
  unlet s:old_statusline
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
      call a:cmdline.callevent("on_char_pre")
    endif
    call s:_finish()
    return
  endif
  call a:cmdline.setline(s:line)
  if s:count >= 0
    call a:cmdline.insert(s:complete_list[s:count], s:pos)
  endif
  if len(s:complete_list) > 1
    " let &statusline = s:_as_statusline(s:complete_list, s:count)
    call setwinvar(winnr("$"), '&statusline', s:_as_statusline(s:complete_list, s:count, winwidth(winnr("$"))))
    redrawstatus
  endif
  if len(s:complete_list) == 1
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
