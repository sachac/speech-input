;;; speech-input.el --- Speech input                 -*- lexical-binding: t; -*-

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

(require 'speech-input-transcribe)
(require 'speech-input-vad)

(defvar speech-input-recording-process nil)
(defvar speech-input-recording-command '("ffmpeg" "-y" "-f" "pulse" "-i" "default" "-f" "wav" "-ar" "22050" "-ac" "1"))

(defun speech-input-insert-once ()
  "Record and transcribe one speech segment."
  (interactive)
  (speech-input-vad-record-one-turn
   (lambda (filename)
     (let ((text (speech-input-transcribe-sync filename)))
       (insert text)
       (delete-file filename)))))

(defun speech-input-normalize-string (s)
  "Simplify S for easier comparison."
  (downcase (replace-regexp-in-string "[^A-Za-z0-9 ]+" " " s)))

(defvar speech-input-string-distance-threshold 0.2)

(defun speech-input-from-list (prompt collection callback &optional must-match normalize-fn)
  "Choose the closest entry from COLLECTION and call CALLBACK with the result and the actual text.
COLLECTION can be a list of strings, a list of (result-string . candidate-string),
or a list of (result-string candidate1 candidate2 candidate3...).
If MUST-MATCH is nil, closest match is returned within `speech-input-string-distance-threshold',
or the speech recognition result otherwise."
  (interactive)
  (when prompt (message "%s" prompt))
  ;; Make collection a consistent shape of (result-string candidate1 candidate2...)
  (setq collection
        (mapcar (lambda (o)
                  (cond
                   ((stringp o) (list o o))
                   ((stringp (cdr o))
                    (list (car o) (cdr o)))
                   (t o)))
                collection))
  (speech-input-vad-record-one-turn
   (lambda (filename)
     (let* ((prompt (mapconcat
                     (lambda (o)
                       (string-join (cdr o) ", "))
                     collection ", "))
            (text (speech-input-transcribe-sync
                   filename
                   prompt))
            (normalized (funcall (or normalize-fn 'speech-input-normalize-string) text))
            (by-distance
             (sort
              (seq-mapcat
               (lambda (o)
                 (mapcar
                  (lambda (cand)
                    (list
                     (string-distance
                      normalized
                      (funcall (or normalize-fn 'speech-input-normalize-string) cand))
                     cand
                     (car o)))
                  (cdr o)))
               collection)
              :key 'car)))
       (delete-file filename)
       (funcall callback
                (if (or must-match
                        (<
                         (/ (elt (car by-distance) 0)
                            (* 1.0 (max (length text) (length (elt (car by-distance) 1)))))
                         speech-input-string-distance-threshold))
                    (elt (car by-distance) 2)
                  text)
                text)))))

;; (speech-input-from-list "Yes or no?" '("Yes" "No") (lambda (s) (message "%s" s)))
;; (speech-input-from-list "Yes or no?" '(("Yes" "Yes" "Yup" "Yeah" "Uh huh" "Sure" "Go ahead") ("No" "No" "Nope")) (lambda (s) (message "%s" s)))

(defvar speech-input-recording-filename nil)

(defun speech-input-stop-recording ()
  (interactive)
  (when (process-live-p speech-input-recording-process)
    (interrupt-process speech-input-recording-process)))

(defun speech-input-start-recording (callback &optional filename)
  (interactive)
  (when (process-live-p speech-input-recording-process)
    (interrupt-process speech-input-recording-process))
  (let* ((temp-file (or filename (make-temp-file "speech-input" nil ".wav"))))
    (setq speech-input-recording-filename temp-file)
    (setq speech-input-recording-process
          (make-process
           :name "record"
           :buffer "*record*"
           :command (append speech-input-recording-command (list temp-file))))
    (set-process-sentinel speech-input-recording-process
                          (lambda (proc status)
                            (when (and (string-match "finished\\|exited\\|killed" status)
                                       callback)
                              (funcall callback temp-file))))))

(defun speech-input-cancel-recording ()
  "Discard the current recording."
  (interactive)
  (when (process-live-p speech-input-recording-process)
    (set-process-sentinel speech-input-recording-process nil))
  (speech-input-stop-recording)
  (remove-hook 'speech-input-vad-on-end-functions 'speech-input-vad-stop-recording-once)
  (when (and speech-input-recording-filename (file-exists-p speech-input-recording-filename))
    (delete-file speech-input-recording-filename)))

(provide 'speech-input)
;;; speech-input.el ends here
