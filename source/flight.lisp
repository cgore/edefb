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
  (:export :make-report
           :make-ship
           :read-report
           :read-ship
           :report
           :report-balance
           :report-body
           :report-cargo
           :report-destination
           :report-fuel-capacity
           :report-fuel-main
           :report-name
           :report-situation
           :report-station
           :report-system
           :report-type
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

(defstruct report
  "A live picture of the flight.
NAME and TYPE name the ship.  SYSTEM, STATION, and BODY say where it
is.  SITUATION is the cockpit state, such as Docked or Supercruise.
FUEL-MAIN and FUEL-CAPACITY are tons.  CARGO is tons.  BALANCE is
credits.  DESTINATION is the selected navigation target."
  name
  type
  system
  station
  body
  situation
  fuel-main
  fuel-capacity
  cargo
  balance
  destination)

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

(defun event-name (event)
  "Return EVENT's name when it is a string."
  (let ((name (gethash "event" event)))
    (when (stringp name)
      name)))

(defun event-named? (event name)
  "Return true when EVENT is a NAME event."
  (let ((found (event-name event)))
    (and found (string-equal found name))))

(defun event-one-of? (event names)
  "Return true when EVENT's name is one of NAMES."
  (let ((found (event-name event)))
    (and found (member found names :test #'string-equal))))

(defun text-value (value)
  "Return VALUE when it is a non-empty string."
  (when (and (stringp value) (plusp (length value)))
    value))

(defun status-flag? (flags bit)
  "Return true when bit BIT of FLAGS is set."
  (and (integerp flags) (logbitp bit flags)))

(defun situation-from-flags (flags flags2)
  "Return the cockpit state named by FLAGS and FLAGS2."
  (cond
    ((status-flag? flags2 0) "On foot")
    ((status-flag? flags2 1) "Taxi")
    ((status-flag? flags2 2) "Multicrew")
    ((status-flag? flags 25) "Fighter")
    ((status-flag? flags 26) "SRV")
    ((status-flag? flags 0) "Docked")
    ((status-flag? flags 1) "Landed")
    ((status-flag? flags2 12) "Glide")
    ((and (status-flag? flags 4) (status-flag? flags2 20))
     "Supercruise overdrive")
    ((status-flag? flags 4) "Supercruise")
    ((integerp flags) "In space")
    (t nil)))

(behavior 'situation-from-flags
  (should-equal "On foot" (situation-from-flags 0 1))
  (should-equal "Taxi" (situation-from-flags 0 2))
  (should-equal "Fighter" (situation-from-flags (ash 1 25) 0))
  (should-equal "SRV" (situation-from-flags (ash 1 26) 0))
  (should-equal "Docked" (situation-from-flags 1 0))
  (should-equal "Landed" (situation-from-flags 2 0))
  (should-equal "Glide" (situation-from-flags 0 4096))
  (should-equal "Supercruise overdrive"
                (situation-from-flags 16 (ash 1 20)))
  (should-equal "Supercruise" (situation-from-flags 16 0))
  (should-equal "In space" (situation-from-flags 0 0))
  (should-be-null (situation-from-flags nil nil))
  (should-equal "Docked" (situation-from-flags (logior 1 16) 0)))

(defun note-report-event (report event)
  "Copy ship, place, and fuel capacity from EVENT onto REPORT."
  (cond
    ((event-one-of? event '("LoadGame" "Loadout"))
     (setf (report-name report)
           (assign-text (report-name report) (gethash "ShipName" event))
           (report-type report)
           (assign-text (report-type report) (gethash "Ship" event)))
     (let ((capacity (gethash "FuelCapacity" event)))
       (when (numberp capacity)
         (setf (report-fuel-capacity report) capacity))))
    ((event-named? event "Location")
     (setf (report-system report)
           (assign-text (report-system report) (gethash "StarSystem" event))
           (report-body report)
           (text-value (gethash "Body" event)))
     (setf (report-station report)
           (when (eq t (gethash "Docked" event))
             (text-value (gethash "StationName" event)))))
    ((event-one-of? event '("FSDJump" "CarrierJump"))
     (setf (report-system report)
           (assign-text (report-system report) (gethash "StarSystem" event))
           (report-station report) nil
           (report-body report) nil))
    ((event-named? event "Docked")
     (setf (report-system report)
           (assign-text (report-system report) (gethash "StarSystem" event))
           (report-station report)
           (text-value (gethash "StationName" event))))
    ((event-named? event "Undocked")
     (setf (report-station report) nil))
    ((event-one-of? event '("ApproachBody" "SupercruiseExit" "Touchdown"))
     (setf (report-body report)
           (assign-text (report-body report) (gethash "Body" event))))
    ((event-named? event "LeaveBody")
     (setf (report-body report) nil)))
  report)

(defun report-from-events (events)
  "Return the report named by EVENTS.
EVENTS are JSON objects from one journal, oldest first."
  (let ((report (make-report)))
    (dolist (event events report)
      (when (hash-table-p event)
        (note-report-event report event)))))

(behavior 'report-from-events
  (let ((report (report-from-events
                 (list (parse "{\"event\":\"LoadGame\",\"Ship\":\"Mandalay\",\"ShipName\":\"Kipling's Ghost\",\"FuelCapacity\":32}")
                       (parse "{\"event\":\"Loadout\",\"Ship\":\"mandalay\"}")
                       (parse "{\"event\":\"Location\",\"StarSystem\":\"Sol\",\"Body\":\"Earth\",\"Docked\":true,\"StationName\":\"Galileo\"}")
                       (parse "{\"event\":\"Undocked\",\"StationName\":\"Galileo\"}")
                       (parse "{\"event\":\"FSDJump\",\"StarSystem\":\"Alpha Centauri\"}")
                       (parse "{\"event\":\"Docked\",\"StarSystem\":\"Alpha Centauri\",\"StationName\":\"Hutton Orbital\"}")))))
    (should-equal "Kipling's Ghost" (report-name report))
    (should-equal "Mandalay" (report-type report))
    (should= 32 (report-fuel-capacity report))
    (should-equal "Alpha Centauri" (report-system report))
    (should-equal "Hutton Orbital" (report-station report))
    (should-be-null (report-body report))))

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

(defun journal-events (directory)
  "Return the events in the newest journal in DIRECTORY."
  (events-from-lines
   (uiop:split-string (read-text (newest-journal directory))
                      :separator '(#\Newline))))

(defun read-status (directory)
  "Return the Status.json object in DIRECTORY.
NIL when the file is missing or not finished JSON."
  (let ((pathname (merge-pathnames "Status.json" directory)))
    (when (probe-file pathname)
      (handler-case
          (let ((text (string-trim '(#\Space #\Tab #\Return #\Newline)
                                   (read-text pathname))))
            (when (plusp (length text))
              (parse text)))
        (error ()
          nil)))))

(defun docked-like? (flags flags2)
  "Return true when FLAGS say the commander is at a station."
  (or (status-flag? flags 0)
      (status-flag? flags2 3)
      (status-flag? flags2 13)
      (status-flag? flags2 14)))

(defun apply-status (report status)
  "Copy the live cockpit fields of STATUS onto REPORT.
STATUS nil leaves REPORT's journal fields in place.  A status that is
not docked clears a station the journal still names."
  (when (hash-table-p status)
    (let ((flags (gethash "Flags" status))
          (flags2 (gethash "Flags2" status))
          (fuel (gethash "Fuel" status))
          (destination (gethash "Destination" status)))
      (when (hash-table-p fuel)
        (let ((main (gethash "FuelMain" fuel)))
          (when (numberp main)
            (setf (report-fuel-main report) main))))
      (when (numberp (gethash "Cargo" status))
        (setf (report-cargo report) (gethash "Cargo" status)))
      (when (numberp (gethash "Balance" status))
        (setf (report-balance report) (gethash "Balance" status)))
      (setf (report-body report) (text-value (gethash "BodyName" status)))
      (when (and (integerp flags) (not (docked-like? flags flags2)))
        (setf (report-station report) nil))
      (setf (report-situation report) (situation-from-flags flags flags2))
      (setf (report-destination report)
            (when (hash-table-p destination)
              (text-value (gethash "Name" destination))))))
  report)

(behavior 'apply-status
  (let ((report (make-report :system "Sol" :station "Galileo" :body "Earth")))
    (apply-status report
                  (parse "{\"Flags\":16,\"Flags2\":0,\"Fuel\":{\"FuelMain\":10.5,\"FuelReservoir\":0.2},\"Cargo\":4,\"Balance\":2500,\"Destination\":{\"System\":1,\"Body\":0,\"Name\":\"Hutton Orbital\"}}"))
    (should-equal "Supercruise" (report-situation report))
    (should= 10.5 (report-fuel-main report))
    (should= 4 (report-cargo report))
    (should= 2500 (report-balance report))
    (should-equal "Hutton Orbital" (report-destination report))
    (should-be-null (report-station report))
    (should-be-null (report-body report))
    (should-equal "Sol" (report-system report)))
  (let ((report (make-report :station "Galileo")))
    (apply-status report
                  (parse "{\"Flags\":1,\"BodyName\":\"Earth\"}"))
    (should-equal "Galileo" (report-station report))
    (should-equal "Earth" (report-body report))
    (should-equal "Docked" (report-situation report)))
  (let ((report (make-report :station "Galileo" :system "Sol")))
    (apply-status report nil)
    (should-equal "Galileo" (report-station report))
    (should-equal "Sol" (report-system report))))

(defun read-report (directory)
  "Return the live report for the newest journal and Status.json in
DIRECTORY."
  (apply-status (report-from-events (journal-events directory))
                (read-status directory)))

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

(behavior 'read-report
  (let ((directory (merge-pathnames
                    "edefb-report-test/"
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
                         output)
             (write-line "{\"event\":\"Location\",\"StarSystem\":\"Sol\",\"Docked\":true,\"StationName\":\"Old Station\"}"
                         output))
           (with-open-file (output (merge-pathnames
                                    "Journal.2026-10-20T180726.01.log"
                                    directory)
                                   :direction :output
                                   :if-exists :supersede
                                   :external-format :utf-8)
             (write-line "{\"event\":\"LoadGame\",\"Ship\":\"Mandalay\",\"ShipName\":\"Kipling's Ghost\",\"FuelCapacity\":32}"
                         output)
             (write-line "{\"event\":\"Location\",\"StarSystem\":\"Sol\",\"Body\":\"Earth\",\"Docked\":true,\"StationName\":\"Galileo\"}"
                         output)
             (write-line "{\"event\":\"FSDJump\",\"StarSystem\":\"Alpha Centauri\"}"
                         output)
             (write-line "{\"event\":\"Load\"" output))
           (with-open-file (output (merge-pathnames "Status.json" directory)
                                   :direction :output
                                   :if-exists :supersede
                                   :external-format :utf-8)
             (write-line "{\"Flags\":" output))
           (let ((report (read-report directory)))
             (should-equal "Kipling's Ghost" (report-name report))
             (should-equal "Mandalay" (report-type report))
             (should-equal "Alpha Centauri" (report-system report))
             (should-be-null (report-station report))
             (should-be-null (report-situation report)))
           (with-open-file (output (merge-pathnames "Status.json" directory)
                                   :direction :output
                                   :if-exists :supersede
                                   :external-format :utf-8)
             (write-line "{\"event\":\"Status\",\"Flags\":16,\"Fuel\":{\"FuelMain\":10.5,\"FuelReservoir\":0.2},\"Cargo\":4,\"Balance\":2500,\"Destination\":{\"System\":1,\"Body\":0,\"Name\":\"Hutton Orbital\"}}"
                         output))
           (let ((report (read-report directory)))
             (should-equal "Supercruise" (report-situation report))
             (should= 10.5 (report-fuel-main report))
             (should= 32 (report-fuel-capacity report))
             (should= 4 (report-cargo report))
             (should= 2500 (report-balance report))
             (should-equal "Hutton Orbital" (report-destination report))
             (should-be-null (report-station report))))
      (uiop:delete-directory-tree
       directory
       :validate (lambda (pathname)
                   (search "edefb-report-test"
                           (namestring pathname)))))))
