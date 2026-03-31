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

(defvar speech-input-string-distance-threshold 0.3)

(defun speech-input--reshape-collection (collection)
  "Make collection a consistent shape of ((result-string candidate1 candidate2...) ...)"
  (mapcar (lambda (o)
            (cond
             ((stringp o) (list o o))
             ((stringp (cdr o))
              (list (car o) (cdr o)))
             (t o)))
          collection))

(defun speech-input-get-list-distances (text collection)
  "Find the item in COLLECTION that is closest to TEXT.
Return a list of (distance candidate main-value)"
  (let* ((collection (speech-input--reshape-collection collection))
         (normalized (speech-input-normalize-string text)))
    (sort
     (seq-mapcat
      (lambda (o)
        (mapcar
         (lambda (cand)
           (list
            (string-distance
             normalized
             (speech-input-normalize-string cand))
            cand
            (car o)))
         (cdr o)))
      collection)
     :key 'car)))

(defun speech-input-string-approx (text other-text)
  "Return non-nil if TEXT is approximately the same as OTHER-TEXT.
TEXT can also be the previously-calculated distance."
  (when (stringp text)
    (setq text (speech-input-normalize-string text))
    (setq other-text (speech-input-normalize-string other-text)))
  (or (null speech-input-string-distance-threshold)
      (<=
       (/ (if (numberp text)
              text
            (string-distance text other-text))
          (* 1.0
             (if (numberp text)
                 (length other-text)
               (max (length text) (length other-text)))))
       speech-input-string-distance-threshold)))

(defun speech-input-match-in-list (text collection)
  "Return the best-matching candidate from collection."
  (let ((by-distance (speech-input-get-list-distances text collection)))
    (if (speech-input-string-approx
         (elt (car by-distance) 0)
         (elt (car by-distance) 1))
        (elt (car by-distance) 2)
      text)))

;; TODO: fuzz the number of words
(defun speech-input-get-first-part-distances (text collection)
  "Try to match COLLECTION against the first part of TEXT.
The candidate may involve multiple words."
  (let* ((words (split-string text))
         (normalized-words (mapcar #'speech-input-normalize-string words))
         (by-distance
          (seq-filter
           (lambda (o)
             (speech-input-string-approx (elt o 0) (elt o 1)))
           (seq-mapcat
            (lambda (cand-group)
              (mapcar
               (lambda (o)
                 (let* ((normalized (speech-input-normalize-string o))
                        (cand-words (split-string normalized))
                        ;; Get that number of words; TODO: fuzz
                        (prefix (string-join (seq-take normalized-words (length cand-words)) " ")))
                   (list
                    (string-distance normalized prefix)
                    o
                    (car cand-group))))
               (cdr cand-group)))
            (speech-input--reshape-collection collection)))))
    (sort by-distance
          :lessp
          (lambda (a b)
            ;; Sort by score and then by length
            (cond
             ((< (elt a 0) (elt b 0)) t)
             ((> (elt a 0) (elt b 0)) nil)
             ((> (length (elt a 1)) (length (elt b 1))) t)
             ((< (length (elt a 1)) (length (elt b 1))) nil)
             (t t))))))

(defun speech-input-match-first-part (text collection)
  "Try to match COLLECTION against the first part of TEXT.
The candidate may involve multiple words.
Return (candidate . remaining-text)."
  (let* ((words (split-string text))
         (distances (speech-input-get-first-part-distances text collection)))
    (if (car distances)
        (cons
         (elt (car distances) 2)
         (string-join
          (seq-drop words (length (split-string (elt (car distances) 1))))
          " "))
      (cons nil text))))

(defun speech-input-match-all (text collection)
  "Try to match COLLECTION against TEXT.
The candidate may involve multiple words.
Return a list of options."
  (let (results)
    (while (not (string= text ""))
      (let ((result (speech-input-match-first-part text collection)))
        (push (car result) results)
        (setq text (cdr result))))
    (nreverse results)))

(defun speech-input-from-list (prompt collection callback &optional normalize-fn)
  "Choose the closest entry from COLLECTION and call CALLBACK with the result and the actual text.
COLLECTION can be a list of strings, a list of (result-string . candidate-string),
or a list of (result-string candidate1 candidate2 candidate3...)."
  (when prompt (message "%s" prompt))
  (speech-input-vad-record-one-turn
   (lambda (filename)
     (let* ((collection (speech-input--reshape-collection collection))
            (prompt (mapconcat
                     (lambda (o)
                       (string-join (cdr o) ", "))
                     collection ", "))
            (text (speech-input-transcribe-sync
                   filename
                   prompt t)))
       (funcall callback
                (speech-input-match-in-list text collection must-match normalize-fn)
                text)))))

(defun speech-input-multiple-from-list (prompt collection each-callback after-all-callback)
  "Call CALLBACK for each recognized item."
  (when prompt (message "%s" prompt))
  (speech-input-vad-record-one-turn
   (lambda (filename)
     (let* ((collection (speech-input--reshape-collection collection))
            (prompt (mapconcat
                     (lambda (o)
                       (string-join (cdr o) ", "))
                     collection ", "))
            (text (speech-input-transcribe-sync
                   filename
                   prompt t))
            (commands (speech-input-match-all text collection)))
       (when each-callback
         (seq-reduce (lambda (prev value)
                       (funcall each-callback value prev))
                     commands nil))
       (when after-all-callback
         (funcall after-all-callback commands text))))))

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
