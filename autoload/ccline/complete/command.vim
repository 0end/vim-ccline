function! ccline#complete#command#complete(A, L, P)
  if !exists('s:session_id') || ccline#session_id() > s:session_id
    let s:command = keys(ccline#command#command())
    let s:session_id = ccline#session_id()
  endif
  return sort(ccline#complete#forward_matcher(s:command, a:A))
endfunction
