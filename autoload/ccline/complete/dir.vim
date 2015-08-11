let s:source = ccline#complete#file#define()

function! ccline#complete#dir#define() abort
  return deepcopy(s:source)
endfunction

let s:file_complete = s:source.complete
function! s:source.complete(...) abort
  let head = strpart(self.path, 0, strlen(self.path) - strlen(a:2))
  return filter(call(s:file_complete, a:000, self), 'isdirectory(head . v:val)')
endfunction
