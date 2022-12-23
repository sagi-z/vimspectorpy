# vimspectorpy - python default configurations for vimspector

## Description

Being able to simply debug a piece of code with 'ipython' or set a breakpoint
in a *pytest/nose* is priceless. Also to use the correct python
environment for debugging automatically should be transparent.

This plugin adds some python customization to [vimspector]:

* Choose the correct python executable if in a VIRTUAL_ENV.
* Run pytest/nosetests for the project or test file, with breakpoints in
  [vimspector].
* Debug the current file as a program.
* Launch ipython and attach a debugger to it to debug your code with vimspector.
* Add a strategy to [vim-test] to allow running a test case in a debugger.

![Pyconsole example](Pyconsole.gif "ipython console debug your code with vimspector")

## Install

### with plug.vim in .vimrc

Of course make sure [vimspector] is installed:

`Plug 'puremourning/vimspector'`

And also add this:

`Plug 'sagi-z/vimspectorpy', { 'do': { -> vimspectorpy#update() } }`

Install and setup:

```vim
:PlugInstall 
:VimspectorpyUpdate 
```

### Manual

* Install [vimspector].
* Clone this repository into your *~/.vim/plugin/* directory.
* From vim execute this command:

```vim
:VimspectorpyUpdate 
```

## Uninstall

* Remove the relevant entries from your *.vimrc* if you used *plug.vim*.
* Remove the *vimspectorpy* directory in *~/.vim/plugin/* if you installed manually.

Anyway, if you want to keep *vimspector*, then also do this (assuming
*vimspector* is installed in *~/.vim/plugged/vimspector*):
```
find ~/.vim/plugged/vimspector/configurations -name '*vimspectorpy.json' -delete
```


## Usage

### Vimspector new configurations

Next time you are on a python source and start a debug session (F5) you'll get
this option:

1. debug this file - launch a debug session for the current file, using the
   python from your $VIRTUAL_ENV if there is one, or *python3*.

### ipython/pytest/nosetests with vim breakpoints

These commands are available to you:

```vim
" ipython started with debugpy, ready to attach to, but not attached.
" The default name is 'Pyconsole' - it is mapped to a port number you
" can attach to with :Pyattach.
:Pyconsole [name]

" start a debug session with vimspector against the port mapped to by
" 'name'. The default name is 'Pyconsole'.
:Pyattach [name]

" pytest started with debugpy, attached to immediately with vimspector.
" The default name is 'PytestD' - it is mapped to a port number you
" can attach to with :Pyattach, if you accidentally detach from it.
" 'options' are passed on to pytest.
:PytestD [name] [options]

" pytest started with debugpy for the current file, attached to immediately
" with vimspector. The default name is 'PytestD' - it is mapped to a port
" number you can attach to with :Pyattach, if you accidentally detach from it.
" 'options' are passed on to pytest. The path to the current file is appended.
:PytestDThis [name] [options]

" nosetests started with debugpy, attached to immediately with vimspector.
" The default name is 'NosetestsD' - it is mapped to a port number you
" can attach to with :Pyattach, if you accidentally detach from it.
" 'options' are passed on to nosetests.
:NosetestsD [name] [options]

" nosetests started with debugpy for the current file, attached to immediately
" with vimspector. The default name is 'NosetestsD' - it is mapped to a port
" number you can attach to with :Pyattach, if you accidentally detach from it.
" 'options' are passed on to nosetests. The path to the current file is appended.
:NosetestsDThis [name] [options]
```

### other commands

```vim
" This installs/updates this plugin's external dependencies:
" * A virtualenv with ipython and debugpy.
" * Some default configurations for {vimspector} python filetype.
:VimspectorpyUpdate
```

## Settings

### g:vimspectorpy#cmd_prefix

This plugin will not override command names you defined yourself.  To avoid
naming conflicts you could add a prefix to its commands.

This will make all the 'Py...' commands start with 'VS' (VSPyconsole,
VSPyattach, ...):

```vim
let g:vimspectorpy#cmd_prefix = "VS"
```

### g:vimspectorpy#launcher

For starting another window the plugin will use [tmux] automatically in a
console and 'xterm' in GUI.

You could choose 'rxvt' or force 'xterm' using:

```vim
let g:vimspectorpy#launcher = "rxvt"
```

## Vim-test

If you are using the excellent [vim-test] plugin, then now you can choose a
strategy to open the test in a [vimspector] debugger:

```vim
let test#strategy = "vimspectorpy"
```

## More help

For the most up to date docs use [:help vimspectorpy](doc/vimspectorpy.txt)

## License

MIT

[vimspector]: https://github.com/puremourning/vimspector
[tmux]:       https://github.com/tmux/tmux/wiki
[vim-test]:   https://github.com/vim-test/vim-test
