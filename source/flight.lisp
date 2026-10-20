;;;; Copyright (c) 2026, Christopher Mark Gore,
;;;; Soli Deo Gloria,
;;;; All rights reserved.
;;;;
;;;; 22 Forest Glade Court, Saint Charles, Missouri 63304 USA.
;;;; Web: http://cgore.com
;;;; Email: cgore@cgore.com
;;;;
;;;; Redistribution and use in source and binary forms, with or without
;;;; modification, are permitted provided that the following conditions are met:
;;;;
;;;;     * Redistributions of source code must retain the above copyright
;;;;       notice, this list of conditions and the following disclaimer.
;;;;
;;;;     * Redistributions in binary form must reproduce the above copyright
;;;;       notice, this list of conditions and the following disclaimer in the
;;;;       documentation and/or other materials provided with the distribution.
;;;;
;;;;     * Neither the name of Christopher Mark Gore nor the names of other
;;;;       contributors may be used to endorse or promote products derived from
;;;;       this software without specific prior written permission.
;;;;
;;;; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
;;;; AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
;;;; IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
;;;; ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
;;;; LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
;;;; CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
;;;; SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
;;;; INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
;;;; CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
;;;; ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
;;;; POSSIBILITY OF SUCH DAMAGE.

(defpackage :edefb/flight
  (:use :common-lisp
        :sigma/behave)
  (:import-from :com.inuoe.jzon
                :parse)
  (:export :make-ship
           :read-ship
           :saved-games-directory
           :ship
           :ship-from-events
           :ship-name
           :ship-type))
(in-package :edefb/flight)

(defstruct ship
  "The ship being flown.  NAME is the name the commander gave it.
TYPE is the ship type."
  name
  type)

(defun saved-games-directory ()
  "Return this user's Elite Dangerous player directory."
  (merge-pathnames
   (make-pathname :directory '(:relative "Saved Games"
                               "Frontier Developments"
                               "Elite Dangerous"))
   (user-homedir-pathname)))

(defun journal-file? (pathname)
  "Return true when PATHNAME is a player journal."
  (let ((name (pathname-name pathname)))
    (and (stringp name)
         (>= (length name) 8)
         (string-equal name "Journal." :end1 8)
         (string-equal (or (pathname-type pathname) "") "log"))))

(behavior 'journal-file?
  (should-be-true
   (journal-file? (make-pathname :name "Journal.2026-10-20T180726.01"
                                 :type "log")))
  (should-be-false (journal-file? (make-pathname :name "Status" :type "json"))))

(defun read-text (pathname)
  "Return the characters of PATHNAME."
  (with-output-to-string (output)
    (with-open-file (input pathname :direction :input :external-format :utf-8)
      (loop for character = (read-char input nil nil)
            while character
            do (write-char character output)))))

(defun assign-text (current value)
  "Return VALUE when it names something, keeping CURRENT's spelling.
A later value that differs only by case leaves CURRENT in place."
  (cond
    ((not (stringp value)) current)
    ((zerop (length value)) current)
    ((and (stringp current) (string-equal current value)) current)
    (t value)))

(behavior 'assign-text
  (should-equal "Mandalay" (assign-text "Mandalay" "mandalay"))
  (should-equal "Cobra Mk III" (assign-text "Mandalay" "Cobra Mk III"))
  (should-equal "Mandalay" (assign-text nil "Mandalay")))

(defun note-ship-event (ship event)
  "Copy a ship name and type from EVENT onto SHIP.
LoadGame and Loadout carry those fields.  Other events are ignored."
  (let ((name (gethash "event" event)))
    (when (and (stringp name)
               (or (string-equal name "LoadGame")
                   (string-equal name "Loadout")))
      (setf (ship-name ship) (assign-text (ship-name ship)
                                          (gethash "ShipName" event))
            (ship-type ship) (assign-text (ship-type ship)
                                          (gethash "Ship" event)))))
  ship)

(defun ship-from-events (events)
  "Return the ship named by EVENTS.
EVENTS are JSON objects from one journal, oldest first."
  (let ((ship (make-ship)))
    (dolist (event events ship)
      (when (hash-table-p event)
        (note-ship-event ship event)))))

(behavior 'ship-from-events
  (let ((ship (ship-from-events
               (list (parse "{\"event\":\"LoadGame\",\"Ship\":\"Mandalay\",\"ShipName\":\"Kipling's Ghost\"}")
                     (parse "{\"event\":\"Loadout\",\"Ship\":\"mandalay\",\"ShipName\":\"Kipling's Ghost\"}")
                     (parse "{\"event\":\"Location\",\"StarSystem\":\"Sol\"}")))))
    (should-equal "Kipling's Ghost" (ship-name ship))
    (should-equal "Mandalay" (ship-type ship))))

(defun events-from-lines (lines)
  "Return the JSON objects in LINES.
A final line that is not finished JSON is dropped.  An earlier broken
line is an error."
  (let ((events nil)
        (pending nil))
    (dolist (line lines)
      (let ((text (string-trim '(#\Space #\Tab #\Return) line)))
        (unless (zerop (length text))
          (when pending
            (push (parse pending) events))
          (setf pending text))))
    (when pending
      (handler-case (push (parse pending) events)
        (error ()
          nil)))
    (nreverse events)))

(behavior 'events-from-lines
  (let ((events (events-from-lines
                 (list "{\"event\":\"LoadGame\",\"Ship\":\"Adder\"}"
                       "{\"event\":\"Load\""))))
    (should= 1 (length events))
    (should-equal "Adder" (gethash "Ship" (first events))))
  (handler-case
      (progn
        (events-from-lines '("{" "{\"event\":\"LoadGame\"}"))
        (should-be-true nil))
    (error ()
      (should-be-true t))))

(defun newest-journal (directory)
  "Return the newest journal pathname in DIRECTORY."
  (let ((journals (remove-if-not
                   #'journal-file?
                   (directory (merge-pathnames "*.log" directory)))))
    (unless journals
      (error "No player journal in ~A." directory))
    (first (sort journals #'string> :key #'namestring))))

(defun read-ship (directory)
  "Return the ship named by the newest journal in DIRECTORY."
  (ship-from-events
   (events-from-lines
    (uiop:split-string (read-text (newest-journal directory))
                       :separator '(#\Newline)))))

(behavior 'read-ship
  (let ((directory (merge-pathnames
                    "edefb-ship-test/"
                    (uiop:temporary-directory))))
    (ensure-directories-exist directory)
    (unwind-protect
         (progn
           (with-open-file (output (merge-pathnames
                                    "Journal.2026-01-01T000000.01.log"
                                    directory)
                                   :direction :output
                                   :if-exists :supersede
                                   :external-format :utf-8)
             (write-line "{\"event\":\"LoadGame\",\"Ship\":\"Adder\",\"ShipName\":\"Old\"}"
                         output))
           (with-open-file (output (merge-pathnames
                                    "Journal.2026-10-20T180726.01.log"
                                    directory)
                                   :direction :output
                                   :if-exists :supersede
                                   :external-format :utf-8)
             (write-line "{\"event\":\"LoadGame\",\"Ship\":\"Mandalay\",\"ShipName\":\"Kipling's Ghost\"}"
                         output)
             (write-line "{\"event\":\"Loadout\",\"Ship\":\"mandalay\"}" output))
           (let ((ship (read-ship directory)))
             (should-equal "Kipling's Ghost" (ship-name ship))
             (should-equal "Mandalay" (ship-type ship))))
      (uiop:delete-directory-tree
       directory
       :validate (lambda (pathname)
                   (search "edefb-ship-test"
                           (namestring pathname)))))))
