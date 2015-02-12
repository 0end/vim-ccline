let s:attr_list = ['bold', 'underline', 'undercurl', 'reverse', 'inverse', 'italic', 'standout', 'NONE']

let s:cterm_colors = [
\ 'bg', 'fg',
\ 'Black',
\ 'DarkBlue',
\ 'DarkGreen',
\ 'DarkCyan',
\ 'DarkRed',
\ 'DarkMagenta',
\ 'Brown', 'DarkYellow',
\ 'LightGray', 'LightGrey', 'Gray', 'Grey',
\ 'DarkGray', 'DarkGrey',
\ 'Blue', 'LightBlue',
\ 'Green', 'LightGreen',
\ 'Cyan', 'LightCyan',
\ 'Red', 'LightRed',
\ 'Magenta', 'LightMagenta',
\ 'Yellow', 'LightYellow',
\ 'White'
\ ]

let s:gui_colors = [
\ 'NONE', 'bg', 'background', 'fg', 'foreground',
\ 'Red', 'LightRed', 'DarkRed',
\ 'Green', 'LightGreen', 'DarkGreen', 'SeaGreen',
\ 'Blue', 'LightBlue', 'DarkBlue', 'SlateBlue',
\ 'Cyan', 'LightCyan', 'DarkCyan',
\ 'Magenta', 'LightMagenta', 'DarkMagenta',
\ 'Yellow', 'LightYellow', 'Brown', 'DarkYellow',
\ 'Gray', 'LightGray', 'DarkGray',
\ 'Black', 'White',
\ 'Orange', 'Purple', 'Violet'
\ ]

let s:dict = {
\ 'term' : s:attr_list,
\ 'start' : [],
\ 'stop' : [],
\ 'cterm' : s:attr_list,
\ 'ctermfg' : s:cterm_colors,
\ 'ctermbg' : s:cterm_colors,
\ 'gui' : s:attr_list,
\ 'font' : ['NONE'],
\ 'guifg' : s:gui_colors,
\ 'guibg' : s:gui_colors,
\ 'guisp' : s:gui_colors,
\}

let s:clear = 'clear'
let s:default = 'default'

function! ccline#complete#highlight#complete(A, L, P)
  if !exists('s:session_id') || ccline#session_id() > s:session_id
    let s:group_name = map(filter(split(ccline#complete#capture('highlight'), '\n'), 'stridx(v:val, " ") != 0'), 'strpart(v:val, 0, stridx(v:val, " "))')
    let s:session_id = ccline#session_id()
  endif
  let args = split(strpart(a:L, 0, a:P))[1 :]
  if !empty(a:A)
    call remove(args, len(args) - 1)
  endif
  let g:test = args
  if len(args) == 0
    return sort(ccline#complete#forward_matcher(s:group_name + [s:clear, s:default], a:A))
  endif
  if args[0] ==# s:clear
    if len(args) == 1
      return sort(ccline#complete#forward_matcher(s:group_name, a:A))
    else
      return []
    endif
  endif
  if args[0] ==# s:default
    if len(args) == 1
      return sort(ccline#complete#forward_matcher(s:group_name, a:A))
    else
      return ccline#complete#option(s:dict, '[a-z]\+', '=', '\w*', a:A, a:L, a:P)
    endif
  endif
  return ccline#complete#option(s:dict, '[a-z]\+', '=', '\w*', a:A, a:L, a:P)
endfunction
