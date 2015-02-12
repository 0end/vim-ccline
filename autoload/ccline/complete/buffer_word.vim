function! ccline#complete#buffer_word#complete(A, L, P)
  if !exists('s:session_id') || ccline#session_id() > s:session_id
    let s:buffer_word = ccline#complete#uniq(filter(split(join(getline(1, '$')), '\W'), '!empty(v:val)'))
    let s:session_id = ccline#session_id()
  endif
  return sort(ccline#complete#forward_matcher(s:buffer_word, a:A), 1)
endfunction
