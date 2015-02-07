scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim

function! ccline#complete#init()
  call ccline#complete#function#init()
  call ccline#complete#buffer_word#init()
endfunction

function! ccline#complete#complete(args)
  let [A, L, P] = a:args
  let backward = strpart(L, 0, P)
  let c = s:get_complete(backward)
  if has_key(s:complete, c)
    return call(s:complete[c], a:args)
  else
    if empty(c)
      return []
    endif
    return call(c, a:args)
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

function! ccline#complete#option(dict, key, delimiter, value, A, L, P)
  let backward = strpart(a:L, 0, a:P)
  let option = matchlist(backward, '\s\(' . a:key . '\)\s*\%(' . a:delimiter . '\)\(' . a:value . '\)$')
  if !empty(option) && has_key(a:dict, option[1])
    return sort(filter(deepcopy(a:dict[option[1]]), 'v:val =~ ''^'' . option[2]'))
  else
    return sort(filter(keys(a:dict), 'v:val =~ ''^'' . a:A'))
  endif
endfunction

function! ccline#complete#forward_matcher(list, string)
  return filter(a:list, "v:val =~ '^" . a:string . "'")
endfunction

let s:complete = {
\ 'command': function('ccline#complete#command#complete'),
\ 'function': function('ccline#complete#function#complete'),
\ 'augroup': function('ccline#complete#augroup#complete'),
\ 'buffer': function('ccline#complete#buffer#complete'),
\ 'option': function('ccline#complete#option#complete'),
\ 'buffer_word': function('ccline#complete#buffer_word#complete'),
\ }

let &cpo = s:save_cpo
unlet s:save_cpo
