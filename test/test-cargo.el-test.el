
(require 'mocker)
(require 'test-cockpit-cargo)

(ert-deftest test-project-cargo-type-available ()
  (should (alist-get 'rust-cargo test-cockpit--project-types)))

(ert-deftest test-cargo-command-with-switches ()
  (dolist (struct '((nil nil "cargo test --color=always")
                    (("--doc") nil "cargo test --color=always --doc")
                    (("--doc" "--ignored") nil "cargo test --color=always --doc")
                    (("--tests") ("foo") "cargo test --color=always --tests --features foo")
                    (("--ignored") ("bar") "cargo test --color=always --features bar")
                    (("--tests") ("bar" "foo") "cargo test --color=always --tests --features bar foo")
                    ))
    (let* ((switches (pop struct))
           (test-cockpit-cargo--enabled-features (pop struct))
           (expected (pop struct)))
    (should (equal (test-cockpit-cargo--command-with-inserted-switches switches) expected))
  )))

(ert-deftest test-cargo-features-string ()
  (let ((test-cockpit-cargo--enabled-features nil))
    (should (equal (test-cockpit-cargo--features-switch) "")))
  (let ((test-cockpit-cargo--enabled-features '("foo")))
    (should (equal (test-cockpit-cargo--features-switch) "--features foo")))
  (let ((test-cockpit-cargo--enabled-features '("bar")))
    (should (equal (test-cockpit-cargo--features-switch) "--features bar")))
  (let ((test-cockpit-cargo--enabled-features '("bar" "foo")))
    (should (equal (test-cockpit-cargo--features-switch) "--features bar foo")))
  )

(ert-deftest test-cargo-current-module-string-no-file-buffer-is-nil ()
  (mocker-let ((buffer-file-name () ((:output nil))))
    (let ((engine (make-instance test-cockpit-cargo-engine)))
      (should (eq (test-cockpit--engine-current-module-string engine) nil)))))

(ert-deftest test-cargo-current-function-string-no-file-buffer-is-nil ()
  (let ((engine (make-instance test-cockpit-cargo-engine)))
    (should (eq (test-cockpit--engine-current-function-string engine) nil))))

(ert-deftest test-cargo-project-command ()
  (setq test-cockpit--project-engines nil)
  (mocker-let
      ((projectile-project-type () ((:output 'rust-cargo)))
       (projectile-project-root (&optional _dir) ((:input-matcher (lambda (_) t) :output "foo-project")))
       (test-cockpit-cargo--build-module-path-or-file-path-fallback () ((:output "bar")))
       (compile (command) ((:input '("cargo test --color=always") :output 'success :occur 1))))
    (test-cockpit-test-project)))

(ert-deftest test-cargo-project-insert-append-command ()
  (setq test-cockpit--project-engines nil)
  (mocker-let
      ((projectile-project-type () ((:output 'rust-cargo)))
       (projectile-project-root (&optional _dir) ((:input-matcher (lambda (_) t) :output "foo-project")))
       (buffer-file-name () ((:output "bar")))
       (test-cockpit-cargo--append-test-switches (args) ((:input '(nil) :output " appended")))
       (test-cockpit-cargo--build-module-path () ((:output "bar")))
       (test-cockpit-cargo--build-test-fn-path () ((:output "bar::foo_function")))
       (compile (command) ((:input '("cargo test --color=always appended") :output 'success :occur 1))))
    (test-cockpit-test-project)))

(ert-deftest test-cargo-module-command ()
  (setq test-cockpit--project-engines nil)
  (mocker-let
      ((projectile-project-type () ((:output 'rust-cargo)))
       (projectile-project-root (&optional _dir) ((:input-matcher (lambda (_) t) :output "foo-project")))
       (buffer-file-name () ((:output "bar")))
       (test-cockpit-cargo--build-module-path () ((:output "bar")))
       (compile (command) ((:input '("cargo test --color=always bar::") :output 'success :occur 1))))
    (test-cockpit-test-module)))

(ert-deftest test-cargo-module-insert-append-command ()
  (setq test-cockpit--project-engines nil)
  (mocker-let
      ((projectile-project-type () ((:output 'rust-cargo)))
       (projectile-project-root (&optional _dir) ((:input-matcher (lambda (_) t) :output "foo-project")))
       (buffer-file-name () ((:output "bar")))
       (test-cockpit-cargo--append-test-switches (args) ((:input '(nil) :output " appended")))
       (test-cockpit-cargo--build-module-path () ((:output "bar")))
       (compile (command) ((:input '("cargo test --color=always bar:: appended") :output 'success :occur 1))))
    (test-cockpit-test-module)))

(ert-deftest test-cargo-function-command ()
  (setq test-cockpit--project-engines nil)
  (mocker-let
      ((projectile-project-type () ((:output 'rust-cargo)))
       (projectile-project-root (&optional _dir) ((:input-matcher (lambda (_) t) :output "foo-project")))
       (buffer-file-name () ((:output "bar")))
       (test-cockpit-cargo--build-test-fn-path () ((:output "bar::foo_function")))
       (test-cockpit-cargo--build-module-path () ((:output "bar")))
       (compile (command) ((:input '("cargo test --color=always bar::foo_function") :output 'success :occur 1))))
    (test-cockpit-test-function)))

(ert-deftest test-cargo-function-insert-append-command ()
  (setq test-cockpit--project-engines nil)
  (mocker-let
      ((projectile-project-type () ((:output 'rust-cargo)))
       (projectile-project-root (&optional _dir) ((:input-matcher (lambda (_) t) :output "foo-project")))
       (buffer-file-name () ((:output "bar")))
       (test-cockpit-cargo--append-test-switches (args) ((:input '(nil) :output " appended")))
       (test-cockpit-cargo--build-test-fn-path () ((:output "bar::foo_function")))
       (test-cockpit-cargo--build-module-path () ((:output "bar")))
       (compile (command) ((:input '("cargo test --color=always bar::foo_function appended") :output 'success :occur 1))))
  (test-cockpit-test-function)))

(ert-deftest test-track-module-path ()
  (let ((buffer-contents "
mod fake {  }

mod foo {
    mod inner_foo {
    }
}

mod bar {
   mod inner_bar {
   }
} "))
    (dolist (struct '((2 "")
                      (16 "")
                      (30 "::foo")
                      (46 "::foo::inner_foo")
                      (52 "::foo")
                      (54 "")
                      (65 "::bar")
                      (84 "::bar::inner_bar")
                      (89 "::bar")
                      (91 "")))
      (let ((init-pos (pop struct))
            (expected-string (pop struct))
            (buf (get-buffer-create "test-buffer")))
        (with-current-buffer buf
          (insert buffer-contents)
          (goto-char 12)
          (search-backward-regexp test-cockpit-cargo--mod-regexp nil t)
            (goto-char init-pos)
            (should (equal (test-cockpit-cargo--track-module-path (point)) expected-string))
            (should (eql (point) init-pos)))
        (kill-buffer buf)))))

(ert-deftest test-build-module-path ()
  (dolist (struct '(("/home/user/src/project/src/foo.rs" "foo::inner")
                    ("/home/user/src/project/src/bar.rs" "bar::inner")
                    ("/home/user/src/project/src/foo/bar.rs" "foo::bar::inner")
                    ("/home/user/src/project/src/foo/mod.rs" "foo::inner")
                    ("/home/user/src/project/src/foo/barmod.rs" "foo::barmod::inner")
                    ("/home/user/src/project/src/lib.rs" "inner")
                    ("/home/user/src/project/src/foolib.rs" "foolib::inner")
                    ("/home/user/src/project/src/main.rs" "inner")
                    ("/home/user/src/project/src/foomain.rs" "foomain::inner")))
    (let ((file-path (pop struct))
          (expected (pop struct)))
      (mocker-let
          ((projectile-project-root () ((:output "/home/user/src/project/" :max-occur 1)))
           (buffer-file-name () ((:output file-path :max-occur 1)))
           (test-cockpit-cargo--track-module-path (initial-pos)
                                                   ((:input '(1) :output "::inner" :max-occur 1))))
        (should (equal (test-cockpit-cargo--build-module-path) expected))))))

(ert-deftest test-build-module-path-no-module ()
  (mocker-let
      ((projectile-project-root () ((:output "/home/user/src/project/" :max-occur 1)))
       (buffer-file-name () ((:output "/home/user/src/project/src/lib.rs" :max-occur 1)))
       (test-cockpit-cargo--track-module-path (initial-pos)
                                               ((:input '(1) :output "" :max-occur 1))))
    (should (equal (test-cockpit-cargo--build-module-path) nil))))

(ert-deftest test-find-test-fn-name ()
  (dolist (struct '((1 nil "use std::ptr;")
                    (31 "foo" "#[test]\nfn foo(f: i32) -> i32 { }")
                    (31 "bar" "#[test]\nfn bar(b: f32) -> f32 { }")
                    (33 "foo_2" "#[test]\nfn foo_2(f: u32) -> u32 { }")
                    (37 "foo_3" "#[test]\n    fn foo_3(f: u32) -> u32 { }")
                    (57 "foo_3" "#[test]\nfn foo_3(f: u32) -> u32 { println!(\"nofn no()\") }")
                    (29 "async_foo" "#[test]\nasync fn async_foo() { }")
                    (35 "foo" "#[test]\nfn foo(f: i32) -> i32 { } ")
                    (34 "foo" "#[test]\nfn foo<T>(f: i32) -> i32 { }")
                    (32 "foo" "#[test]\nfn foo (f: i32) -> i32 { }")
                    (41 "foo" "#[test]\n#[serial] fn foo (f: i32) -> i32 { }")
                    (23 nil "fn foo (f: i32) -> i32 { }")))
    (let ((init-pos (pop struct))
          (expected (pop struct))
          (buffer-contents (pop struct))
          (buf (get-buffer-create "test-buffer")))
      (with-current-buffer buf
        (insert buffer-contents)
        (goto-char init-pos)
        (should (eql (point) init-pos))
        (should (equal (test-cockpit-cargo--find-test-fn-name) expected)))
      (set-match-data nil)
      (kill-buffer buf))))

(ert-deftest test-build-test-fn-name-module ()
  (mocker-let ((test-cockpit-cargo--build-module-path () ((:output "module")))
               (test-cockpit-cargo--find-test-fn-name () ((:output "foo"))))
    (should (equal (test-cockpit-cargo--build-test-fn-path) "module::foo"))))

(ert-deftest test-build-test-fn-name-no-module ()
  (mocker-let ((test-cockpit-cargo--build-module-path () ((:output nil)))
               (test-cockpit-cargo--find-test-fn-name () ((:output "foo"))))
    (should (equal (test-cockpit-cargo--build-test-fn-path) "foo"))))

(ert-deftest test-cargo-insert-test-switches ()
  (dolist (struct '((() "")
                    (("--tests") "--tests")
                    (("--benches") "--benches")
                    (("--examples") "--examples")
                    (("--doc") "--doc")
                    (("--examples" "--tests") "--examples --tests")
                    (("--doc" "--tests") "--doc")
                    (("--ignored") "")))
    (let ((switches (pop struct))
          (expected (pop struct)))
      (should (equal (test-cockpit-cargo--insert-test-switches switches) expected)))))

(ert-deftest test-cargo-append-test-switches ()
  (dolist (struct '((() "")
                    (("--tests") "")
                    (("--ignored") " -- --ignored")
                    (("--include-ignored") " -- --include-ignored")
                    (("--nocapture") " -- --nocapture")
                    (("--ignored" "--nocapture") " -- --ignored --nocapture")))
    (let ((switches (pop struct))
          (expected (pop struct)))
      (should (equal (test-cockpit-cargo--append-test-switches switches) expected)))))

(ert-deftest test-cargo-read-crate-features ()
  (mocker-let
      ((projectile-project-root () ((:output "/home/user/src/project/foo/")))
       (toml:read-from-file (file) ((:input
                                     '("/home/user/src/project/foo/Cargo.toml")
                                     :output
                                     '(("package" ("version" . "3.1.4") ("name" . "foo-rs"))
                                       ("features" ("bar") ("foo"))
                                       ("dependencies" ("somedep") ("0.1.2")))))))
    (should (equal (test-cockpit-cargo--read-crate-features) '("bar" "foo")))))

(ert-deftest test-cargo-infix ()
  (mocker-let
      ((projectile-project-type () ((:output 'rust-cargo))))
    (let ((infix (test-cockpit--infix)))
      (should (and (equal (aref (aref infix 0) 0) "Targets")
                   (equal (aref (aref infix 0) 1) '("-t" "tests" "--tests"))
                   (equal (aref (aref infix 0) 2) '("-b" "with benchmarks" "--benches"))
                   (equal (aref (aref infix 0) 3) '("-x" "with examples" "--examples"))
                   (equal (aref (aref infix 0) 4) '("-d" "only doctests" "--doc"))
                   (equal (car (aref (aref infix 0) 5)) "-f")
                   (equal (aref (aref infix 1) 0) "Switches")
                   (equal (aref (aref infix 1) 1) '("-I" "only ignored tests" "--ignored"))
                   (equal (aref (aref infix 1) 2) '("-i" "include ignored tests" "--include-ignored"))
                   (equal (aref (aref infix 1) 3) '("-n" "print output" "--nocapture")))))))

;;; test-rust.el-test.el ends here
