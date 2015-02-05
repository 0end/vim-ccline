function! s:_uniq(list)
  let dict = {}
  for _ in a:list
    let dict[_] = 0
  endfor
  return keys(dict)
endfunction

function! ccline#complete#buffer_word#complete(A, L, P)
  if !exists('s:buffer_word')
    let s:buffer_word = s:_uniq(filter(split(join(getline(1, '$')), '\W'), '!empty(v:val)'))
  endif
  return sort(filter(s:buffer_word, 'v:val =~ ''^'' . a:A'), 1)
endfunction

function! ccline#complete#buffer_word#init()
  unlet! s:buffer_word
endfunction
