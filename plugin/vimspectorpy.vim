" Vimspector add ons for python
" Last Change:	2021 March 15
" Maintainer:	Sagi Zeevi <sagi.zeevi@gmail.com>
" License:      MIT


if exists("g:loaded_vimspector_python")
    finish
endif
let g:loaded_vimspector_python = 1

" temporarily change compatible option
let s:save_cpo = &cpo
set cpo&vim

let g:vimspectorpy_home = expand( '<sfile>:p:h:h' )
if ! exists("g:vimspectorpy_venv")
    let g:vimspectorpy_venv=g:vimspectorpy_home . "/venv"
endif

let s:debugpy_port = 6789
let s:sessions = {}


function! s:PythonPathStr()
    return glob(g:vimspectorpy_venv . '/lib/python*/site-packages')
endfunction

function! s:AssertCanWork()
    if ! isdirectory(g:vimspectorpy_venv . '/lib')
        throw "Please execute VimspectorpyUpdate first"
    endif
    if ! has_key(g:vimspectorpy#imps, g:vimspectorpy#launcher)
        throw "No registered implementation for window launcher '" . g:vimspectorpy#launcher . "'"
    endif
endfunction


function! s:DebugpyLaunchSuccess(name, port, attach)
    let s:sessions[a:name] = a:port
    if a:attach
        call s:DebugpyAttach(a:name)
    endif
endfunction

function! s:DebugpyLaunchFailure(name, port, cmd, imp, attach, errs)
    if match(a:errs, "Address already in use") != -1
        let cmd = substitute(a:cmd, 'localhost:' . a:port, 'localhost:' . s:debugpy_port, "")
        let Imp = a:imp
        let SuccessCB = funcref('s:DebugpyLaunchSuccess', [a:name, s:debugpy_port, a:attach])
        let FailureCB = funcref('s:DebugpyLaunchFailure', [a:name, s:debugpy_port, cmd, Imp, a:attach])
        call Imp(cmd, SuccessCB, FailureCB)
        let s:debugpy_port += 1  " For next attempts
    else
        echoerr "debugpy failed to launch: " . a:errs
    endif
endfunction

function! s:DebugpyLaunch(cmd, args, name, default_name, use_ext_venv, wait, attach)
    call s:AssertCanWork()
    if empty(a:name)
        let name = a:default_name
    else
        let name = a:name
    endif
    if empty(name)
        throw "Must get a name to assign to this session"
    endif
    let Imp = g:vimspectorpy#imps[g:vimspectorpy#launcher]
    if a:use_ext_venv
        let use_ext_venv="export PYTHONPATH=" . s:PythonPathStr() . " && "
    else
        let use_ext_venv=""
    endif
    if a:wait
        let wait="--wait-for-client"
    else
        let wait=""
    endif
    let cmd = use_ext_venv . "python -m debugpy " . wait .  " --configure-subProcess False "
                \. "--listen localhost:" . s:debugpy_port .  " `which " . a:cmd . "` "
                \. a:args .  " && read -p PRESS\\ ENTER\\ TO\\ CLOSE REPLY"
    let SuccessCB = funcref('s:DebugpyLaunchSuccess', [name, s:debugpy_port, a:attach])
    let FailureCB = funcref('s:DebugpyLaunchFailure', [name, s:debugpy_port, cmd, Imp, a:attach])
    call Imp(cmd, SuccessCB, FailureCB)
    let s:debugpy_port += 1  " For next attempts
endfunction


function! s:DebugpyAttach(name, default_name=v:none)
    if empty(a:name)
        let name = a:default_name
    else
        let name = a:name
    endif
    if empty(name)
        throw "Must get a session name to connect to"
    endif
    if ! has_key(s:sessions, name)
        throw "There is no session with name " . name
    endif
    call vimspector#LaunchWithSettings( #{ configuration: 'attach2port', port: s:sessions[name]})
endfunction


function! s:Pytest(args)
    call s:DebugpyLaunch('pytest', a:args, 'Pytest', v:none, 1, 1, 1)
endfunction


function! s:Nosetests(args)
    call s:DebugpyLaunch('nosetests', a:args, 'Nosetests', v:none, 1, 1, 1)
endfunction


if !exists(g:vimspectorpy#cmd_prefix . ":Pyconsole")
    exe "command! -nargs=? " . g:vimspectorpy#cmd_prefix . "Pyconsole call s:DebugpyLaunch('ipython', '',  <q-args>, 'Pyconsole', 1, 0, 0)"
endif

if !exists(g:vimspectorpy#cmd_prefix . ":Pyattach")
    exe "command! -nargs=? " . g:vimspectorpy#cmd_prefix . "Pyattach call s:DebugpyAttach(<q-args>, 'Pyconsole')" 
endif

if !exists(g:vimspectorpy#cmd_prefix . ":Pytest")
    exe "command! -nargs=* " . g:vimspectorpy#cmd_prefix . "Pytest call s:Pytest(<q-args>)"
endif

if !exists(g:vimspectorpy#cmd_prefix . ":PytestThis")
    exe "command! -nargs=* " . g:vimspectorpy#cmd_prefix . "PytestThis call s:Pytest(<q-args> . ' ' . expand('%'))"
endif

if !exists(g:vimspectorpy#cmd_prefix . ":Nosetests")
    exe "command! -nargs=* " . g:vimspectorpy#cmd_prefix . "Nosetests call s:Nosetests(<q-args>)"
endif

if !exists(g:vimspectorpy#cmd_prefix . ":NosetestsThis")
    exe "command! -nargs=* " . g:vimspectorpy#cmd_prefix . "NosetestsThis call s:Nosetests(<q-args> . ' ' . expand('%'))"
endif

if !exists(":VimspectorpyUpdate")
    command! VimspectorpyUpdate call vimspectorpy#update()
endif

" restore compatible option
let &cpo = s:save_cpo
unlet s:save_cpo

