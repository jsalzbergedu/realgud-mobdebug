;; Copyright (C) 2019 Free Software Foundation, Inc
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

(eval-when-compile (require 'cl-lib))

(require 'realgud)

(declare-function realgud:expand-file-name-if-exists 'realgud-core)
(declare-function realgud-lang-mode? 'realgud-lang)
(declare-function realgud-parse-command-arg 'realgud-core)
(declare-function realgud-query-cmdline 'realgud-core)

;; FIXME: I think the following could be generalized and moved to
;; realgud-... probably via a macro.
(defvar realgud:mobdebug-minibuffer-history nil
  "minibuffer history list for the command `mobdebug'.")

(easy-mmode-defmap realgud:mobdebug-minibuffer-local-map
  '(("\C-i" . comint-dynamic-complete-filename))
  "Keymap for minibuffer prompting of gud startup command."
  :inherit minibuffer-local-map)

;; FIXME: I think this code and the keymaps and history
;; variable chould be generalized, perhaps via a macro.
(defun realgud:mobdebug-query-cmdline (&optional opt-debugger)
  (realgud-query-cmdline
   'realgud:mobdebug-suggest-invocation
   realgud:mobdebug-minibuffer-local-map
   'realgud:mobdebug-minibuffer-history
   opt-debugger))

(defvar realgud:mobdebug-file-remap (make-hash-table :test 'equal)
  "How to remap mobdebug files in  when we otherwise can't find in
  the filesystem. The hash key is the file string we saw, and the
  value is associated filesystem string presumably in the
  filesystem")

(defun realgud:mobdebug-find-file(cmd-marker filename directory)
  "A find-file specific for mobdebug. We will prompt for a mapping and save that in
`realgud:mobdebug-file-remap' when that works."
  (let ((resolved-filename filename)
	(remapped-filename (gethash filename realgud:mobdebug-file-remap)))
    (cond
     ((and remapped-filename (stringp remapped-filename)
	   (file-exists-p remapped-filename)) remapped-filename)
     ((file-exists-p filename) filename)
     ('t
      (setq resolved-filename
	    (buffer-file-name
	     (compilation-find-file (point-marker) filename nil "")))
      (puthash filename resolved-filename realgud:mobdebug-file-remap)))
     ))

(defun realgud:cmd-mobdebug-break()
  "Set a breakpoint storing mapping between a file and its basename"
  (let* ((resolved-filename (realgud-expand-format "%X"))
	 (cmdbuf (realgud-get-cmdbuf))
	 (filename (file-name-nondirectory resolved-filename)))

    ;; Save mapping from basename to long name so that we know what's
    ;; up in a "Breakpoint set at" message
    (puthash filename resolved-filename realgud:mobdebug-file-remap)

    ;; Run actual command
    (realgud:cmd-break)
    ))


;; FIXME: setting a breakpoint should add a[ file-to-basename mapping
;; so that when this is called it can look up the short name and
;; remap it.
(defun realgud:mobdebug-loc-fn-callback(text filename lineno source-str
					 cmd-mark directory column)
  (realgud:file-loc-from-line filename lineno
			      cmd-mark source-str nil nil directory))
			      ;; 'realgud:mobdebug-find-file directory))

(defun realgud:mobdebug-parse-cmd-args (orig-args)
  "Parse command line ARGS for the annotate level and name of script to debug.

ORIG_ARGS should contain a tokenized list of the command line to run.

We return the a list containing
* the name of the debugger given (e.g. mobdebug) and its arguments - a list of strings
* nil (a placehoder in other routines of this ilk for a debugger
* the script name and its arguments - list of strings
* whether the emacs option was given ('--emacs) - a boolean

For example for the following input
  (map 'list 'symbol-name
   '(mobdebug --tty /dev/pts/1 -cd ~ --emacs ./gcd.py a b))

we might return:
   ((\"mobdebug\" \"--tty\" \"/dev/pts/1\" \"-cd\" \"home/rocky\' \"--emacs\") nil \"(/tmp/gcd.py a b\") 't\")

Note that path elements have been expanded via `expand-file-name'.
"

  ;; Parse the following kind of pattern:
  ;;  mobdebug mobdebug-options script-name script-options
  '(nil nil nil nil))
  ;; (let (
  ;;       (args orig-args)
  ;;       (pair)          ;; temp return from

  ;;       ;; One dash is added automatically to the below, so
  ;;       ;; a is really -a. mobdebug doesn't seem to have long
  ;;       ;; (--) options.
  ;;       (mobdebug-two-args '("a" "f" "c" "s" "o" "S" "k" "L"
  ;;       		"p" "O"  "K"))
  ;;       ;; mobdebug doesn't optional 2-arg options.
  ;;       (mobdebug-opt-two-args '("r"))

  ;;       ;; Things returned
  ;;       (script-name nil)
  ;;       (debugger-name nil)
  ;;       (debugger-args '())
  ;;       (script-args '())
  ;;       (annotate-p nil))

  ;;   (if (not (and args))
  ;;       ;; Got nothing: return '(nil nil nil nil)
  ;;       (list debugger-args nil script-args annotate-p)
  ;;     ;; else
  ;;     (progn

  ;;       ;; Remove "mobdebug" from "mobdebug --mobdebug-options script
  ;;       ;; --script-options"
  ;;       (setq debugger-name (file-name-sans-extension
  ;;       		     (file-name-nondirectory (car args))))
  ;;       (unless (string-match "^mobdebug.*" debugger-name)
  ;;         (message
  ;;          "Expecting debugger name `%s' to be `mobdebug'"
  ;;          debugger-name))
  ;;       (setq debugger-args (list (pop args)))

  ;;       ;; Skip to the first non-option argument.
  ;;       (while (and args (not script-name))
  ;;         (let ((arg (car args)))
  ;;           (cond
  ;;            ;; path-argument ooptions
  ;;            ((member arg '("-cd" ))
  ;;             (setq arg (pop args))
  ;;             (nconc debugger-args
  ;;       	     (list arg (realgud:expand-file-name-if-exists
  ;;       			(pop args)))))
  ;;            ;; Options with arguments.
  ;;            ((string-match "^-" arg)
  ;;             (setq pair (realgud-parse-command-arg
  ;;       		  args mobdebug-two-args mobdebug-opt-two-args))
  ;;             (nconc debugger-args (car pair))
  ;;             (setq args (cadr pair)))
  ;;            ;; Anything else must be the script to debug.
  ;;            (t (setq script-name arg)
  ;;       	(setq script-args args))
  ;;            )))
  ;;       (list debugger-args nil script-args annotate-p)))))

(defun realgud:mobdebug-suggest-invocation (&optional debugger-name)
  "Suggest a mobdebug command invocation. Here is the priority we use:
* an executable file with the name of the current buffer stripped of its extension
* any executable file in the current directory with no extension
* the last invocation in mobdebug:minibuffer-history
* any executable in the current directory
When all else fails return the empty string."
  "lua -e \"require('mobdebug').listen()\"")

(defun realgud:mobdebug-reset ()
  "Mobdebug cleanup - remove debugger's internal buffers (frame,
breakpoints, etc.)."
  (interactive)
  ;; (mobdebug-breakpoint-remove-all-icons)
  (dolist (buffer (buffer-list))
    (when (string-match "\\*mobdebug-[a-z]+\\*" (buffer-name buffer))
      (let ((w (get-buffer-window buffer)))
        (when w
          (delete-window w)))
      (kill-buffer buffer))))

;; (defun mobdebug-reset-keymaps()
;;   "This unbinds the special debugger keys of the source buffers."
;;   (interactive)
;;   (setcdr (assq 'mobdebug-debugger-support-minor-mode minor-mode-map-alist)
;; 	  mobdebug-debugger-support-minor-mode-map-when-deactive))


(defun realgud:mobdebug-customize ()
  "Use `customize' to edit the settings of the `realgud:mobdebug' debugger."
  (interactive)
  (customize-group 'realgud:mobdebug))

(provide-me "realgud:mobdebug-")
