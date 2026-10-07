;;; speech-input-commands.el --- Process regular-expression-based commands  -*- lexical-binding: t; -*-

;; Copyright (C) 2026  Sacha Chua

;; Author: Sacha Chua <sacha@sachachua.com>
;; Keywords: multimedia

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

;; See https://sachachua.com/dotemacs#writing-and-editing-speech-recognition-slowly-building-speech-based-commands-for-emacs

;;; Code:

(defcustom speech-input-commands nil
  "Commands as (regexp . function)"
  :type '(alist :key-type (string :tag "Regexp")
								:value-type (function :tag "Function"))
  :group 'speech-input-commands)


(defun speech-input-commands-find (text)
	"Return the row for the command matching TEXT."
	(seq-find
	 (lambda (row)
		 (string-match (format "^\\(?:%s\\)\\>" (car row)) text))
	 speech-input-commands))

;;;###autoload
(defun speech-input-commands-process (text)
	"Process commands in TEXT using `speech-input-commands'."
	(interactive (list (if (region-active-p)
												 (buffer-substring (region-beginning) (region-end))
											 (buffer-substring (line-beginning-position) (line-end-position)))))
	(let (done entry func num-args)
		(while (and text (not (string= text "")) (not done))
			(setq entry
						(speech-input-commands-find text))
			(if (null entry)
					(setq done t)
				(setq func (cdr entry))
				(setq num-args (and func (func-arity func)))
				(cond
				 ((commandp func)
					(setq text (replace-match "" nil nil text))
					(call-interactively func))
				 ((and (functionp func) (>= (cdr num-args) 1))
					(unless (match-string 1 text)
						(setq text (replace-match "" nil nil text)))
					(setq text (funcall func (or (match-string 1 text) text))))
				 ((functionp func)
					(setq text (replace-match "" nil nil text))
					(funcall func))))
			(when (string-match "^[ \\.?,]+\\(?:and \\)?" text)
				(setq text (replace-match "" nil nil text))))
		(when (string= text "") (setq text nil))
		text))


(provide 'speech-input-commands)
;;; speech-input-commands.el ends here
