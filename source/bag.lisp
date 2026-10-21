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

(defpackage :edefb/bag
  (:use :common-lisp
        :sigma/behave
        :FitzCLIM
        :edefb/flight)
  (:export :bag-frame
           :bag-report
           :present-report
           :show-ship))
(in-package :edefb/bag)

(define-application-frame bag-frame ()
  ((report
    :initarg :report
    :initform nil
    :accessor bag-report))
  (:pretty-name "EDEFB")
  (:panes
   (name :label :label "" :width 520 :height 24)
   (kind :label :label "" :width 520 :height 24)
   (system :label :label "" :width 520 :height 24)
   (station :label :label "" :width 520 :height 24)
   (body :label :label "" :width 520 :height 24)
   (state :label :label "" :width 520 :height 24)
   (fuel :label :label "" :width 520 :height 24)
   (cargo :label :label "" :width 520 :height 24)
   (credits :label :label "" :width 520 :height 24)
   (destination :label :label "" :width 520 :height 24))
  (:layouts
   (default (vertically (:spacing 8)
              name kind system station body state fuel cargo credits
              destination)))
  (:geometry 560 360))

(defun report-line (caption value)
  "Return one report line, CAPTION then VALUE.
An empty VALUE is shown as a dash."
  (format nil "~13A~A"
          caption
          (if (and (stringp value) (plusp (length value)))
              value
              "-")))

(defun fuel-text (report)
  "Return REPORT's fuel line, or NIL when the tank level is unknown."
  (when report
    (let ((main (report-fuel-main report))
          (capacity (report-fuel-capacity report)))
      (cond
        ((and (numberp main) (numberp capacity))
         (format nil "~,1F / ~,1F t" main capacity))
        ((numberp main)
         (format nil "~,1F t" main))))))

(defun cargo-text (report)
  "Return REPORT's cargo mass, or NIL when it is unknown."
  (when (and report (numberp (report-cargo report)))
    (format nil "~,1F t" (report-cargo report))))

(defun credits-text (report)
  "Return REPORT's credit balance, or NIL when it is unknown."
  (when (and report (numberp (report-balance report)))
    (format nil "~:D CR" (round (report-balance report)))))

(defun set-report-label (frame name text)
  "Set the label NAME of FRAME to TEXT when the text changed."
  (let ((pane (find-pane-named frame name)))
    (when (and pane (not (equal text (gadget-label pane))))
      (setf (gadget-label pane) text)))
  frame)

(defun present-report (frame)
  "Put FRAME's report on its labels."
  (let ((report (bag-report frame)))
    (set-report-label frame 'name (or (and report (report-name report)) "-"))
    (set-report-label frame 'kind (or (and report (report-type report)) "-"))
    (set-report-label frame 'system
                      (report-line "System" (and report (report-system report))))
    (set-report-label frame 'station
                      (report-line "Station" (and report (report-station report))))
    (set-report-label frame 'body
                      (report-line "Body" (and report (report-body report))))
    (set-report-label frame 'state
                      (report-line "State" (and report (report-situation report))))
    (set-report-label frame 'fuel (report-line "Fuel" (fuel-text report)))
    (set-report-label frame 'cargo (report-line "Cargo" (cargo-text report)))
    (set-report-label frame 'credits (report-line "Credits" (credits-text report)))
    (set-report-label frame 'destination
                      (report-line "Destination"
                                   (and report (report-destination report)))))
  frame)

(behavior 'present-report
  (let ((frame (make-application-frame
                'bag-frame
                :report (make-report :name "Kipling's Ghost"
                                     :type "Mandalay"
                                     :system "Sol"
                                     :station "Galileo"
                                     :body "Earth"
                                     :situation "Docked"
                                     :fuel-main 10.5
                                     :fuel-capacity 32
                                     :cargo 4
                                     :balance 2500
                                     :destination "Hutton Orbital"))))
    (present-report frame)
    (should-equal "Kipling's Ghost"
                  (gadget-label (find-pane-named frame 'name)))
    (should-equal "Mandalay"
                  (gadget-label (find-pane-named frame 'kind)))
    (should-equal "System       Sol"
                  (gadget-label (find-pane-named frame 'system)))
    (should-equal "Station      Galileo"
                  (gadget-label (find-pane-named frame 'station)))
    (should-equal "Fuel         10.5 / 32.0 t"
                  (gadget-label (find-pane-named frame 'fuel)))
    (should-equal "Credits      2,500 CR"
                  (gadget-label (find-pane-named frame 'credits)))
    (should-equal "Destination  Hutton Orbital"
                  (gadget-label (find-pane-named frame 'destination)))))

(defun update-report (frame directory)
  "Read DIRECTORY and put that report on FRAME."
  (setf (bag-report frame) (read-report directory))
  (present-report frame))

(defun refresh-report (frame directory)
  "Read DIRECTORY onto FRAME, ignoring a file that is mid-write."
  (handler-case (update-report frame directory)
    (error ()
      frame)))

(defun show-ship (&optional (directory (saved-games-directory)))
  "Open the live report for DIRECTORY and run its command loop.
The report shows the ship, where it is, and the cockpit figures.
It is read again every second until the window closes.  Returns the frame."
  (let* ((frame (make-application-frame 'bag-frame))
         (manager (make-frame-manager))
         (timer (sb-ext:make-timer
                 (lambda ()
                   (refresh-report frame directory))
                 :name "edefb-report"
                 :thread t))
         (scheduled nil))
    (update-report frame directory)
    (adopt-frame manager frame)
    (enable-frame manager frame)
    (unwind-protect
         (progn
           (sb-ext:schedule-timer timer 1 :repeat-interval 1)
           (setf scheduled t)
           (run-frame-top-level frame))
      (when scheduled
        (sb-ext:unschedule-timer timer)))
    frame))
