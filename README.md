# vimspectorpy - python default configurations for vimspector

## Description

Add some python customization to [vimspector]:

* Choose the correct python executable if in a VIRTUAL_ENV.
* Run pytest/nodetests for the project or test file.
* Debug the current file as a program.
* Launch ipython and attach a debugger to it to debug your code with vimspector
  (currently needs [tmux]).

![ipython example](ipython.gif "ipython console debug code")

## Install

### with plug.vim

`Plug 'sagi-z/vimspectorpy' {}`

Of course make sure [vimspector] is installed:

`Plug 'puremourning/vimspector'`

### Manual

* Install [vimspector].
* Clone this repository into your *~/.vim/plugin/* directory.
* From vim execute this command:

```vim
:VimspectorpyUpdate 
```

## Usage

### Vimspector new configurations

Next time you are on a python source and start a debug sesion (F5) you'll get
these options:

1. attach2port - attach to a port of a debugpy running on localhost (used
   internally by IpythonAttach).
2. debug this file - launch a debug session for the current file.
3. pytest - launch a debug session running pytest, breaking on your breakpoints.
4. pytest this test file - launch a debug session running pytest, breaking on
   your breakpoints, using the current file as  a test file.
5. nosetests - launch a debug session running nosetests, breaking on your breakpoints.
6. nosetests this test file - launch a debug session running nosetests,
   breaking on your breakpoints, using the current file as  a test file.

### ipython with vim breakpoints

These commands are availbale to you:

```vim
" ipython debug attach - start ipython in another window and start a debug
" session inside vim, breaking on breakpoints
:IpythonDA

" ipython debug - start ipython in another window with debugpy, but don't
" attach to it for now
:IpythonDebug

" ipython attach - start a debug session to the latest 'IpythonDebug'  window
" attaching to it now
:IpythonAttach
```

### other commands

```vim
" ipython - start ipython in another window without any debugger nor any plans
" to attach to it later.
:IpythonAttach

" update ipython and debugpy - upgrade them to latest versions
:VimspectorpyUpdate
```

## Configuration

For starting another window, Currently the 'ipython' will use [tmux]
automatically in a console and *xterm* in GUI.

You could choose *rxvt* or force *xterm* using:

```vim
let g:vimspectorpy#launcher = "rxvt"
```

### Advanced: Add a window launcher for *ipython*

It is simple enough to add support for other launchers - here is an 'rxvt' example:

```vim

" This is a sample implementation for 'rxvt' as a launcher in window.
" To add another launcher for 'a:cmd' in a window follow this simple guide:
" Make sure that 'cmd' is successful or throw the error messages it generated
" as a string.
function! Rxvt_launcher(cmd)
endfunction
let g:vimspectorpy#imps["rxvt"] = function("Rxvt_launcher")
```

### Advanced: Virtual env for *ipython* and *debugpy*

This plugin needs a place to take from *ipython* and *debugpy*. It handles this
AUTOMATICALLY in another directory where the plugin is instaleld. However if
you want to change this to your own VIRTUAL_ENV, do this:

```vim
" Do this only to use ipython and debugpy from your own VIRTUAL_ENV
if exists('$VIRTUAL_ENV')
    let g:viminspectorpy_venv=$VIRTUAL_ENV
endif
```

## License

MIT

[vimspector]: https://github.com/puremourning/vimspector
[tmux]:       https://github.com/tmux/tmux/wiki

