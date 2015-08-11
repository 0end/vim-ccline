scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim

function! ccline#vital() abort
  if !exists('s:V')
    " let s:V = vital#of('vital')
    let s:V = vital#of('ccline')
  endif
  return s:V
endfunction

let s:C = ccline#vital().import('Over.Commandline')

let s:ccline = s:C.make_default()

call s:ccline.connect('Paste')
call s:ccline.connect('CursorMove')
call s:ccline.connect('InsertRegister')
call s:ccline.connect(s:C.make_module('NoInsert', ''))
call s:ccline.connect('Redraw')
call s:ccline.connect('CCLineDrawCommandline')
call s:ccline.connect('ExceptionExit')
call s:ccline.connect('ExceptionMessage')
call s:ccline.connect('CCLineComplete')
call s:ccline.connect(s:C.make_module('Doautocmd', 'CCLine'))

let s:execute = {
\ 'name': 'CCLineExecute',
\ }
function! s:execute.priority(event)
  if a:event == 'on_char_pre'
    return 1
  endif
  return 0
endfunction
function! s:execute.is_input_enter(cmdline)
  return a:cmdline.is_input("\<CR>")
  \   || a:cmdline.is_input("\<NL>")
  \   || a:cmdline.is_input("\<C-j>")
endfunction
function! s:execute.on_char_pre(cmdline)
  if self.is_input_enter(a:cmdline)
    call self.execute(a:cmdline)
    call a:cmdline.setchar('')
    call a:cmdline.exit(0)
  elseif a:cmdline.is_input("<Over>(execute-no-exit)")
    call self.execute(a:cmdline)
    call a:cmdline.setchar('')
  endif
endfunction
function! s:execute.execute(cmdline)
  if empty(a:cmdline.getline())
    return a:cmdline.execute(a:cmdline.default_command())
  endif
  return a:cmdline.execute()
endfunction
call s:ccline.connect(s:execute)

call s:ccline.connect('CCLineHistory')
call s:ccline.connect('CCLineDelete')

let s:histadd = s:C.make_module('HistAdd', ':')
function! s:histadd.on_enter(cmdline)
  let self._exception = ''
endfunction
function! s:histadd.on_execute_failed(cmdline)
  let self._exception = v:exception
endfunction
function! s:histadd.on_leave(cmdline)
  if self._exception =~# '^Vim\%((\a\+)\)\?:E492'
    " Not an editor command
    return
  endif
  if a:cmdline._cancel
    return
  endif
  call histadd(self.mode, a:cmdline.getline())
endfunction
call s:ccline.connect(s:histadd)

let s:cancel = s:C.make_module('Cancel')
function! s:cancel.on_enter(cmdline) abort
  let a:cmdline._cancel = 0
endfunction
function! s:cancel.on_char_pre(cmdline) abort
  if a:cmdline.is_input("\<Esc>")
    call a:cmdline.exit(1)
    call a:cmdline.setchar('')
  elseif a:cmdline.is_input("\<C-c>")
    let a:cmdline._cancel = 1
    call a:cmdline.exit(1)
    call a:cmdline.setchar('')
  endif
endfunction
call s:ccline.connect(s:cancel)

let s:ccline._suffix_highlight = 'CCLineCommandLineSuffix'
execute 'highlight link' s:ccline._suffix_highlight 'Comment'

call s:ccline.cnoremap("\<Tab>", "<Over>(complete)")

function! s:ccline.on_draw_pre(cmdline)
  " call self.set_suffix(string(self.commandline.core))
  call self._set_syntax(ccline#syntax#syntax(self))
endfunction

function! s:ccline.on_char_pre(cmdline) abort
  let self.commandline.last_modified_expr = -1
endfunction

let s:ccline_modules = {}
function! s:ccline.on_char(cmdline) abort
  let cmd = ccline#command#expand_alias(self.commandline.current_command(self.getpos()))
  if has_key(s:ccline_modules, cmd) || !ccline#command#iscommand(cmd)
    return
  endif
  try
    let c = ccline#module#{cmd}#make()
  catch /^Vim\%((\a\+)\)\?:E117/
    return
  endtry
  let c.is_ccline_module = 1
  call self.connect(c)
  let s:ccline_modules[cmd] = c
  call c.init(self)
endfunction


let s:flatten = ccline#vital().import('Data.List').flatten
function! ccline#list2str(list) abort
  return join(s:flatten(a:list), '')
endfunction

let s:_orig_setline = s:ccline.setline
function! s:ccline.setline(...)
  if type(a:000[0]) == type('')
    call self.commandline.remove_backward(0)
    call self.commandline.add(a:000[0])
  endif
  return call(s:_orig_setline, a:000, s:ccline)
endfunction

let s:_orig_insert = s:ccline.insert
function! s:ccline.insert(...) abort
  let pos = get(a:000, 1, self.getpos())
  call self.commandline.insert(a:000[0], pos)
  return call(s:_orig_insert, a:000, s:ccline)
endfunction


function! s:ccline.remove_prev() abort
  call self.commandline.delete(self.getpos() - 1, 1)
  return self.line.remove_prev()
endfunction
function! s:ccline.remove_pos() abort
  call self.commandline.delete(self.getpos(), 1)
  return self.line.remove_pos()
endfunction
function! s:ccline.pos_char() abort
  return self.line.pos_char()
endfunction

function! s:ccline._set_syntax(syntax) abort
  let self._line_syntax = a:syntax
endfunction
function! s:ccline._get_syntax() abort
  return self._line_syntax
endfunction

function! s:ccline._set_prompt_syntax(syntax) abort
  let self._prompt_syntax = a:syntax
endfunction
function! s:ccline._get_prompt_syntax() abort
  return self._prompt_syntax
endfunction

function! s:ccline.complete()
  return ccline#complete#complete(self)
endfunction

function! s:ccline.default_command()
  return histget('cmd')
endfunction

let s:ccline.session_id = 0

function! s:ccline.on_enter(cmdline)
  let self.commandline = ccline#commandline#make()
  call self._set_syntax([])
  call ccline#syntax#clean_cache()
  call ccline#command#refresh()
  let self.session_id += 1
endfunction

function! s:ccline.on_leave(cmdline)
  call self.variables.modules.disconnect_by('has_key(v:val, "is_ccline_module")')
  for c in values(s:ccline_modules)
    call c.on_leave(self)
  endfor
  let s:ccline_modules = {}
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

let g:ccline#prompt = get(g:, 'ccline#prompt',
\ [{'value': ':', 'group': 'CursorLine'}, {'value': '>', 'group': 'Comment'}, {'value': ' ', 'group': 'None'}])

function! ccline#start(input) abort
  if a:input ==# "'<,'>"
    let s:visual_hl = matchadd('Visual', '\%V', -1)
  endif
  call s:ccline._set_prompt_syntax(g:ccline#prompt)
  call s:ccline.set_prompt(join(map(deepcopy(g:ccline#prompt), 'v:val.value'), ''))
  let exit_code = s:ccline.start(a:input)
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
