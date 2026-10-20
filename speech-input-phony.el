;;; speech-input-phony.el --- Work with phony.el to define grammar  -*- lexical-binding: t; -*-

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

;; phony.el: https://github.com/ErikPrantare/phony.el

;; To use phony.el without using TalonVoice, you can
;; (setq phony-export-function #'ignore)
;;; Code:

(require 'phony-parser)

;;;###autoload
(defun speech-input-phony-process (text)
  "Evaluate TEXT.
Pass TEXT through if not parsed.
Add this to `whisper-insert-text-at-point'."
	(if (eq (phony-evaluate text 'not-parsed) 'not-parsed)
			text
		;; parsed and executed, so don't continue
		""))

(provide 'speech-input-phony)
;;; speech-input-phony.el ends here
