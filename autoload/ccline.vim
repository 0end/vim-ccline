scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim

let s:cmdline = vital#of("ccline").import("Over.Commandline")

let s:ccline = s:cmdline.make_default()
call s:ccline.connect(s:cmdline.make_module("History", ":"))
call s:ccline.connect(s:cmdline.make_module("HistAdd", ":"))
call s:ccline.connect("Paste")
call s:ccline.connect("Cancel")
call s:ccline.connect("Delete")
call s:ccline.connect("CursorMove")
call s:ccline.connect("InsertRegister")
call s:ccline.connect(s:cmdline.make_module("NoInsert", ""))
call s:ccline.connect("Redraw")
call s:ccline.connect("DrawColorfulCommandline")
call s:ccline.connect("ExceptionExit")
call s:ccline.connect("ExceptionMessage")
call s:ccline.connect("Execute")
call s:ccline.connect("Complete")
call s:ccline.connect(s:cmdline.make_module("Doautocmd", "CCLine"))

call s:ccline.cnoremap("\<Tab>", "<Over>(complete)")

let s:line_highlight = [{'str': '', 'syntax': 'None'}]

function! ccline#start(prompt, input)
  if a:input == "'<,'>"
    let s:visual_hl = matchadd('Visual', '\%V', -1)
  endif
  call s:ccline.set_prompt(a:prompt)
  let exit_code = s:ccline.start(a:input)
  " if exit_code == 1
  "   doautocmd User CCLineCancel
  " endif
endfunction

function! s:ccline.get_highlight()
  if s:ccline.is_input("\<Right>") || s:ccline.is_input("\<Left>")
    return deepcopy(s:line_highlight)
  endif
  let s:line_highlight = ccline#highlight#strsyntax(s:ccline.getline(), 'vim')
  return deepcopy(s:line_highlight)
endfunction

function! s:ccline.get_complete_words(args)
  return ccline#complete#complete(a:args)
endfunction

function! s:ccline.on_execute_pre(cmdline)
  if exists('s:visual_hl')
    call matchdelete(s:visual_hl)
    unlet s:visual_hl
  endif
endfunction

function! s:ccline.on_leave(cmdline)
  if exists('s:visual_hl')
    call matchdelete(s:visual_hl)
    unlet s:visual_hl
  endif
  let s:line_highlight = [{'str': '', 'syntax': 'None'}]
  call ccline#complete#finish()
endfunction


function! ccline#getline()
  return s:ccline.getline()
endfunction
function! ccline#setline(line)
  return s:ccline.set(a:line)
endfunction
function! ccline#char()
  return s:ccline.char()
endfunction
function! ccline#setchar(char)
  call s:ccline.setchar(a:char)
endfunction
function! ccline#getpos()
  return s:ccline.getpos()
endfunction
function! ccline#setpos(pos)
  return s:ccline.setpos(a:pos)
endfunction
function! ccline#wait_keyinput_on(key)
  return s:ccline.tap_keyinput(a:key)
endfunction
function! ccline#wait_keyinput_off(key)
  return s:ccline.untap_keyinput(a:key)
endfunction
function! ccline#get_wait_keyinput()
  return s:ccline.get_tap_key()
endfunction
function! ccline#is_input(...)
  return call(s:ccline.is_input, a:000, s:ccline)
endfunction
function! ccline#insert(...)
  return call(s:ccline.insert, a:000, s:ccline)
endfunction
function! ccline#forward()
  return s:ccline.forward()
endfunction
function! ccline#backward()
  return s:ccline.backward()
endfunction

call ccline#substitute#load()

let &cpo = s:save_cpo
unlet s:save_cpo
