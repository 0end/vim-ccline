let s:source = {}

function! ccline#complete#source#menu#define() abort
  return deepcopy(s:source)
endfunction

function! s:source.init() abort
  let self.candidates = s:parse()
endfunction

function! s:source.parse(cmdline) abort
  return ccline#complete#parse_by(a:cmdline.backward(), '[^.[:blank:]]\+')
endfunction

function! s:source.complete(cmdline, arg, line, pos) abort
  let args = a:cmdline.commandline.current_expr(a:pos)[2]
  let list = deepcopy(self.candidates)
  if empty(args)
    let arg = []
  else
    let arg = split(args[len(args) - 1][0], '\.', 1)
  endif
  if len(arg) > 1
    for e in arg[0 : len(arg) - 2]
      let list = filter(list, 'v:val.name ==# e')
      if empty(list)
        break
      endif
      let list = list[0].children
    endfor
  endif
  let self.list = copy(list)
  let list = map(list, 'v:val.name')
  return ccline#complete#forward_matcher(list, a:arg)
endfunction

function! s:source.insert(candidate) abort
  let m = filter(copy(self.list), 'v:val.name ==# a:candidate')[0]
  if empty(m.children)
    return a:candidate
  endif
  return a:candidate . '.'
endfunction

let s:default_menu = {
\ 'name': '',
\ 'priority': 500,
\ 'children': [],
\ 'parent': {},
\ 'indent': -1,
\ }

function! s:parse() abort
  let menu = ccline#complete#capture('menu')
  let list = filter(map(split(menu, '[\r\n]')[1 :], 's:parse_line(v:val)'), '!empty(v:val)')
  let root = deepcopy(s:default_menu)
  let target = root
  for e in list
    let d = target.indent - e.indent
    let d = (d == 0 ? 0 : d/abs(d)) + 1
    let parent = eval('target' . repeat('.parent', d))
    let e.parent = parent
    call add(parent.children, e)
    let target = e
  endfor
  return root.children
endfunction

function! s:parse_line(str) abort
  let m = matchlist(a:str, '^\(\s*\)\(\d\+\)\s\(\S\+\)$')
  if empty(m)
    return {}
  endif
  return extend(deepcopy(s:default_menu), {'indent': strlen(m[1]), 'priority': m[2], 'name': m[3]})
endfunction
