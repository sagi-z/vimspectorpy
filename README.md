# vimspectorpy - python default configurations for vimspector

## Description

Add some python customization to [vimspector]:

* Choose the correct python executable if in a VIRTUAL_ENV.
* Run pytest/nosetests for the project or test file.
* Debug the current file as a program.
* Launch ipython and attach a debugger to it to debug your code with vimspector.

![Pyconsole example](Pyconsole.gif "ipython console debug your code with vimspector")

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

Next time you are on a python source and start a debug session (F5) you'll get
these options:

1. attach2port - attach to a port of a debugpy running on localhost (used
   internally by this plugin). This is a simple "multi-session" adapter
   configuration that attaches to localhost and needs a port to connect to.
   See [vimspector] documentation if you want this.

2. debug this file - launch a debug session for the current file, using the
   python from your $VIRTUAL_ENV if there is one, or *python3*.

### ipython with vim breakpoints

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
" The default name is 'Pytest' - it is mapped to a port number you
" can attach to with :Pyattach, if you accidentally detach from it.
" 'options' are passed on to pytest.
:Pytest [name] [options]

" pytest started with debugpy for the current file, attached to immediately
" with vimspector. The default name is 'Pytest' - it is mapped to a port
" number you can attach to with :Pyattach, if you accidentally detach from it.
" 'options' are passed on to pytest. The path to the current file is appended.
:PytestThis [name] [options]

" nosetests started with debugpy, attached to immediately with vimspector.
" The default name is 'Nosetests' - it is mapped to a port number you
" can attach to with :Pyattach, if you accidentally detach from it.
" 'options' are passed on to nosetests.
:Nosetests [name] [options]

" nosetests started with debugpy for the current file, attached to immediately
" with vimspector. The default name is 'Nosetests' - it is mapped to a port
" number you can attach to with :Pyattach, if you accidentally detach from it.
" 'options' are passed on to nosetests. The path to the current file is appended.
:NosetestsThis [name] [options]
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

## More help

For the most up to date docs use [:help vimspectorpy](doc/vimspectorpy.txt)

## License

MIT

[vimspector]: https://github.com/puremourning/vimspector
[tmux]:       https://github.com/tmux/tmux/wiki

