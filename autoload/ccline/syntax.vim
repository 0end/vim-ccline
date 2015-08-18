scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim

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
    silent keepjumps enew
    let &l:bufhidden = save_hidden
    return
  endif
  execute 'noautocmd silent keepjumps buffer! ' . save_bufnr
  let &l:bufhidden = save_hidden
  call setpos(".", save_pos)
  call winrestview(save_view)
endfunction

function! ccline#syntax#strsyntax(str, ft, ...)
  if empty(a:str)
    return []
  endif
  let start_pos = get(a:000, 0, [1, 1])
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
  for linenr in range(start_pos[0], len(lines))
    let chars = split(lines[linenr - 1], '\zs')
    for col in range(start_pos[1], len(chars))
      let synID = synIDtrans(synID(linenr, col, 1))
      if old_synID != synID && temp_str != ''
        let synname = (old_synID == 0) ? 'None' : synIDattr(old_synID, 'name')
        let syntax_list += [{'value' : temp_str, 'group' : synname}]
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
  let syntax_list += [{'value' : temp_str, 'group' : synname}]
  call s:close_tempbuffer(save)
  return syntax_list
endfunction

function! ccline#syntax#as_echohl(hl_list)
  let expr = ''
  for i in a:hl_list
    let expr .= "echohl " . i.group . " | echon " . string(i.value) . " | "
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


function! ccline#syntax#expr(command, args) abort
  let result = []
  let result += ccline#syntax#command(a:command)
  let result += ccline#syntax#args(a:command, a:args)
  return result
endfunction

function! ccline#syntax#command(command) abort
  let result = []
  let [range, cmd, bang, space] = a:command
  let iscommand = ccline#command#iscommand(ccline#command#expand_alias(cmd))
  let c = ccline#command#get(cmd)
  if !iscommand || !empty(c.range)
    let result += ccline#syntax#range(range)
  else
    let result += [{'value': range, 'group': 'Error'}]
  endif
  if iscommand
    let result += [{'value': cmd, 'group': 'Statement'}]
  else
    let result += [{'value': cmd, 'group': 'Normal'}]
  endif
  if c.bang
    let result += [{'value': bang, 'group': 'Normal'}]
  else
    let result += [{'value': bang, 'group': 'Error'}]
  endif
  let result += [{'value': space, 'group': 'None'}]
  return result
endfunction

function! ccline#syntax#args(command, args) abort
  if empty(a:args)
    return []
  endif
  let space = empty(a:command[3]) ? '' : ' '
  let line = a:command[1] . space . ccline#list2str(a:args)
  return ccline#syntax#strsyntax(line, 'vim', [1, strchars(a:command[1] . space) + 1])
endfunction

function! ccline#syntax#range(range) abort
  if a:range == '%'
    return [{'value': a:range, 'group': 'None'}]
  endif

  let search_pattern = '\v/[^/]*\\@<!%(\\\\)*/|\?[^?]*\\@<!%(\\\\)*\?'
  let line_specifier = '\v%(\d+|[.$]|''\S|\\[/?&])?%([+-]\d*|' . search_pattern . ')*'
  let range_pattern = '\v[;,]?' . line_specifier

  let result = []
  for p in s:matchstr_list(a:range, range_pattern)
    let d = matchstr(p, '^,')
    if !empty(d)
      let result += [{'value': d, 'group': 'Normal'}]
      let p = strpart(p, 1)
    endif
    let d = matchstr(p, '^;')
    if !empty(d)
      let result += [{'value': d, 'group': 'Delimiter'}]
      let p = strpart(p, 1)
    endif
    let result += [{'value': p, 'group': 'Number'}]
  endfor
  return result
endfunction

function! s:matchstr_list(expr, pattern) abort
  let result = []
  let end = 0
  while 1
    let begin = match(a:expr, a:pattern, end)
    let end = matchend(a:expr, a:pattern, begin)
    if begin == end
      break
    endif
    let result += [strpart(a:expr, begin, end - begin)]
  endwhile
  return result
endfunction

function! ccline#syntax#clean_cache() abort
  let s:cache = []
endfunction

let s:cache = []

function! ccline#syntax#syntax(cmdline) abort
  let m = a:cmdline.commandline.get_last_modified_expr()
  if m < 0
    return s:flatten(s:cache)
  endif
  if m <= len(s:cache) - 1
    call remove(s:cache, m, len(s:cache) - 1)
  endif
  let result = s:flatten(s:cache)
  for expr in a:cmdline.commandline.core[m :]
    let hl = [{'value': expr[0], 'group': 'None'}]

    if empty(expr[1])
      let hl += [{'value': ccline#list2str(expr[2]), 'group': 'None'}]
      let result += hl
      let s:cache += [hl]
      continue
    endif

    let cmd = ccline#command#get(expr[1][0][1])
    let syntax = cmd.syntax
    if empty(syntax)
      let hl += ccline#syntax#expr(expr[1][0], expr[1][1 :] + expr[2])
    else
      try
        let hl += ccline#syntax#{syntax}#syntax(expr[1][0], expr[1][1 :] + expr[2])
      catch /^Vim\%((\a\+)\)\?:E117/
        let hl += ccline#syntax#expr(expr[1][0], expr[1][1 :] + expr[2])
      endtry
    endif
    let result += hl
    let s:cache += [hl]
  endfor
  return result
endfunction

function! s:flatten(list) abort
  let result = []
  for l in a:list
    let result += l
  endfor
  return result
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
