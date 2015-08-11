let s:source = {}

function! ccline#complete#highlight#define() abort
  return deepcopy(s:source)
endfunction

function! s:source.init() abort
  let s:group_name = map(filter(split(ccline#complete#capture('highlight'), '\n'), 'stridx(v:val, " ") != 0'), 'strpart(v:val, 0, stridx(v:val, " "))')
endfunction

function! s:source.parse(cmdline) abort
  return ccline#complete#parse_by(a:cmdline.backward(), '\w\+')
endfunction

function! s:source.insert(candidate) abort
  if has_key(s:dict, a:candidate)
    return a:candidate . '='
  endif
  return a:candidate
endfunction

function! s:source.complete(cmdline, arg, line, pos) abort
  let args = a:cmdline.commandline.current_expr(a:pos)[2]
  let len = len(args)
  let len -= len > 0 && empty(args[len - 1][1])
  if len == 0
    return sort(ccline#complete#forward_matcher(s:group_name + [s:clear, s:default], a:arg))
  endif
  if args[0][0] ==# s:clear
    if len == 1
      return sort(ccline#complete#forward_matcher(s:group_name, a:arg))
    else
      return []
    endif
  endif
  if args[0][0] ==# s:default && len == 1
    return sort(ccline#complete#forward_matcher(s:group_name, a:arg))
  endif
  let o = ccline#complete#last_option_pair(ccline#list2str(a:cmdline.commandline.current_expr(a:pos)[2]), '[a-z]\+', '\s*=\s*', '\w*')
  if empty(o)
    return sort(ccline#complete#forward_matcher(keys(s:dict), a:arg))
  else
    return sort(ccline#complete#forward_matcher(s:dict[o[1]], o[2]))
  endif
endfunction

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
