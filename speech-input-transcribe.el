;;; speech-input-transcribe.el --- Transcribe audio with OpenAI-compatible services  -*- lexical-binding: t; -*-

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

;;

;;; Code:

(defcustom speech-input-transcribe-url "http://localhost:8000/v1/audio/transcriptions"
  "URL of instance to use.
If it is a function, call it with the filename and callback instead."
  :group 'speech-input)

(defcustom speech-input-transcribe-api-key "not needed for local"
  "API key to use."
  :group 'speech-input)

(defcustom speech-input-transcribe-model "Systran/faster-whisper-base.en"
  "API key to use."
  :group 'speech-input)

(defvar speech-input-transcribe-curl-command '("curl" "-s"))
(defvar speech-input-transcribe-prompt nil)

(defun speech-input-transcribe-file-to-json (filename &optional callback delete-after)
  "Send FILENAME to the transcribe endpoint and return the result JSON.
If CALLBACK is specified, transcribe asynchronously and call CALLBACK with the results.
If DELETE-AFTER is non-nil, delete the audio file.

If `speech-input-transcribe-url' is a function, call it with the filename and callback instead."
  (prog1
			(if (stringp speech-input-transcribe-url)
					(speech-input-curl-json
					 speech-input-transcribe-url
					 (list (concat "Authorization: Bearer " speech-input-transcribe-api-key)
								 "Content-type: multipart/form-data")
					 (delq nil
								 (list (concat "model=" speech-input-transcribe-model)
											 (concat "file=@" filename)
											 "response_format=json"
											 (if speech-input-transcribe-prompt
													 (concat "prompt=" speech-input-transcribe-prompt)
												 nil)))
					 (if (and (functionp callback) delete-after)
							 (lambda (result)
								 (delete-file filename)
								 (funcall callback result))
						 callback))
				(funcall speech-input-transcribe-url filename
								 (if (and (functionp callback) delete-after)
										 (lambda (result)
											 (delete-file filename)
											 (funcall callback result))
									 callback)))
    (when (and delete-after (not (functionp callback)))
      (delete-file filename))))

;;;###autoload
(defun speech-input-transcribe (filename &optional callback delete-after)
  "Get the text for FILENAME.
If CALLBACK is specified, transcribe asynchronously and call CALLBACK with the results.
If DELETE-AFTER is non-nil, delete the audio file."
	(interactive "FFile: ")
  (if (functionp callback)
      (speech-input-transcribe-file-to-json filename
                     (lambda (result)
                       (funcall callback (alist-get 'text result))))
		(let ((result (alist-get 'text (speech-input-transcribe-file-to-json filename))))
			(when (called-interactively-p 'any)
				(kill-new result)
				(message "%s" result))
			result)))

(provide 'speech-input-transcribe)
;;; speech-input-transcribe.el ends here
