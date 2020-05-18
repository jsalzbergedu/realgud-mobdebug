;; Copyright (C) 2016-2019 Free Software Foundation, Inc
;; Author: Rocky Bernstein <rocky@gnu.org>

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;  `realgud:mobdebug' Main interface to mobdebug via Emacs
(require 'load-relative)
(require 'realgud)
(require-relative-list '("core" "track-mode") "realgud:mobdebug-")

;; This is needed, or at least the docstring part of it is needed to
;; get the customization menu to work in Emacs 25.
(defgroup realgud:mobdebug nil
  "The realgud interface to mobdebug"
  :group 'realgud
  :version "25.1")

;; -------------------------------------------------------------------
;; User definable variables
;;

(defcustom realgud:mobdebug-command-name
  "mobdebug"
  "File name for executing the and command options.
This should be an executable on your path, or an absolute file name."
  :type 'string
  :group 'realgud:mobdebug)

(declare-function realgud:mobdebug-track-mode     'realgud:mobdebug-track-mode)
(declare-function realgud-command              'realgud-send)
(declare-function realgud:mobdebug-parse-cmd-args 'realgud:mobdebug-core)
(declare-function realgud:mobdebug-query-cmdline  'realgud:mobdebug-core)
(declare-function realgud:run-process          'realgud-run)
(declare-function realgud:flatten              'realgud-utils)
(declare-function realgud:remove-ansi-schmutz  'realgud-utils)

;; -------------------------------------------------------------------
;; The end.
;;

;;;###autoload
(defun realgud:mobdebug (&optional opt-cmd-line no-reset)
  "Invoke the mobdebug debugger and start the Emacs user interface.

OPT-CMD-LINE is treated like a shell string; arguments are
tokenized by `split-string-and-unquote'.

Normally, command buffers are reused when the same debugger is
reinvoked inside a command buffer with a similar command. If we
discover that the buffer has prior command-buffer information and
NO-RESET is nil, then that information which may point into other
buffers and source buffers which may contain marks and fringe or
marginal icons is reset. See `loc-changes-clear-buffer' to clear
fringe and marginal icons.
"
  (interactive)
  (let* ((cmd-str (or opt-cmd-line (realgud:mobdebug-query-cmdline "")))
	 (cmd-args (split-string-and-unquote cmd-str))
	 (parsed-args (realgud:mobdebug-parse-cmd-args cmd-args))
	 (script-args (caddr parsed-args))
	 (script-name (car script-args))
	 (parsed-cmd-args
	  (cl-remove-if 'nil (realgud:flatten parsed-args)))
	 (cmd-buf (realgud:run-process realgud:mobdebug-command-name
				       script-name parsed-cmd-args
				       'realgud:mobdebug-minibuffer-history
				       nil))
	 )
    (if cmd-buf
	(with-current-buffer cmd-buf
	  (set (make-local-variable 'realgud:mobdebug-file-remap)
	       (make-hash-table :test 'equal))
	  (realgud:remove-ansi-schmutz)
	  )
      )
    )
  )

(defalias 'mobdebug 'realgud:mobdebug)

(provide-me "realgud-")

;; Local Variables:
;; byte-compile-warnings: (not cl-functions)
;; End:
