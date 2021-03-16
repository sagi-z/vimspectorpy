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
let s:debugpy_port=6789


function! s:AssertCanWork()
    if ! isdirectory(g:vimspectorpy_venv . '/lib')
        throw "Please execute VimspectorpyUpdate first"
    endif
    if has_key(g:vimspectorpy#imps, g:vimspectorpy#launcher)
        throw "No registered implementation for window launcher '" . g: vimspectorpy#launcher . "'"
    endif
endfunction


function! s:Ipython()
    call AssertCanWork()
    let cmd = "export PYTHONPATH=" . g:vimspectorpy_venv . " && python `which ipython`"
    let cb = g:vimspectorpy#imps[g:vimspectorpy#launcher]
    call cb(cmd)
endfunction


function! s:IpythonDebugpy()
    call AssertCanWork()
    let cb = g:vimspectorpy#imps[g:vimspectorpy#launcher]
    while 1
        let cmd = "export PYTHONPATH=" . g:vimspectorpy_venv . " && python -m debugpy --listen localhost:"
                    \. s:debugpy_port .  " `which ipython`"
        try
            call cb(cmd)
            break
            catch /Address already in use/
                let s:debugpy_port += 1
        endtry
    endwhile
endfunction


function! s:IpythonDebugpyWithAttach()
    exe "IpythonDebugpy"
    exe "IpythonAttach" 
endfunction


if !exists(":Ipython")
    command! Ipython call s:Ipython()
endif

if !exists(":IpythonDebugpy")
    command! VSIpythonDebugpy  call s:IpythonDebugpy()
endif

if !exists(":IpythonAttach")
    command! IpythonAttach call vimspector#LaunchWithSettings( #{ configuration: 'attach2port', port: s:debugpy_port})
endif

if !exists(":IpythonDA")
    command! IpythonDA call s:IpythonDebugpyWithAttach()
endif

if !exists(":VimspectorpyUpdate")
    command! VimspectorpyUpdate call g:vimspectorpy#update()
endif

" restore compatible option
let &cpo = s:save_cpo
unlet s:save_cpo

