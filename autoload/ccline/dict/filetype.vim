function! ccline#dict#filetype#get() abort
  if !exists('s:filetypes')
    call ccline#dict#filetype#refresh()
  endif
  return s:filetypes
endfunction

function! ccline#dict#filetype#refresh() abort
  let s:filetypes = ccline#complete#uniq(map(
  \ globpath(&runtimepath, 'ftplugin/*.vim', 0, 1) + globpath(&runtimepath, 'syntax/*.vim', 0, 1),
  \ 'fnamemodify(v:val, ":t:r")'))
endfunction

