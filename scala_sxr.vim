" Vim plugin to annotate Scala files with type information.

" Save compatibility options to restore them at the end of the script.
let s:save_cpo = &cpo
" Use line-continuation within the script
set cpo&vim

" Only do this when not done yet for this buffer
if exists("b:did_ftplugin")
	finish
endif
let b:did_ftplugin = 1

let b:autodetect = !exists("g:sxr_disable_autodetect")

if !exists("*s:AutodetectDirs")
	" Try to autodetect source and output directories from the currently open
	" file.
	" Updates b:sxr_scala_dir and b:sxr_output_dir, returns a boolean indicating
	" if both directories are set after execution.
	function s:AutodetectDirs()
		let result = 1
		" Find an 'src' dir above the file
		" Note: requires vim to be compiled with the +file_in_path option
		let src_dir = finddir("src", b:scala_file . ";")
		if strlen(src_dir) > 0
			if !exists("b:sxr_scala_dir")
				" Find a 'scala' dir below src
				let b:sxr_scala_dir = finddir("scala", src_dir . "**")
				if strlen(b:sxr_scala_dir) == 0
					unlet b:sxr_scala_dir
				endif
			endif
			if !exists("b:sxr_output_dir")
				" Find a 'classes.sxr' dir below src's parent
				let b:sxr_output_dir = finddir("classes.sxr", src_dir . "/../**")
				if strlen(b:sxr_output_dir) == 0
					unlet b:sxr_output_dir
				endif
			endif
		endif
		if !exists("b:sxr_scala_dir")
			echo "Could not autodetect scala directory."
			let result = 0
		endif
		if !exists("b:sxr_output_dir")
			echo "Could not autodetect SXR output directory."
			let result = 0
		endif
		return result
	endfunction
endif
if !exists("*s:SetDirs")
	" Sets the source and output directories according to the autodetect mode
	" Returns a boolean indicating success or failure.
	function s:SetDirs()
		if b:autodetect
			return s:AutodetectDirs()
		else
			let result = 1
			if !exists("b:sxr_scala_dir")
				if !exists("g:sxr_scala_dir")
					echo "In manual mode, sxr_scala_dir must be set."
					let result = 0
				else
					let b:sxr_scala_dir = g:sxr_scala_dir
				endif
			endif
			if !exists("b:sxr_output_dir")
				if !exists("g:sxr_output_dir")
					echo "In manual mode, sxr_output_dir must be set."
					let result = 0
				else
					let b:sxr_output_dir = g:sxr_output_dir
				endif
			endif
			return result
		endif
	endfunction
endif

" Absolute, UNIX-style path of the file in this buffer
let b:scala_file = expand("%:p:gs?\\?/?")

if !exists("*s:GetSxrFile")
	" Computes the path of the SXR file corresponding to the current source
	" file, and store its path in the buffer variable b:sxr_file
	" Returns 1 if the function succeeded, 0 otherwise.
	function s:GetSxrFile()
		" If the directories were set manually, we still need to check their
		" existence
		let scala_dir_abs = fnamemodify(b:sxr_scala_dir, ":p:gs?\\?/?")
		if !isdirectory(scala_dir_abs)
			echo "Invalid directory : " . scala_dir_abs . ". Set the sxr_scala_dir variable."
			unlet b:sxr_scala_dir
			unlet! b:sxr_file
			return 0
		endif
		let output_dir_abs = fnamemodify(b:sxr_output_dir, ":p:gs?\\?/?")
		if !isdirectory(output_dir_abs)
			echo "Invalid directory : " . output_dir_abs . ". Set the sxr_output_dir variable."
			unlet b:sxr_output_dir
			unlet! b:sxr_file
			return 0
		endif

		if match(b:scala_file, scala_dir_abs) == 0
			let b:sxr_file = substitute(b:scala_file, scala_dir_abs, output_dir_abs, "") . ".txt"
			return 1
		else
			echo b:scala_file . " is not in the directory " . scala_dir_abs . ". Set the sxr_scala_dir variable."
			unlet b:sxr_scala_dir
			unlet! b:sxr_file
			return 0
		endif
	endfunction
endif

if !exists("*s:Load")
	" Loads the annotation data and stores it in the buffer variable b:sxr_data
	" Returns 1 if the function succeeded, 0 otherwise.
	function s:Load()
		if !(exists("b:sxr_scala_dir") && exists("b:sxr_output_dir")) && !s:SetDirs()
			return 0
		endif
		if !exists("b:sxr_file") && !s:GetSxrFile()
			return 0
		endif
		if !filereadable(b:sxr_file)
			echo b:sxr_file . " does not exist or can't be read. Check the value of sxr_output_dir."
			return 0
		endif
		" Load data if not cached or stale
		if !exists("b:last_loaded") || getftime(b:sxr_file) > b:last_loaded
			let b:sxr_data = readfile(b:sxr_file)
			let b:last_loaded = getftime(b:sxr_file)
		endif
		return 1
	endfunction
endif

if !exists("*s:GetSxrData")
	" Retrieves a token (identified by its index) from the line corresponding to
	" the current offset in the SXR data file.
	" Returns "default" if the data does not exist.
	function s:GetSxrData(index, default)
		" Note: requires vim to be compiled with the +byte_offset option
		let offset = line2byte(line(".")) + col(".") - 2

		for line in b:sxr_data
			let matches = matchlist(line, '\(\d\+\)\t\(\d\+\)\t\(.*\)\t\(.*\)')
			if get(matches, 1, -1) > offset
				" Current line defines a token starting after the current offset,
				" no match
				return a:default
			elseif offset <= get(matches, 2, -1)
				" Current line defines a token containing the current offset,
				" match
				return get(matches, a:index, a:default)
			endif
		endfor
		" Tried all lines, no match
		return a:default
	endfunction
endif

if !exists("*s:Annotate")
	" Echoes the type annotation for the current cursor position
	function s:Annotate()
		if !s:Load()
			return
		endif
		echo s:GetSxrData(3, "No annotation here.")
	endfunction
endif

if !exists("*s:SetTags")
	" Adds the tag file for the current buffer to the global tags variable
	function s:SetTags()
		execute "set tags+=" . findfile("tags", b:sxr_output_dir)
	endfunction
endif

if !exists("*s:JumpTo")
	" Jumps to the declaration of the symbol at the current position
	function s:JumpTo()
		if !s:Load()
			return
		endif
		let tag_name = s:GetSxrData(4, "")
		if strlen(tag_name) == 0
			echo "No link here."
		else
			" Set the tags each time, to handle an eventual change of
			" sxr_output_dir
			call s:SetTags()
			execute "tag " . tag_name
		endif
	endfunction
endif



" KEY MAPPINGS
" Gives the user a chance to disable mappings
if !exists("no_plugin_maps") && !exists("no_scala_maps")
	" Mapping for Annotate
	" Gives the user a chance to use a different mapping
	if !hasmapto("<Plug>Annotate")
		map <silent><buffer><unique> <F2> <Plug>Annotate
	endif
	noremap <silent><buffer><unique> <Plug>Annotate :call <Sid>Annotate()<CR>

	" Mapping for JumpTo
	if !hasmapto("<Plug>JumpTo")
		" No <unique>, we are purposedly remapping an existing shortcut
		map <silent><buffer> <C-]> <Plug>JumpTo
	endif
	map <silent><buffer><unique> <Plug>JumpTo :call <Sid>JumpTo()<CR>
endif



" Restore compatibility options
let &cpo = s:save_cpo
