scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim

let s:module = {
\	"name" : "DrawColorfulCommandline"
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
	let left = a:cmdline.get_prompt() . a:cmdline.getline() . (empty(a:cmdline.line.pos_word()) ? " " : "")
	let width = len(left) + 1

	if	a:cmdline.get_suffix() != ""
		let width += len(s:suffix(left, a:cmdline.get_suffix())) - 1
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
	let suffix = ""
	if	a:cmdline.get_suffix() != ""
		let suffix = s:_as_echon(s:suffix(a:cmdline.get_prompt() . a:cmdline.getline() . repeat(" ", empty(a:cmdline.line.pos_word())), a:cmdline.get_suffix()))
	endif

  let linehl = s:get_linehl(a:cmdline)

  let self.draw_command  = join([
  \		"echohl " . a:cmdline.highlights.prompt,
  \		s:_as_echon(a:cmdline.get_prompt()),
  \   linehl,
  \		"echohl NONE",
  \		suffix,
  \	], " | ")

	call s:_redraw(a:cmdline)
endfunction


function! s:get_linehl(cmdline)
  let syntax_dict = deepcopy(a:cmdline.syntax_dict)

  if empty(a:cmdline.line.pos_word())
    let cursor = {'str': ' ','syntax': a:cmdline.highlights.cursor}
    call add(syntax_dict, cursor)
  else
    let cursor = {'str': a:cmdline.line.pos_word(),'syntax': a:cmdline.highlights.cursor_on}
    let cursor_pos = strchars(a:cmdline.backward())
    let len = 0
    for i in range(len(syntax_dict))
      let len += strchars(syntax_dict[i].str)
      if len == cursor_pos
        let cursor_on = remove(syntax_dict, i+1)
        let cursor_on.str = s:strpart(cursor_on.str, 1)
        call insert(syntax_dict, cursor_on, i+1)
        call insert(syntax_dict, cursor, i+1)
        break
      elseif len > cursor_pos
        let cursor_on = remove(syntax_dict, i)
        let cursor_on_str_len = strchars(cursor_on.str)
        let cursor_on_forward_len = len - cursor_pos - 1
        let cursor_on_forward = s:strpart(cursor_on.str, cursor_on_str_len - cursor_on_forward_len, cursor_on_forward_len)
        let cursor_on_backward = s:strpart(cursor_on.str, 0, cursor_on_str_len - cursor_on_forward_len - 1)
        call insert(syntax_dict, {'str': cursor_on_forward, 'syntax': cursor_on.syntax}, i)
        call insert(syntax_dict, cursor, i)
        call insert(syntax_dict, {'str': cursor_on_backward, 'syntax': cursor_on.syntax}, i)
        break
      endif
    endfor
  endif
  return ccline#syntax_dict_to_string(syntax_dict)
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
" 	if empty(a:cmdline.line.pos_word())
" 		execute "echohl" a:cmdline.highlights.cursor
" 		call s:echon(' ')
" 	else
" 		execute "echohl" a:cmdline.highlights.cursor_on
" 		call s:echon(a:cmdline.line.pos_word())
" 	endif
" 	echohl NONE
" 	call s:echon(a:cmdline.forward())
" 	if	a:cmdline.get_suffix() != ""
" 		call s:echon(s:suffix(a:cmdline.get_prompt() . a:cmdline.getline() . repeat(" ", empty(a:cmdline.line.pos_word())), a:cmdline.get_suffix()))
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
