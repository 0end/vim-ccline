scriptencoding utf-8

if exists('g:loaded_ccline')
  finish
endif
let g:loaded_ccline = 1

let s:save_cpo = &cpo
set cpo&vim

command! -count -nargs=? CCLineNormal call ccline#start(
\        (<count> != 0 ? ".,.+" . (<count> - <line1>) : '') .
\         <q-args>
\ )

command! -range -nargs=? CCLineVisual call ccline#start("'<,'>" . <q-args>)

nnoremap <silent> <Plug>(ccline) :CCLineNormal<CR>
vnoremap <silent> <Plug>(ccline) :CCLineVisual<CR>
onoremap <silent> <Plug>(ccline) :CCLineNormal<CR>

let &cpo = s:save_cpo
unlet s:save_cpo
