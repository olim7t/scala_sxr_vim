" Vim plugin to annotate Scala files with type information.

" Next two blocks per guidelines of VIM help paragraph 41.11:

" Save compatibility options to restore them at the end of the script.
let s:save_cpo = &cpo
" Use line-continuation within the script
set cpo&vim

" Gives the user a chance to disable loading this plugin
if exists("loaded_sxr")
	finish
endif
let loaded_sxr = 1



" The message displayed when no annotation is available for the current offset
let s:no_annotation = "No annotation here..."

" Try to autodetect source and/or output directories (if not manually set) from
" the currently open file.
" Updates g:sxr_scala_dir and/or g:sxr_output_dir, returns a boolean indicating if
" both directories are set after execution.
function AutodetectDirs()
	let result = 1
	" Find an 'src' dir above the file
	" Note: requires vim to be compiled with the +file_in_path option
	let src_dir = finddir("src", b:scala_file . ";")
	if (strlen(src_dir) > 0)
		if (!exists("g:sxr_scala_dir"))
			" Find a 'scala' dir below src
			let g:sxr_scala_dir = finddir("scala", src_dir . "**")
			if (strlen(g:sxr_scala_dir) > 0)
				echo "Autodetected Scala directory:\n   " . g:sxr_scala_dir
			else
				unlet g:sxr_scala_dir
			endif
		endif
		if (!exists("g:sxr_output_dir"))
			" Find a 'classes.sxrt' dir below src's parent
			let g:sxr_output_dir = finddir("classes.sxrt", src_dir . "/../**")
			if (strlen(g:sxr_output_dir) > 0)
				echo "Autodetected SXR output directory:\n   " . g:sxr_output_dir
			else
				unlet g:sxr_output_dir
			endif
		endif
	endif
	if (!exists("g:sxr_scala_dir"))
		echo "Could not autodetect scala directory. Please set manually (:let sxr_scala_dir = ...)"
		let result = 0
	endif
	if (!exists("g:sxr_output_dir"))
		echo "Could not autodetect SXR output directory. Please set manually (:let sxr_output_dir = ...)"
		let result = 0
	endif
	return result
endfunction

" Computes the path of the SXR file corresponding to the current source file,
" and store its path in the buffer variable b:sxr_file
" Returns 1 if the function succeeded, 0 otherwise.
function GetSxrFile()
	" Make the path absolute and UNIX-style
	let scala_dir_abs = fnamemodify(g:sxr_scala_dir, ":p:gs?\\?/?")
	if (!isdirectory(scala_dir_abs))
		echo "Invalid directory : " . scala_dir_abs . ". Set the sxr_scala_dir variable."
		unlet! b:sxr_file
		return 0
	endif
	let output_dir_abs = fnamemodify(g:sxr_output_dir, ":p:gs?\\?/?")
	if (!isdirectory(output_dir_abs))
		echo "Invalid directory : " . output_dir_abs . ". Set the sxr_output_dir variable."
		unlet! b:sxr_file
		return 0
	endif

	if (match(b:scala_file, scala_dir_abs) == 0)
		let b:sxr_file = substitute(b:scala_file, scala_dir_abs, output_dir_abs, "") . ".txt"
		return 1
	else
		echo b:scala_file . " is not in the directory " . scala_dir_abs . ". Set the sxr_scala_dir variable."
		unlet! b:sxr_file
		return 0
	endif
endfunction

" Loads the annotation data and store it in the buffer variable b:annotations
" Returns 1 if the function succeeded, 0 otherwise.
function Load()
	if (!filereadable(b:sxr_file))
		echo b:sxr_file . " does not exist or can't be read"
		return 0
	endif
	" Load data if not cached or stale
	if (!exists("b:last_loaded") || getftime(b:sxr_file) > b:last_loaded)
		let b:annotations = readfile(b:sxr_file)
		let b:last_loaded = getftime(b:sxr_file)
	endif
	return 1
endfunction

" Retrieves the annotation for a given offset, if it exists
function GetAnnotation(offset)
	for line in b:annotations
		let matches = matchlist(line, '\(\d\+\)\s\(\d\+\)\s\(.*\)')
		if (get(matches, 1, -1) > a:offset)
			return s:no_annotation
		elseif (a:offset <= get(matches, 2, -1))
			return get(matches, 3, s:no_annotation)
		endif
	endfor
	return s:no_annotation
endfunction

" Echoes the type annotation for the current cursor position
function Annotate()
	if (!exists("b:scala_file"))
		" Note: requires vim to be compiled with the +modify_fname option
		" (run 'vim --version' to check)
		let b:scala_file = expand("%:p:gs?\\?/?")
	endif
	if (!(exists("g:sxr_scala_dir") && exists("g:sxr_output_dir")) && !AutodetectDirs())
		return
	endif
	if (!exists("b:sxr_file") && !GetSxrFile())
		return
	endif
	if (!Load())
		return
	endif

	" Note: requires vim to be compiled with the +byte_offset option
	let offset = line2byte(line(".")) + col(".") - 2

	echo GetAnnotation(offset)
endfunction

map <C-I> :call Annotate()<CR>

" Restore compatibility options
let &cpo = s:save_cpo
