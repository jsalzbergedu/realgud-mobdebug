Emacs Lisp Module to add support for mobdebug, the lua remote debugger, to emacs.

Because mobdebug uses lua paths and emacs uses full pathnames, this module requires
the use of a [wrapper script](https://github.com/jsalzbergedu/mobdebug-emacs)
in order to put in breakpoints etc.

To use, run M-x realgud:mobdebug in the project directory, and run the following
in a lua repl

```lua
mobdebug = require("mobdebug")
mobdebug.loop()
```

In order to start the debugger.
