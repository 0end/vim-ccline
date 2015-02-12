scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim

function! ccline#command#command()
  if !exists('s:session_id') || ccline#session_id() > s:session_id
    let s:user_command = s:get_user_command()
    let s:command = extend(deepcopy(s:default_command), s:user_command)
    let s:session_id = ccline#session_id()
  endif
  return s:command
endfunction

function! ccline#command#current(backward)
  let [part, space] = s:parse(a:backward)
  let exprs = s:split_list(part, '|')
  if empty(exprs)
    return ':'
  endif
  let current_expr = exprs[len(exprs) - 1]
  if empty(current_expr)
    return ':'
  endif
  if a:backward !~# '\s$'
    call remove(current_expr, len(current_expr) - 1)
  endif
  if empty(current_expr)
    return ':'
  endif
  let command = ''
  for expr in current_expr
    if !s:iscommand(expr)
      return ''
    endif
    let command = expr
    if get(ccline#command#command()[command], 'complete', '') != 'command'
      return command
    endif
  endfor
  return command
endfunction

function! s:iscommand(expr)
  return has_key(ccline#command#command(), a:expr)
endfunction

function! s:parse(str)
  let single_quote = "'"
  let double_quote = '"'
  let space = ' '
  let escape = '\'
  let bar = '|'
  let normal = 0
  let single_quote_inner = 1
  let double_quote_inner = 2
  let endflag = 0
  let escapeflag = 0
  let spaceflag = 1
  let state = normal
  let result = []
  let spaceresult = []
  let part = ''
  let spacepart = ''
  for char in split(a:str, '\zs')
    if state == single_quote_inner
      if char == single_quote
        let endflag = !endflag
        let part .= char
        continue
      else
        if endflag
          let state = normal
          let endflag = 0
        else
          let part .= char
          continue
        endif
      endif
    elseif state == double_quote_inner
      if char == double_quote
        let endflag = !endflag
        let part .= char
        continue
      else
        if endflag
          let state = normal
          let endflag = 0
        else
          let part .= char
          continue
        endif
      endif
    endif
    if state == normal
      if char == single_quote
        let state = single_quote_inner
        if !empty(part)
          let result += [part]
        endif
        let part = char
      elseif char == double_quote
        let state = double_quote_inner
        if !empty(part)
          let result += [part]
        endif
        let part = char
      elseif char == space
        if escapeflag
          let part .= char
          let escapeflag = 0
        else
          if spaceflag
            let spacepart .= char
          else
            let spaceflag = 1
            if !empty(part)
              let result += [part]
            endif
            let part = ''
            let spacepart = char
          endif
        endif
      elseif char == escape
        let escapeflag = !escapeflag
        let part .= char
      elseif char == bar
        if !empty(part)
          let result += [part]
        endif
        let result += [char]
        let part = ''
      else
        let part .= char
      endif

      if char != space && spaceflag
        let spaceflag = 0
        let spaceresult += [spacepart]
      endif

    endif
  endfor
  if !empty(part)
    let result += [part]
  endif
  let spaceresult += [spacepart]
  if !spaceflag
    call add(spaceresult, '')
  endif
  return [result, spaceresult]
endfunction

function! s:split_list(list, separator)
  let result = []
  let e = 0
  for i in range(len(a:list))
    if a:list[i] ==# a:separator
      let result += [a:list[e : i - 1]]
      let e = i + 1
    endif
  endfor
  let result += [a:list[e : len(a:list) - 1]]
  return result
endfunction

function! s:combine(part, space)
  let result = []
  for i in range(len(a:part))
    let result += [a:space[i], a:part[i]]
  endfor
  " return result + [a:space[i + 1]]
  return result + [a:space[len(a:space) - 1]]
endfunction


function! s:get_user_command()
  let result = {}
  let command = split(ccline#complete#capture('command'), '[\r\n]')
  call remove(command, 0)
  for line in command
    let p = s:parse_command_list(line)
    let result[p[0]] = p[1]
  endfor
  return result
endfunction
function! s:parse_command_list(line)
  let first = strpart(a:line, 0, 2)
  let bang = (stridx(first, '!') >= 0)
  let register = (stridx(first, '"') >= 0)
  let buffer_local = (stridx(first, 'b') >= 0)
  let name = matchstr(strpart(a:line, 4), '^[A-Z]\S*')
  let name_len = strlen(name)
  if name_len <= 11
    let args = strpart(a:line, 16, 1)
    let range = matchstr(strpart(a:line, 21), '^\S\+')
    let complete = matchstr(strpart(a:line, 27), '^\S\+')
  else
    let args = strpart(a:line, name_len+5, 1)
    let range = matchstr(strpart(a:line, name_len+10), '^\S\+')
    let complete = matchstr(strpart(a:line, name_len+16), '^\S\+')
  endif
  return [name, {'bang': bang, 'register': register, 'buffer_local': buffer_local, 'args': args, 'range': range, 'complete': complete}]
endfunction

let s:default_command = {
\ '!': {'complete': 'shellcmd'},
\ '#': {},
\ '&': {},
\ '*': {},
\ '<': {},
\ '=': {},
\ '>': {},
\ '@': {},
\ 'Next': {},
\ 'Print': {},
\ 'X': {},
\ 'abbreviate': {},
\ 'abclear': {},
\ 'aboveleft': {},
\ 'all': {},
\ 'amenu': {},
\ 'anoremenu': {},
\ 'append': {},
\ 'argadd': {},
\ 'argdelete': {},
\ 'argdo': {},
\ 'argedit': {},
\ 'argglobal': {},
\ 'arglocal': {},
\ 'args': {},
\ 'argument': {'complete': ''},
\ 'ascii': {},
\ 'augroup': {'complete': 'augroup'},
\ 'aunmenu': {},
\ 'autocmd': {'complete': 'event'},
\ 'bNext': {},
\ 'badd': {},
\ 'ball': {},
\ 'bdelete': {},
\ 'behave': {'complete': 'behave'},
\ 'belowright': {},
\ 'bfirst': {},
\ 'blast': {},
\ 'bmodified': {},
\ 'bnext': {},
\ 'botright': {},
\ 'bprevious': {},
\ 'break': {'complete': ''},
\ 'breakadd': {},
\ 'breakdel': {},
\ 'breaklist': {},
\ 'brewind': {},
\ 'browse': {},
\ 'bufdo': {},
\ 'buffer': {'complete': 'buffer'},
\ 'buffers': {},
\ 'bunload': {},
\ 'bwipeout': {},
\ 'cNext': {},
\ 'cNfile': {},
\ 'cabbrev': {},
\ 'cabclear': {},
\ 'caddbuffer': {},
\ 'caddexpr': {},
\ 'caddfile': {},
\ 'call': {'complete': 'function'},
\ 'catch': {'complete': ''},
\ 'cbuffer': {},
\ 'cc': {'complete': ''},
\ 'cclose': {},
\ 'cd': {},
\ 'center': {},
\ 'cexpr': {},
\ 'cfile': {},
\ 'cfirst': {},
\ 'cgetbuffer': {},
\ 'cgetexpr': {},
\ 'cgetfile': {},
\ 'change': {},
\ 'changes': {},
\ 'chdir': {},
\ 'checkpath': {},
\ 'checktime': {},
\ 'clast': {},
\ 'clist': {},
\ 'close': {},
\ 'cmap': {},
\ 'cmapclear': {},
\ 'cmenu': {},
\ 'cnewer': {},
\ 'cnext': {},
\ 'cnfile': {},
\ 'cnoreabbrev': {},
\ 'cnoremap': {},
\ 'cnoremenu': {},
\ 'colder': {},
\ 'colorscheme': {'complete': 'color'},
\ 'comclear': {},
\ 'command': {'complete': 'command'},
\ 'compiler': {'complete': 'compiler'},
\ 'confirm': {},
\ 'continue': {},
\ 'copen': {},
\ 'copy': {},
\ 'cpfile': {},
\ 'cprevious': {},
\ 'cquit': {},
\ 'crewind': {},
\ 'cscope': {'complete': 'cscope'},
\ 'cstag': {},
\ 'cunabbrev': {},
\ 'cunmap': {},
\ 'cunmenu': {},
\ 'cwindow': {},
\ 'debug': {},
\ 'debuggreedy': {},
\ 'delcommand': {},
\ 'delete': {},
\ 'delfunction': {},
\ 'delmarks': {},
\ 'diffget': {},
\ 'diffoff': {},
\ 'diffpatch': {},
\ 'diffput': {},
\ 'diffsplit': {},
\ 'diffthis': {},
\ 'diffupdate': {},
\ 'digraphs': {},
\ 'display': {},
\ 'djump': {},
\ 'dlist': {},
\ 'doautoall': {},
\ 'doautocmd': {},
\ 'drop': {},
\ 'dsearch': {},
\ 'dsplit': {},
\ 'earlier': {},
\ 'echo': {'complete': 'function'},
\ 'echoerr': {'complete': 'function'},
\ 'echohl': {},
\ 'echomsg': {'complete': 'function'},
\ 'echon': {'complete': 'function'},
\ 'edit': {},
\ 'else': {'complete': ''},
\ 'elseif': {},
\ 'emenu': {},
\ 'endfor': {'complete': ''},
\ 'endfunction': {'complete': ''},
\ 'endif': {'complete': ''},
\ 'endtry': {'complete': ''},
\ 'endwhile': {'complete': ''},
\ 'enew': {},
\ 'ex': {},
\ 'execute': {},
\ 'exit': {},
\ 'exusage': {},
\ 'file': {},
\ 'files': {},
\ 'filetype': {},
\ 'finally': {},
\ 'find': {},
\ 'finish': {'complete': ''},
\ 'first': {'complete': ''},
\ 'fixdel': {},
\ 'fold': {'complete': ''},
\ 'foldclose': {'complete': ''},
\ 'folddoclosed': {'complete': 'command'},
\ 'folddoopen': {'complete': 'command'},
\ 'foldopen': {'complete': ''},
\ 'for': {},
\ 'function': {},
\ 'global': {},
\ 'goto': {},
\ 'grep': {},
\ 'grepadd': {},
\ 'gui': {},
\ 'gvim': {},
\ 'hardcopy': {},
\ 'help': {},
\ 'helpfind': {},
\ 'helpgrep': {},
\ 'helptags': {},
\ 'hide': {},
\ 'highlight': {'complete': 'highlight'},
\ 'history': {'complete': 'history'},
\ 'iabbrev': {},
\ 'iabclear': {},
\ 'if': {},
\ 'ijump': {},
\ 'ilist': {},
\ 'imap': {},
\ 'imapclear': {},
\ 'imenu': {},
\ 'inoreabbrev': {},
\ 'inoremap': {},
\ 'inoremenu': {},
\ 'insert': {},
\ 'intro': {'complete': ''},
\ 'isearch': {},
\ 'isplit': {},
\ 'iunabbrev': {},
\ 'iunmap': {},
\ 'iunmenu': {},
\ 'join': {},
\ 'jumps': {'complete': ''},
\ 'k': {},
\ 'keepalt': {},
\ 'keepjumps': {},
\ 'keepmarks': {},
\ 'keeppatterns': {},
\ 'lNext': {},
\ 'lNfile': {},
\ 'laddbuffer': {},
\ 'laddexpr': {},
\ 'laddfile': {},
\ 'language': {},
\ 'last': {},
\ 'later': {},
\ 'lbuffer': {},
\ 'lcd': {},
\ 'lchdir': {},
\ 'lclose': {},
\ 'lcscope': {},
\ 'left': {},
\ 'leftabove': {},
\ 'let': {},
\ 'lexpr': {},
\ 'lfile': {},
\ 'lfirst': {},
\ 'lgetbuffer': {},
\ 'lgetexpr': {},
\ 'lgetfile': {},
\ 'lgrep': {},
\ 'lgrepadd': {},
\ 'lhelpgrep': {},
\ 'list': {},
\ 'll': {},
\ 'llast': {},
\ 'llist': {},
\ 'lmake': {},
\ 'lmap': {},
\ 'lmapclear': {},
\ 'lnewer': {},
\ 'lnext': {},
\ 'lnfile': {},
\ 'lnoremap': {},
\ 'loadkeymap': {},
\ 'loadview': {},
\ 'lockmarks': {},
\ 'lockvar': {},
\ 'lolder': {},
\ 'lopen': {},
\ 'lpfile': {},
\ 'lprevious': {},
\ 'lrewind': {},
\ 'ls': {},
\ 'ltag': {},
\ 'lua': {},
\ 'luado': {},
\ 'luafile': {},
\ 'lunmap': {},
\ 'lvimgrep': {},
\ 'lvimgrepadd': {},
\ 'lwindow': {},
\ 'make': {},
\ 'map': {},
\ 'mapclear': {},
\ 'mark': {},
\ 'marks': {},
\ 'match': {},
\ 'menu': {},
\ 'menutranslate': {},
\ 'messages': {},
\ 'mkexrc': {},
\ 'mksession': {},
\ 'mkspell': {},
\ 'mkview': {},
\ 'mkvimrc': {},
\ 'mode': {},
\ 'move': {},
\ 'mzfile': {},
\ 'mzscheme': {},
\ 'nbclose': {},
\ 'nbkey': {},
\ 'nbstart': {},
\ 'new': {},
\ 'next': {},
\ 'nmap': {},
\ 'nmapclear': {},
\ 'nmenu': {},
\ 'nnoremap': {},
\ 'nnoremenu': {},
\ 'noautocmd': {},
\ 'nohlsearch': {},
\ 'noreabbrev': {},
\ 'noremap': {},
\ 'noremenu': {},
\ 'normal': {},
\ 'noswapfile': {},
\ 'number': {},
\ 'nunmap': {},
\ 'nunmenu': {},
\ 'oldfiles': {},
\ 'omap': {},
\ 'omapclear': {},
\ 'omenu': {},
\ 'only': {},
\ 'onoremap': {},
\ 'onoremenu': {},
\ 'open': {},
\ 'options': {},
\ 'ounmap': {},
\ 'ounmenu': {},
\ 'ownsyntax': {'complete': 'syntax'},
\ 'pclose': {},
\ 'pedit': {},
\ 'perl': {},
\ 'perldo': {},
\ 'pop': {},
\ 'popup': {},
\ 'ppop': {},
\ 'preserve': {},
\ 'previous': {},
\ 'print': {},
\ 'profdel': {},
\ 'profile': {},
\ 'promptfind': {},
\ 'promptrepl': {},
\ 'psearch': {},
\ 'ptNext': {},
\ 'ptag': {},
\ 'ptfirst': {},
\ 'ptjump': {},
\ 'ptlast': {},
\ 'ptnext': {},
\ 'ptprevious': {},
\ 'ptrewind': {},
\ 'ptselect': {},
\ 'put': {},
\ 'pwd': {},
\ 'py3': {},
\ 'py3do': {},
\ 'py3file': {},
\ 'pydo': {},
\ 'pyfile': {},
\ 'python': {},
\ 'python3': {},
\ 'qall': {},
\ 'quit': {},
\ 'quitall': {},
\ 'read': {},
\ 'recover': {},
\ 'redir': {},
\ 'redo': {},
\ 'redraw': {},
\ 'redrawstatus': {},
\ 'registers': {},
\ 'resize': {},
\ 'retab': {},
\ 'return': {},
\ 'rewind': {},
\ 'right': {},
\ 'rightbelow': {},
\ 'ruby': {},
\ 'rubydo': {},
\ 'rubyfile': {},
\ 'rundo': {},
\ 'runtime': {},
\ 'rviminfo': {},
\ 'sNext': {},
\ 'sall': {},
\ 'sandbox': {},
\ 'sargument': {},
\ 'saveas': {},
\ 'sbNext': {},
\ 'sball': {},
\ 'sbfirst': {},
\ 'sblast': {},
\ 'sbmodified': {},
\ 'sbnext': {},
\ 'sbprevious': {},
\ 'sbrewind': {},
\ 'sbuffer': {},
\ 'scriptencoding': {},
\ 'scriptnames': {},
\ 'scscope': {},
\ 'set': {'complete': 'option'},
\ 'setfiletype': {'complete': 'filetype'},
\ 'setglobal': {},
\ 'setlocal': {'complete': 'option'},
\ 'sfind': {},
\ 'sfirst': {},
\ 'shell': {},
\ 'sign': {'complete': 'sign'},
\ 'silent': {},
\ 'simalt': {},
\ 'slast': {},
\ 'sleep': {'complete': ''},
\ 'smagic': {},
\ 'smap': {},
\ 'smapclear': {},
\ 'smenu': {},
\ 'snext': {},
\ 'sniff': {},
\ 'snomagic': {},
\ 'snoremap': {},
\ 'snoremenu': {},
\ 'sort': {},
\ 'source': {},
\ 'spelldump': {},
\ 'spellgood': {},
\ 'spellinfo': {},
\ 'spellrepall': {},
\ 'spellundo': {},
\ 'spellwrong': {},
\ 'split': {},
\ 'sprevious': {},
\ 'srewind': {},
\ 'stag': {},
\ 'startgreplace': {},
\ 'startinsert': {},
\ 'startreplace': {},
\ 'stjump': {},
\ 'stop': {},
\ 'stopinsert': {},
\ 'stselect': {},
\ 'substitute': {},
\ 'sunhide': {},
\ 'sunmap': {},
\ 'sunmenu': {},
\ 'suspend': {},
\ 'sview': {},
\ 'swapname': {},
\ 'syncbind': {},
\ 'syntax': {},
\ 'syntime': {'complete': 'syntime'},
\ 't': {},
\ 'tNext': {},
\ 'tab': {},
\ 'tabNext': {},
\ 'tabclose': {},
\ 'tabdo': {},
\ 'tabedit': {},
\ 'tabfind': {},
\ 'tabfirst': {},
\ 'tablast': {},
\ 'tabmove': {},
\ 'tabnew': {},
\ 'tabnext': {},
\ 'tabonly': {},
\ 'tabprevious': {},
\ 'tabrewind': {},
\ 'tabs': {},
\ 'tag': {},
\ 'tags': {},
\ 'tcl': {},
\ 'tcldo': {},
\ 'tclfile': {},
\ 'tearoff': {},
\ 'tfirst': {},
\ 'throw': {},
\ 'tjump': {},
\ 'tlast': {},
\ 'tmenu': {},
\ 'tnext': {},
\ 'topleft': {},
\ 'tprevious': {},
\ 'trewind': {},
\ 'try': {},
\ 'tselect': {},
\ 'tunmenu': {},
\ 'unabbreviate': {},
\ 'undo': {},
\ 'undojoin': {},
\ 'undolist': {},
\ 'unhide': {},
\ 'unlet': {},
\ 'unlockvar': {},
\ 'unmap': {},
\ 'unmenu': {},
\ 'unsilent': {},
\ 'update': {},
\ 'verbose': {},
\ 'version': {},
\ 'vertical': {},
\ 'vglobal': {},
\ 'view': {},
\ 'vimgrep': {},
\ 'vimgrepadd': {},
\ 'visual': {},
\ 'viusage': {},
\ 'vmap': {},
\ 'vmapclear': {},
\ 'vmenu': {},
\ 'vnew': {},
\ 'vnoremap': {},
\ 'vnoremenu': {},
\ 'vsplit': {},
\ 'vunmap': {},
\ 'vunmenu': {},
\ 'wNext': {},
\ 'wall': {},
\ 'while': {},
\ 'wincmd': {},
\ 'windo': {},
\ 'winpos': {},
\ 'winsize': {},
\ 'wnext': {},
\ 'wprevious': {},
\ 'wq': {},
\ 'wqall': {},
\ 'write': {},
\ 'wsverb': {},
\ 'wundo': {},
\ 'wviminfo': {},
\ 'xall': {},
\ 'xit': {},
\ 'xmap': {},
\ 'xmapclear': {},
\ 'xmenu': {},
\ 'xnoremap': {},
\ 'xnoremenu': {},
\ 'xunmap': {},
\ 'xunmenu': {},
\ 'yank': {},
\ 'z': {},
\ '~': {},
\ }

let &cpo = s:save_cpo
unlet s:save_cpo
