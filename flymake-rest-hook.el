;;; flymake-rest-hook.el --- Support for binding flymake backends to specific modes -*- lexical-binding: t -*-

;; Copyright (c) 2021 Mohsin Kaleem

;; Permission is hereby granted, free of charge, to any person obtaining a copy
;; of this software and associated documentation files (the "Software"), to deal
;; in the Software without restriction, including without limitation the rights
;; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
;; copies of the Software, and to permit persons to whom the Software is
;; furnished to do so, subject to the following conditions:

;; The above copyright notice and this permission notice shall be included in all
;; copies or substantial portions of the Software.

;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
;; SOFTWARE.

;;; Commentary
;; This file implements a way to associate major-modes to flymake checkers.

;;; Code:

(require 'cl-lib)

;;;###autoload
(defcustom flymake-rest-config
  '((python-mode
     flymake-rest-pycodestyle
     (flymake-mypy :disabled t)
     (flymake-rest-pylint :disabled t))
    (awk-mode flymake-rest-awk-gawk)
    (c-mode
     flymake-rest-clang
     (flymake-rest-gcc :disabled t))
    (c++-mode
     flymake-rest-clang
     (flymake-rest-gcc :disabled t))
    (js-mode flymake-rest-eslint)
    (js2-mode flymake-rest-eslint)
    (typescript-mode flymake-rest-eslint)
    (json-mode
     flymake-rest-jq
     (flymake-rest-jsonlint :disabled t))
    (less-mode flymake-rest-less)
    (markdown-mode
     flymake-rest-markdownlint
     flymake-rest-proselint)
    (lua-mode
     flymake-rest-luacheck
     (flymake-rest-lua :disabled t))
    (sql-mode
     flymake-rest-sql-lint
     (flymake-rest-sqlint :disabled t))
    (ruby-mode flymake-rest-rubocop)
    ;; (hledger-mode flymake-rest-hledger)
    (sh-mode flymake-rest-shellcheck)
    (yaml-mode flymake-rest-yamllint)
    (web-mode flymake-rest-html-tidy)
    (org-mode flymake-rest-proselint)
    (notmuch-message-mode flymake-rest-proselint)
    (nxml-mode flymake-rest-xmllint))
  "Configuration mapping major-modes to `flymake' backends."
  :type 'list
  :group 'flymake-rest)

(defcustom flymake-rest-config-inherit nil
  "When true diagnostic hooks inherit parent-mode hooks."
  :type 'boolean
  :group 'flymake-rest)

(defun flymake-rest-configured-checkers (mode)
  "Fetch the list of diagnostic functions configured for MODE."
  (let (checkers
        (modes (list mode)))
    ;; Consider all the parent modes as well.
    (when flymake-rest-config-inherit
      (while (setq mode (get mode 'derived-mode-parent))
        (push mode modes)))
    ;; For each mode populate the checkers alist with (checker . depth).
    (dolist (mode modes)
      (dolist (conf (alist-get mode flymake-rest-config))
        (cond ((symbolp conf)
               (push (cons conf nil) checkers))
              ((consp conf)
               (cl-destructuring-bind (checker &optional &key depth predicate disabled &allow-other-keys)
                   (if (numberp conf)
                       `(,(car conf) :depth ,(cdr conf))
                     conf)
                 (when (and (not disabled)
                            (or (not predicate)
                                (funcall predicate)))
                   (push (cons checker depth) checkers))))
              (t
               (warn "Unknown checker config in `flymake-rest-config': %s" conf)))))
    (nreverse checkers)))

(defcustom flymake-rest-hook-ignore-modes nil
  "List of modes in which `flymake-rest-hook' is inhibited."
  :type '(list symbol))

(defun flymake-rest-hook-set-backends ()
  "Setup `flymake-diagnostic-functions' using `flymake-rest-config'."
  (unless (cl-find-if (lambda (mode)
                        (or (eq major-mode mode)
                            (and (boundp mode)
                                 (eval mode))))
                      flymake-rest-hook-ignore-modes)
    (dolist (it (flymake-rest-configured-checkers major-mode))
      (add-hook 'flymake-diagnostic-functions (car it) (cdr it) t))))

;;;###autoload
(defun flymake-rest-hook-setup ()
  "Setup flymake-hook."
  (add-hook 'after-change-major-mode-hook #'flymake-rest-hook-set-backends))

(defun flymake-rest-hook-teardown ()
  "Tear down flymake-hook."
  (remove-hook 'after-change-major-mode-hook #'flymake-rest-hook-set-backends))

(provide 'flymake-rest-hook)

;;; flymake-rest-hook.el ends here
