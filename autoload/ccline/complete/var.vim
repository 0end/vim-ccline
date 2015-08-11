let s:source = {}

function! ccline#complete#var#define() abort
  return deepcopy(s:source)
endfunction

function! s:source.parse(cmdline) abort
  let self.scope = 'g:'
  let backward = a:cmdline.backward()
  let args = a:cmdline.commandline.current_expr(strlen(backward))[2]
  if empty(args)
    return [strchars(backward), '']
  endif
  let arg = args[len(args) - 1]
  if !empty(arg[1])
    return [strchars(backward), '']
  endif
  if arg[0][1] ==# ':'
    let self.scope = strpart(arg[0], 0, 2)
    let keyword = strpart(arg[0], 2)
  else
    let keyword = arg[0]
  endif
  return [strchars(backward) - strchars(keyword), keyword]
endfunction

function! s:source.complete(cmdline, arg, line, pos) abort
  try
    let dict = eval(self.scope)
  catch
    return []
  endtry
  return sort(ccline#complete#forward_matcher(keys(dict), a:arg))
endfunction

