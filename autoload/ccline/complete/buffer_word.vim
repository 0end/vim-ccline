function! s:_uniq(list)
  let dict = {}
  for _ in a:list
    let dict[_] = 0
  endfor
  return keys(dict)
endfunction

function! ccline#complete#buffer_word#complete(A, L, P)
  if !exists('s:session_id') || ccline#session_id() > s:session_id
    let s:buffer_word = s:_uniq(filter(split(join(getline(1, '$')), '\W'), '!empty(v:val)'))
    let s:session_id = ccline#session_id()
  endif
  return sort(ccline#complete#forward_matcher(s:buffer_word, a:A), 1)
endfunction
