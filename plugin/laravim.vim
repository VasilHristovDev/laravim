" Title:	Laravim
" Description:	A plugin that integrates with Laravel projects
" Last Change	7 May 2023
" Maintainer	VasilHristovDev

if exists("g:loaded_laravim")
	finish
endif

let g:loaded_laravim = 1

command! HasComposer :call HasComposer()
command! ListArtisanCommands :call ListArtisanCommands()
command! -nargs=1 LaravimExec :call ExecuteArtisanCommand(<q-args>)
command! IsLaravel :call IsLaravel(GetParentDirectory())

function! HasComposer()
	let command_output = system('composer --version 2> /dev/null')
	if v:shell_error == 0 && command_output =~ 'Composer version'
		echo "Composer is installed"
	else
		echo "Composer is not installed"
	endif
endfunction



function! IsLaravel(current_directory)
	let project_root = FindLaravelRoot()
	if empty(project_root)
		echo "It is not Laravel project"
		return 0
	endif

	let full_path = project_root . '/' . a:current_directory
	echo full_path
	echo "Is it Laravel project"	
	return 1
endfunction

function! FindLaravelRoot() abort
	let current_dir = getcwd()
	while !empty(current_dir) && current_dir !=# '/'
		if filereadable(current_dir . '/composer.json') && filereadable(current_dir . '/artisan')
			return current_dir
		endif
		let current_dir = fnamemodify(current_dir, ':h')
	endwhile
	return ''
endfunction

function! GetParentDirectory()
	let current_file = expand('%:p')
	let parent_dir = fnamemodify(current_file, ':h')
	return parent_dir
endfunction

function! ListArtisanCommands()
	let is_laravel = IsLaravel(GetParentDirectory())
	if is_laravel
		echo  system('php artisan list')
	else 
		echo "It is not a Laravel project"
	endif
	return
endfunction

function! ExecuteArtisanCommand(command)
	let project_root = FindLaravelRoot()	
	if empty(project_root)
		echo "It is not a Laravel Project"
		return	
	endif
	let cmd = 'cd ' . shellescape(project_root) . ' && php artisan ' . a:command
	let output = system(cmd)

	if v:shell_error != 0
		echohl ErrorMsg
		echomsg "Error running artisan commands"
		echohl None
		return
	endif

	echomsg output
endfunction
