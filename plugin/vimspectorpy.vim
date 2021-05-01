" Vimspector add ons for python
" Last Change:	2021 May 01
" Maintainer:	Sagi Zeevi <sagi.zeevi@gmail.com>
" License:      MIT


if exists("g:loaded_vimspector_python")
    finish
endif
let g:loaded_vimspector_python = 1

" temporarily change compatible option
let s:save_cpo = &cpo
set cpo&vim

let s:vnone = ''

let g:vimspectorpy_home = expand( '<sfile>:p:h:h' )
if ! exists("g:vimspectorpy_venv")
    let g:vimspectorpy_venv=g:vimspectorpy_home . "/venv"
endif

let s:debugpy_port = 6789
let s:sessions = {}
let s:ft = s:vnone


function! s:PythonPathStr()
    return glob(g:vimspectorpy_venv . '/lib/python*/site-packages')
endfunction

function! s:AssertCanWork()
    if ! isdirectory(g:vimspectorpy_venv . '/lib')
        call vimspectorpy#warn("Please execute VimspectorpyUpdate first")
        return 0
    endif
    if ! has_key(g:vimspectorpy#imps, g:vimspectorpy#launcher)
        call vimspectorpy#warn("No registered implementation for window launcher '" . g:vimspectorpy#launcher . "'")
        return 0
    endif
    return 1
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
        call vimspectorpy#warn("debugpy failed to launch: " . trim(a:errs))
    endif
endfunction

function! s:DebugpyLaunch(cmd, args, name, default_name, use_ext_venv, wait, attach)
    if ! s:AssertCanWork()
        return
    endif
    if empty(a:name)
        let name = a:default_name
    else
        let name = a:name
    endif
    if empty(name)
        return vimspectorpy#warn("Must get a name to assign to this session")
    endif
    let Imp = g:vimspectorpy#imps[g:vimspectorpy#launcher]
    if a:use_ext_venv
        let use_ext_venv="export PYTHONPATH=" . s:PythonPathStr() . " && "
        let bin = g:vimspectorpy_venv . '/bin/' . a:cmd
        if ! executable(bin)
            let bin = exepath(a:cmd)
        endif
    else
        let use_ext_venv=""
        let bin = exepath(a:cmd)
    endif
    if ! executable(bin)
        return vimspectorpy#warn("'" . a:cmd . "' was not found")
    endif
    if a:wait
        let wait="--wait-for-client"
    else
        let wait=""
    endif
    let cmd = use_ext_venv . "python -m debugpy " . wait .  " --configure-subProcess False "
                \. "--listen localhost:" . s:debugpy_port .  " " . bin . " " .
                \. a:args .  " && read -p PRESS\\ ENTER\\ TO\\ CLOSE REPLY"
    let SuccessCB = funcref('s:DebugpyLaunchSuccess', [name, s:debugpy_port, a:attach])
    let FailureCB = funcref('s:DebugpyLaunchFailure', [name, s:debugpy_port, cmd, Imp, a:attach])
    call Imp(cmd, SuccessCB, FailureCB)
    let s:debugpy_port += 1  " For next attempts
endfunction


function! s:DebugpyAttach(name, ...)
    let default_name = s:vnone
	if a:0 >= 1
		let default_name = a:1
	endif
    if empty(a:name)
        let name = default_name
    else
        let name = a:name
    endif
    if empty(name)
        return vimspectorpy#warn("Must get a session name to connect to")
    endif
    if ! has_key(s:sessions, name)
        return vimspectorpy#warn("There is no session with name " . name)
    endif
    let s:ft = &l:ft
    let &l:ft = 'vimspectorpy'
    call vimspector#LaunchWithSettings( { 'configuration': 'attach2port', 'port': s:sessions[name]})
    " See s:CustomiseUI() for restoring the filetype to the buffer
endfunction


function! s:Pytest(args)
    call s:DebugpyLaunch('pytest', a:args, 'Pytest', s:vnone, 1, 1, 1)
endfunction


function! s:Nosetests(args)
    call s:DebugpyLaunch('nosetests', a:args, 'Nosetests', s:vnone, 1, 1, 1)
endfunction


augroup VimspectorpyUICustomization
    autocmd!
    autocmd User VimspectorUICreated call s:CustomiseUI()
augroup END

function! s:CustomiseUI()
    call win_gotoid(g:vimspector_session_windows.code)
    if s:ft isnot s:vnone
        let &l:ft = s:ft
        let s:ft = s:vnone
    endif
endfunction


" vim-test strategy
function! s:VimspectorpyStrategy(cmd)
    let i = match(a:cmd, ' ')
    if i == -1
        let cmd = a:cmd
        let args = ''
    else
        let cmd = trim(a:cmd[:i])
        let args = trim(a:cmd[i:])
    endif
    call s:DebugpyLaunch(cmd, args, 'vim-test', s:vnone, 1, 1, 1)
endfunction

if ! exists("g:test#custom_strategies")
    let g:test#custom_strategies = {'vimspectorpy': function('s:VimspectorpyStrategy')}
else
    let g:test#custom_strategies['vimspectorpy'] = function('s:VimspectorpyStrategy')
endif


if !exists(g:vimspectorpy#cmd_prefix . ":Pyconsole")
    exe "command! -nargs=? " . g:vimspectorpy#cmd_prefix . "Pyconsole call s:DebugpyLaunch('ipython', '',  <q-args>, 'Pyconsole', 1, 0, 0)"
endif

if !exists(g:vimspectorpy#cmd_prefix . ":Pyattach")
    exe "command! -nargs=? " . g:vimspectorpy#cmd_prefix . "Pyattach call s:DebugpyAttach(<q-args>, 'Pyconsole')" 
endif

if !exists(g:vimspectorpy#cmd_prefix . ":PytestD")
    exe "command! -nargs=* " . g:vimspectorpy#cmd_prefix . "PytestD call s:Pytest(<q-args>)"
endif

if !exists(g:vimspectorpy#cmd_prefix . ":PytestDThis")
    exe "command! -nargs=* " . g:vimspectorpy#cmd_prefix . "PytestDThis call s:Pytest(<q-args> . ' ' . expand('%'))"
endif

if !exists(g:vimspectorpy#cmd_prefix . ":NosetestsD")
    exe "command! -nargs=* " . g:vimspectorpy#cmd_prefix . "Nosetests call s:Nosetests(<q-args>)"
endif

if !exists(g:vimspectorpy#cmd_prefix . ":NosetestsDThis")
    exe "command! -nargs=* " . g:vimspectorpy#cmd_prefix . "NosetestsDThis call s:Nosetests(<q-args> . ' ' . expand('%'))"
endif

if !exists(":VimspectorpyUpdate")
    command! VimspectorpyUpdate call vimspectorpy#update()
endif

" restore compatible option
let &cpo = s:save_cpo
unlet s:save_cpo

