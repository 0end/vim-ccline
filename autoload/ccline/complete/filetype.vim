function! ccline#complete#filetype#complete(A, L, P)
  if !exists('s:session_id') || ccline#session_id() > s:session_id
    let s:filetype = ccline#complete#uniq(map(globpath(&runtimepath, 'ftplugin/*.vim', 0, 1) + globpath(&runtimepath, 'syntax/*.vim', 0, 1), 'fnamemodify(v:val, ":t:r")'))
    let s:session_id = ccline#session_id()
  endif
  return sort(ccline#complete#forward_matcher(s:filetype, a:A))
endfunction
