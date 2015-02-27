scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim

function! s:parse_line(line)
  return ccline#complete#parse_by(a:line, '\w\+')
endfunction

function! ccline#complete#parse_by(line, pattern)
  let keyword = matchstr(a:line, '\zs' . a:pattern . '\ze$')
  let pos = strchars(a:line) - strchars(keyword)
  return [pos, keyword]
endfunction

function! ccline#complete#parse_arg(line)
  let [args, spaces] = ccline#command#parse(a:line)
  if empty(spaces[len(spaces) - 1])
    let keyword = args[len(args) - 1]
  else
    let keyword = ''
  endif
  let pos = strchars(a:line) - strchars(keyword)
  return [pos, keyword]
endfunction

function! ccline#complete#parse(line)
  let c = s:get_complete(a:line)
  if empty(c)
    return s:parse_line(a:line)
  endif
  if type(c) == type({})
    return call(c.parser, [a:line])
  endif
  if !has_key(s:complete, c)
    return s:parse_line(a:line)
  endif
  let Complete = s:complete[c]
  if type(Complete) == type({})
    return call(Complete.parser, [a:line])
  else
    return s:parse_line(a:line)
  endif
endfunction

function! ccline#complete#complete(args)
  let [A, L, P] = a:args
  let backward = strpart(L, 0, P)
  let c = s:get_complete(backward)
  if empty(c)
    return []
  endif
  if type(c) == type({})
    return call(c.completer, a:args)
  endif
  if !has_key(s:complete, c)
    return call(c, a:args)
  endif
  let Complete = s:complete[c]
  if type(Complete) == type({})
    return call(Complete.completer, a:args)
  else
    return call(Complete, a:args)
  endif
endfunction

function! s:get_complete(backward)
  let c = ccline#command#current(a:backward)
  if c == ':'
    return 'command'
  endif
  if empty(c)
    return ''
  endif
  return get(ccline#command#command()[c], 'complete', '')
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

function! ccline#complete#option(dict, key, delimiter, value, A, L, P)
  let backward = strpart(a:L, 0, a:P)
  let option = matchlist(backward, '\s\(' . a:key . '\)\s*\%(' . a:delimiter . '\)\(' . a:value . '\)$')
  if !empty(option) && has_key(a:dict, option[1])
    return sort(ccline#complete#forward_matcher(a:dict[option[1]], option[2]))
  else
    return sort(ccline#complete#forward_matcher(keys(a:dict), a:A))
  endif
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

let s:complete = {
\ 'command': function('ccline#complete#command#complete'),
\ 'function': function('ccline#complete#function#complete'),
\ 'augroup': function('ccline#complete#augroup#complete'),
\ 'buffer': function('ccline#complete#buffer#complete'),
\ 'option': function('ccline#complete#option#complete'),
\ 'behave': function('ccline#complete#behave#complete'),
\ 'cscope': function('ccline#complete#cscope#complete'),
\ 'history': function('ccline#complete#history#complete'),
\ 'sign': function('ccline#complete#sign#complete'),
\ 'syntime': function('ccline#complete#syntime#complete'),
\ 'help': {'completer': function('ccline#complete#help#complete'), 'parser': function('ccline#complete#help#parse')},
\ 'color': function('ccline#complete#color#complete'),
\ 'environment': function('ccline#complete#environment#complete'),
\ 'event': function('ccline#complete#event#complete'),
\ 'filetype': function('ccline#complete#filetype#complete'),
\ 'highlight': function('ccline#complete#highlight#complete'),
\ 'shellcmd': function('ccline#complete#shellcmd#complete'),
\ 'compiler': function('ccline#complete#compiler#complete'),
\ 'syntax': function('ccline#complete#syntax#complete'),
\ 'mapping': {'completer': function('ccline#complete#mapping#complete'), 'parser': function('ccline#complete#mapping#parse')},
\ 'buffer_word': function('ccline#complete#buffer_word#complete'),
\ 'file': {'completer': function('ccline#complete#file#complete'), 'parser': function('ccline#complete#file#parse')},
\ 'dir': {'completer': function('ccline#complete#dir#complete'), 'parser': function('ccline#complete#dir#parse')},
\ }

let &cpo = s:save_cpo
unlet s:save_cpo
