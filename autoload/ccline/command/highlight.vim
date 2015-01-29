let s:attr_list = ['bold', 'underline', 'undercurl', 'reverse', 'inverse', 'italic', 'standout', 'NONE']

let s:cterm_colors = [
\ 'bg', 'fg',
\ 'Black',
\ 'DarkBlue',
\ 'DarkGreen',
\ 'DarkCyan',
\ 'DarkRed',
\ 'DarkMagenta',
\ 'Brown', ' DarkYellow',
\ 'LightGray', ' LightGrey, Gray, Grey',
\ 'DarkGray', ' DarkGrey',
\ 'Blue', ' LightBlue',
\ 'Green', ' LightGreen',
\ 'Cyan', ' LightCyan',
\ 'Red', ' LightRed',
\ 'Magenta', ' LightMagenta',
\ 'Yellow', ' LightYellow',
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

function! ccline#command#highlight#complete(A, L, P)
  return ccline#complete#option(s:dict, '[a-z]\+', '=', '\w*', a:A, a:L, a:P)
endfunction
