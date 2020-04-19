;;; rhythmbox.el --- Rhytmbox controller via DBus    -*- lexical-binding: t; -*-

;; Copyright (C) 2020  AmirrezaAskarpour

;; Author: AmirrezaAskarpour <raskarpour@gmail.com>
;; Keywords: 

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


(defun Rhythmbox/play-song (song)
  "Let Rhythmbox play SONG."
  (message "%s" song)
  (let ((service "org.gnome.Rhythmbox3")
        (path "/org/mpris/MediaPlayer2")
        (interface "org.mpris.MediaPlayer2.Player"))
    (dbus-call-method :session service path interface "OpenUri" (cdr song))))

;;;###autoload
(defun Rhythmbox/playpause-current-song ()
  "Play/pause the current song."
  (interactive)
  (let ((service "org.gnome.Rhythmbox3")
        (path "/org/mpris/MediaPlayer2")
        (interface "org.mpris.MediaPlayer2.Player"))
    (dbus-call-method :session service path interface
                      "PlayPause")))

(defvar Rhythmbox/songs nil "List of songs in library.")

;;;###autoload
(defun Rhythmbox/current-song-name ()
  "Return the currently playing song title."
  (interactive)
  (ignore-errors
    (let* ((entry (dbus-get-property
                   :session
                   "org.mpris.MediaPlayer2.rhythmbox"
                   "/org/mpris/MediaPlayer2"
                   "org.mpris.MediaPlayer2.Player"
                   "Metadata"))
           (artist (caar (cadr (assoc "xesam:artist" entry))))
           (album (cl-caadr (assoc "xesam:album" entry)))
           (title (cl-caadr (assoc "xesam:title" entry))))
      (message (format "%s - %s - %s" artist album title)))))


;;;###autoload
(defun Rhythmbox (&rest arg)
  "Load list of songs in Rhythmbox library using given ARG."
  (interactive "P")
  (require 'dbus)
  (when (null Rhythmbox/songs)
    (let* ((service "org.gnome.Rhythmbox3")
           (path "/org/gnome/UPnP/MediaServer2/Library/all")
           (interface "org.gnome.UPnP.MediaContainer2")
           (nb-songs (dbus-get-property
                      :session service path interface "ChildCount")))
      (if (not nb-songs)
          (error "Couldn't connect to Rhythmbox")
        (setq Rhythmbox/songs
              (mapcar (lambda (x)
                        (cons
                         (format
                          "%s - %s - %s"
                          (cl-caadr (assoc "Artist" x))
                          (cl-caadr (assoc "Album" x))
                          (cl-caadr (assoc "DisplayName" x)))
                         (cl-caaadr (assoc "URLs" x))))
                      (dbus-call-method
                       :session service path interface "ListChildren"
                       0 nb-songs '("*")))))))
  
  (let ((song-name (assoc (completing-read "Song: " Rhythmbox/songs) Rhythmbox/songs)))
    (Rhythmbox/play-song song-name)))

(provide 'rhythmbox)
;;; rhythmbox.el ends here
