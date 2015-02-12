function! ccline#complete#buffer#complete(A, L, P)
  if !exists('s:session_id') || ccline#session_id() > s:session_id
    let s:buffers = map(split(ccline#complete#capture('buffers'), '[\r\n]'), 'strpart(v:val, 10, stridx(v:val, ''"'', 10) - 10)')
    let s:session_id = ccline#session_id()
  endif
  return ccline#complete#forward_matcher(s:buffers, a:A)
endfunction
