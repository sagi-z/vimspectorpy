
" temporarily change compatible option
let s:save_cpo = &cpo
set cpo&vim

" Registered implementations for window launchers (maps strings to function refeences)
let g:vimspectorpy#imps = {}

" The chosen launcher of windows (tmux is selected automatically if under $TMUX)
if !exists("g:vimspectorpy#launcher") || empty(g:vimspectorpy#launcher)
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
function! vimspectorpy#xterm_launcher(cmd)
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
let g:vimspectorpy#imps["xterm"] = function("vimspectorpy#xterm_launcher")


" This is a simple implementation for 'rxvt' as a launcher in window.
" To add another launcher for 'a:cmd' in a window follow this simple guide:
" Make sure that 'cmd' is successful or throw the error messages it generated
" as a string.
function! vimspectorpy#rxvt_launcher(cmd)
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
let g:vimspectorpy#imps["rxvt"] = function("vimspectorpy#rxvt_launcher")

let s:shell_error = 0
let s:system_running = 0
function! s:SystemDone(msg, exitval)
    let s:shell_error = a:exitval
    let s:system_running = 0
endfunction

function! vimspectorpy#systemlist(cmd, close_on_error=0)
    let s:shell_error = 0
    echom a:cmd
    let buf = term_start(a:cmd, {"exit_cb": funcref("s:SystemDone")})
    let s:system_running = 1
    while s:system_running == 1
        call term_wait(buf)
    endwhile
    if s:shell_error
        if a:close_on_error
            exe "bdel " . buf
        endif
    else
        exe "bdel " . buf
    endif
    let lines = getbufline(buf, 1, "$")
    return lines
endfunction

function! vimspectorpy#update()
    if stridx(g:vimspectorpy_venv, g:vimspectorpy_home) != 0
        throw "Please update your own directory manually (" . g:vimspectorpy_venv . ")"
    endif
    call mkdir(g:vimspectorpy_venv, "p")
    call vimspectorpy#systemlist(["python", "-m", "venv", "--clear", g:vimspectorpy_venv])
    if s:shell_error
        throw "vimspectorpy#update failed to create a virtualenv for ipython and debugpy"
    endif
    call vimspectorpy#systemlist(["sh", "-c", "source " . g:vimspectorpy_venv . "/bin/activate && pip install -U ipython debugpy"])
    if s:shell_error
        throw "vimspectorpy#update failed to install/update ipython and debugpy"
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
    call vimspectorpy#systemlist(["/bin/cp", g:vimspectorpy_home . "/vimspectorpy.json", config_dir])
    if s:shell_error
        throw "vimspectorpy#update failed to copy vimspectorpy.json"
    endif
endfunction


" restore compatible option
let &cpo = s:save_cpo
unlet s:save_cpo

