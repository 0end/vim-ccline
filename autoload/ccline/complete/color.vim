function! ccline#complete#color#complete(A, L, P)
  if !exists('s:session_id') || ccline#session_id() > s:session_id
    let s:colors = map(globpath(&runtimepath, 'colors/*.vim', 0, 1), 'fnamemodify(v:val, ":t:r")')
    let s:session_id = ccline#session_id()
  endif
  return sort(ccline#complete#forward_matcher(s:colors, a:A))
endfunction
