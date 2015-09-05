scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim

function! s:_vital_loaded(V) abort
  let s:H = a:V.import('Highlight')
endfunction

function! s:_vital_depends() abort
  return ['Highlight']
endfunction

let s:module = {
\	"name" : "CCLineDrawCommandline"
\}

let s:cmdheight = {}

function! s:cmdheight.save()
	if has_key(self, "value")
		return
	endif
	let self.value = &cmdheight
endfunction

function! s:cmdheight.restore()
	if has_key(self, "value")
		let &cmdheight = self.value
		unlet self.value
	endif
endfunction


function! s:cmdheight.get()
	return self.value
endfunction

function! s:suffix(left, suffix)
  if empty(a:suffix)
    return ''
  endif
	let left_len = strdisplaywidth(a:left)
	let len = &columns - left_len % &columns
	let len = len + (&columns * (strdisplaywidth(a:suffix) > (len - 1))) - 1
	return repeat(" ", len - strdisplaywidth(a:suffix)) . a:suffix
" 	return printf("%" . len . "S", a:suffix)
endfunction

let s:old_height = 0
function! s:_redraw(lines)
  let height = 0
  for l in a:lines
    " strdisplaywidth(repeat('a', &columns + 1)) != &columns + 1
    let height += (strwidth(l) - 1)/&columns + 1
  endfor
  if strwidth(a:lines[len(a:lines) - 1]) % &columns == 0
    " echo repeat('a', &columns)
    let height += 1
  endif
  if !(height == 1 && s:old_height == 1)
    normal! :
  endif
  let s:old_height = height
  call s:cmdheight.save()
  let height = max([height, s:cmdheight.get()])
  if height != &cmdheight
    let &cmdheight = height
    redraw
  endif
endfunction

function! s:module.priority(event)
  if a:event == "on_draw_pre" || a:event == "on_draw"
    return 1
  endif
  return 0
endfunction

function! s:module.on_draw_pre(cmdline)
  let left = a:cmdline.get_prompt() . a:cmdline.getline() . repeat(' ', empty(a:cmdline.line.pos_char()))
  let suffix = s:suffix(left, a:cmdline.get_suffix())
  let a:cmdline._syntax = {
  \ 'before': [],
  \ 'prompt': a:cmdline._get_prompt_syntax(),
  \ 'suffix': [{'group': a:cmdline._suffix_highlight, 'value': suffix}],
  \ 'after': [],
  \ }
  let [a:cmdline._syntax.backward, a:cmdline._syntax.cursor, a:cmdline._syntax.forward] = s:draw_cursor(a:cmdline)
endfunction

function! s:module.on_draw(cmdline)
  let list = a:cmdline._syntax.before
  \ +        [
  \            a:cmdline._syntax.prompt
  \          + a:cmdline._syntax.backward
  \          + a:cmdline._syntax.cursor
  \          + a:cmdline._syntax.forward
  \          + a:cmdline._syntax.suffix
  \          ]
  \ +        a:cmdline._syntax.after
  call s:_redraw(s:to_raw(list))
  execute s:as_echohl(list)
  redraw
endfunction

function! s:draw_cursor(cmdline) abort
  let l = deepcopy(a:cmdline._get_syntax())
  if empty(a:cmdline.line.pos_char())
    return [l, [{'value': ' ', 'group': a:cmdline.highlights.cursor_on}], []]
  endif
  let cursor = {'value': a:cmdline.line.pos_char(), 'group': a:cmdline._cursor_insert_highlight}
  let pos = strlen(a:cmdline.backward() . cursor.value)
  let len = 0
  for i in range(len(l))
    let len += strlen(l[i].value)
    if len < pos
      continue
    endif
    let backward = i > 0 ? l[: i - 1] : []
    let on_cursor = l[i]
    let forward = l[i + 1 :]
    let backward += [{'value': strpart(on_cursor.value, 0, strlen(on_cursor.value) - (len - strlen(a:cmdline.backward()))), 'group': on_cursor.group}]
    let forward = [{'value': strpart(on_cursor.value, strlen(on_cursor.value) - (len - pos)), 'group': on_cursor.group}] + forward

    call s:H.clear(a:cmdline._cursor_insert_highlight)
    call s:H.highlight(a:cmdline._cursor_insert_highlight, s:H.extend(s:H.gethldict(on_cursor.group), s:H.gethldict(a:cmdline.highlights.cursor_insert)))

    return [backward, [cursor] , forward]
  endfor
endfunction

function! s:to_raw(list) abort
  let result = []
  for line in a:list
    let str = ''
    for l in line
      let str .= l.value
    endfor
    call add(result, strtrans(str))
  endfor
  return result
endfunction

function! s:as_echohl(list) abort
  let command = ''
  let over_columns = 0
  for i in range(len(a:list))
    let str = ''
    for l in a:list[i]
      let v = strtrans(l.value)
      let str .= v
      let command .= 'echohl ' . l.group . ' | echon ' . string(v) . ' | '
    endfor
    if strwidth(str) % &columns != 0 && i < len(a:list) - 1
      let command .= 'echon "\n" | '
    endif
  endfor
  return command . 'echohl None'
endfunction

function! s:module.on_execute_pre(...)
	call s:cmdheight.restore()
endfunction


function! s:module.on_leave(...)
	call s:cmdheight.restore()
endfunction


function! s:make()
	return deepcopy(s:module)
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
