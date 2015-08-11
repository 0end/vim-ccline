let s:source = {}

function! ccline#complete#mapping#define() abort
  return deepcopy(s:source)
endfunction

function! s:source.init() abort
  let self.candidates = ccline#complete#uniq(s:prefixs + s:default_keys + s:get_user_key())
endfunction

function! s:source.complete(cmdline, arg, line, pos) abort
  return sort(ccline#complete#forward_matcher(self.candidates, a:arg))
endfunction

function! s:get_user_key()
  return map(split(ccline#complete#capture('map'), '\n') + split(ccline#complete#capture('imap'), '\n'), 'strpart(v:val, 3, stridx(v:val, " ", 3) - 3)')
endfunction

let s:prefixs = [
\ '<buffer>',
\ '<expr>',
\ '<nowait>',
\ '<script>',
\ '<silent>',
\ '<special>',
\ '<unique>'
\ ]

let s:default_keys = [
\ '<BS>',
\ '<Bar>',
\ '<Bslash>',
\ '<C-Left>',
\ '<C-Right>',
\ '<CR>',
\ '<CSI>',
\ '<Del>',
\ '<Down>',
\ '<EOL>',
\ '<End>',
\ '<Enter>',
\ '<Esc>',
\ '<FF>',
\ '<Help>',
\ '<Home>',
\ '<Insert>',
\ '<Left>',
\ '<NL>',
\ '<Nul>',
\ '<PageDown>',
\ '<PageUp>',
\ '<Return>',
\ '<Right>',
\ '<S-Down>',
\ '<S-Left>',
\ '<S-Right>',
\ '<S-Up>',
\ '<Space>',
\ '<Tab>',
\ '<Undo>',
\ '<Up>',
\ '<kDivide>',
\ '<kEnd>',
\ '<kEnter>',
\ '<kHome>',
\ '<kMinus>',
\ '<kMultiply>',
\ '<kPageDown>',
\ '<kPageUp>',
\ '<kPlus>',
\ '<kPoint>',
\ '<lt>',
\ '<xCSI>'
\ ]
