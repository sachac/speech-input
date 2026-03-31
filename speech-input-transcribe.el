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

(defvar speech-input-transcribe-url "http://localhost:8001/v1/audio/transcriptions")
(defvar speech-input-transcribe-model "Systran/faster-whisper-base.en")
(defvar speech-input-transcribe-language "en")
(defvar speech-input-transcribe-api-key "Not needed for local")
(defvar speech-input-transcribe-curl-command '("curl"))
(defvar speech-input-transcribe-prompt nil)

(defun speech-input-transcribe-curl-args (filename prompt)
  (append
   (list "-s" speech-input-transcribe-url)
   (cdr speech-input-transcribe-curl-command)
   (list
    "-H" (format "Authorization: Bearer %s" speech-input-transcribe-api-key)
    "-H" "Content-Type: multipart/form-data"
    "-F" (concat "file=@" (expand-file-name filename))
    "-F" "response_format=json"
    "-F" (concat "prompt=" (if prompt (url-hexify-string prompt) ""))
    "-F" (concat "model=" speech-input-transcribe-model))))

(defun speech-input-transcribe-sync (filename &optional prompt delete-after)
  (speech-input-transcribe filename nil prompt delete-after))

(defun speech-input-transcribe (filename &optional callback prompt delete-after)
  "Get the text for FILENAME.
If PROMPT is specified, pass it to the transcription process.
If DELETE-AFTER is non-nil, delete the audio file."
  (with-temp-buffer
    (if (or (eq callback 'sync) (null callback))
        (apply 'call-process
               (car speech-input-transcribe-curl-command)
               nil t nil
               (speech-input-transcribe-curl-args filename prompt))
      (apply 'start-process
             "transcribe"
             (current-buffer)
             (car speech-input-transcribe-curl-command)
             (speech-input-transcribe-curl-args filename prompt)))
    (goto-char (point-min))
    (let ((text (alist-get 'text (json-parse-buffer :object-type 'alist))))
      (when callback
        (funcall callback
                 text))
      (when delete-after (delete-file filename))
      text)))

(provide 'speech-input-transcribe)
;;; speech-input-transcribe.el ends here
