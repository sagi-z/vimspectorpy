
" temporarily change compatible option
let s:save_cpo = &cpo
set cpo&vim

" Registered implementations for window launchers (maps strings to function references)
let g:vimspectorpy#imps = {}

" Allow a user prefix for commands
if ! exists("g:vimspectorpy#cmd_prefix")
    let g:vimspectorpy#cmd_prefix = ""
endif

if ! exists("g:vimspectorpy#tmux#split")
    let g:vimspectorpy#tmux#split = "v"
endif
if ! exists("g:vimspectorpy#tmux#size")
    let g:vimspectorpy#tmux#size = 10
endif

function! vimspectorpy#warn(msg)
    echohl WarningMsg | echo "vimspectorpy: " . a:msg | echohl None
endfunction


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

" Below are the implementation for some window launchers.
" To add another launcher for 'a:cmd' in a window follow this simple guide:
" Make sure that 'a:cmd' is successful without blocking and invoke success_cb()
" or failure_cb(cmd_output). See examples below.
let g:vimspectorpy#imps["tmux"] = function("vimspectorpy#tmux_launcher")
let g:vimspectorpy#imps["xterm"] = function("vimspectorpy#xterm_launcher")
let g:vimspectorpy#imps["rxvt"] = function("vimspectorpy#rxvt_launcher")


function! vimspectorpy#tmux_launcher(cmd, success_cb, failure_cb)
    let base_err_file = "/tmp/vimspectorpy-tmux-err." . getpid()
    for f in glob(base_err_file . "/*" ,1 ,1)
        call delete(f)
    endfor
    let cmd = "tmux split-window -l ". g:vimspectorpy#tmux#size ." -" . g:vimspectorpy#tmux#split .
                \" -d -P -F '#{pane_id}' sh -c '". a:cmd .
                \" || tmux capture-pane -S - -E - -p -t $TMUX_PANE > " . base_err_file . ".${TMUX_PANE}'"
    let pane = trim(system(cmd))
    if v:shell_error
        return vimspectorpy#warn("tmux failed :" . pane)
    endif
    let err_file = base_err_file . "." . pane
    " Check success/failure after 2 seconds and continue flow there
    call timer_start(2000, funcref('s:TmuxCmdChecker', [err_file, a:success_cb, a:failure_cb]))
endfunction


function s:TmuxCmdChecker(err_file, success_cb, failure_cb, timer)
    if filereadable(a:err_file)
        let errs=system('cat ' . a:err_file)
        call delete(a:err_file)
        let CB = a:failure_cb
        call CB(errs)
    else
        let CB = a:success_cb
        call CB()
    endif
endfunction


function! vimspectorpy#xterm_launcher(cmd, success_cb, failure_cb)
    let err_file = "/tmp/vimspectorpy-xterm-err." . getpid()
    if filereadable(err_file)
        call delete(err_file)
    endif
    let out = system("xterm -l -lf " . err_file . " -e sh -c '" . a:cmd .  " || echo VIMSPECTORPY_FAIL' &")
    if v:shell_error
        return vimspectorpy#warn("xterm failed :" . out)
    endif
    " Check success/failure after 2 seconds and continue flow there
    call timer_start(2000, funcref('s:XtermCmdChecker', [err_file, a:success_cb, a:failure_cb]))
endfunction


function s:XtermCmdChecker(err_file, success_cb, failure_cb, timer)
    let errs=trim(system('cat ' . a:err_file))
    call delete(a:err_file)
    if match(errs, 'VIMSPECTORPY_FAIL') != -1
        let CB = a:failure_cb
        call CB(errs)
    else
        let CB = a:success_cb
        call CB()
    endif
endfunction


function! vimspectorpy#rxvt_launcher(cmd, success_cb, failure_cb)
    let err_file = "/tmp/vimspectorpy-rxvt-err." . getpid()
    if filereadable(err_file)
        call delete(err_file)
    endif
    let out = system("rxvt -xrm 'URxvt.print-pipe: cat > " . err_file . "' -e sh -c '". a:cmd .
                \' || (iPrtSc="$(echo -ne "\033[i")" && echo -n "$PrtSc")' . "' &")
    if v:shell_error
        return vimspectorpy#warn("rxvt failed :" . out)
    endif
    " Check success/failure after 2 seconds and continue flow there
    call timer_start(2000, funcref('s:RxvtCmdChecker', [err_file, a:success_cb, a:failure_cb]))
endfunction


function s:RxvtCmdChecker(err_file, success_cb, failure_cb, timer)
    if filereadable(a:err_file)
        let errs=trim(system('cat ' . a:err_file))
        call delete(a:err_file)
        let CB = a:failure_cb
        call CB(errs)
    else
        let CB = a:success_cb
        call CB()
    endif
endfunction



" This installs/updates this plugin's external dependencies:
" * A virtualenv with ipython and debugpy.
" * Some default configurations for vimspector python filetype.
function! vimspectorpy#update()
    if exists("g:vimspector_home")
        let vimspector_home = g:vimspector_home
    else
        let vimspector_home = fnamemodify(g:vimspectorpy_home . "/../vimspector", ":p")
    endif
    if ! isdirectory(vimspector_home)
        return vimspectorpy#warn("Please install vimspector first and then execute :VimspectorpyUpdate")
    endif
    try
        exe 'VimspectorUpdate debugpy'
    catch
        return vimspectorpy#warn("Please enable the vimspector plugin first and then execute :VimspectorpyUpdate")
    endtry
    if stridx(g:vimspectorpy_venv, g:vimspectorpy_home) != 0
        return vimspectorpy#warn("Please update your own VIRTUAL_ENV manually (pip3 install -U ipython debugpy)")
    endif
    let virtualenv = "python3 -m venv"
    call mkdir(g:vimspectorpy_venv, "p")
    let out = system(virtualenv . " --clear " . g:vimspectorpy_venv)
    if v:shell_error
        throw "vimspectorpy#update failed to create a virtualenv for ipython and debugpy: " . out
    endif
    let out = system("source " . g:vimspectorpy_venv . "/bin/activate && pip3 install -U ipython debugpy")
    if v:shell_error
        throw "vimspectorpy#update failed to install/update ipython and debugpy: " . out
    endif
    let base_config_dir = ""
    for base_config_dir in glob(vimspector_home . "/configurations/*", 1, 1)
        if isdirectory(base_config_dir)
            break
        endif
    endfor
    if ! isdirectory(base_config_dir)
        throw "vimspectorpy#update failed to find vimspector configurations directory"
    endif
    let config_dir = base_config_dir . "/python"
    call mkdir(config_dir, "p")
    let out = system("/bin/cp " . g:vimspectorpy_home . "/vimspectorpy.json " . config_dir)
    if v:shell_error
        throw "vimspectorpy#update failed to copy vimspectorpy.json: " . out
    endif
    let config_dir = base_config_dir . "/vimspectorpy"
    call mkdir(config_dir, "p")
    let out = system("/bin/cp " . g:vimspectorpy_home . "/__vimspectorpy.json " . config_dir)
    if v:shell_error
        throw "vimspectorpy#update failed to copy __vimspectorpy.json: " . out
    endif
endfunction


" restore compatible option
let &cpo = s:save_cpo
unlet s:save_cpo
