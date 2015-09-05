let s:save_cpo = &cpo
set cpo&vim


function! s:highlight(group_name, attr_dict)
  if empty(a:attr_dict)
    return
  endif
  execute 'highlight' a:group_name s:hldict2str(a:attr_dict)
endfunction

function! s:clear(group_name) abort
  execute 'highlight clear' a:group_name
endfunction

function! s:link(from_group_name, to_group_name) abort
  execute 'highlight link' a:from_group_name a:to_group_name
endfunction

function! s:copy(to_group_name, from_group_name)
  call s:highlight(a:to_group_name, s:gethldict(a:from_group_name))
endfunction

function! s:extend(dict1, dict2) abort
  for k in keys(a:dict2)
    if has_key(a:dict1, k) && k =~? 'gui\|term\|cterm'
      let a:dict1[k] .= ',' . a:dict2[k]
    else
      let a:dict1[k] = a:dict2[k]
    endif
  endfor
  return a:dict1
endfunction

function! s:_capture(cmd)
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

function! s:gethlstr(group)
  let hl = s:_capture('highlight ' . a:group)
  let link = matchlist(hl, '^\n\w\+\s\+xxx\slinks\sto\s\(\w\+\)')
  if !empty(link)
    return s:gethlstr(link[1])
  endif
  return hl
endfunction

function! s:gethldict(group)
  return s:hlstr2dict(s:gethlstr(a:group))
endfunction

function! s:hldict2str(dict)
  return join(values(map(copy(a:dict), 'v:key . "=" . v:val')))
endfunction

function! s:hlstr2dict(str)
  let result = {}
  for expr in split(a:str)
    let list = matchlist(expr, '\(\w\+\)=\(\d\+\|#\x\{6}\|\a\+\|[,[:alpha:]]\+\)')
    if empty(list)
      continue
    endif
    let result[list[1]] = list[2]
  endfor
  return result
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
