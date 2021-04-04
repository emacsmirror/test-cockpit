;;; test-cockpit.el --- A command center to run tests of a software project

;; Author: Johannes Mueller <github@johannes-mueller.org
;; URL: https://github.com/johannes-mueller/test-cockpit.el
;; License: GPLv2

;;; Commentary:

;; test-cockpit aims to be a unified user interface for test runners of different
;; programming languages resp. their testing tools.  There are excellent user interfaces
;; for running tests like python-pytest, but thy are usually special solutions for a
;; specific programming language resp testing tool.  People working with multiple
;; programming languages in their various projects have to deal with different user
;; interfaces to run tests.  That can be annoying.

;; test-cockpit uses transient.el to provide a user interface like the well known git
;; frontend magit does.  There are general commands to run tests that are the same for
;; all programming languages.  Furthermore there are switches or settings, that are
;; specific to some programming language.  test-cockpit uses projectile to guess the
;; type of project and chooses the user interface variant for the specific programming
;; language accordingly.  That way the basic testing commands can be called by the same
;; keybindings for all the supported project types.

;; In this early stage the following programming environments are planned:

;; * Emacs Lisp – cask / ert: basics work
;; * Python – pytest: basics work
;; * Rust – Cargo: basics and feature discovery work
;; * Elixir – mix: planned

;; Each language has its own package to implement the testing of a project.
;; Such packages can be added locally, i. e. without modifying the code of
;; test-cockpit.el.

;;; Code:

(require 'transient)
(require 'projectile)
(require 'subr-x)

(defvar test-cockpit--project-types nil
  "List of known project types.")


(defvar test-cockpit--project-engines nil)

(defclass test-cockpit--engine ()
  ((last-command :initarg :last-command
		 :initform nil)
   (last-switches :initarg :last-switches
		  :initform nil)))

(cl-defmethod test-cockpit--test-project-command ((obj test-cockpit--engine)) nil)
(cl-defmethod test-cockpit--test-module-command ((obj test-cockpit--engine)) nil)
(cl-defmethod test-cockpit--test-function-command ((obj test-cockpit--engine)) nil)
(cl-defmethod test-cockpit--transient-infix ((obj test-cockpit--engine)) (lambda () nil))


(defun test-cockpit-register-project-type (project-type engine-class)
    "Register a language testing package."
  (setq test-cockpit--project-types
	(cons `(,project-type . (lambda () (make-instance ,engine-class)))
	      test-cockpit--project-types)))

(defun test-cockpit-register-project-type-alias (alias project-type)
  "Register an alias for a known project type.
Some project types are similar in a way that they can be tested
by the same commands, yet they are different for projectile.  In
those cases the already registered PROJECT-TYPE can be registered
again as ALIAS."
  (setq test-cockpit--project-types
	(cons `(,alias . ,(alist-get project-type test-cockpit--project-types)) test-cockpit--project-types)))

(defun test-cockpit--retrieve-engine ()
  (if-let ((engine (alist-get (projectile-project-root) test-cockpit--project-engines nil nil 'equal)))
      engine
    (let ((engine (funcall (alist-get (projectile-project-type) test-cockpit--project-types))))
      (setf (alist-get (projectile-project-root) test-cockpit--project-engines nil nil 'equal) engine)
      engine)))

(defun test-cockpit--make-test-function (func args)
  (string-trim (funcall
		(funcall func (test-cockpit--retrieve-engine))
		args)))

(defun test-cockpit-test-project-command (args)
  "Call the test-project-command function with ARGS of the current project type."
  (test-cockpit--make-test-function 'test-cockpit--test-project-command args))

(defun test-cockpit-test-module-command (args)
  "Call the test-module-command function with ARGS of the current project type."
  (test-cockpit--make-test-function 'test-cockpit--test-module-command args))

(defun test-cockpit-test-function-command (args)
  "Call the test-function-command function with ARGS of the current project type."
  (test-cockpit--make-test-function 'test-cockpit--test-function-command args))

(defun test-cockpit-infix ()
  "Call the infix function of the current project type and return the infix array."
  (funcall (test-cockpit--transient-infix (funcall (alist-get (projectile-project-type) test-cockpit--project-types)))))

(defun test-cockpit--insert-infix ()
  "Insert the infix array into the transient-prefix."
  (unless (equal (aref (transient-get-suffix 'test-cockpit-prefix '(0)) 2) '(:description "Run test"))
    (transient-remove-suffix 'test-cockpit-prefix '(0)))
  (if-let (infix (test-cockpit-infix))
      (transient-insert-suffix 'test-cockpit-prefix '(0) infix)))

(defun test-cockpit--run-test (command)
  "Run the test command COMMAND and remembers for the case the test is repeated."
  (oset (test-cockpit--retrieve-engine) last-command command)
  (projectile-with-default-dir (projectile-acquire-root)
    (compile command)))

(defun test-cockpit--command (func args)
  (let ((command (funcall func args)))
    (oset (test-cockpit--retrieve-engine) last-switches args)
    command))

(defun test-cockpit-test-project (&optional args)
  "Test the whole project.
ARGS is the UI state for language specific settings."
  (interactive
   (list (transient-args 'test-cockpit-prefix)))
  (test-cockpit--run-test (test-cockpit--command 'test-cockpit-test-project-command args)))

(defun test-cockpit-test-module (&optional args)
  "Test the module of the current buffer.
The exact determination of the model is done by the language specific package.
ARGS is the UI state for language specific settings."
  (interactive
   (list (transient-args 'test-cockpit-prefix)))
  (test-cockpit--run-test (test-cockpit--command 'test-cockpit-test-module-command args)))

(defun test-cockpit-test-function (&optional args)
  "Run the test function at point.
The exact determination of the function is done by the language
specific package.  ARGS is the UI state for language specific
settings."
  (interactive
   (list (transient-args 'test-cockpit-prefix)))
  (test-cockpit--run-test (test-cockpit--command 'test-cockpit-test-function-command args)))

(defun test-cockpit-repeat-test (&optional _args)
  "Repeat the last test."
  (interactive
   (list (transient-args 'test-cockpit-prefix)))
  (if-let (last-command (oref (test-cockpit--retrieve-engine) last-command))
      (test-cockpit--run-test last-command)
    (test-cockpit-dispatch)))

(defun test-cockpit--last-switches ()
  (oref (test-cockpit--retrieve-engine) last-switches))

(transient-define-prefix test-cockpit-prefix ()
  "Test the project"
  :value 'test-cockpit--last-switches
  ["Run test"
   ("p" "project" test-cockpit-test-project)
   ("m" "module" test-cockpit-test-module)
   ("f" "function" test-cockpit-test-function)
   ("r" "repeat" test-cockpit-repeat-test)])

(defun test-cockpit-dispatch ()
  "Invoke the user interface of to setup and run tests."
  (interactive)
  (test-cockpit--insert-infix)
  (test-cockpit-prefix)
  )

(defun test-cockpit--join-filter-switches (candidates allowed)
  "Join the list of strings CANDIDATES together.
Candidates not in ALLOWED are excluded.  The items are separated
with a space."
  (string-join (delete 'exclude
		       (mapcar (lambda (sw) (if (member sw candidates) sw 'exclude))
			       allowed))
	       " "))

(defun test-cockpit-add-leading-space-to-switches (switches)
  (if (string-empty-p switches)
      ""
    (concat " " switches)))

(provide 'test-cockpit)

;;; test-cockpit.el ends here
