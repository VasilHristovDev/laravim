" Title:	Laravim
" Description:	A plugin that integrates with Laravel projects
" Last Change	7 May 2023
" Maintainer	VasilHristovDev

if exists("g:loaded_laravim")
	finish
endif

let g:loaded_laravim = 1
nnoremap gh :call GoTo()<CR>

command! HasComposer :call HasComposer()
command! ListArtisanCommands :call ListArtisanCommands()
command! -nargs=1 LaravimExec :call ExecuteArtisanCommand(<q-args>)
command! IsLaravel :call IsLaravel(GetParentDirectory())
command! -nargs=1 ComposerExec :call ExecuteComposerCommand(<q-args>)
command! GoTo :call GoToRouteDefinintion()
command! Match :call MatchRoute()

function! HasComposer()
	let command_output = system('composer --version 2> /dev/null')
	if v:shell_error == 0 && command_output =~ 'Composer version'
		echo "Composer is installed"
		return 1
	else
		echo "Composer is not installed"
		return 0
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

	echo  output
endfunction

function! ExecuteComposerCommand(command)
	let has_composer = HasComposer()
	if has_composer == 0
		return
	endif
	let cmd = 'composer ' . a:command
	let output = system(cmd)

	if v:shell_error != 0
		echohl ErrorMsg
		echomsg "Error running composer commands"
		echohl None
		echo output
		return
	endif
	
	echo output
endfunction

function! GoTo()
	let current_file = expand('%:t')
	if current_file == 'web.php'
		call GoToViewDefinition()
	elseif current_file == 'api.php'
		call GoToRouteDefinition()
	else
		echohl ErrorMsg
		echomsg "We still don't support this file for route tracing"
		echohl None
	endif

endfunction

function! GoToRouteDefinition()
	let matches = MatchRoute()
	let controller_path = "app/Http/Controllers/" . matches['controller_path']	
	let method = matches['route_method']
	echo controller_path

	let project_root = FindLaravelRoot()
	
	if empty(project_root)
		echohl ErrorMsg
		echo "Laravel project not found"
		echohl None
		return
	endif
	let controller_path = project_root . '/'. controller_path
	if filereadable(controller_path)
		execute 'tabnew ' . controller_path
		call search(method, 'w')
	endif	
endfunction	

function! GoToViewDefinition()
       	let view = MatchView()
	let project_root = FindLaravelRoot()
	if empty(project_root)
		echohl ErrorMsg
		echomsg "Laravel project not found"
		echohl None
		return
	endif
	let view_path = project_root . '/' . 'resources/views/' . view . '.blade.php'
	if filereadable(view_path)
		execute 'tabnew ' . view_path
	endif
endfunction	

function! MatchRoute()
	let current_line = getline('.')
"	let pattern = 'Route::\w\+(''[^'']\+'',\s*[\\\=App\\Http\\Controllers\\[^,]\+.*::class\s*,\s*''[^'']\+''\])'
	let pattern = 'Route::\w\+(''[^'']\+'',\s*[\\\=App\\Http\\Controllers\\\{-}\\[^,]\+.*::class,\s*''[^'']\+''\])'
	let pattern_controller_path = '\\\=App\\Http\\Controllers\\'
	let match = match(current_line, pattern)

	if match != -1
	    if match(current_line, pattern_controller_path) == -1
		    let controller_name = matchstr(current_line, '\w\+::class')
		    let controller_name = substitute(controller_name, '::class', '', '')
		    let prev_position = getpos('.')
		    keepjumps norm! 1G
		    let line =  search(controller_name,'w')
		    let controller_path = getline('.')
		    let controller_path = substitute(controller_path, 'use\s*App\\Http\\Controllers\\', '', '') . '.php'
		    let controller_path = substitute(controller_path, ';', '', '') 
		    let controller_path = substitute(controller_path, '\\', '/', '') 
		    call setpos('.', prev_position)
	    else 
		    let route_controller_class = matchstr(current_line, '\\\=App\\Http\\Controllers\\\+.*::class')
		    let controller_path = substitute(route_controller_class, 'App\\Http\\Controllers\\', '', '') . '.php'
		    let controller_path = substitute(controller_path, '::class', '', '')
	    endif
	    let route_method = matchstr(current_line, ',\s*''[^'']\+''])')
	    let route_method = substitute(route_method, ',\s*', '', '')
	    let route_method = substitute(route_method, '])', '', '')
	    let route_method = substitute(route_method, "'", '', 'g')
	    return {"route_method" : route_method, "controller_path" : controller_path }
	else
	    echohl ErrorMsg
	    echo "Current line does not match the pattern."
	    echohl None
	endif
endfunction
function! MatchView()
	let current_line = getline('.')
	let pattern = 'return\s*view(''[^'']\+'');'
       	let match = match(current_line, pattern)
	
	if match != -1
		let view = matchstr(current_line,'view(''[^'']\+'')')
		let view = substitute(view, 'view(''\|'')', '', 'g')
		return view
	else
		echohl ErrorMsg
		echomsg "Invalid view"
		echohl None
	endif	
endfunction
