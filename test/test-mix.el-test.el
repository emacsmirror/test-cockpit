(require 'mocker)
(require 'test-cockpit-mix)

(ert-deftest test-cockpit-mix-type-available ()
  (should (alist-get 'elixir test-cockpit--project-types)))

(ert-deftest test-elixir-current-module-string-no-file-buffer-is-nil ()
  (mocker-let ((buffer-file-name () ((:output nil))))
    (let ((engine (make-instance test-cockpit--mix-engine)))
      (should (eq (test-cockpit--engine-current-module-string engine) nil)))))

(ert-deftest test-elixir-current-function-string-no-file-buffer-is-nil ()
  (mocker-let ((buffer-file-name () ((:output nil))))
    (let ((engine (make-instance test-cockpit--mix-engine)))
      (should (eq (test-cockpit--engine-current-function-string engine) nil)))))

(ert-deftest test-get-elixir-test-project-command-no-switches ()
  (setq test-cockpit--project-engines nil)
  (mocker-let ((projectile-project-type () ((:output 'elixir :min-occur 0)))
               (projectile-project-root (&optional _dir) ((:input-matcher (lambda (_) t) :output "foo-project")))
               (compile (command) ((:input '("mix test") :output 'success))))
    (test-cockpit-test-project)))

(ert-deftest test-get-elixir-test-module-command-no-switches ()
  (setq test-cockpit--project-engines nil)
  (mocker-let ((projectile-project-type () ((:output 'elixir :min-occur 0)))
               (projectile-project-root (&optional _dir) ((:input-matcher (lambda (_) t) :output "foo-project")))
               (buffer-file-name () ((:output "test/foo/bar_test.exs")))
               (compile (command) ((:input '("mix test test/foo/bar_test.exs") :output 'success))))
    (test-cockpit-test-module)))

(ert-deftest test-get-elixir-test-function-command-no-switches ()
  (setq test-cockpit--project-engines nil)
  (mocker-let ((projectile-project-type () ((:output 'elixir :min-occur 0)))
               (projectile-project-root (&optional _dir) ((:input-matcher (lambda (_) t) :output "foo-project")))
               (buffer-file-name () ((:output "test/foo/bar_test.exs")))
               (line-number-at-pos () ((:output 23)))
               (compile (command) ((:input '("mix test test/foo/bar_test.exs:23") :output 'success))))
    (test-cockpit-test-function)))

(ert-deftest test-get-elixir-module-string-no-test-file ()
  (setq test-cockpit--project-engines nil)
  (mocker-let ((projectile-project-type () ((:output 'elixir :min-occur 0)))
               (projectile-project-root (&optional _dir) ((:input-matcher (lambda (_) t) :output "foo-project")))
               (buffer-file-name () ((:output "test/foo/bar.exs"))))
    (should (eq (test-cockpit--current-module-string) nil))))

(ert-deftest test-get-elixir-function-string-no-test-file ()
  (setq test-cockpit--project-engines nil)
  (mocker-let ((projectile-project-type () ((:output 'elixir :min-occur 0)))
               (projectile-project-root (&optional _dir) ((:input-matcher (lambda (_) t) :output "foo-project")))
               (buffer-file-name () ((:output "test/foo/bar.exs"))))
    (should (eq (test-cockpit--current-function-string) nil))))

(ert-deftest test-get-elixir-test-project-command-reset-switch ()
  (setq test-cockpit--project-engines nil)
  (mocker-let ((projectile-project-type () ((:output 'elixir :min-occur 0)))
               (projectile-project-root (&optional _dir) ((:input-matcher (lambda (_) t) :output "foo-project")))
               (compile (command) ((:input '("MIX_ENV=test mix ecto.reset && mix test") :output 'success))))
    (test-cockpit-test-project '("reset"))))

(ert-deftest test-get-elixir-test-module-command-reset-switch ()
  (setq test-cockpit--project-engines nil)
  (mocker-let ((projectile-project-type () ((:output 'elixir :min-occur 0)))
               (projectile-project-root (&optional _dir) ((:input-matcher (lambda (_) t) :output "foo-project")))
               (test-cockpit--current-module-string () ((:output "module-string")))
               (compile (command) ((:input '("MIX_ENV=test mix ecto.reset && mix test module-string") :output 'success))))
    (test-cockpit-test-module '("reset"))))

(ert-deftest test-get-elixir-test-function-command-reset-switch ()
  (setq test-cockpit--project-engines nil)
  (mocker-let ((projectile-project-type () ((:output 'elixir :min-occur 0)))
               (projectile-project-root (&optional _dir) ((:input-matcher (lambda (_) t) :output "foo-project")))
               (test-cockpit--current-function-string () ((:output "function-string")))
               (compile (command) ((:input '("MIX_ENV=test mix ecto.reset && mix test function-string") :output 'success))))
    (test-cockpit-test-function '("reset"))))

(ert-deftest test-get-elixir-test-project-command-failed-switch ()
  (setq test-cockpit--project-engines nil)
  (mocker-let ((projectile-project-type () ((:output 'elixir :min-occur 0)))
               (projectile-project-root (&optional _dir) ((:input-matcher (lambda (_) t) :output "foo-project")))
               (compile (command) ((:input '("mix test --failed") :output 'success))))
    (test-cockpit-test-project '("--failed"))))

(ert-deftest test-get-elixir-test-module-command-failed-switch ()
  (setq test-cockpit--project-engines nil)
  (mocker-let ((projectile-project-type () ((:output 'elixir :min-occur 0)))
               (projectile-project-root (&optional _dir) ((:input-matcher (lambda (_) t) :output "foo-project")))
               (test-cockpit--current-module-string () ((:output "module-string")))
               (compile (command) ((:input '("mix test module-string --failed") :output 'success))))
    (test-cockpit-test-module '("--failed"))))

(ert-deftest test-get-elixir-test-function-command-failed-switch ()
  (setq test-cockpit--project-engines nil)
  (mocker-let ((projectile-project-type () ((:output 'elixir :min-occur 0)))
               (projectile-project-root (&optional _dir) ((:input-matcher (lambda (_) t) :output "foo-project")))
               (test-cockpit--current-function-string () ((:output "function-string")))
               (compile (command) ((:input '("mix test function-string --failed") :output 'success))))
    (test-cockpit-test-function '("--failed"))))

(ert-deftest test-get-elixir-test-function-command-trace-switch ()
  (setq test-cockpit--project-engines nil)
  (mocker-let ((projectile-project-type () ((:output 'elixir :min-occur 0)))
               (projectile-project-root (&optional _dir) ((:input-matcher (lambda (_) t) :output "foo-project")))
               (test-cockpit--current-function-string () ((:output "function-string")))
               (compile (command) ((:input '("mix test function-string --trace") :output 'success))))
    (test-cockpit-test-function '("--trace"))))

(ert-deftest test-get-elixir-test-project-command-debug-log ()
  (setq test-cockpit--project-engines nil)
  (mocker-let ((projectile-project-type () ((:output 'elixir :min-occur 0)))
               (projectile-project-root (&optional _dir)
                                        ((:input-matcher (lambda (_) t) :output "foo-project")))
               (compile
                (command)
                ((:input '("MIX_TEST_LOGLEVEL=debug mix test") :output 'success))))
    (test-cockpit-test-project '("debuglog"))))

(ert-deftest test-mix-infix ()
  (setq test-cockpit--project-engines nil)
  (mocker-let
   ((projectile-project-type () ((:output 'elixir))))
   (let ((infix (test-cockpit-infix)))
     (should
      (and (equal (aref infix 0) "Mix specific switches")
           (equal (aref infix 1) '("-r" "Reset Ecto before test" "reset"))
           (equal (aref infix 2) '("-f" "Only lastly failed tests" "--failed"))
           (equal (aref infix 3) '("-d" "Set loglevel to \"debug\"" "debuglog"))
           (equal (aref infix 4) '("-t" "Output trace" "--trace")))))))


;;; test-mix.el-test.el ends here
