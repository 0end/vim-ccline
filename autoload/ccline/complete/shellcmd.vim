let s:source = {}

function! ccline#complete#shellcmd#define() abort
  return deepcopy(s:source)
endfunction

function! s:source.init() abort
  let self.candidates = s:get_shellcmd()
endfunction

function! s:source.complete(cmdline, arg, line, pos) abort
  return ccline#complete#forward_matcher(self.candidates, a:arg)
endfunction

function! s:get_shellcmd()
  let result = []
  for path in split($PATH, ';')
    for file in globpath(path, '*', 0, 1)
      if !executable(file) && !isdirectory(file)
        continue
      endif
      let result += [fnamemodify(file, ":t") . (isdirectory(file) ? "/" : "")]
    endfor
  endfor
  return result
endfunction
