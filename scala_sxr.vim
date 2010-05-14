" Vim plugin to annotate Scala files with type information.


" Save compatibility options to restore them at the end of the script.
let s:save_cpo = &cpo
" Use line-continuation within the script
set cpo&vim

" Gives the user a chance to disable loading this plugin
if exists("loaded_sxr")
	finish
endif
let loaded_sxr = 1


" The directory containing the scala sources (set to default if not defined)
" Windows : the path can use either forward or slashes, but the drive letter
"           (if present) MUST be uppercase.
if (!exists("sxr_scala_dir"))
	let sxr_scala_dir = 'D:/temp/test/scala'
endif
" The directory where SXR outputs the type information for each source file
if (!exists("sxr_output_dir"))
	let sxr_output_dir = 'D:/temp/test/output.sxr'
endif

" The message displayed when no annotation is available for the current offset
let s:no_annotation = "No annotation here..."

" Computes the path of the SXR file corresponding to the current source file,
" and store its path in the buffer variable b:sxr_file
" Returns 1 if the function succeeded, 0 otherwise.
function GetSxrFile()
	" Make the path absolute and UNIX-style
	let s:scala_dir_abs = fnamemodify(g:sxr_scala_dir, ":p:gs?\\?/?")
	if (!isdirectory(s:scala_dir_abs))
		echo "Invalid directory : " . s:scala_dir_abs . ". Set the sxr_scala_dir variable."
		unlet! b:sxr_file
		return 0
	endif
	let s:output_dir_abs = fnamemodify(g:sxr_output_dir, ":p:gs?\\?/?")
	if (!isdirectory(s:output_dir_abs))
		echo "Invalid directory : " . s:output_dir_abs . ". Set the sxr_output_dir variable."
		unlet! b:sxr_file
		return 0
	endif

	if (match(b:scala_file, s:scala_dir_abs) == 0)
		let b:sxr_file = substitute(b:scala_file, s:scala_dir_abs, s:output_dir_abs, "")
		let b:sxr_file = substitute(b:sxr_file, "\.scala$", ".sxr", "")
		return 1
	else
		echo b:scala_file . " is not in the directory " . s:scala_dir_abs . ". Set the sxr_scala_dir variable."
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
		let s:matches = matchlist(line, '\(\d\+\)\s\(\d\+\)\s\(.*\)')
		if (get(s:matches, 1, -1) > a:offset)
			return s:no_annotation
		elseif (a:offset <= get(s:matches, 2, -1))
			return get(s:matches, 3, s:no_annotation)
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

	if (!exists("b:sxr_file"))
		if (GetSxrFile() == 0)
			return
		endif
	endif

	if (Load() == 0)
		return
	endif

	" Note: requires vim to be compiled with the +byte_offset option
	let s:offset = line2byte(line(".")) + col(".")

	echo GetAnnotation(s:offset)
endfunction

map <C-I> :call Annotate()<CR>
imap <C-I> <ESC> <C-I>

" Restore compatibility options
let &cpo = s:save_cpo
