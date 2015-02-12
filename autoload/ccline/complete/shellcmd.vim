function! ccline#complete#shellcmd#complete(A, L, P)
  if !exists('s:session_id') || ccline#session_id() > s:session_id
    let s:shellcmd = s:get_shellcmd()
    let s:session_id = ccline#session_id()
  endif
  return ccline#complete#forward_matcher(s:shellcmd, a:A)
endfunction

function! s:get_shellcmd()
  let result = []
  for path in split($PATH, ';')
    for file in globpath(path, '*', 0, 1)
      if !executable(file) && !isdirectory(file)
        continue
      endif
      let result += [fnamemodify(file, ":t") . (isdirectory(file) ? "/" : "")]
    endfor
  endfor
  return result
endfunction
