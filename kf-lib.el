;;; kf-lib.el --- Kevin Fischer's personal library  -*- lexical-binding: t; -*-

;; Copyright (C) 2023 Kevin Fischer

;; Author: Kevin Fischer <kfischer_okarin@yahoo.co.jp>
;; URL: https://github.com/kfischer-okarin/kf.el
;; Version: 2023.9.15
;; Package-Requires: ((emacs "25.1")
;;                    (cl-lib "1.0")
;;                    (projectile "2.7.0"))
;; Keywords: convenience

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

;;; Commentary:

;;; Code:

;;;; Requirements

;; (require 'foo)
;; (require 'bar)

;;;; Customization

(defgroup kf-lib nil
  "Settings for `kf-lib'."
  :group 'convenience
  :link '(url-link "https://github.com/kfischer-okarin/kf-lib.el"))

;;;; Variables

;; (defvar package-name-var nil
;;   "A variable.")

;;;;; Keymaps

;; This technique makes it easier and less verbose to define keymaps
;; that have many bindings.

;; (defvar package-name-map
;;   ;; This makes it easy and much less verbose to define keys
;;   (let ((map (make-sparse-keymap "package-name map"))
;;         (maps (list
;;                ;; Mappings go here, e.g.:
;;                "RET" #'package-name-RET-command
;;                [remap search-forward] #'package-name-search-forward
;;                )))
;;     (cl-loop for (key fn) on maps by #'cddr
;;              do (progn
;;                   (when (stringp key)
;;                     (setq key (kbd key)))
;;                   (define-key map key fn)))
;;     map))

;;;; Commands

;;;###autoload
;; (defun package-name-command (args)
;;   "Frobnicate the flange."
;;   (interactive)
;;   (package-name-foo
;;    (package-name--bar args)))

;;;; Functions

;;;;; Public

;;;;;; Data structure helpers

(defun kf-lib-assoc-value (key alist &optional testfn)
  "Return the value of KEY in ALIST.

If TESTFN is non-nil, use it as the test function for `assoc'."
  (cdr (assoc key alist testfn)))

(defmacro kf-lib-set-alist-value (key value alist)
  "Set the value of KEY in ALIST to VALUE.

If KEY is not present in ALIST, add it to the front."
  `(let ((existing (assoc ,key ,alist)))
     (if existing
         (setcdr existing ,value)
       (push (cons ,key ,value) ,alist))))


;;;;;;; Emacs Automation

(defmacro kf-lib-with-minibuffer-input (input &rest body)
  "Execute BODY and use INPUT as the minibuffer input."
  `(minibuffer-with-setup-hook
       (lambda ()
         (insert ,input)
         (run-with-timer 0 nil
                         (lambda () (execute-kbd-macro (kbd "RET")))))
     ,@body))

;;;;;;; Encrypted Secrets

(defcustom kf-lib-secrets-directory user-emacs-directory
  "Directory where the encrypted secrets.json containing the secrets is stored."
  :type 'directory
  :group 'kf-lib)

(defcustom kf-lib-decrypt-secrets-command "sops -d"
  "Command to decrypt secrets."
  :type 'string
  :group 'kf-lib)

(setq kf-lib-cached-secrets nil)

(defun kf-lib-get-secret (key)
  (unless kf-lib-cached-secrets
    (let* ((decrypted-output nil)
           (asked-for-passphrase nil)
           (process (make-process :name "decrypt secrets"
                                  :command (split-string-shell-command
                                            (concat kf-lib-decrypt-secrets-command " "
                                                    (shell-quote-argument
                                                     (expand-file-name "secrets.json" kf-lib-secrets-directory))))
                                  :filter (lambda (process output)
                                            (if (string-equal output "Enter passphrase: ")
                                                (progn
                                                  (setq asked-for-passphrase t)
                                                  (process-send-string process
                                                                       (concat
                                                                        (read-passwd "Enter passphrase: ")
                                                                        "\n")))
                                              (setq decrypted-output (concat decrypted-output output)))))))
      (while (accept-process-output process))
      (if (not (zerop (process-exit-status process)))
          (error (if asked-for-passphrase
                     "Incorrect passphrase"
                   "Failed to decrypt secrets.json")))
      (setq kf-lib-cached-secrets (json-read-from-string decrypted-output))))
  (cdr (assoc key kf-lib-cached-secrets)))

;;;;; Private

;; (defun package-name--bar (args)
;;   "Return bar for ARGS."
;;   (bar args))

;;;; Footer

(provide 'kf-lib)

;;; package-name.el ends here
