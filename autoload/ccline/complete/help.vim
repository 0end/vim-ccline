function! ccline#complete#help#parse(line)
  return ccline#complete#parse_by(a:line, '\S\+')
endfunction

function! ccline#complete#help#complete(A, L, P)
  if !exists('s:session_id') || ccline#session_id() > s:session_id
    let s:tags = s:tags()
    let s:session_id = ccline#session_id()
  endif
  return s:helptag_match(s:tags, a:A)
endfunction

function! s:helptag_match(helptag, string)
  let str = empty(a:string) ? 'help' : a:string
  let result = range(7)
  let result[6] = [] " str
  let result[5] = [] " str-- , --str
  let result[4] = [] " str-xxx , xxx-str , --str--
  let result[3] = [] " --str-xxx , xxx-str-- , strxxx , xxxstr
  let result[2] = [] " xxx-str-xxx
  let result[1] = [] " xxx-strxxx, xxxstr-xxx
  let result[0] = [] " xxxstrxxx
  let ignorecase = &ignorecase && !(&smartcase && str =~# '\u')
  for lang in keys(a:helptag)
    for line in a:helptag[lang]
      let part = strpart(line, 0, stridx(line, '	'))
      if part ==# '!_TAG_FILE_ENCODING'
        continue
      endif
      if ignorecase
        let pos = stridx(tolower(part), tolower(str))
      else
        let pos = stridx(part, str)
      endif
      if pos == -1
        continue
      endif
      let backward = strpart(part, 0, pos)
      let forward = strpart(part, pos + strlen(str))
      let p = 0

      let p += empty(backward) * 3
      let p += empty(forward) * 3

      let backward_is_delimiter = match(backward, '^\A\+$') != -1
      let forward_is_delimiter = match(forward, '^\A\+$') != -1
      let p += backward_is_delimiter * 2
      let p += forward_is_delimiter * 2

      let backward_char_is_delimiter = match(backward, '^.*\a\A\+$') != -1
      let forward_char_is_delimiter = match(forward, '^\A\+\a.*$') != -1
      let p += backward_char_is_delimiter * 1
      let p += forward_char_is_delimiter * 1

      let result[p] += [part . '@' . lang]
    endfor
  endfor
  let r = []
  for i in range(len(result))
    let r += sort(result[len(result) - i - 1], 's:help_compare')
  endfor
  return r
endfunction

let s:helplang = split(&helplang, ',')

function! s:help_compare(str1, str2)
  let p1 = strpart(a:str1, 0, strlen(a:str1) - 3)
  let p2 = strpart(a:str2, 0, strlen(a:str2) - 3)
  if p1 !=# p2
    if p1 < p2
      return -1
    endif
    if p1 > p2
      return 1
    endif
  endif
  let l1 = strpart(a:str1, strlen(a:str1) - 2)
  let l2 = strpart(a:str2, strlen(a:str2) - 2)
  if l1 ==# 'en'
    return 1
  endif
  if l2 ==# 'en'
    return -1
  endif
  let i1 = index(s:helplang, l1)
  let i2 = index(s:helplang, l2)
  if i1 == -1 && i2 == -1
    return 0
  endif
  if i1 == -1
    return 1
  endif
  if i2 == -1
    return -1
  endif
  if i1 < i2
    return -1
  endif
  if i1 > i2
    return 1
  endif
  return 0
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
