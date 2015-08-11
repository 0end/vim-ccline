function! ccline#dict#help#get() abort
  if !exists('s:helptag')
    call ccline#dict#help#refresh()
  endif
  return s:helptag
endfunction

function! ccline#dict#help#refresh() abort
  let s:helptag = s:tags()
endfunction

function! s:tags()
  let paths = globpath(&runtimepath, 'doc/{tags,tags-??}', 0, 1)
  let tags = {}
  for path in paths
    if !filereadable(path)
      continue
    endif
    let fname = fnamemodify(path, ':t')
    if strlen(fname) == 4
      let lang = 'en'
    else
      let lang = strpart(fname, 5)
    endif
    if has_key(tags, lang)
      let tags[lang] += readfile(path)
    else
      let tags[lang] = readfile(path)
    endif
  endfor
  return tags
endfunction
