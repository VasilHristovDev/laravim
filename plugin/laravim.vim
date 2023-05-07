" Title:	Laravim
" Description:	A plugin that integrates with Laravel projects
" Last Change	7 May 2023
" Maintainer	VasilHristovDev

if exists("g:loaded_laravim")
	finish
endif

let g:loaded_laravim = 1

command! -nargs=0 DisplayTime call laravim#DisplayTime()
command! -nargs=0 DisplayDate call laravim#DisplayDate()

