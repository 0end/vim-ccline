let s:source = {}

function! ccline#complete#source#file#define() abort
  return deepcopy(s:source)
endfunction

let s:escape_char = '[[:space:]%#<]'
let s:slash = exists('+shellslash') ? (&shellslash ? '/' : '\') : '/'

function! s:source.parse(cmdline) abort
  let self.path = ''
  let backward = a:cmdline.backward()
  let args = a:cmdline.commandline.current_expr(strlen(backward))[2]
  if empty(args)
    return [strchars(backward), '']
  endif
  let arg = args[len(args) - 1]
  if !empty(arg[1])
    return [strchars(backward), '']
  endif
  let self.path = arg[0]
  let slash = '[/\\]'
  if strpart(self.path, strlen(self.path) - 1) =~# slash
    if s:is_exists(self.path)
      return [strchars(backward), '']
    else
      return [strchars(backward) - strchars(self.path), self.path]
    endif
  endif
  let parts = split(self.path, slash)
  let keyword = parts[len(parts) - 1]
  let pos = strchars(backward) - strchars(keyword)
  if !s:is_exists(strpart(self.path, 0, strlen(self.path) - strlen(keyword)))
    return [strchars(backward) - strchars(self.path), self.path]
  endif
  return [pos, keyword]
endfunction

function! s:source.complete(cmdline, arg, line, pos) abort
  let head = strpart(self.path, 0, strlen(self.path) - strlen(a:arg))
  return map(s:complete(head, a:arg), "s:add_dir_slash('" . s:remove_escape(head) . "', v:val)")
endfunction

function! s:source.insert(candidate) abort
  return fnameescape(a:candidate)
endfunction

function! s:complete(head, tail)
  if empty(a:head)
    if a:tail ==# '~'
      return glob(a:tail, 0, 1)
    endif
    return glob(s:partial_completion_pattern(s:remove_escape(a:tail)) . '*', 0, 1)
  endif
  return ccline#complete#forward_matcher(
  \ map(glob(s:partial_completion_pattern(s:remove_escape(a:head)) . '*', 0, 1), 'fnamemodify(v:val, ":t")'),
  \ s:remove_escape(a:tail))
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

function! s:partial_completion_pattern(expr) abort
  if s:is_exists(a:expr)
    return a:expr
  endif
  let l = split(a:expr, '/\|\\', 1)
  if len(l) <= 1
    return a:expr
  endif
  for i in range(len(l))
    if l[i] ==# '..' || i == 0 && empty(l[i])
      continue
    endif
    let l[i] .= '*'
  endfor
  return join(l, '/')
endfunction

function! s:add_dir_slash(head, tail)
  if !isdirectory(fnamemodify(a:head . a:tail, ':p'))
    return a:tail
  endif
  return a:tail . s:slash
endfunction

function! s:remove_escape(expr)
  return substitute(a:expr, '\\\ze' . s:escape_char, '', 'g')
endfunction
