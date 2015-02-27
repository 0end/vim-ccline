let s:escape_char = '[[:space:]%#<]'

function! ccline#complete#dir#parse(line)
  let s:slash = exists('+shellslash') ? (&shellslash ? '/' : '\') : '/'
  let [args, spaces] = ccline#command#parse(a:line)
  if empty(spaces[len(spaces) - 1])
    let s:path = args[len(args) - 1]
  else
    let s:path = ''
    return [strchars(a:line), '']
  endif
  if strpart(s:path, strlen(s:path) - 1) ==# s:slash
    return [strchars(a:line), '']
  endif
  let parts = split(s:path, s:slash)
  let keyword = parts[len(parts) - 1]
  if s:slash ==# '\'
    let i = len(parts) - 2
    while keyword =~# '^' . s:escape_char . ''
      let keyword = parts[i] . '\' . keyword
      let i -= 1
    endwhile
  endif
  let pos = strchars(a:line) - strchars(keyword)
  return [pos, keyword]
endfunction

function! ccline#complete#dir#complete(A, L, P)
  let head = strpart(s:path, 0, strlen(s:path) - strlen(a:A))
  return map(s:complete(head, a:A), "s:as_candidate(v:val)")
endfunction

function! s:as_candidate(tail)
  let abbr = a:tail . s:slash
  return {'word': fnameescape(abbr), 'abbr': abbr}
endfunction

function! s:complete(head, tail)
  if empty(a:head)
    if a:tail ==# '~'
      return glob(a:tail, 0, 1)
    endif
    return filter(glob(s:remove_escape(a:tail) . '*', 0, 1), 'isdirectory(v:val)')
  endif
  return ccline#complete#forward_matcher(
  \ map(filter(glob(s:remove_escape(a:head) . '*', 0, 1), 'isdirectory(v:val)'), 'fnamemodify(v:val, ":t")'),
  \ s:remove_escape(a:tail))
endfunction

function! s:remove_escape(expr)
  return substitute(a:expr, '\\\ze' . s:escape_char, '', 'g')
endfunction
