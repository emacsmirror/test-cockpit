;;; test-cockpit.el-test.el --- Tests for test-cockpit.el

(require 'mocker)
(require 'test-cockpit)

(defclass test-cockpit--foo-engine (test-cockpit--engine)
  ((current-module-string :initarg :current-module-string
			 :initform "foo-module-string")
   (current-function-string :initarg :current-function-string
			    :initform "foo-function-string")))

(cl-defmethod test-cockpit--test-project-command ((obj test-cockpit--foo-engine))
  (lambda (_ args) (concat "test project" " " (string-join args " "))))
(cl-defmethod test-cockpit--test-module-command ((obj test-cockpit--foo-engine))
  (lambda (module args) (concat "test module" " " module " " (string-join args " "))))
(cl-defmethod test-cockpit--test-function-command ((obj test-cockpit--foo-engine))
  (lambda (func args) (concat "test function" " " func " " (string-join args " "))))
(cl-defmethod test-cockpit--transient-infix ((obj test-cockpit--foo-engine))
  ["Foo" ("-f" "foo" "--foo")])
(cl-defmethod test-cockpit--engine-current-module-string ((obj test-cockpit--foo-engine))
  (oref obj current-module-string))
(cl-defmethod test-cockpit--engine-current-function-string ((obj test-cockpit--foo-engine))
  (oref obj current-function-string))

(defun tc--register-foo-project ()
  (setq test-cockpit--project-engines nil)
  (test-cockpit-register-project-type 'foo-project-type 'test-cockpit--foo-engine))

(ert-deftest test-register-project-type-primary ()
  (tc--register-foo-project)
  (should (alist-get 'foo-project-type test-cockpit--project-types)))

(ert-deftest test-register-project-type-alias ()
  (tc--register-foo-project)
  (test-cockpit-register-project-type-alias 'foo-project-type-alias 'foo-project-type)
  (should (eq (alist-get 'foo-project-type test-cockpit--project-types)
	      (alist-get 'foo-project-type-alias test-cockpit--project-types))))

(ert-deftest test-current-module-string-dummy ()
  (setq test-cockpit--project-engines nil)
  (mocker-let ((projectile-project-type () ((:output 'bar-project-type)))
	       (projectile-project-root (&optional _dir) ((:input-matcher (lambda (_) t) :output "bar-project"))))
    (should (eq (test-cockpit--current-module-string) nil))))

(ert-deftest test-current-module-string-foo ()
  (tc--register-foo-project)
  (mocker-let ((projectile-project-type () ((:output 'foo-project-type)))
	       (projectile-project-root (&optional _dir) ((:input-matcher (lambda (_) t) :output "foo-project"))))
    (should (equal (test-cockpit--current-module-string) "foo-module-string"))))

(ert-deftest test-last-module-string-default-nil ()
  (should (eq (test-cockpit--last-module-string) nil)))

(ert-deftest test-repeat-module-no-last-module ()
  (tc--register-foo-project)
  (mocker-let ((projectile-project-type () ((:output 'foo-project-type)))
	       (projectile-project-root (&optional _dir) ((:input-matcher (lambda (_) t) :output "foo-project")))
	       (test-cockpit-dispatch () ((:occur 1))))
    (test-cockpit-repeat-module)))

(ert-deftest test-test-last-strings-module-called ()
  (tc--register-foo-project)
  (mocker-let ((projectile-project-type () ((:output 'foo-project-type)))
	       (projectile-project-root (&optional _dir) ((:input-matcher (lambda (_) t) :output "foo-project")))
	       (compile (command) ((:input '("test module foo-module-string") :output 'success))))
    (should (equal (test-cockpit--last-module-string) nil))
    (should (equal (test-cockpit--last-function-string) nil))
    (test-cockpit-test-module)
    (should (equal (test-cockpit--last-module-string) "foo-module-string"))
    (should (equal (test-cockpit--last-function-string) "foo-function-string"))))

(ert-deftest test-test-last-strings-module-repeat-called ()
  (tc--register-foo-project)
  (mocker-let ((projectile-project-type () ((:output 'foo-project-type)))
	       (projectile-project-root (&optional _dir) ((:input-matcher (lambda (_) t) :output "foo-project")))
	       (compile (command) ((:input '("test module foo-module-string") :output 'success))))
    (test-cockpit-test-module)
    (oset (test-cockpit--retrieve-engine) current-function-string nil)
    (oset (test-cockpit--retrieve-engine) current-module-string nil)
    (test-cockpit-repeat-module)
    (should (equal (test-cockpit--last-function-string) "foo-function-string"))
    (should (equal (test-cockpit--last-module-string) "foo-module-string"))))

(ert-deftest test-current-function-string-dummy ()
  (setq test-cockpit--project-engines nil)
  (mocker-let ((projectile-project-type () ((:output 'bar-project-type)))
	       (projectile-project-root (&optional _dir) ((:input-matcher (lambda (_) t) :output "bar-project"))))
    (should (eq (test-cockpit--current-function-string) nil))))

(ert-deftest test-current-function-string-foo ()
  (tc--register-foo-project)
  (mocker-let ((projectile-project-type () ((:output 'foo-project-type)))
	       (projectile-project-root (&optional _dir) ((:input-matcher (lambda (_) t) :output "foo-project"))))
    (should (equal (test-cockpit--current-function-string) "foo-function-string"))))

(ert-deftest test-last-function-string-default-nil ()
  (should (eq (test-cockpit--last-function-string) nil)))

(ert-deftest test-repeat-function-no-last-function ()
  (tc--register-foo-project)
  (mocker-let ((projectile-project-type () ((:output 'foo-project-type)))
	       (projectile-project-root (&optional _dir) ((:input-matcher (lambda (_) t) :output "foo-project")))
	       (test-cockpit-dispatch () ((:occur 1))))
    (test-cockpit-repeat-function)))

(ert-deftest test-test-last-strings-function-called ()
  (tc--register-foo-project)
  (mocker-let ((projectile-project-type () ((:output 'foo-project-type)))
	       (projectile-project-root (&optional _dir) ((:input-matcher (lambda (_) t) :output "foo-project")))
	       (compile (command) ((:input '("test function foo-function-string") :output 'success))))
    (should (equal (test-cockpit--last-module-string) nil))
    (should (equal (test-cockpit--last-function-string) nil))
    (test-cockpit-test-function)
    (should (equal (test-cockpit--last-module-string) "foo-module-string"))
    (should (equal (test-cockpit--last-function-string) "foo-function-string"))))

(ert-deftest test-test-last-strings-function-repeat-called ()
  (tc--register-foo-project)
  (mocker-let ((projectile-project-type () ((:output 'foo-project-type)))
	       (projectile-project-root (&optional _dir) ((:input-matcher (lambda (_) t) :output "foo-project")))
	       (compile (command) ((:input '("test function foo-function-string") :output 'success))))
    (test-cockpit-test-function)
    (oset (test-cockpit--retrieve-engine) current-module-string nil)
    (oset (test-cockpit--retrieve-engine) current-function-string nil)
    (test-cockpit-repeat-function)
    (should (equal (test-cockpit--last-module-string) "foo-module-string"))
    (should (equal (test-cockpit--last-function-string) "foo-function-string"))))

(ert-deftest test-test-last-strings-project-called ()
  (tc--register-foo-project)
  (mocker-let ((projectile-project-type () ((:output 'foo-project-type)))
	       (projectile-project-root (&optional _dir) ((:input-matcher (lambda (_) t) :output "foo-project")))
	       (compile (command) ((:input '("test project") :output 'success))))
    (should (equal (test-cockpit--last-module-string) nil))
    (should (equal (test-cockpit--last-function-string) nil))
    (test-cockpit-test-project)
    (should (equal (test-cockpit--last-module-string) "foo-module-string"))
    (should (equal (test-cockpit--last-function-string) "foo-function-string"))))


(ert-deftest test-test-project-no-args ()
  (tc--register-foo-project)
  (mocker-let ((projectile-project-type () ((:output 'foo-project-type)))
	       (projectile-project-root (&optional dir) ((:input-matcher (lambda (_) t) :output "foo-project")))
	       (compile (command) ((:input '("test project") :output 'success))))
    (test-cockpit-test-project)
    ))

(ert-deftest test-test-project-cached ()
  (tc--register-foo-project)
  (mocker-let ((projectile-project-type () ((:output 'foo-project-type :max-occur 1)))
	       (projectile-project-root (&optional dir) ((:input-matcher (lambda (_) t) :output "foo-project")))
	       (compile (command) ((:input '("test project") :output 'success))))
    (test-cockpit-test-project)
    (test-cockpit-test-project)
    ))

(ert-deftest test-test-project-with-args ()
  (tc--register-foo-project)
  (mocker-let ((projectile-project-type () ((:output 'foo-project-type)))
	       (projectile-project-root (&optional _dir) ((:input-matcher (lambda (_) t) :output "foo-project")))
	       (compile (command) ((:input '("test project foo bar") :output 'success))))
    (test-cockpit-test-project '("foo" "bar"))
    (should (equal (test-cockpit--last-switches) '("foo" "bar")))))

(ert-deftest test-test-module-no-args ()
  (tc--register-foo-project)
  (mocker-let ((projectile-project-type () ((:output 'foo-project-type)))
	       (projectile-project-root (&optional _dir) ((:input-matcher (lambda (_) t) :output "foo-project")))
	       (compile (command) ((:input '("test module foo-module-string") :output 'success))))
    (test-cockpit-test-module)
    ))

(ert-deftest test-test-module-with-args ()
  (tc--register-foo-project)
  (mocker-let ((projectile-project-type () ((:output 'foo-project-type)))
	       (projectile-project-root (&optional _dir) ((:input-matcher (lambda (_) t) :output "foo-project")))
	       (compile (command) ((:input '("test module foo-module-string foo bar") :output 'success))))
    (test-cockpit-test-module '("foo" "bar"))
    (should (equal (test-cockpit--last-switches) '("foo" "bar")))))

(ert-deftest test-test-function-no-args ()
  (tc--register-foo-project)
  (mocker-let ((projectile-project-type () ((:output 'foo-project-type)))
	       (projectile-project-root (&optional _dir) ((:input-matcher (lambda (_) t) :output "foo-project")))
	       (compile (command) ((:input '("test function foo-function-string") :output 'success))))
    (test-cockpit-test-function)
    ))

(ert-deftest test-test-function-with-args ()
  (tc--register-foo-project)
  (mocker-let ((projectile-project-type () ((:output 'foo-project-type)))
	       (projectile-project-root (&optional _dir) ((:input-matcher (lambda (_) t) :output "foo-project")))
	       (compile (command) ((:input '("test function foo-function-string foo bar") :output 'success))))
    (test-cockpit-test-function '("foo" "bar"))
    (should (equal (test-cockpit--last-switches) '("foo" "bar")))))

(ert-deftest test-repeat-test ()
  (tc--register-foo-project)
  (mocker-let ((projectile-project-type () ((:output 'foo-project-type)))
	       (projectile-project-root (&optional _dir) ((:input-matcher (lambda (_) t) :output "foo-project")))
	       (compile (command) ((:input '("test project") :output 'success :occur 2)
				   (:input '("test module foo-module-string") :output 'success :occur 3))))
    (test-cockpit-test-project)
    (test-cockpit-repeat-test)
    (test-cockpit-test-module)
    (test-cockpit-repeat-test)
    (test-cockpit-repeat-test)
    (should t)))

(ert-deftest test-repeat-module-no-last ()
  (tc--register-foo-project)
  (mocker-let ((projectile-project-type () ((:output 'foo-project-type)))
	       (projectile-project-root (&optional _dir) ((:input-matcher (lambda (_) t) :output "foo-project"))))
    (test-cockpit-repeat-module)))

(ert-deftest test-repeat-module-with-last-no-args ()
  (tc--register-foo-project)
  (mocker-let ((projectile-project-type () ((:output 'foo-project-type)))
	       (projectile-project-root (&optional _dir) ((:input-matcher (lambda (_) t) :output "foo-project")))
	       (compile (command) ((:input '("test project") :output 'success :occur 1)
				   (:input '("test module foo-module-string foo bar") :output 'success :occur 1))))
    (test-cockpit-test-project)
    (test-cockpit--do-repeat-module '("foo" "bar"))))

(ert-deftest test-repeat-module-with-last-with-args ()
  (tc--register-foo-project)
  (mocker-let ((projectile-project-type () ((:output 'foo-project-type)))
	       (projectile-project-root (&optional _dir) ((:input-matcher (lambda (_) t) :output "foo-project")))
	       (compile (command) ((:input '("test function foo-function-string") :output 'success :occur 1)
				   (:input '("test module foo-module-string") :output 'success :occur 1))))
    (test-cockpit-test-function)
    (test-cockpit-repeat-module)))

(ert-deftest test-repeat-module-with-last-with-last-args ()
  (tc--register-foo-project)
  (mocker-let ((projectile-project-type () ((:output 'foo-project-type)))
	       (projectile-project-root (&optional _dir) ((:input-matcher (lambda (_) t) :output "foo-project")))
	       (compile (command) ((:input '("test function foo-function-string foo bar") :output 'success :occur 1)
				   (:input '("test module foo-module-string foo bar") :output 'success :occur 1))))
    (test-cockpit-test-function '("foo bar"))
    (test-cockpit-repeat-module)))

(ert-deftest test-do-repeat-module-with-last-with-no-args ()
  (tc--register-foo-project)
  (mocker-let ((projectile-project-type () ((:output 'foo-project-type)))
	       (projectile-project-root (&optional _dir) ((:input-matcher (lambda (_) t) :output "foo-project")))
	       (compile (command) ((:input '("test function foo-function-string foo bar") :output 'success :occur 1)
				   (:input '("test module foo-module-string") :output 'success :occur 1))))
    (test-cockpit-test-function '("foo bar"))
    (test-cockpit--do-repeat-module nil)))

(ert-deftest test-repeat-function-no-last ()
  (tc--register-foo-project)
  (mocker-let ((projectile-project-type () ((:output 'foo-project-type)))
	       (projectile-project-root (&optional _dir) ((:input-matcher (lambda (_) t) :output "foo-project"))))
    (test-cockpit-repeat-function)))

(ert-deftest test-repeat-function-with-last-no-args ()
  (tc--register-foo-project)
  (mocker-let ((projectile-project-type () ((:output 'foo-project-type)))
	       (projectile-project-root (&optional _dir) ((:input-matcher (lambda (_) t) :output "foo-project")))
	       (compile (command) ((:input '("test project") :output 'success :occur 1)
				   (:input '("test function foo-function-string") :output 'success :occur 1))))
    (test-cockpit-test-project)
    (test-cockpit-repeat-function)))

(ert-deftest test-repeat-function-with-last-with-args ()
  (tc--register-foo-project)
  (mocker-let ((projectile-project-type () ((:output 'foo-project-type)))
	       (projectile-project-root (&optional _dir) ((:input-matcher (lambda (_) t) :output "foo-project")))
	       (compile (command) ((:input '("test module foo-module-string") :output 'success :occur 1)
				   (:input '("test function foo-function-string bar foo") :output 'success :occur 1))))
    (test-cockpit-test-module)
    (test-cockpit--do-repeat-function '("bar" "foo"))))

(ert-deftest test-repeat-function-with-last-with-last-args ()
  (tc--register-foo-project)
  (mocker-let ((projectile-project-type () ((:output 'foo-project-type)))
	       (projectile-project-root (&optional _dir) ((:input-matcher (lambda (_) t) :output "foo-project")))
	       (compile (command) ((:input '("test module foo-module-string bar foo") :output 'success :occur 1)
				   (:input '("test function foo-function-string bar foo") :output 'success :occur 1))))
    (test-cockpit-test-module '("bar" "foo"))
    (test-cockpit-repeat-function)))

(ert-deftest test-do-repeat-function-with-last-with-no-args ()
  (tc--register-foo-project)
  (mocker-let ((projectile-project-type () ((:output 'foo-project-type)))
	       (projectile-project-root (&optional _dir) ((:input-matcher (lambda (_) t) :output "foo-project")))
	       (compile (command) ((:input '("test module foo-module-string bar foo") :output 'success :occur 1)
				   (:input '("test function foo-function-string") :output 'success :occur 1))))
    (test-cockpit-test-module '("bar" "foo"))
    (test-cockpit--do-repeat-function nil)))

(ert-deftest test-repeat-transient-suffix-nil ()
  (should (eq (test-cockpit--transient-suffix-for-repeat) nil)))

(ert-deftest test-repeat-transient-suffix-non-nil ()
  (tc--register-foo-project)
  (mocker-let ((projectile-project-type () ((:output 'foo-project-type)))
	       (projectile-project-root (&optional _dir) ((:input-matcher (lambda (_) t) :output "/home/user/projects/foo-project")))
	       (compile (command) ((:input '("test project") :output 'success))))
    (oset (test-cockpit--retrieve-engine) current-module-string "/home/user/projects/foo-project/foo-module")
    (oset (test-cockpit--retrieve-engine) current-function-string "/home/user/projects/foo-project/foo-module::foo-function")
    (should (eq (test-cockpit--transient-suffix-for-repeat) nil))
    (test-cockpit-test-project)
    (should (equal (test-cockpit--transient-suffix-for-repeat)
		["Repeat tests"
		 ("M" "last module: foo-module" test-cockpit--do-repeat-module)
		 ("F" "last function: foo-module::foo-function" test-cockpit--do-repeat-function)]))
    (oset (test-cockpit--retrieve-engine) last-module-string nil)
    (should (equal (test-cockpit--transient-suffix-for-repeat)
		["Repeat tests"
		 ("F" "last function: foo-module::foo-function" test-cockpit--do-repeat-function)]))
    (test-cockpit-test-project)
    (oset (test-cockpit--retrieve-engine) last-function-string nil)
    (should (equal (test-cockpit--transient-suffix-for-repeat)
		["Repeat tests"
		 ("M" "last module: foo-module" test-cockpit--do-repeat-module)]))))

(ert-deftest test-test-or-projectile-build-known-project-type ()
  (tc--register-foo-project)
  (mocker-let ((projectile-project-type () ((:output 'foo-project-type)))
	       (projectile-project-root (&optional _dir) ((:input-matcher (lambda (_) t) :output "foo-project")))
	       (test-cockpit-dispatch () ((:occur 1)))
	       (compile (command) ((:input '("test project foo bar") :output 'success :occur 1))))
    (test-cockpit-test-or-projectile-build)
    (test-cockpit-test-project '("foo" "bar")))
  (mocker-let ((projectile-project-root (&optional _dir) ((:input-matcher (lambda (_) t) :output "foo-project")))
	       (test-cockpit-dispatch () ((:occur 1))))
    (test-cockpit-test-or-projectile-build)))

(ert-deftest test-repeat-test-or-projectile-build-known-project-type ()
  (tc--register-foo-project)
  (mocker-let ((projectile-project-type () ((:output 'foo-project-type)))
	       (projectile-project-root (&optional _dir) ((:input-matcher (lambda (_) t) :output "foo-project")))
	       (test-cockpit-dispatch () ((:occur 1)))
	       (compile (command) ((:input '("test project foo bar") :output 'success :occur 1))))
    (test-cockpit-repeat-test-or-projectile-build)
    (test-cockpit-test-project '("foo" "bar")))
  (mocker-let ((projectile-project-root (&optional _dir) ((:input-matcher (lambda (_) t) :output "foo-project")))
	       (compile (command) ((:input '("test project foo bar") :output 'success :occur 1))))
    (test-cockpit-repeat-test-or-projectile-build)))

(ert-deftest test-test-or-projectile-build-unknown-project-type ()
  (tc--register-foo-project)
  (mocker-let ((projectile-project-type () ((:output 'bar-project-type)))
	       (projectile-project-root (&optional _dir) ((:input-matcher (lambda (_) t) :output "bar-project")))
	       (test-cockpit-dispatch () ((:occur 0)))
	       (projectile-compile-project (arg) ((:input '(nil) :output 'success :occur 2))))
    (let ((compile-command "make all"))
      (should (equal (test-cockpit--last-build-command) nil))
      (test-cockpit-test-or-projectile-build)
      (should (equal (test-cockpit--last-build-command) "make all")))
    (let ((compile-command "make special"))
      (test-cockpit-test-or-projectile-build)
      (should (equal (test-cockpit--last-build-command) "make special")))))

(ert-deftest test-repeat-test-or-projectile-build-unknown-project-type ()
  (mocker-let ((projectile-project-type () ((:output 'bar-project-type)))
	       (projectile-project-root (&optional _dir) ((:input-matcher (lambda (_) t) :output "bar-project")))
	       (test-cockpit-dispatch () ((:occur 0)))
	       (projectile-compile-project (arg) ((:input '(nil) :output 'success :max-occur 1)))
	       (compile (command) ((:input '("make all") :output 'success :occur 1))))
    (let ((compile-command "make all"))
      (test-cockpit-test-or-projectile-build)
      (test-cockpit-repeat-test-or-projectile-build))))


(ert-deftest test-test-or-projectile-test-known-project-type ()
  (tc--register-foo-project)
  (mocker-let ((projectile-project-type () ((:output 'foo-project-type)))
	       (projectile-project-root (&optional _dir) ((:input-matcher (lambda (_) t) :output "foo-project")))
	       (test-cockpit-dispatch () ((:occur 1)))
	       (compile (command) ((:input '("test project foo bar") :output 'success :occur 1))))
    (test-cockpit-test-or-projectile-test)
    (test-cockpit-test-project '("foo" "bar")))
  (mocker-let ((projectile-project-root (&optional _dir) ((:input-matcher (lambda (_) t) :output "foo-project")))
	       (test-cockpit-dispatch () ((:occur 1))))
    (test-cockpit-test-or-projectile-test)))

(ert-deftest test-repeat-test-or-projectile-test-known-project-type ()
  (tc--register-foo-project)
  (mocker-let ((projectile-project-type () ((:output 'foo-project-type)))
	       (projectile-project-root (&optional _dir) ((:input-matcher (lambda (_) t) :output "foo-project")))
	       (test-cockpit-dispatch () ((:occur 1)))
	       (compile (command) ((:input '("test project foo bar") :output 'success :occur 1))))
    (test-cockpit-repeat-test-or-projectile-test)
    (test-cockpit-test-project '("foo" "bar")))
  (mocker-let ((projectile-project-root (&optional _dir) ((:input-matcher (lambda (_) t) :output "foo-project")))
	       (compile (command) ((:input '("test project foo bar") :output 'success :occur 1))))
    (test-cockpit-repeat-test-or-projectile-test)))

(ert-deftest test-test-or-projectile-test-unknown-project-type ()
  (tc--register-foo-project)
  (mocker-let ((projectile-project-type () ((:output 'bar-project-type)))
	       (projectile-project-root (&optional _dir) ((:input-matcher (lambda (_) t) :output "bar-project")))
	       (test-cockpit-dispatch () ((:occur 0)))
	       (projectile-test-project (arg) ((:input '(nil) :output 'success :occur 2))))
    (let ((compile-command "make all"))
      (should (equal (test-cockpit--last-test-command) nil))
      (test-cockpit-test-or-projectile-test)
      (should (equal (test-cockpit--last-test-command) "make all")))
    (let ((compile-command "make special"))
      (test-cockpit-test-or-projectile-test)
      (should (equal (test-cockpit--last-test-command) "make special")))))

(ert-deftest test-repeat-test-or-projectile-test-unknown-project-type ()
  (mocker-let ((projectile-project-type () ((:output 'bar-project-type :max-occur 1)))
	       (projectile-project-root (&optional _dir) ((:input-matcher (lambda (_) t) :output "bar-project")))
	       (test-cockpit-dispatch () ((:occur 0)))
	       (projectile-test-project (arg) ((:input '(nil) :output 'success :occur 1)))
	       (compile (command) ((:input '("make test") :output 'success :occur 1))))
    (let ((compile-command "make test"))
      (test-cockpit-test-or-projectile-test)
      (test-cockpit-repeat-test-or-projectile-test))))

(ert-deftest test-custom-test-command ()
  (mocker-let ((call-interactively (func) ((:input `(compile) :output 'success :occur 1)))
	       (compile (command)
			((:input '("some custom command") :output 'success :occur 1))))
    (let ((compile-command "some custom command"))
      (test-cockpit-custom-test-command)
      (test-cockpit-repeat-test))))

(ert-deftest test-set-infix ()
  (tc--register-foo-project)
  (mocker-let ((projectile-project-type () ((:output 'foo-project-type))))
    (test-cockpit--insert-infix)
    (should (equal
	     (aref (transient-get-suffix 'test-cockpit-prefix '(0)) 2)
	     '(:description "Foo")))
    (should (equal
	     (aref (transient-get-suffix 'test-cockpit-prefix '(1)) 2)
	     '(:description "Run test")))))

(defclass test-cockpit--no-infix-engine (test-cockpit--engine) ())

(ert-deftest test-set-nil-infix ()
  (test-cockpit-register-project-type 'noinfix-project-type 'test-cockpit--no-infix-engine)
  (mocker-let ((projectile-project-type () ((:output 'noinfix-project-type)))
	       (transient-insert-suffix (prefix loc infix) ((:min-occur 0 :max-occur 0))))
    (test-cockpit--insert-infix)
    (should (equal
	     (aref (transient-get-suffix 'test-cockpit-prefix '(0)) 2)
	     '(:description "Run test")))))

(ert-deftest test-join-filter-switches ()
  (let ((allowed '("foo" "bar")))
    (should (equal (test-cockpit--join-filter-switches '( "foo" "bar") allowed) "foo bar"))
    (should (equal (test-cockpit--join-filter-switches '("bar" "boing") allowed) "bar"))))

(ert-deftest test-join-filter-options ()
  (let ((allowed '("-f" "--bar=")))
    (should (equal (test-cockpit--join-filter-switches '("-foo" "--bar=bar" "--baz=baz") allowed)
		   "-foo --bar=bar"))))

(ert-deftest test-add-leading-space-to-switches ()
  (should (equal (test-cockpit-add-leading-space-to-switches "") ""))
  (should (equal (test-cockpit-add-leading-space-to-switches "--foo") " --foo")))

(ert-deftest test-last-test-no-engine-at-first ()
  (tc--register-foo-project)
  (mocker-let ((projectile-project-type () ((:output 'foo-project-type)))
	       (projectile-project-root (&optional _dir) ((:input-matcher (lambda (_) t) :output "foo-project")))
	       (test-cockpit-dispatch () ((:min-occur 1))))
    (test-cockpit-repeat-test)))

(ert-deftest test-last-test-command-no-engine-after-project-switch ()
  (tc--register-foo-project)
  (mocker-let ((projectile-project-type () ((:output 'foo-project-type)))
	       (projectile-project-root (&optional _dir) ((:input-matcher (lambda (_) t) :output "foo-project")))
	       (compile (command) ((:input '("test project foo bar") :output 'success))))
    (test-cockpit-test-project '("foo" "bar"))
    (should (equal (test-cockpit--last-switches) '("foo" "bar")))
    (should (eq (length test-cockpit--project-engines) 1)))
  (mocker-let ((projectile-project-type () ((:output 'foo-project-type)))
	       (projectile-project-root (&optional _dir) ((:input-matcher (lambda (_) t) :output "bar-project")))
	       (test-cockpit-dispatch () ((:min-occur 1))))
    (should (eq (test-cockpit--last-switches) nil))
    (test-cockpit-repeat-test)
    (should (eq (length test-cockpit--project-engines) 2)))
  (mocker-let ((projectile-project-root (&optional _dir) ((:input-matcher (lambda (_) t) :output "foo-project"))))
    (should (equal (test-cockpit--last-switches) '("foo" "bar")))
    (should (eq (length test-cockpit--project-engines) 2))))

(ert-deftest test-repeat-test-dummy-engine ()
  (tc--register-foo-project)
  (mocker-let ((projectile-project-type () ((:output 'bar-project-type)))
	       (projectile-project-root (&optional _dir) ((:input-matcher (lambda (_) t) :output "bar-project"))))
    (should-error (test-cockpit-repeat-test))))

(ert-deftest test-dispatch-dummy-engine ()
  (tc--register-foo-project)
  (mocker-let ((projectile-project-type () ((:output 'bar-project-type)))
	       (projectile-project-root (&optional _dir) ((:input-matcher (lambda (_) t) :output "bar-project"))))
    (should-error (test-cockpit-dispatch))))

;;; test-cockpit.el-test.el ends here
