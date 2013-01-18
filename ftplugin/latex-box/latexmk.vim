" LaTeX Box latexmk functions


" <SID> Wrap {{{
function! s:GetSID()
	return matchstr(expand('<sfile>'), '\zs<SNR>\d\+_\ze.*$')
endfunction
let s:SID = s:GetSID()
function! s:SIDWrap(func)
	return s:SID . a:func
endfunction
" }}}


" dictionary of latexmk PID's (basename: pid)
let s:latexmk_running_pids = {}

" Set PID {{{
function! s:LatexmkSetPID(basename, pid)
	let s:latexmk_running_pids[a:basename] = a:pid
endfunction
" }}}

" Callback {{{
function! s:LatexmkCallback(basename, status)
	"let pos = getpos('.')
	if a:status
		echomsg "latexmk exited with status " . a:status
	else
		echomsg "latexmk finished"
	endif
	call remove(s:latexmk_running_pids, a:basename)
	call LatexBox_LatexErrors(g:LatexBox_autojump && a:status, a:basename)
	"call setpos('.', pos)
endfunction
" }}}

" Latexmk {{{
function! LatexBox_Latexmk(force)

	let basename = LatexBox_GetTexBasename(1)

	let l:options = '-' . g:LatexBox_output_type . ' -quiet ' . g:LatexBox_latexmk_options
	if a:force
		let l:options .= ' -g'
	endif
	" let l:options .= " -e '$pdflatex =~ s/ / -file-line-error /'"
	let l:options .= "'-file-line-error'"

	" wrap width in log file
	let max_print_line = 2000

	" set environment
	if match(&shell, '/tcsh$') >= 0
		let l:env = 'setenv max_print_line ' . max_print_line . '; '
	else
		let l:env = 'max_print_line=' . max_print_line
	endif

	" latexmk command
	let cmd = 'cd ' . shellescape(LatexBox_GetTexRoot()) . ' ; ' . l:env .
				\ ' pdflatex ' . l:options	. ' ' . shellescape(LatexBox_GetMainTexFile())

	execute '! ( ( ' . cmd . ' ) ; ) '
	if !has("gui_running")
		redraw!
	endif
endfunction
" }}}

" LatexErrors {{{
" LatexBox_LatexErrors(jump, [basename])
function! LatexBox_LatexErrors(jump, ...)
	if a:0 >= 1
		let log = a:1 . '.log'
	else
		let log = LatexBox_GetLogFile()
	endif

	if (a:jump)
		execute 'cfile ' . fnameescape(log)
	else
		execute 'cgetfile ' . fnameescape(log)
	endif
endfunction
" }}}

" Commands {{{
command! -buffer -bang	Latexmk				call LatexBox_Latexmk(<q-bang> == "!")
command! -buffer      	LatexErrors			call LatexBox_LatexErrors(1)
command! -buffer      	LatexErrors2			call LatexBox_LatexErrors2(1)
" }}}

function! LatexBox_LatexErrors2(jump, ...)
	call s:SetLatexEfm()
	let a = Tex_CompileLatex()
	let errlist = Tex_GetErrorList()
	cclose
	cwindow
endfunction




" Tex_GetErrorList: returns vim's clist {{{
" Description: returns the contents of the error list available via the :clist
"              command.
function! Tex_GetErrorList()
	let _a = @a
	redir @a | silent! clist | redir END
	let errlist = @a
	let @a = _a

	if errlist =~ 'E42: '
		let errlist = ''
	endif
	echo errlist
	return errlist
endfunction " }}}


" Tex_CompileLatex: compiles the present file. {{{
" Description:
function! Tex_CompileLatex()
	if &ft != 'tex'
		echo "calling Tex_RunLaTeX from a non-tex file"
		return
	end

	" close any preview windows left open.
	pclose!

	let s:origdir = fnameescape(getcwd())

	let mainfname = 'report.tex'

	let escChars = '{}\'
	let current_compiler = 'pdflatex'
	" TODO - Put the vimlatex binary in a variable (why not include it the plugin??)
	let &l:makeprg =  '/home/jtrindade/vim/bundle/vimlatex/vimlatex ' . current_compiler . ' ' . '"\nonstopmode \input{$*}"'
	exec 'make! '.mainfname
	redraw!

	exe 'cd '.s:origdir
endfunction " }}}

function! <SID>SetLatexEfm()

	let g:Tex_ShowallLines = 0
	let pm = ( g:Tex_ShowallLines == 1 ? '+' : '-' )

	set efm=
	" remove default error formats that cause issues with revtex, where they
	" match version messages
	" Reference: http://bugs.debian.org/582100
	set efm-=%f:%l:%m
	set efm-=%f:%l:%c:%m

	" if !g:Tex_ShowallLines
	" 	call s:IgnoreWarnings()
	" endif

	set efm+=%E!\ LaTeX\ %trror:\ %m
	set efm+=%E!\ %m
	set efm+=%E%f:%l:\ %m

	set efm+=%+WLaTeX\ %.%#Warning:\ %.%#line\ %l%.%#
	set efm+=%+W%.%#\ at\ lines\ %l--%*\\d
	set efm+=%+WLaTeX\ %.%#Warning:\ %m

	exec 'set efm+=%'.pm.'Cl.%l\ %m'
	exec 'set efm+=%'.pm.'Cl.%l\ '
	exec 'set efm+=%'.pm.'C\ \ %m'
	exec 'set efm+=%'.pm.'C%.%#-%.%#'
	exec 'set efm+=%'.pm.'C%.%#[]%.%#'
	exec 'set efm+=%'.pm.'C[]%.%#'
	exec 'set efm+=%'.pm.'C%.%#%[{}\\]%.%#'
	exec 'set efm+=%'.pm.'C<%.%#>%m'
	exec 'set efm+=%'.pm.'C\ \ %m'
	exec 'set efm+=%'.pm.'GSee\ the\ LaTeX%m'
	exec 'set efm+=%'.pm.'GType\ \ H\ <return>%m'
	exec 'set efm+=%'.pm.'G\ ...%.%#'
	exec 'set efm+=%'.pm.'G%.%#\ (C)\ %.%#'
	exec 'set efm+=%'.pm.'G(see\ the\ transcript%.%#)'
	exec 'set efm+=%'.pm.'G\\s%#'
	exec 'set efm+=%'.pm.'O(%*[^()])%r'
	exec 'set efm+=%'.pm.'P(%f%r'
	exec 'set efm+=%'.pm.'P\ %\\=(%f%r'
	exec 'set efm+=%'.pm.'P%*[^()](%f%r'
	exec 'set efm+=%'.pm.'P(%f%*[^()]'
	exec 'set efm+=%'.pm.'P[%\\d%[^()]%#(%f%r'
	" if g:Tex_IgnoreUnmatched && !g:Tex_ShowallLines
	" 	set efm+=%-P%*[^()]
	" endif
	exec 'set efm+=%'.pm.'Q)%r'
	exec 'set efm+=%'.pm.'Q%*[^()])%r'
	exec 'set efm+=%'.pm.'Q[%\\d%*[^()])%r'
	" if g:Tex_IgnoreUnmatched && !g:Tex_ShowallLines
	" 	set efm+=%-Q%*[^()]
	" endif
	" if g:Tex_IgnoreUnmatched && !g:Tex_ShowallLines
	" 	set efm+=%-G%.%#
	" endif

endfunction 
" vim:fdm=marker:ff=unix:noet:ts=4:sw=4
