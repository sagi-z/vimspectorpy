
" temporarily change compatible option
let s:save_cpo = &cpo
set cpo&vim

" Registered implementations for window launchers (maps strings to function refeences)
let g:vimspectorpy#imps = {}

" The chosen launcher of windows (tmux is selected automatically if under $TMUX)
if !exists(g:vimspectorpy#launcher) || empty(g:vimspectorpy#launcher)
    let g:vimspectorpy#launcher = ""
    if has("gui_running")
        if executable("xterm")
            let g:vimspectorpy#launcher = "xterm"
        elseif executable("rxvt")
            let g:vimspectorpy#launcher = "rxvt"
        endif
    else
        if exists('$TMUX')
            let g:vimspectorpy#launcher = "tmux"
        endif
    endif
endif

" This is the implementation for TMUX as a launcher in a split window.
" To add another launcher for 'a:cmd' in a window follow this simple guide:
" Make sure that 'cmd' is successful  or throw the error messages it generated
" as a string.
function! vimspectorpy#tmux_launcher(cmd)
    let base_err_file = "/tmp/vimspectorpy-tmux-err." . getpid()
    for f in glob(base_err_file . "/*" ,1 ,1)
        delete(f)
    endfor
    let pane = trim(system("tmux split-window -l 10 -d -P -F '#{pane_id}' sh -c '". a:cmd .
                \" || tmux capture-pane -S - -E - -p -t $TMUX_PANE > " . base_err_file . ".${TMUX_PANE}'"))
    let errs_file = base_err_file . ipython_pane
    sleep 1
    if filereadable(errs_file)
        let errs=system('cat ' . errs_file)
        call delete(errs_file)
        throw errs
    endif
endfunction
let g:vimspectorpy#imps["tmux"] = function("vimspectorpy#tmux_launcher")


" This is a simple implementation for 'xterm' as a launcher in window.
" To add another launcher for 'a:cmd' in a window follow this simple guide:
" Make sure that 'cmd' is successful or throw the error messages it generated
" as a string.
function! vimspector#xterm_launcher(cmd)
    let err_file = "/tmp/vimspectorpy-xterm-err." . getpid()
    if filereadable(err_file)
        delete(err_file)
    endif
    call system("xterm xterm -l -lf " . err_file . " -e sh -c '" . a:cmd .  " || echo VIMSPECTORPY_FAIL' &")
    sleep 1
    if filereadable(errs_file)
        let errs=trim(system('cat ' . errs_file))
        call delete(errs_file)
        if match(errs, 'VIMSPECTORPY_FAIL')
            throw errs
        endif
    endif
endfunction
let g:vimspectorpy#imps["xterm"] = function("vimspector#xterm_launcher")


" This is a simple implementation for 'rxvt' as a launcher in window.
" To add another launcher for 'a:cmd' in a window follow this simple guide:
" Make sure that 'cmd' is successful or throw the error messages it generated
" as a string.
function! vimspector#rxvt_launcher(cmd)
    let err_file = "/tmp/vimspectorpy-rxvt-err." . getpid()
    if filereadable(err_file)
        delete(err_file)
    endif
    call system("rxvt -xrm 'URxvt.print-pipe: cat > " . err_file . "' -e sh -c '". a:cmd .
                \' || (iPrtSc="$(echo -ne "\033[i")" && echo -n "$PrtSc")' . "' &"))
    sleep 1
    if filereadable(errs_file)
        let errs=trim(system('cat ' . errs_file))
        call delete(errs_file)
        throw errs
    endif
endfunction
let g:vimspectorpy#imps["rxvt"] = function("vimspector#rxvt_launcher")


function! vimspectorpy#update()
    call mkdir(s:viminspectorpy_venv, "p")
    let out=system("python -m venv " . s:viminspectorpy_venv)
    if v:shell_error
        throw "vimspectorpy#update failed to create a virtualenv for ipython and debugpy: " . out
    endif
    let out=system("source " . s:viminspectorpy_venv . "/bin/activate && pip install -U ipython debugpy")
    if v:shell_error
        throw "vimspectorpy#update failed to install/update ipython and debugpy: " . out
    endif
    for config_dir in glob(g:vimspector_home . "/configurations/*", 1, 1)
        if isdirectory(config_dir)
            break
        endif
    endfor
    if ! isdirectory(config_dir)
        throw "vimspectorpy#update failed to find vimspector configurations directory"
    endif
    let config_dir = config_dir . "/python"
    call mkdir(config_dir, "p")
    let out=system("/bin/cp " . s:vimspector_python_home . "/vimspectorpy.json " . config_dir)
    if v:shell_error
        throw "vimspectorpy#update failed to copy vimspectorpy.json: " . out
    endif
endfunction


" restore compatible option
let &cpo = s:save_cpo
unlet s:save_cpo

