function! ccline#syntax#file#syntax(command, args)
  let result = ccline#syntax#command(a:command)
  for arg in a:args
    let result += s:parse_arg(arg)
  endfor
  return result
endfunction

let s:escape_char = '[[:space:]%#<]'
let s:slash = exists('+shellslash') ? (&shellslash ? '/' : '\') : '/'

function! s:parse_arg(arg) abort
  let [path, space] = a:arg
  let p = path
  while !empty(p) && !s:is_exists(p)
    let p = s:head(p)
  endwhile
  return [{'value': p, 'group': s:isdirectory(p) ? 'Directory': 'Title'},
  \ {'value': strpart(path, strlen(p)) . space, 'group': 'None'}
  \ ]
endfunction

function! s:head(path) abort
  let result = fnamemodify(a:path, ':h')
  if result ==# a:path || result ==# '.' && stridx(a:path, '.') != 0
    return ''
  endif
  return result
endfunction

function! s:is_exists(path) abort
  let result = glob(s:remove_escape(a:path), 0, 1)
  if empty(result)
    return 0
  endif
  if (strpart(result[0], strlen(result[0]) - 1) ==# s:slash) && !isdirectory(result[0])
    return 0
  endif
  return 1
endfunction

function! s:isdirectory(path) abort
  let result = glob(s:remove_escape(a:path), 0, 1)
  return len(result) == 1 && isdirectory(result[0])
endfunction

function! s:remove_escape(expr)
  return substitute(a:expr, '\\\ze' . s:escape_char, '', 'g')
endfunction
