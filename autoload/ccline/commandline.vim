scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim

let s:commandline = {
\ 'line': '',
\ 'core': [['', [], []]],
\ 'state': 0,
\ 'start_expr': 0,
\ 'on_command': 1,
\ 'on_args': 2,
\ 'last_state': 0,
\ 'in_bar_command': 0,
\ }

" :silent.delete == :silent .delete

" https://github.com/thinca/vim-ambicmd/blob/78fa88c5647071e73a3d21e5f575ed408f68aaaf/autoload/ambicmd.vim#L26
function! s:separate_range(line)
  let search_pattern = '\v/[^/]*\\@<!%(\\\\)*/|\?[^?]*\\@<!%(\\\\)*\?'
  let line_specifier = '\v%(\d+|[.$]|''\S|\\[/?&])?%([+-]\d*|' . search_pattern . ')*'
  let range_pattern = '\v^%(\%|' . line_specifier . '%([;,]' . line_specifier . ')*)'
  let range = matchstr(a:line, range_pattern)
  return [range, strpart(a:line, strlen(range))]
endfunction
function! s:extract_command(line)
  let [range, remain] = s:separate_range(a:line)
  let cmd = matchstr(remain, '^\%(\a\+\|[!#&*<=>@~]\)')

  let remain = strpart(remain, strlen(cmd))
  if empty(cmd)
    let bang = ''
  else
    let bang = matchstr(remain, '^!')
    let remain = strpart(remain, strlen(bang))
  endif
  let space = matchstr(remain, '^\s*')
  return [range, cmd, bang, space]
endfunction

function! s:parse_args(str, bar)
  let result = []
  let pos = 0
  let escape_pat = '\%(\\\\\)*\\'
  let escape_space_pat = escape_pat . '\@<=\s'
  let escape_bar_pat = escape_pat . '\@<=|'
  let nonspace_pat = a:bar ? '^\%([^|[:blank:]]\|' . escape_space_pat . '\|' . escape_bar_pat . '\)*'
  \                        : '^\%(\S\|' . escape_space_pat . '\)*'
  while pos < strlen(a:str)
    let p = matchstr(a:str, nonspace_pat, pos)
    let pos += strlen(p)
    let s = matchstr(a:str, '\s*', pos)
    let pos += strlen(s)
    let result += [[p, s]]
    if a:bar && match(a:str, '^|', pos) == pos
      break
    endif
  endwhile
  return result
endfunction

function! s:commandline.add(str)
  let self.line .= a:str
  call self.set_last_modified_expr(len(self.core) - 1)
  let expr = remove(self.core, len(self.core) - 1)
  if self.state == self.start_expr
    let remain = expr[0]
  elseif self.state == self.on_command
    if empty(expr[1])
      let remain = ''
    else
      let remain = join(remove(expr[1], len(expr[1]) - 1), '')
    endif
  elseif self.state == self.on_args
    if empty(expr[2])
      let remain = ''
    else
      if len(expr[2]) == 1 && expr[2][0][0] =~# '^\%(''$\|/\|?\)' && expr[2][0][1] ==# ''
        " can't complete on input
        " let s:c = ccline#commandline#make()
        " call s:c.add('silent')
        " call s:c.add('''')
        " call s:c.add('a')
        " echo s:c.core
        " let s:c = ccline#commandline#make()
        " call s:c.add('silent')
        " call s:c.add('''a')
        " echo s:c.core
        let remain = join(remove(expr[1], len(expr[1]) - 1), '') . join(remove(expr[2], len(expr[2]) - 1), '')
        let self.state = self.on_command
      else
        let remain = join(remove(expr[2], len(expr[2]) - 1), '')
      endif
    endif
  endif
  let remain .= a:str

  while !empty(remain)
    let self.last_state = self.state
    if self.state == self.start_expr
      " let head = matchstr(remain, '^|\?\s*')
      " :::echo 'test'
      let head = matchstr(remain, '^\%(:\+\||\)\?\s*')
      let expr[0] = head
      let remain = strpart(remain, strlen(head))
      let self.state = self.on_command
    elseif self.state == self.on_command
      let command = s:extract_command(remain)
      let expr[1] += [command]
      let remain = strpart(remain, strlen(join(command, '')))

      let cmd = ccline#command#get(command[1])
      let self.state = (get(cmd, 'complete', '') ==# 'command') ? self.on_command : self.on_args
      let self.in_bar_command = get(cmd, 'bar', 0)
    elseif self.state == self.on_args
      let args = s:parse_args(remain, self.in_bar_command)
      let expr[2] += args
      let remain = strpart(remain,
      \                    strlen(join(map(copy(args), 'join(v:val, "")'), ''))
      \                    )
      let self.core += [expr]
      let expr = ['', [], []]
      let self.state = self.start_expr
    endif
  endwhile
  let self.state = self.last_state
  if self.last_state != self.on_args
    let self.core += [expr]
  endif
endfunction

let s:flatten_iterator = ccline#vital().import('Iterator').flatten_iterator
function! s:commandline.iterator() abort
  return s:flatten_iterator(self.core)
endfunction

function! s:strpart(str, start, ...)
  let s = strpart(a:str, byteidx(a:str, a:start))
  if a:0 == 0
    return s
  else
    let i = byteidx(s, a:1)
    return i == -1 ? s : strpart(s, 0, i)
  endif
endfunction

function! s:remove_tail(str, pos) abort
  return s:strpart(a:str, 0, strchars(a:str) - a:pos)
endfunction
function! s:tail(str, pos) abort
  return s:strpart(a:str, strchars(a:str) - a:pos)
endfunction
function! s:clean_backward_list(list, index) abort
  " not include index
  let result = ''
  if a:index + 1 <= len(a:list) - 1
    for i in range(a:index + 1, len(a:list) - 1)
      if type(a:list[i]) == type([])
        let result .= ccline#list2str(a:list[i])
        let a:list[i] = []
      elseif type(a:list[i]) == type('')
        let result .= a:list[i]
        let a:list[i] = ''
      endif
    endfor
  endif
  return result
endfunction
function! s:remove_backward_list(list, index) abort
  " not include index
  if a:index < len(a:list) - 1
    return ccline#list2str(remove(a:list, a:index + 1, len(a:list) - 1))
  else
    return ''
  endif
endfunction

let s:commandline.last_modified_expr = -1

function! s:commandline.set_last_modified_expr(index) abort
  if self.last_modified_expr < 0
    let self.last_modified_expr = a:index
    return
  endif
  if a:index < 0
    return
  endif
  let self.last_modified_expr = min([a:index, self.last_modified_expr])
endfunction

function! s:commandline.get_last_modified_expr() abort
  return self.last_modified_expr
endfunction

function! s:commandline.remove_backward(pos) abort
  if a:pos <= 0
    let self.state = self.start_expr
    let self.core = [['', [], []]]
    let line = self.line
    let self.line = ''
    call self.set_last_modified_expr(0)
    return line
  elseif a:pos >= strchars(self.line)
    call self.set_last_modified_expr(-1)
    return ''
  endif
  let self.line = s:strpart(self.line, 0, a:pos)
  let p = 0
  let result = ''
  let itr = self.iterator()
  while itr.has_next()
    let p += strchars(itr.next())
    let d = p - a:pos
    if d >= 0
      call self.set_last_modified_expr(itr.index[0])
      let list = itr._get(len(itr.index) - 2)
      let result .= s:tail(list[itr.index[len(itr.index) - 1]], d)
      let list[itr.index[len(itr.index) - 1]] = s:remove_tail(list[itr.index[len(itr.index) - 1]], d)
      if itr.index[1] > 0
        let result .= s:clean_backward_list(itr._get(2), itr.index[3])
        let result .= s:remove_backward_list(itr._get(1), itr.index[2])
      endif
      let result .= s:clean_backward_list(itr._get(0), itr.index[1])
      let result .= s:remove_backward_list(itr._get(-1), itr.index[0])
      let self.state = itr.index[1] == 0 ? self.start_expr :
      \                itr.index[1] == 1 ? self.on_command :
      \                itr.index[1] == 2 ? self.on_args : -1
      break
    endif
  endwhile
  return result
endfunction

function! s:commandline.insert(str, pos) abort
  if empty(a:str)
    return
  endif
  call self.add(a:str . self.remove_backward(a:pos))
endfunction

function! s:commandline.delete(start, len) abort
  call self.add(s:strpart(self.remove_backward(a:start), a:len))
endfunction

function! ccline#commandline#make() abort
  return deepcopy(s:commandline)
endfunction

function! s:commandline.current_expr(pos) abort
  let temp_cmdline = deepcopy(self)
  call temp_cmdline.remove_backward(a:pos)
  return temp_cmdline.core[len(temp_cmdline.core) - 1]
endfunction

function! s:commandline.current_command(pos) abort
  let expr = self.current_expr(a:pos)
  let commands = expr[1]
  if empty(commands)
    return ':'
  endif
  let current_command = commands[len(commands) - 1]
  if empty(current_command[1])
    return ':'
  endif
  if empty(expr[2]) && empty(current_command[2]) && empty(current_command[3])
    return ':'
  endif
  if !ccline#command#iscommand(ccline#command#expand_alias(current_command[1]))
    return ''
  endif
  return current_command[1]
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
