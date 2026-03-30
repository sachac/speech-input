;;; speech-input-test.el --- Tests                   -*- lexical-binding: t; -*-

;; Copyright (C) 2026  Sacha Chua

;; Author: Sacha Chua <sacha@sachachua.com>
;; Keywords:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;;

;;; Code:
(ert-deftest speech-input-match-all ()
  "Tests `speech-input-match-all'."
  (let ((categories '(("Org Mode" "Org" "Org Mode")
                      "Other"
                      "Emacs Lisp"
                      "Writing"
                      "Appearance"
                      "Coding"
                      "Community"
                      ("Emacs configuration" "Config" "Configuration"))))
    (should (equal (speech-input-match-all "Coding Configuration Other" categories t)
                   '("Coding" "Emacs configuration" "Other")))
    (should (equal (speech-input-match-all "Org Mode Coding Configuration Other" categories t)
                   '("Org Mode" "Coding" "Emacs configuration" "Other")))
    (should (equal (speech-input-match-all "Org Coding Configuration Other" categories t)
                   '("Org Mode" "Coding" "Emacs configuration" "Other")))
    (should (equal (speech-input-match-all "Emax Lisp Coding Configuration Other" categories t)
                   '("Emacs Lisp" "Coding" "Emacs configuration" "Other")))
    (should (equal (speech-input-match-all "Writing Appearance Community" categories t)
                   '("Writing" "Appearance" "Community")))))

(ert-deftest speech-input-match-first-part ()
  "Tests `speech-input-match-first-part'."
  (let ((categories '(("Org Mode" "Org" "Org Mode")
                      "Other"
                      "Emacs Lisp"
                      "Coding"
                      ("Emacs configuration" "Config" "Configuration"))))
    (should (equal (speech-input-match-first-part "Coding Configuration Other" categories t)
                   '("Coding" . "Configuration Other")))
    (should (equal (speech-input-match-first-part "Org Mode Coding Configuration Other" categories t)
                   '("Org Mode" . "Coding Configuration Other")))
    (should (equal (speech-input-match-first-part "Org Coding Configuration Other" categories t)
                   '("Org Mode" . "Coding Configuration Other")))
    (should (equal (speech-input-match-first-part "Emax Lisp Coding Configuration Other" categories t)
                   '("Emacs Lisp" . "Coding Configuration Other")))))


(ert-deftest speech-input-match-in-list ()
  "Tests `speech-input-match-in-list'."
  (should (equal (speech-input-match-in-list "Taste" '("Option A" "Test") t) "Test"))
  (should (equal (speech-input-match-in-list "Taste" '("Option A" "Test" "Taste")) "Taste"))
  (should (equal (speech-input-match-in-list "Taste" '("Option A")) "Taste")))

(provide 'speech-input-test)
;;; speech-input-test.el ends here
