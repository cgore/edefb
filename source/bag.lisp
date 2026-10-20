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
           :bag-ship
           :present-ship
           :show-ship))
(in-package :edefb/bag)

(define-application-frame bag-frame ()
  ((ship
    :initarg :ship
    :accessor bag-ship))
  (:pretty-name "EDEFB")
  (:panes
   (name :label :label "" :width 400 :height 24)
   (kind :label :label "" :width 400 :height 24))
  (:layouts
   (default (vertically (:spacing 8) name kind)))
  (:geometry 420 120))

(defun present-ship (frame)
  "Put FRAME's ship name and type on its labels."
  (let ((ship (bag-ship frame)))
    (setf (gadget-label (find-pane-named frame 'name))
          (or (and ship (ship-name ship)) ""))
    (setf (gadget-label (find-pane-named frame 'kind))
          (or (and ship (ship-type ship)) "")))
  frame)

(behavior 'present-ship
  (let ((frame (make-application-frame
                'bag-frame
                :ship (make-ship :name "Kipling's Ghost" :type "Mandalay"))))
    (present-ship frame)
    (should-equal "Kipling's Ghost"
                  (gadget-label (find-pane-named frame 'name)))
    (should-equal "Mandalay"
                  (gadget-label (find-pane-named frame 'kind)))))

(defun show-ship (&optional (directory (saved-games-directory)))
  "Open the flight bag on DIRECTORY and run its command loop.
The frame shows the ship name and the ship type.  Returns the frame."
  (let ((frame (make-application-frame 'bag-frame
                                       :ship (read-ship directory)))
        (manager (make-frame-manager)))
    (present-ship frame)
    (adopt-frame manager frame)
    (enable-frame manager frame)
    (run-frame-top-level frame)
    frame))
