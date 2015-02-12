function! ccline#complete#environment#complete(A, L, P)
  if !exists('s:session_id') || ccline#session_id() > s:session_id
    let s:environment = map(split(system(s:environment_command), '\n'), 'strpart(v:val, 0, stridx(v:val, "="))')
    let s:session_id = ccline#session_id()
  endif
  return ccline#complete#forward_matcher(s:environment, a:A)
endfunction

let s:environment_command = has('win32') ? 'set' : 'env'
