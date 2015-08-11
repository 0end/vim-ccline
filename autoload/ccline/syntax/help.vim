function! ccline#syntax#help#syntax(command, args)
  let result = ccline#syntax#command(a:command)
  if !empty(a:args)
    let result += s:parse_arg(a:args[0])
  endif
  for arg in a:args[1 :]
    let result += [{'value': ccline#list2str(arg), 'group': 'None'}]
  endfor
  return result
endfunction

function! s:parse_arg(arg)
  let [arg, space] = a:arg
  let lang = matchstr(arg, '@\a\{2}$')
  let subject = strpart(arg, 0, strlen(arg) - strlen(lang))
  return s:parse_subject(subject) + s:parse_lang(lang) + [{'value': space, 'group': 'None'}]
endfunction

function! s:parse_lang(lang) abort
  if empty(a:lang)
    return []
  endif
  return [{'value': strpart(a:lang, 0, 1), 'group': 'None'}, {'value': strpart(a:lang, 1, 2), 'group': 'Constant'}]
endfunction

function! s:parse_subject(subject)
  let command = '^:\%(\h\w*\|@\)$'
  let option = '^''\l\+''\?$'
  let function = '^\h[[:alnum:]_#]*()\?$'

  let one_keys = '\S\{1,2}'
  let special_key = '<[[:alnum:]-]\+>'
  let combination_key = '\cctrl-\S'
  let continue = join(['_' . one_keys, '_\?' . special_key, '_' . combination_key], '\|')
  let pre = join([one_keys, special_key, combination_key], '\|')
  let key = '^\%(' . pre . '\)\%(' . continue . '\)*$'

  if a:subject =~# command
    return [{'value': ':', 'group': 'None'}, {'value': strpart(a:subject, 1), 'group': 'Statement'}]
  elseif a:subject =~# option
    return [{'value': a:subject, 'group': 'Type'}]
  elseif a:subject =~# function
    let name = matchstr(a:subject, '^\h[[:alnum:]_#]*')
    return [{'value': name, 'group': 'Function'}, {'value': strpart(a:subject, strlen(name)), 'group': 'Special'}]
  elseif a:subject =~# key
    return [{'value': a:subject, 'group': 'Special'}]
  else
    return [{'value': a:subject, 'group': 'None'}]
  endif
endfunction
