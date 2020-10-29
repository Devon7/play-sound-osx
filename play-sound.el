;;; play-sound.el --- play sound files on MacOSX  -*- lexical-binding: t; -*-

;; Copyright (C) 2011-2013  Leo Liu
;; Copyright (c) 2020 Devon Sean McCullough

;; Author: Leo Liu <sdl.web@gmail.com>
;; Version: 1.1α
;; Keywords: audio, comm, tools, convenience

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Provide a compatibility layer for play-sound on OSX since
;; `play-sound-internal' is not implemented.

;; Provide :asynch keyword argument for asynchronous sound,
;; a feature not supported by the synchronous-only
;; built-in `play-sound-internal' function
;; as of emacs-version 27.0.91.

;;; To install:

;; (require 'play-sound)

;;; Code:

(eval-when-compile (require 'cl))


(defvar play-sound-external-function
  (case system-type
    (gnu          'play-sound--afplay) 
    (gnu/linux    'play-sound--afplay) 
    (gnu/kfreebsd 'play-sound--afplay) 
    (darwin       'play-sound--afplay) 
    (ms-dos       'play-sound--afplay) 
    (windows-nt   'play-sound--afplay) 
    (cygwin       'play-sound--afplay) 
    (t            'play-sound--afplay))
  ;; TO DO
  ;; Support players other than afplay.
  ;; Think about modifying the `play-sound' docstring.
  ;; Initially check for installed players and offer to customize.
  "Function to support `play-sound' by running a program.
Useful on builds lacking the `play-sound-internal' function
or lacking asynchronous sound support.

Should be a function, e.g., `play-sound--afplay',
which works like `play-sound' with this additional keyword:

  :async ASYNC - synchronous if ASYNC is nil, the default;
if non-nil, return without waiting for the sound to finish.")


(defun play-sound--afplay (sound)
  "See the ‘play-sound-external-function’ variable documentation."
  (or (and (eq (car-safe sound) 'sound)
	   (consp (cdr-safe sound)))
      (signal 'wrong-type-argument (list sound)))

  (destructuring-bind (&key file data volume device async)
      (cdr sound)

    (and (or data device)
         (error "DATA and DEVICE arg not supported"))

    (let ((args (append (and volume (list "-v" volume))
			(list (expand-file-name file data-directory)))))
      (if async
	  (apply #'start-process "play-sound" nil "afplay" args)
	(apply #'call-process "afplay" nil nil nil args)))))


(if (and (fboundp 'play-sound-internal)
         (subrp (symbol-function 'play-sound-internal)))

    (advice-add 'play-sound-internal :around
		(defun play-sound--async (oldfun &rest sound)
		  (apply (if (and (consp (cdr-safe sound))
				  (getf (cdr sound) :async))
			     play-sound-external-function
			   oldfun)
			 sound)))

  (defun play-sound-internal (sound)
    "Internal function for `play-sound' (which see)."
    (funcall play-sound-external-function sound)))


(provide 'play-sound)
;;; play-sound.el ends here
