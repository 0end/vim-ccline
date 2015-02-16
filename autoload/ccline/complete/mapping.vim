function! ccline#complete#mapping#parse(line)
  return ccline#complete#parse_by(a:line, '\S\+')
endfunction

function! ccline#complete#mapping#complete(A, L, P)
  if !exists('s:session_id') || ccline#session_id() > s:session_id
    let s:keys = ccline#complete#uniq(s:prefixs + s:default_keys + s:get_user_key())
    let s:session_id = ccline#session_id()
  endif
  return sort(ccline#complete#forward_matcher(s:keys, a:A))
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
