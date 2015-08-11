let s:save_cpo = &cpo
set cpo&vim

let s:_iterator = {
\ 'index': -1
\ }
function! s:_iterator.has_next() abort
  return len(self.list) - 1 > self.index
endfunction
function! s:_iterator.next() abort
  let self.index += 1
  return self.list[self.index]
endfunction
function! s:iterator(list) abort
  let iterator = deepcopy(s:_iterator)
  let iterator.list = a:list
  return iterator
endfunction

let s:_reverse_iterator = {}
function! s:_reverse_iterator.has_next() abort
  return 0 < self.index
endfunction
function! s:_reverse_iterator.next() abort
  let self.index -= 1
  return self.list[self.index]
endfunction
function! s:reverse_iterator(list) abort
  let reverse_iterator = extend(s:iterator(a:list), deepcopy(s:_reverse_iterator))
  let reverse_iterator.index = len(reverse_iterator.list)
  return reverse_iterator
endfunction

let s:_flatten_iterator = {
\ 'index': [-1],
\ '_next': [0, []]
\ }

function! s:_flatten_iterator._get(level) abort
  if a:level < 0
    return self.list
  endif
  let result = self.list
  if a:level - 1 >= 0
    for i in range(0, a:level - 1)
      let result = result[self.index[i]]
    endfor
  endif
  return result[self.index[a:level]]

"  return eval('self.list' . join(map(copy(self.index[: a:level]), '"[" . v:val . "]"'), ''))
endfunction

function! s:_flatten_iterator.has_next() abort
  let self._next = self._nexts()
  if !self._next[0] && empty(self._next[1])
    return 0
  endif
  return 1
endfunction

function! s:_flatten_iterator.next() abort
  let [i, n] = self._next
  call remove(self.index, i, len(self.index) - 1)
  let self.index += n
  return self._get(len(self.index) - 1)
endfunction

function! s:_flatten_iterator._nexts() abort
  for i in reverse(range(len(self.index)))
    let parent = self._get(i - 1)
    let j = self.index[i] + 1
    while len(parent) - 1 >= j
      let cur = parent[j]
      if type(cur) != type([])
        return [i, [j]]
      endif
      let f = s:_first_element(cur, [])
      if !empty(f)
        return [i, [j] + f]
      endif
      let j += 1
      unlet cur
    endwhile
  endfor
  return [0, []]
endfunction

function! s:_first_element(list, index)
  for i in range(len(a:list))
    if type(a:list[i]) == type([])
      if empty(a:list[i])
        continue
      endif
      let inner = s:_first_element(a:list[i], a:index + [i])
      if len(a:index) == len(inner)
        continue
      endif
      return inner
    endif
    return a:index + [i]
  endfor
  return a:index
endfunction

function! s:flatten_iterator(list) abort
  let flatten_iterator = extend(s:iterator(a:list), deepcopy(s:_flatten_iterator))
  return flatten_iterator
endfunction

"let s:list = ['a', ['b', 'c'], [['d', 'e', ['f'], [], 'g']], [[]], ['h']]
"let s:f = s:flatten_iterator(s:list)
"while s:f.has_next()
"  echo s:f.next()
"endwhile

let &cpo = s:save_cpo
unlet s:save_cpo
