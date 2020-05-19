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

;;; mobdebug debugger

(eval-when-compile (require 'cl-lib))

(require 'realgud)

(defvar realgud:mobdebug-pat-hash (make-hash-table :test 'equal)
  "hash key is the what kind of pattern we want to match:
backtrace, prompt, etc.  the values of a hash entry is a
realgud-loc-pat struct")

(defvar realgud-mobdebug-hash
  nil
  "A buffer local hash table which maps a debugger name, .e.g. 'mobdebug' to its
the debugger specific hash table, e.g. 'realugd-mobdebug-pat-hash'.")
(declare-function make-realgud-loc-pat (realgud-loc))

(declare-function make-realgud-loc "realgud-loc" (a b c d e f))


;; Handle both
;; * line and column number as well as
;; * line without column number.
;; For example:
;;   SolidityParserError.cpp:102:35
;;   SolidityParserError.cpp:102
;;
;; Note the minimal-match regexp up to the first colon
(defconst realgud:mobdebug-file-col-regexp
  (format "\\(.+?\\):%s\\(?::%s\\)?"
	  realgud:regexp-captured-num
	  realgud:regexp-captured-num))

(defconst realgud:mobdebug-frame-start-regexp
  "\\(?:^\\|\n\\)")

(setf (gethash "loc" realgud:mobdebug-pat-hash)
      (make-realgud-loc-pat
       :regexp (format "^Paused at file \\(.+?\\) line %s"
                       realgud:regexp-captured-num)
       :file-group 1
       :line-group 2))

;; realgud-loc-pat that describes a mobdebug prompt
;; For example:
;;   > 
(setf (gethash "prompt" realgud:mobdebug-pat-hash)
      (make-realgud-loc-pat :regexp "^> "))

;;  Prefix used in variable names (e.g. short-key-mode-map) for
;; this debugger
(setf (gethash "mobdebug" realgud:variable-basename-hash) "realgud:mobdebug")

(defvar realgud:mobdebug-command-hash (make-hash-table :test 'equal)
  "Hash key is command name like 'continue' and the value is
  the mobdebug command to use, like 'process continue'")

;;  (("step" . "step %p") ("run" . "run") ("quit" . "quit") ("eval" . "print %s") ("delete" . "delete %p") ("continue" . "continue") ("clear" . "clear %X:%l") ("break" . "break %X:%l"))
(setf (gethash "step"             realgud:mobdebug-command-hash) "step")
(setf (gethash "continue"         realgud:mobdebug-command-hash) "run")
(setf (gethash "run"              realgud:mobdebug-command-hash) "run")
(setf (gethash "quit"             realgud:mobdebug-command-hash) "done")
(setf (gethash "eval"             realgud:mobdebug-command-hash) "eval %s")
(setf (gethash "delete"           realgud:mobdebug-command-hash) "delb %X %l")
(setf (gethash "clear"            realgud:mobdebug-command-hash) "delb %X %l")
(setf (gethash "break"            realgud:mobdebug-command-hash) "setb %X %l")
(setf (gethash "backtrace"        realgud:mobdebug-command-hash) "stack")
(setf (gethash "delete_all"       realgud:mobdebug-command-hash) "delallb")
(setf (gethash "finish"           realgud:mobdebug-command-hash) "done")
(setf (gethash "info-breakpoints" realgud:mobdebug-command-hash) "listb")
(setf (gethash "restart"          realgud:mobdebug-command-hash) "reload")

(setf (gethash "mobdebug" realgud-command-hash) realgud:mobdebug-command-hash)
(setf (gethash "mobdebug" realgud-pat-hash) realgud:mobdebug-pat-hash)

(provide-me "realgud:mobdebug-")
