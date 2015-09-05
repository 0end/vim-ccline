scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim


let s:module = {
\ 'name' : 'CCLineAutoSuggest',
\ 'mode' : 'cmd',
\ }

function! s:module.histories()
  if histnr(self.mode) < 1
    return []
  endif
  return map(range(1, histnr(self.mode)), 'histget(self.mode, -1 * v:val)')
endfunction

function! s:module.match_lines(line) abort
  return filter(self.histories(),
  \ !empty(a:line) ? 'stridx(v:val, a:line) == 0' : '!empty(v:val)')
endfunction

function! s:module.on_draw(cmdline)
  let l = self.match_lines(a:cmdline.getline())
  if len(l) > 0
    let d = strpart(l[0], strlen(a:cmdline.getline()))
    if empty(d)
      return
    endif
    if empty(a:cmdline.line.pos_char())
      let a:cmdline._syntax.cursor = [{'group': a:cmdline.highlights.cursor_on, 'value': d[0]}]
      let a:cmdline._syntax.forward += [{'group': 'Comment', 'value': d[1 :]}]
    else
      let a:cmdline._syntax.forward += [{'group': 'Comment', 'value': d}]
    endif
  endif
endfunction

function! s:module.on_char_pre(cmdline) abort
  if a:cmdline.is_input("\<Right>") && empty(a:cmdline.line.pos_char())
    let l = self.match_lines(a:cmdline.getline())
    if len(l) > 0
      call a:cmdline.setchar('')
      call a:cmdline.setline(l[0])
    endif
  endif
endfunction

function! s:make(...)
  let module = deepcopy(s:module)
  let module.mode = get(a:, 1, "cmd")
  return module
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
