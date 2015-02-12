function! ccline#complete#compiler#complete(A, L, P)
  if !exists('s:session_id') || ccline#session_id() > s:session_id
    let s:compiler = map(split(ccline#complete#capture('compiler'), '\n'), 'fnamemodify(v:val, ":t:r")')
    let s:session_id = ccline#session_id()
  endif
  return sort(ccline#complete#forward_matcher(s:compiler, a:A))
endfunction
