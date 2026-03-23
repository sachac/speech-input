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

(defun speech-input-transcribe-sync (filename)
  "Get the text for FILENAME."
  (let* ((boundary (format "%s%d" (make-string 20 ?-) (time-to-seconds)))
         (url-request-method "POST")
         (url-request-extra-headers
          (append
           (list
            (cons "Content-Type"
                  (concat "multipart/form-data; boundary=" boundary))
            (cons "Authorization" (concat "Bearer " speech-input-transcribe-api-key)))
           url-request-extra-headers))
         (url-request-data
          (mm-url-encode-multipart-form-data
           `(("file" .
              (("name" . "file")
               ("filename" . ,(file-name-nondirectory filename))
               ("content-type" . "audio/wav")
               ("filedata" . ,(with-temp-buffer
                                (insert-file-contents-literally filename)
                                (buffer-string)))))
             ("model" . ,speech-input-transcribe-model)))))
    (with-current-buffer (url-retrieve-synchronously speech-input-transcribe-url)
      (goto-char (point-min))
      (re-search-forward "^$")
      (prog1 (buffer-substring (point) (point-max))
        (kill-buffer (current-buffer))))))

;; (mpv-play "~/recordings/whisper/2026-03-04-10-24-29.wav")
;; (speech-input-transcribe-sync "~/recordings/whisper/2026-03-04-10-24-29.wav")
(provide 'speech-input-transcribe)
;;; speech-input-transcribe.el ends here
