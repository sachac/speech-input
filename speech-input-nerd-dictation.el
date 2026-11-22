;;; speech-input-nerd-dictation.el --- Use nerd-dictation  -*- lexical-binding: t; -*-

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

;; Connect https://github.com/ideasman42/nerd-dictation with https://github.com/sachac/whisper.el with
;;
;; nerd-dictation uses Vosk, which uses time-delay neural networks
;; (TDNN) instead of transformers.

;;; Code:

(defvar speech-input-nerd-dictation-process nil "Process to listen to and recognize text.")
(defvar speech-input-nerd-dictation-begin-command '("/home/sacha/vendor/nerd-dictation/nerd-dictation" "begin" "--output=STDOUT") "Command to run.")
(defvar speech-input-nerd-dictation-end-command '("/home/sacha/vendor/nerd-dictation/nerd-dictation" "end") "Command to end.")

;;;###autoload
(defun speech-input-nerd-dictation-run ()
  "Start or stop the nerd-dictation process.
Bind this to a keyboard shortcut so that you can use it to start and
stop dictation."
  (interactive)
	(if (process-live-p speech-input-nerd-dictation-process)
			(progn
				(message "Transcribing...")
				(apply #'call-process (car speech-input-nerd-dictation-end-command) nil nil nil (cdr speech-input-nerd-dictation-end-command)))
		(with-current-buffer (get-buffer-create "*nerd-dictation*")
			(erase-buffer))
		(message "Listening...")
		(setq speech-input-nerd-dictation-process
					(make-process
					 :name "nerd-dictation"
					 :buffer (get-buffer-create "*nerd-dictation*")
					 :command speech-input-nerd-dictation-begin-command
					 :sentinel (lambda (process event)
											 (let (text)
												 (with-current-buffer (process-buffer process)
													 (when (string-match "finished" event)
														 (setq text (buffer-string))))
												 (when text
													 (whisper--process-transcription-text text))))))))

(provide 'speech-input-nerd-dictation)
;;; speech-input-nerd-dictation.el ends here
