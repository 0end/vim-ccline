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
call s:ccline.connect("Complete")
call s:ccline.connect(s:cmdline.make_module("Doautocmd", "CCLine"))

let s:execute = {
\ "name" : "CCLineExecute",
\}
function! s:execute.priority(event)
  if a:event == "on_char_pre"
    return 2
  endif
  return 0
endfunction
function! s:execute.is_input_enter(cmdline)
  return a:cmdline.is_input("\<CR>")
  \   || a:cmdline.is_input("\<NL>")
  \   || a:cmdline.is_input("\<C-j>")
endfunction
function! s:execute.on_char_pre(cmdline)
  if exists("g:ccline_flag")
    return
  endif
  if self.is_input_enter(a:cmdline)
    call self.execute(a:cmdline)
    call a:cmdline.setchar("")
    call a:cmdline.exit(0)
  elseif a:cmdline.is_input("<Over>(execute-no-exit)")
    call self.execute(a:cmdline)
    call a:cmdline.setchar("")
  endif
endfunction
function! s:execute.execute(cmdline)
  if empty(a:cmdline.getline())
    return a:cmdline.execute(a:cmdline.default_command())
  endif
  return a:cmdline.execute()
endfunction
call s:ccline.connect(s:execute)

let s:ccline.suffix_highlight = "CCLineCommandLineSuffix"
execute "highlight link " . s:ccline.suffix_highlight . " Comment"

call s:ccline.cnoremap("\<Tab>", "<Over>(complete)")

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

function! s:ccline.on_draw_pre(cmdline)
  if empty(s:ccline.getline())
    call s:ccline.set_suffix(s:ccline.default_command())
  else
    call s:ccline.set_suffix('')
  endif

  if !s:ccline.is_input("\<Right>") && !s:ccline.is_input("\<Left>")
    call s:ccline.set_syntax(ccline#syntax#strsyntax(s:ccline.getline(), 'vim'))
  endif
endfunction

function! s:ccline.set_syntax(syntax)
  let s:ccline.line_syntax = a:syntax
endfunction
function! s:ccline.get_syntax()
  return s:ccline.line_syntax
endfunction

function! s:ccline.parse_line(line)
  return ccline#complete#parse(a:line)
endfunction
function! s:ccline.complete_words(args)
  return ccline#complete#complete(a:args)
endfunction

function! s:ccline.default_command()
  return histget("cmd")
endfunction

let s:session_id = 0
function! ccline#session_id()
  return s:session_id
endfunction

function! s:ccline.on_enter(cmdline)
  let s:ccline.line_syntax = [{'str': '', 'syntax': 'None'}]
  let s:session_id += 1
endfunction

function! s:ccline.on_leave(cmdline)
  if exists('s:visual_hl')
    call matchdelete(s:visual_hl)
    unlet s:visual_hl
  endif
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
