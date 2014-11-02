scriptencoding utf-8

if exists('g:loaded_ccline')
  finish
endif
let g:loaded_ccline = 1

let s:save_cpo = &cpo
set cpo&vim

command! -count CCLineNormal call ccline#start(
\        ":", <count> != 0 ? ".,.+" . (<count> - <line1>) : '')

command! -range CCLineVisual call ccline#start(":", "'<,'>")

nnoremap <silent> <Plug>(ccline) :CCLineNormal<CR>
vnoremap <silent> <Plug>(ccline) :CCLineVisual<CR>
onoremap <silent> <Plug>(ccline) :CCLineNormal<CR>

let &cpo = s:save_cpo
unlet s:save_cpo
