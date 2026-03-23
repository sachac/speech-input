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

(defun speech-input-transcribe-sync (filename &optional prompt)
  "Get the text for FILENAME."
  (with-temp-buffer
    (apply 'call-process
           (car speech-input-transcribe-curl-command)
           nil t nil
           "-s"
           speech-input-transcribe-url
           (append
            (cdr speech-input-transcribe-curl-command)
            (list "-H" (format "Authorization: Bearer %s" speech-input-transcribe-api-key))
            (list "-H" "Content-Type: multipart/form-data")
            (list "-F" (concat "file=@" (expand-file-name filename)))
            (list "-F" "response_format=json")
            (list "-F" (concat "prompt=" (if prompt (url-hexify-string prompt) "")))
            (list "-F" (concat "model=" speech-input-transcribe-model))))
    (goto-char (point-min))
    (alist-get 'text (json-parse-buffer :object-type 'alist))))

(provide 'speech-input-transcribe)
;;; speech-input-transcribe.el ends here
