" function! ccline#command#help#syntax(command, args, spaces)
"   let result = [{'str': a:command, 'syntax': 'Statement'}]
"   let space = map(a:spaces, '{"str": v:val, "syntax": "None"}')
"   if len(a:args) >= 1
"     let result += s:parse(a:args[0])
"     let result += [space[0]]
"   endif
"   if len(a:args) > 1
"     let result += s:combine(map(args[1 :], '{"str": v:val, "syntax": "None"}'), [{'str': '', 'syntax': 'None'}] + space[1 :])
"   endif
"   return result
" endfunction

function! ccline#command#help#syntax(command)
  " return ccline#syntax#strsyntax(a:command 'help')
  let [part, space] = s:separate(a:command)
  if empty(part)
    return [{'str': a:command, 'syntax': 'None'}]
  endif
  call map(space, '{"str": v:val, "syntax": "None"}')
  let result = [space[0], {'str': part[0], 'syntax': 'Statement'}, space[1]]
  if len(part) >= 2
    let result += s:parse(part[1]) + [space[2]]
  endif
  if len(part) > 2
    let result += s:combine(map(part[2 :], '{"str": v:val, "syntax": "None"}'), space[3 :])
  endif
  return result
endfunction

function! s:parse(arg)
  let k = '\%(\a_\|\a\)\?<[[:alnum:]-]\{-}>' " i_<Home>, g<Home>
  let e = 'ctrl-.\%(_ctrl-.\|_\a\)*' " CTRL-W_CTRL-W
  let y = '\a\%(_ctrl-.\|_\a\)\+' " o_CTRL-V
  let key = '\%(' . k . '\|' . e . '\|' . y . '\)'
  let command = ':\a\+'
  let option = '''[[:alnum:]-]\+'''
  let function = '\w\+()'
  let pattern = [key, command, option, function]
  let syntax = ["Special", "Statement", "Type", "Function"]
  let subject = {'str': '', 'syntax': 'None'}
  for i in range(len(pattern))
    let match = matchstr(a:arg, '^\zs' . pattern[i] . '\ze\%(@\|$\)')
    if !empty(match)
      let subject = {'str': match, 'syntax': syntax[i]}
      break
    endif
  endfor
  let lang_pattern = '@\a\{2}'
  let match = matchstr(a:arg, '^.\{-}\zs' . lang_pattern . '\ze$')
  if empty(match)
    let lang = {'str': '', 'syntax': 'None'}
  else
    let lang = {'str': match, 'syntax': "Character"}
  endif
  let m = strpart(a:arg, strlen(subject.str))
  let m = strpart(m, 0, strlen(m) - strlen(lang.str))
  if empty(m)
    return [subject, lang]
  else
    return [subject, {'str': m, 'syntax': 'None'}, lang]
  endif
endfunction


function! s:separate(str)
  let chars = split(a:str, '\zs')
  let part = []
  let space = []
  let space_flag = 1
  let temp_part = ''
  let temp_space = ''
  for c in chars
    if c =~# '\s'
      if space_flag
        let temp_space .= c
      else
        let space_flag = 1
        let temp_space .= c
        call add(part, temp_part)
        let temp_part = ''
      endif
    else
      if space_flag
        let space_flag = 0
        let temp_part .= c
        call add(space, temp_space)
        let temp_space = ''
      else
        let temp_part .= c
      endif
    endif
  endfor
  if space_flag
    call add(space, temp_space)
  else
    call add(part, temp_part)
    call add(space, '')
  endif
  return [part, space]
endfunction

function! s:combine(part, space)
  let result = []
  for i in range(len(a:part))
    let result += [a:space[i], a:part[i]]
  endfor
  " return result + [a:space[i + 1]]
  return result + [a:space[len(a:space) - 1]]
endfunction
