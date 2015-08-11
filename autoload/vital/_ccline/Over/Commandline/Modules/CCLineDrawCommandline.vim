scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim

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
	let left_len = strdisplaywidth(a:left)
	let len = &columns - left_len % &columns
	let len = len + (&columns * (strdisplaywidth(a:suffix) > (len - 1))) - 1
	return repeat(" ", len - strdisplaywidth(a:suffix)) . a:suffix
" 	return printf("%" . len . "S", a:suffix)
endfunction


let s:old_width = 0
function! s:_redraw(cmdline)
	let left = a:cmdline.get_prompt() . a:cmdline.getline() . (empty(a:cmdline.line.pos_char()) ? " " : "")
	let width = strdisplaywidth(left) + 1

	if	a:cmdline.get_suffix() != ""
		let width += strdisplaywidth(s:suffix(left, a:cmdline.get_suffix())) - 1
	endif

	if &columns >= width && &columns <= s:old_width && s:old_width >= width
		redraw
		normal! :
	elseif &columns <= width
		normal! :
	else
		redraw
	endif
	let s:old_width = width

	call s:cmdheight.save()
	let height = max([(width - 1) / (&columns) + 1, s:cmdheight.get()])
	if height > &cmdheight || &cmdheight > height
		let &cmdheight = height
		redraw
	endif
endfunction


function! s:_as_echon(str)
	return "echon " . strtrans(string(a:str))
endfunction


function! s:module.on_draw_pre(cmdline)
  if !empty(a:cmdline.get_suffix())
    let left = a:cmdline.get_prompt() . a:cmdline.getline() . repeat(" ", empty(a:cmdline.line.pos_char()))
    let suffix =  s:_as_echon(s:suffix(left, a:cmdline.get_suffix()))
  else
    let suffix = 'echon'
  endif
  let prompt = s:as_echohl(a:cmdline._get_prompt_syntax())

  let self.draw_command = join([
  \  prompt,
  \  self.syntax_highlight(a:cmdline),
  \  'echohl ' . a:cmdline._suffix_highlight,
  \  suffix,
  \  'echohl NONE',
  \ ], ' | ')

  call s:_redraw(a:cmdline)
endfunction

function! s:module.syntax_highlight(cmdline)
  return s:as_echohl(s:draw_cursor(a:cmdline))
endfunction

function! s:draw_cursor(cmdline) abort
  let hl_list = deepcopy(a:cmdline._get_syntax())
  call filter(hl_list, '!empty(v:val.value)')
  if empty(a:cmdline.line.pos_char())
    return hl_list + [{'value': ' ', 'group': a:cmdline.highlights.cursor}]
  endif
  let cursor = {'value': a:cmdline.line.pos_char(), 'group': a:cmdline.highlights.cursor_on}
  let len = 0
  for i in range(len(hl_list))
    let len += strchars(hl_list[i].value)
    if len == a:cmdline.getpos()
      let backward = hl_list[: i]
      let on_cursor = hl_list[i + 1]
      let on_cursor.value = s:strpart(on_cursor.value, 1)
      let forward = hl_list[i + 2 :]
      let hl_list = backward + [cursor] + [on_cursor] + forward
      break
    elseif len > a:cmdline.getpos()
      if i > 0
        let backward = hl_list[: i - 1]
      else
        let backward = []
      endif
      let on_cursor = hl_list[i]
      let forward = hl_list[i + 1 :]
      let backward += [{'value': s:strpart(on_cursor.value, 0, strchars(on_cursor.value) - (len - a:cmdline.getpos())),
      \ 'group': on_cursor.group}]
      let forward = [{'value': s:strpart(on_cursor.value, strchars(on_cursor.value) - (len - a:cmdline.getpos()) + 1),
      \ 'group': on_cursor.group}] + forward
      let hl_list = backward + [cursor] + forward
      break
    endif
  endfor
  return hl_list
endfunction

function! s:as_echohl(list) abort
  let expr = ''
  for i in a:list
    let expr .= "echohl " . i.group . " | echon " . string(i.value) . " | "
  endfor
  let expr .= "echohl None"
  return strtrans(expr)
endfunction


function! s:strpart(str, start, ...)
  let s = strpart(a:str, byteidx(a:str, a:start))
  if a:0 == 0
    return s
  else
    let i = byteidx(s, a:1)
    return i == -1 ? s : strpart(s, 0, i)
  endif
endfunction


function! s:_echon(expr)
	echon strtrans(a:expr)
endfunction


function! s:module.on_draw(cmdline)
	execute self.draw_command
" 	execute "echohl" a:cmdline.highlights.prompt
" 	call s:echon(a:cmdline.get_prompt())
" 	echohl NONE
" 	call s:echon(a:cmdline.backward())
" 	if empty(a:cmdline.line.pos_char())
" 		execute "echohl" a:cmdline.highlights.cursor
" 		call s:echon(' ')
" 	else
" 		execute "echohl" a:cmdline.highlights.cursor_on
" 		call s:echon(a:cmdline.line.pos_char())
" 	endif
" 	echohl NONE
" 	call s:echon(a:cmdline.forward())
" 	if	a:cmdline.get_suffix() != ""
" 		call s:echon(s:suffix(a:cmdline.get_prompt() . a:cmdline.getline() . repeat(" ", empty(a:cmdline.line.pos_char())), a:cmdline.get_suffix()))
" 	endif
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
