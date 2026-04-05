;;; speech-input-speaches.el --- Work with speaches.ai  -*- lexical-binding: t; -*-

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

;; This module is for managing a speaches.ai server running locally.
;; Follow the instructions at https://speaches.ai/installation/ to install the server
;; and then customize `speech-input-speaches-command' and `speech-input-speaches-base-url' accordingly.

;;; Code:

(require 'request)

(defcustom speech-input-speaches-command
  `("docker" "compose" "-f"
    ,(expand-file-name "~/vendor/speaches-cuda/compose.cuda-cdi.yaml")
    "up")
  "Command to start the Speaches server.
Change this to match your installation."
  :type '(repeat string))

(defcustom speech-input-speaches-base-url "http://localhost:8000"
  "URL of instance to use."
  :type 'string
  :group 'speech-input)


(defun speech-input-speaches-models (&optional task)
  "List available models.
TASK can be \"automatic-speech-recognition\" or \"text-to-speech\"."
  (alist-get 'data
             (request-response-data
              (request
                (concat speech-input-speaches-base-url "/v1/registry"
                        (if task
                            (concat "?task=" (url-hexify-string task))
                          ""))
                :parser #'json-read
                :sync t))))

(defun speech-input-speaches-read-model-name (&optional task)
  "Prompt the user and return the name of a model for TASK."
  (let ((models (speech-input-speaches-models task)))
    (completing-read
     "Model: "
     (mapcar (lambda (o) (alist-get 'id o))
             (speech-input-speaches-models)))))

(defun speech-input-speaches-download-model (model-name)
  "Download MODEL-NAME."
  (interactive (list (speech-input-speaches-read-model-name)))
  (request
    (concat speech-input-speaches-base-url "/v1/models/" model-name)
    :type "POST"
    :sync t))

(defvar speech-input-speaches--process nil)

;;;###autoload
(defun speech-input-speaches-server-start ()
  "Start the process if it's not already running."
  (interactive)
  (unless (process-live-p speech-input-speaches--process)
    (setq speech-input-speaches--process
            (make-process
             :name "speaches"
             :command speech-input-speaches-command
             :buffer (get-buffer-create "*speaches*")
             :stderr (get-buffer-create "*speaches-err*")))))

(provide 'speech-input-speaches)
;;; speech-input-speaches.el ends here
