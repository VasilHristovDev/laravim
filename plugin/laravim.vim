" Title:	Laravim
" Description:	A plugin that integrates with Laravel projects
" Last Change	7 May 2023
" Maintainer	VasilHristovDev

if exists("g:loaded_laravim")
	finish
endif

let g:loaded_laravim = 1
let g:vendor_library_paths = {}
nnoremap gh :call GoTo()<CR>
nnoremap gc :call GoToClassDefinition()<CR>
nnoremap gd :call GoToDefinition()<CR>

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
	let project_root = g:laravel_root
	if empty(project_root)
		return 0
	endif

	let full_path = project_root . '/' . a:current_directory
	echo full_path
	echo "Is it Laravel project"	
	return 1
endfunction

function! FindLaravelRoot() 
	let current_dir = getcwd()
	while !empty(current_dir) && current_dir !=# '/'
		if filereadable(current_dir . '/composer.json') && filereadable(current_dir . '/artisan')
			return current_dir
		endif
		let current_dir = fnamemodify(current_dir, ':h')
	endwhile
	echohl ErrorMsg
	echo "No Laravel project found"
	echohl None
	return ''
endfunction
let g:laravel_root = FindLaravelRoot()

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
	let project_root = g:laravel_root	
	if empty(project_root)
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

	let project_root = g:laravel_root
	
	if empty(project_root)
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
	let project_root = g:laravel_root
	if empty(project_root)
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
		    call search(controller_name,'w')
		    let controller_path = getline('.')
		    let controller_path = substitute(controller_path, 'use\s*App\\Http\\Controllers\\', '', '') . '.php'
		    let controller_path = substitute(controller_path, ';', '', '') 
		    let controller_path = substitute(controller_path, '\\', '/', '') 
		    call setpos('.', prev_position)
	    else 
		    let route_controller_class = matchstr(current_line, '\\\=App\\Http\\Controllers\\\+.*::class')
		    let controller_path = substitute(route_controller_class, 'App\\Http\\Controllers\\', '', '') . '.php'
		    let controller_path = substitute(controller_path, '::class', '', '')
		    let controller_path = substitute(controller_path, '\\', '/', 'g')
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

function! GoToDefinition()
	let current_line = getline('.')
	let cursor_col = col('.')
	
	let start_col = search('\w\+\s*::\w\+\s*(\s*.*\s*)\s*\%(\->\|;\|\n\)', 'bcnW')
	if start_col > 0
		let class_method = matchstr(current_line, '\w\+\s*::\w\+\s*(\s*.*\s*)\s*\%(\->\|;\|\n\)')
		let class_name = matchstr(class_method, '\w\+')
		let method_name = matchstr(class_method, '::\w\+')
		let method_name = substitute(method_name, '::', '', '')
		let current_pos = getpos('.')
		keepjumps norm! 1G	
		call search('\'.class_name.';','w')
		let line = getline('.')
		let line = substitute(line, 'use\s*', '', '')
		let line = substitute(line, ';', '', '')
		let line = substitute(line, '\\', '/', 'g') . '.php'
		let result = GetFullPath(line)
		if result["found"]
			let path = result["path"] . substitute(line, '\w\+', '', '')
		else
			let project_root = g:laravel_root
			if empty(project_root)
				return
			endif
			let path = project_root . '/' . line 
		endif
		call setpos('.', current_pos)
		if filereadable(path)
			execute 'tabnew ' . path
			call search(method_name, 'w')
		else
			echohl ErrorMsg
			echo "Cannot open class file"
			echohl None	
		endif
	endif
	return	
endfunction

function! GoToMethodDefinition()
endfunction

function! GoToClassDefinition()
	let class = expand('<cword>')
	let current_pos = getpos('.')
 	keepjumps norm! 1G
	call search(class, 'w')
	let class_path = getline('.')	
	let class_path = substitute(class_path, 'use\s*', '', '')
	let class_path = substitute(class_path, ';', '', '')
	let class_path = substitute(class_path, '\\', '/', 'g') . '.php'
	let root_path = g:laravel_root 
	if empty(root_path)
		return
	endif

	let result = GetFullPath(class_path)
	if result["found"]
		let path = result["path"] . substitute(class_path, '\w\+', '', '')
	else
		let class_path = substitute(class_path, '\\App\|App', 'app', '') 
		let project_root = g:laravel_root
		if empty(project_root)
			return
		endif
		let path = project_root . '/' . class_path
	endif
	call setpos('.', current_pos)
	if filereadable(path)
		execute 'tabnew ' . path
	else
		echohl ErrorMsg
		echo "Cannot open class file"
		echohl None	
	endif
	return	
endfunction

function! ListSrcFilesInVendor()
    let vendor_dir = g:laravel_root . '/vendor' 
    let libraries = glob(vendor_dir . '/*', 1, 1)

    for library in libraries
        call SearchSrcDir(library)
    endfor
endfunction

function! SearchSrcDir(directory)
    let src_dir = a:directory.'/src'
    if isdirectory(src_dir)
        let src_files = glob(src_dir . '/*', 0, 1)
        for file in src_files
            let file_name = fnamemodify(file, ':t')
	    if isdirectory(file)
		    let g:vendor_library_paths[file_name] = file
	    endif
        endfor
    else
        let subdirs = glob(a:directory . '/*', 1, 1)
        for subdir in subdirs
            call SearchSrcDir(subdir)
        endfor
    endif
endfunction

call ListSrcFilesInVendor()

function! GetFullPath(line)
	let lib_name = matchstr(a:line, '\w\+/')
	let lib_name = substitute(lib_name, '/', '', '')
	let returnable = {"found" : 0, "path": a:line }
	if has_key(g:vendor_library_paths, lib_name)
		let returnable["path"] = g:vendor_library_paths[lib_name]
		let returnable["found"] = 1
	endif
	return returnable
endfunction
