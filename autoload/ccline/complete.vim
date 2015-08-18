scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim

function! s:last(list, default) abort
  if empty(a:list)
    return a:default
  endif
  return a:list[len(a:list) - 1]
endfunction

function! s:parse(cmdline)
  let line = a:cmdline.backward()
  let expr = a:cmdline.commandline.current_expr(a:cmdline.getpos())
  if !empty(expr[2])
    let current_arg = s:last(expr[2], 1)
    if !empty(current_arg[1])
      return [strchars(line), '']
    endif
    let keyword = current_arg[0]
    let pos = strchars(line) - strchars(keyword) - strchars(current_arg[1])
    return [pos, keyword]
  endif
  if !empty(expr[1])
    let current_command = expr[1][len(expr[1]) - 1]
    if empty(current_command[2]) && empty(current_command[3])
      let keyword = current_command[1]
      let pos = strchars(line) - strchars(keyword) - strchars(current_command[2]) - strchars(current_command[3])
      return [pos, keyword]
    endif
  endif
  return [strchars(line), '']
endfunction

function! ccline#complete#parse_by(line, pattern)
  let keyword = matchstr(a:line, '\zs' . a:pattern . '\ze$')
  let pos = strchars(a:line) - strchars(keyword)
  return [pos, keyword]
endfunction

function! ccline#complete#source(cmdline)
  let current_command = a:cmdline.commandline.current_command(a:cmdline.getpos())
  if empty(current_command)
    return deepcopy(s:default_source)
  endif
  if current_command == ':'
    return extend(deepcopy(s:default_source), ccline#complete#source#command#define())
  endif
  let cmd = ccline#command#get(current_command)
  let complete =  cmd.complete
  if empty(complete)
    return deepcopy(s:default_source)
  endif
  let nargs = cmd.nargs
  if nargs ==# '0'
    return deepcopy(s:default_source)
  elseif nargs ==# '1' || nargs ==# '?'
    let args = a:cmdline.commandline.current_expr(a:cmdline.getpos())[2]
    if len(args) - empty(s:last(args, ['', ''])[1]) > 0
      return deepcopy(s:default_source)
    endif
  endif
  return extend(deepcopy(s:default_source), ccline#complete#source#{complete}#define())
endfunction

let s:default_source = {
\ 'session_id': 0
\ }
function! s:default_source.init() abort
endfunction
function! s:default_source.parse(cmdline) abort
  return s:parse(a:cmdline)
endfunction
function! s:default_source.complete(arg, line, pos, args) abort
  return []
endfunction
function! s:default_source.display(candidate) abort
  return a:candidate
endfunction
function! s:default_source.insert(candidate) abort
  return a:candidate
endfunction


function! ccline#complete#drawer(cmdline) abort
  let g:ccline#complete#drawer = get(g:, 'ccline#complete#drawer', 'statusline')
  return extend(deepcopy(s:default_drawer), ccline#complete#drawer#{g:ccline#complete#drawer}#make())
endfunction

let s:default_drawer = {}
function! s:default_drawer.init() abort
endfunction
function! s:default_drawer.finish() abort
endfunction
function! s:default_drawer.draw() abort
endfunction
function! s:default_drawer.on_draw(cmdline) abort
endfunction



function! ccline#complete#capture(cmd)
  let save_verbose = &verbose
  let &verbose = 0
  try
    redir => result
    execute "silent! " . a:cmd
    redir END
  finally
    let &verbose = save_verbose
  endtry
  return result
endfunction

function! ccline#complete#uniq(list)
  let dict = {}
  for _ in a:list
    let dict[_] = 0
  endfor
  return keys(dict)
endfunction

function! ccline#complete#last_option_pair(expr, key_pattern, delimiter_pattern, value_pattern)
  return matchlist(a:expr, '\(' . a:key_pattern . '\)\%(' . a:delimiter_pattern . '\)\%(\%(' . a:value_pattern . '\),\)*\(' . a:value_pattern . '\)$')
endfunction

function! ccline#complete#forward_matcher(list, string)
  if empty(a:string)
    return a:list
  endif
  if &ignorecase
    let result = []
    for e in a:list
      if stridx(tolower(e), tolower(a:string)) == 0
        call add(result, e)
      endif
    endfor
    return result
  else
    let result = []
    for e in a:list
      if stridx(e, a:string) == 0
        call add(result, e)
      endif
    endfor
    return result
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
