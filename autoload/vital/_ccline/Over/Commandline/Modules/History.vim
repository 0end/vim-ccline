scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim

let s:module = {
\	"name" : "History",
\	"mode" : "cmd",
\}

function! s:module.histories()
  if histnr(self.mode) < 1
    return []
  endif
  return map(range(1, histnr(self.mode)), 'histget(self.mode, -1 * v:val)')
endfunction

function! s:_should_match_cmdline(cmdline)
	return a:cmdline.is_input("\<Up>")
\		|| a:cmdline.is_input("\<Down>")
endfunction

function! s:_reset()
	let s:cmdhist = []
	let s:count = 0
	let s:is_match_mode = 0 " <Up>/<Down>: true, <C-n>/<C-p>: false
endfunction

function! s:module.on_enter(...)
	call s:_reset()
endfunction

function! s:module.on_char_pre(cmdline)
	if !a:cmdline.is_input("\<Up>") && !a:cmdline.is_input("\<Down>")
	\	&& !a:cmdline.is_input("\<C-p>") && !a:cmdline.is_input("\<C-n>")
		call s:_reset()
		return
	endif
	if s:count == 0 && empty(s:cmdhist)
	\	|| s:is_match_mode != s:_should_match_cmdline(a:cmdline)
		let cmdline = '^' . a:cmdline.getline()
		let s:is_match_mode = s:_should_match_cmdline(a:cmdline)
		" let s:cmdhist = [a:cmdline.getline()] + (s:is_match_mode ?
		" \	filter(self.histories(), 'v:val =~ cmdline') : self.histories())
		let s:cmdhist = [a:cmdline.getline()] + filter(self.histories(),
		\ (s:is_match_mode && !empty(a:cmdline.getline()) ? 'v:val =~ cmdline' : '!empty(v:val)'))
	endif
	call a:cmdline.setchar("")
	if a:cmdline.is_input("\<Down>") || a:cmdline.is_input("\<C-n>")
		let s:count = max([s:count - 1, 0])
	endif
	if a:cmdline.is_input("\<Up>") || a:cmdline.is_input("\<C-p>")
		let s:count = min([s:count + 1, len(s:cmdhist) - 1])
	endif
	call a:cmdline.setline(get(s:cmdhist, s:count, a:cmdline.getline()))
endfunction

function! s:make(...)
	let module = deepcopy(s:module)
	let module.mode = get(a:, 1, "cmd")
	return module
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
