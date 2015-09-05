scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim

let s:module = {
\	"name" : "CCLineComplete",
\}

function! s:module.priority(event)
  if a:event == "on_char_pre"
    return 2
  endif
  return 0
endfunction


function! s:module.complete(cmdline)
  let self.on_complete = 1
  let self.drawer = a:cmdline.complete_drawer()
  call self.drawer.init()
  let s:complete = a:cmdline.complete_source()
  if s:complete.session_id < a:cmdline.session_id
    call s:complete.init()
    let s:complete.session_id = a:cmdline.session_id
  endif
  let backward = a:cmdline.backward()
  let [pos, keyword] = s:complete.parse(a:cmdline)
  let s:complete_list = s:complete.complete(a:cmdline, keyword, a:cmdline.getline(), strlen(backward))
  if empty(s:complete_list)
    return -1
  endif
  if pos == 0
    let backward = ""
  else
    let backward = join(split(backward, '\zs')[ : pos-1 ], "")
  endif
  let s:pos = pos
  let s:keyword = keyword
  let s:head = backward
  if len(split(a:cmdline.getline(), '\zs')) > s:pos + strchars(s:keyword)
    let s:tail = split(a:cmdline.getline(), '\zs')[s:pos + strchars(s:keyword)] . a:cmdline.forward()
  else
    let s:tail = a:cmdline.forward()
  endif
  call a:cmdline.setline(s:head . s:tail)
  call a:cmdline.setpos(s:pos + strchars(s:keyword))
  let s:count = 0
endfunction


function! s:module._finish()
  if self.on_complete
    call self.drawer.finish()
    let self.on_complete = 0
  endif
endfunction


function! s:module.on_char_pre(cmdline)
  if a:cmdline.is_input("<Over>(complete)") || a:cmdline.is_input("<Over>(complete)", "AutoCompletion")
    call self._finish()
    if self.complete(a:cmdline) == -1
      call a:cmdline.setchar('')
      return
    endif
    call a:cmdline.setchar('')
    call a:cmdline.tap_keyinput("Completion")
  elseif a:cmdline.is_input("<Over>(complete)", "Completion")
  \   || a:cmdline.is_input("\<Right>", "Completion")
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
    call self._finish()
    let self.autocomplete = 1
    if a:cmdline.untap_keyinput("Completion") || a:cmdline.untap_keyinput("AutoCompletion")
      call a:cmdline.callevent("on_char_pre")
    endif
    return
  endif
  let keyword = (s:count >= 0) ? s:complete.insert(s:complete_list[s:count]) : s:keyword
  call a:cmdline.setline(s:head . keyword . s:tail)
  call a:cmdline.setpos(s:pos + strchars(keyword))
  if len(s:complete_list) > 1
    call self.drawer.draw(a:cmdline, s:complete_list, s:count, s:complete)
  elseif len(s:complete_list) == 1
    call a:cmdline.untap_keyinput("Completion")
  endif
endfunction

function! s:module.on_char(cmdline) abort
  if !exists('g:ccline#autocomplete') || !g:ccline#autocomplete
    return
  endif
  if !self.autocomplete
    return
  endif
  let self.autocomplete = 0
  if self.complete(a:cmdline) == -1
    return
  endif
  let s:count = -1
  call a:cmdline.tap_keyinput("AutoCompletion")
  let keyword = (s:count >= 0) ? s:complete.insert(s:complete_list[s:count]) : s:keyword
  call a:cmdline.setline(s:head . keyword . s:tail)
  call a:cmdline.setpos(s:pos + strchars(keyword))
  if len(s:complete_list) >= 1
    call self.drawer.draw(a:cmdline, s:complete_list, s:count, s:complete)
  else
    call a:cmdline.untap_keyinput("AutoCompletion")
  endif
endfunction


function! s:module.on_draw_pre(...)
endfunction


function! s:module.on_leave(cmdline)
  call self._finish()
endfunction

function! s:module.on_execute_pre(cmdline) abort
  call self._finish()
endfunction

function! s:module.on_draw(cmdline) abort
  if self.on_complete
    call self.drawer.on_draw(a:cmdline)
  endif
endfunction

function! s:make()
  let module = deepcopy(s:module)
  let module.on_complete = 0
  let module.autocomplete = 0
  return module
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
