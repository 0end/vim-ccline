scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim

let s:cmdline = vital#of("ccline").import("Over.Commandline")

let s:ccline = s:cmdline.make_default(":")
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

call s:ccline.cnoremap("\<Tab>", "<Over>(complete)")

let s:ccline.line_highlight = [{'str': '', 'syntax': 'None'}]

function! ccline#start(input)
  call s:ccline.start(a:input)
endfunction

function! s:ccline.on_draw_pre(cmdline)
  if a:cmdline.is_input("\<Right>") || a:cmdline.is_input("\<Left>")
    return
  endif
  let a:cmdline.line_highlight = ccline#strsyntax(a:cmdline.getline(), 'vim')
endfunction

function! s:ccline.get_complete_words(args)
  return ccline#complete#complete(a:args)
endfunction

function! s:ccline.on_leave(cmdline)
  call ccline#complete#finish()
endfunction

let s:tempbufnr = 0

function! s:open_tempbuffer(...)
  let bufnr = get(a:000, 0, 0)
  let save_bufnr = bufnr("%")
  let save_pos = getpos(".")
  let save_view = winsaveview()
  let save_empty = 0
  let save_hidden = &l:bufhidden
  setlocal bufhidden=hide
  if bufnr == 0 || bufloaded(bufnr)
    noautocmd silent keepjumps enew
    let bufnr = bufnr("%")
    if bufnr == save_bufnr
      let save_empty = 1
    endif
  else
    try
      execute 'noautocmd silent keepjumps buffer! ' . bufnr
    catch
      noautocmd silent keepjumps enew
      let bufnr = bufnr("%")
    endtry
  endif
  setlocal nobuflisted noswapfile buftype=nofile bufhidden=unload
  return [bufnr, [save_bufnr, save_pos, save_view, save_empty, save_hidden]]
endfunction

function! s:close_tempbuffer(save)
  let [save_bufnr, save_pos, save_view, save_empty, save_hidden] = a:save
  if save_empty
    noautocmd silent keepjumps enew
    let &l:bufhidden = save_hidden
    return
  endif
  execute 'noautocmd silent keepjumps buffer! ' . save_bufnr
  let &l:bufhidden = save_hidden
  call setpos(".", save_pos)
  call winrestview(save_view)
endfunction

function! ccline#strsyntax(str, ft)
  let [s:tempbufnr, save] = s:open_tempbuffer(s:tempbufnr)
  execute 'noautocmd setlocal ft=' . a:ft
  let &l:syntax = a:ft
  let [save_reg, save_reg_type] = [getreg('"'), getregtype('"')]
  let @" = a:str
  normal! ""gP
  call setreg('"', save_reg, save_reg_type)
  let syntax_list = []
  let temp_str = ''
  let synID = 0
  let old_synID = 0
  let lines = split(a:str, '\n', 1)
  for linenr in range(1, len(lines))
    let chars = split(lines[linenr - 1], '\zs')
    for col in range(1, len(chars))
      let synID = synIDtrans(synID(linenr, col, 1))
      if old_synID != synID && temp_str != ''
        let synname = (old_synID == 0) ? 'None' : synIDattr(old_synID, 'name')
        let syntax_list += [{'str' : temp_str, 'syntax' : synname}]
        let temp_str = chars[col - 1]
      else
        let temp_str .= chars[col - 1]
      endif
      let old_synID = synID
    endfor
    if linenr != len(lines)
      let temp_str .= "\n"
    endif
  endfor
  let synname = (synID == 0) ? 'None' : synIDattr(synID, 'name')
  let syntax_list += [{'str' : temp_str, 'syntax' : synname}]
  call s:close_tempbuffer(save)
  return syntax_list
endfunction

function! ccline#as_echohl(hl_list)
  let expr = ''
  for i in a:hl_list
    let expr .= "echohl " . i.syntax . " | echon " . string(i.str) . " | "
  endfor
  let expr .= "echohl None"
  return expr
endfunction

function! s:get_cursor_char()
  let [save_reg, save_reg_type] = [getreg('"'), getregtype('"')]
  try
    if col('.') ==# col('$') || virtcol('.') > virtcol('$')
      return ''
    endif
    normal! ""yl
    return @"
  catch
    return ''
  finally
    call setreg('"', save_reg, save_reg_type)
  endtry
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
