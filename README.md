Emacs Lisp Module to add support for mobdebug, the lua remote debugger, to emacs.

Because mobdebug uses lua paths and emacs uses full pathnames, this module requires
the use of a [wrapper script](https://github.com/jsalzbergedu/mobdebug-emacs)
in order to put in breakpoints etc.
