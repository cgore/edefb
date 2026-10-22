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

(defvar *report-text-style* nil
  "The text style of the live report, cached after the first lookup.")

(defun report-text-style ()
  "Return the text style used by the live report.
The face is the standard sans serif at 12pt roman."
  (or *report-text-style*
      (setf *report-text-style*
            (make-text-style :sans-serif :roman 12))))

(behavior 'report-text-style
  (let ((style (report-text-style)))
    (should-eq :sans-serif (text-style-family style))
    (should-eq :roman (text-style-face style))
    (should= 12 (text-style-size style))))

(defun report-orange ()
  "Return the orange of an Elite Dangerous cockpit display.
The channels are the #FF8000 hologram orange."
  (make-rgb-color 1 128/255 0))

(defun report-background ()
  "Return the black of a cockpit panel."
  +black+)

(defun report-label (text &key caption (min-width 360) max-width)
  "Return a report label showing TEXT.
CAPTION true is a fixed caption.  A value label grows across the row.
MIN-WIDTH and MAX-WIDTH size a value label.  The colors are the
orange on black of a cockpit display."
  (if caption
      (make-pane :label :label text :text-style (report-text-style)
                 :foreground (report-orange) :background (report-background)
                 :min-width 140 :max-width 140 :height 28)
      (apply #'make-pane :label
             :label text
             :text-style (report-text-style)
             :foreground (report-orange)
             :background (report-background)
             :min-width min-width
             :height 28
             (when max-width
               (list :max-width max-width)))))

(define-application-frame bag-frame ()
  ((report
    :initarg :report
    :initform nil
    :accessor bag-report))
  (:pretty-name "EDEFB")
  (:panes
   (time (report-label "-" :min-width 200 :max-width 200))
   (position (report-label "-" :min-width 640))
   (cmdr-title (report-label "CMDR" :caption t))
   (commander-label (report-label "Name" :caption t))
   (combat-label (report-label "Combat" :caption t))
   (trade-label (report-label "Trade" :caption t))
   (explore-label (report-label "Exploration" :caption t))
   (exo-label (report-label "Exobiology" :caption t))
   (mercenary-label (report-label "Mercenary" :caption t))
   (cqc-label (report-label "CQC" :caption t))
   (federation-label (report-label "Federation" :caption t))
   (empire-label (report-label "Empire" :caption t))
   (credits-label (report-label "Credits" :caption t))
   (legal-label (report-label "Legal" :caption t))
   (commander (report-label "-"))
   (combat (report-label "-"))
   (trade (report-label "-"))
   (explore (report-label "-"))
   (exo (report-label "-"))
   (mercenary (report-label "-"))
   (cqc (report-label "-"))
   (federation (report-label "-"))
   (empire (report-label "-"))
   (credits (report-label "-"))
   (legal (report-label "-"))
   (vehicle-title (report-label "Ship" :caption t))
   (name-label (report-label "Ship Name" :caption t))
   (kind-label (report-label "Ship Type" :caption t))
   (ident-label (report-label "Ident" :caption t))
   (pad-label (report-label "Pad Class" :caption t))
   (hull-label (report-label "Hull" :caption t))
   (shields-label (report-label "Shields" :caption t))
   (power-label (report-label "Power" :caption t))
   (fuel-label (report-label "Fuel" :caption t))
   (cargo-label (report-label "Cargo" :caption t))
   (jump-label (report-label "Jump" :caption t))
   (rebuy-label (report-label "Rebuy" :caption t))
   (name (report-label "-"))
   (kind (report-label "-"))
   (ident (report-label "-"))
   (pad (report-label "-"))
   (hull (report-label "-"))
   (shields (report-label "-"))
   (power (report-label "-"))
   (fuel (report-label "-"))
   (cargo (report-label "-"))
   (jump (report-label "-"))
   (rebuy (report-label "-")))
  (:layouts
   (default
    (outlining (:thickness 8 :ink (report-orange))
      (vertically (:spacing 12)
        (horizontally (:spacing 24)
          time position)
        (horizontally (:spacing 32)
          (vertically (:spacing 8)
            cmdr-title
            (horizontally (:spacing 24)
              (vertically (:spacing 8)
                commander-label combat-label trade-label explore-label
                exo-label mercenary-label cqc-label federation-label
                empire-label credits-label legal-label)
              (vertically (:spacing 8)
                commander combat trade explore exo mercenary cqc
                federation empire credits legal)))
          (vertically (:spacing 8)
            vehicle-title
            (horizontally (:spacing 24)
              (vertically (:spacing 8)
                name-label kind-label ident-label pad-label hull-label
                shields-label power-label fuel-label cargo-label
                jump-label rebuy-label)
              (vertically (:spacing 8)
                name kind ident pad hull shields power fuel cargo
                jump rebuy))))))))
  (:geometry 1500 510))

(defmethod initialize-instance :around ((frame bag-frame) &rest initargs)
  "Give the report the black of a cockpit panel.
An :AFTER method would replace the pane constructor."
  (declare (ignore initargs))
  (call-next-method)
  (setf (frame-background frame) (report-background)))

(behavior 'report-colors
  (let ((frame (make-application-frame 'bag-frame)))
    (should-eq +black+ (frame-background frame))
    (multiple-value-bind (red green blue)
        (color-rgb (outlining-ink (frame-panes frame)))
      (should= 1 red)
      (should= 128/255 green)
      (should= 0 blue))
    (let ((caption (find-pane-named frame 'name-label))
          (value (find-pane-named frame 'name)))
      (multiple-value-bind (red green blue) (color-rgb (gadget-foreground caption))
        (should= 1 red)
        (should= 128/255 green)
        (should= 0 blue))
      (should-eq +black+ (gadget-background caption))
      (multiple-value-bind (red green blue) (color-rgb (gadget-foreground value))
        (should= 1 red)
        (should= 128/255 green)
        (should= 0 blue))
      (should-eq +black+ (gadget-background value)))))

(defun shown-text (value)
  "Return VALUE when it is a non-empty string, otherwise a dash."
  (if (and (stringp value) (plusp (length value)))
      value
      "-"))

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
  "Return REPORT's cargo as tons used, free, and total.
The mass is the tons in the hold.  Free is the capacity that is left."
  (when report
    (let ((used (report-cargo report))
          (total (report-cargo-capacity report)))
      (cond
        ((and (numberp used) (numberp total))
         (format nil "~,1F t used, ~,1F t free, ~,1F t total"
                 used
                 (max 0 (- total used))
                 total))
        ((numberp used)
         (format nil "~,1F t used" used))
        ((numberp total)
         (format nil "~,1F t total" total))))))

(defun credits-text (balance)
  "Return BALANCE as credits, or NIL when it is unknown."
  (when (numberp balance)
    (format nil "~:D CR" (round balance))))

(defun percent-text (value)
  "Return VALUE, a fraction from 0 to 1, as a percent."
  (when (numberp value)
    (format nil "~D%" (round (* value 100)))))

(defun shields-text (shields)
  "Return SHIELDS as Up or Down."
  (case shields
    (:up "Up")
    (:down "Down")))

(defun power-text (pips)
  "Return PIPS as SYS, ENG, and WEP.
The journal stores each in half-pips, from 0 to 8."
  (when (and (listp pips) (= (length pips) 3) (every #'numberp pips))
    (format nil "~,1F SYS  ~,1F ENG  ~,1F WEP"
            (/ (first pips) 2)
            (/ (second pips) 2)
            (/ (third pips) 2))))

(defun jump-text (range)
  "Return RANGE in light years."
  (when (numberp range)
    (format nil "~,1F ly" range)))

(defun gravity-text (gravity)
  "Return GRAVITY in standard gravities."
  (when (numberp gravity)
    (format nil "~,2F G" gravity)))

(defun temperature-text (temperature)
  "Return TEMPERATURE in kelvin."
  (when (numberp temperature)
    (format nil "~D K" (round temperature))))

(defun air-text (breathable)
  "Return whether the air is breathable."
  (case breathable
    (:yes "Breathable")
    (:no "Helmet")))

(defun legal-text (value)
  "Return the legal state VALUE in words."
  (cond
    ((not (stringp value)) nil)
    ((string-equal value "IllegalCargo") "Illegal Cargo")
    ((string-equal value "PassengerWanted") "Passenger Wanted")
    (t value)))

(defparameter +game-year-offset+ 1286
  "Years added to a journal timestamp to make the game date.
The journal writes UTC.  The game calendar is that civil date with
1286 years added, and the clock is the same UTC time.")

(defun game-time-text (timestamp)
  "Return the game date and clock for a journal TIMESTAMP."
  (when (and (stringp timestamp)
             (>= (length timestamp) 20)
             (char= (char timestamp 4) #\-)
             (char= (char timestamp 7) #\-)
             (or (char= (char timestamp 10) #\T)
                 (char= (char timestamp 10) #\Space)))
    (let ((year (parse-integer timestamp :start 0 :end 4 :junk-allowed t)))
      (when (and year
                 (every #'digit-char-p (subseq timestamp 5 7))
                 (every #'digit-char-p (subseq timestamp 8 10))
                 (char= (char timestamp 13) #\:)
                 (char= (char timestamp 16) #\:))
        (format nil "~D-~A-~A  ~A"
                (+ year +game-year-offset+)
                (subseq timestamp 5 7)
                (subseq timestamp 8 10)
                (subseq timestamp 11 19))))))

(behavior 'game-time-text
  (should-equal "3312-10-21  01:15:10"
                (game-time-text "2026-10-21T01:15:10Z"))
  (should-be-null (game-time-text nil))
  (should-be-null (game-time-text "not a time")))

(defun position-part (text)
  "Return TEXT when it can be shown in the position line."
  (when (and (stringp text) (plusp (length text)))
    text))

(defun station-text (report)
  "Return REPORT's station as it should be shown.
A fleet carrier is its callsign and its given name, in the spelling
the journal wrote.  Another station is its name."
  (let ((station (and report (report-station report)))
        (callsign (and report (report-station-callsign report))))
    (if (and (position-part station) (position-part callsign))
        (format nil "~A ~A" callsign station)
        station)))

(behavior 'station-text
  (should-equal "K2T-10F BEYOND THE ZURARA"
                (station-text
                 (make-report :station "BEYOND THE ZURARA"
                              :station-callsign "K2T-10F"
                              :station-kind "FleetCarrier")))
  (should-equal "[VANG] CAUSTIC-Crusade"
                (station-text
                 (make-report :station "[VANG] CAUSTIC-Crusade")))
  (should-equal "Galileo"
                (station-text (make-report :station "Galileo")))
  (should-be-null (station-text nil)))

(defun position-text (report)
  "Return REPORT's place on one line.
The parts are the system, body, station, state, destination, and,
near a planet, the latitude, longitude, altitude, and heading."
  (if (not report)
      "-"
      (let ((parts nil))
        (flet ((add (text)
                 (when (position-part text)
                   (push text parts))))
          (add (report-system report))
          (add (report-body report))
          (add (station-text report))
          (add (report-situation report))
          (when (position-part (report-destination report))
            (add (format nil "TO ~A" (report-destination report))))
          (when (and (numberp (report-latitude report))
                     (numberp (report-longitude report)))
            (add (format nil "LAT ~,2F  LON ~,2F"
                         (report-latitude report)
                         (report-longitude report))))
          (when (numberp (report-altitude report))
            (add (format nil "ALT ~D M" (round (report-altitude report)))))
          (when (numberp (report-heading report))
            (add (format nil "HDG ~D" (round (report-heading report))))))
        (if parts
            (format nil "~{~A~^  /  ~}" (nreverse parts))
            "-"))))

(defun rank-text (report ladder)
  "Return REPORT's rank name on LADDER."
  (rank-name ladder (report-rank report ladder)))

(defun vehicle-heading (report)
  "Return the heading of the vehicle cluster for REPORT."
  (cond
    ((report-on-foot? report) "On Foot")
    ((and report
          (stringp (report-situation report))
          (string-equal (report-situation report) "SRV"))
     "SRV")
    ((and report
          (stringp (report-situation report))
          (string-equal (report-situation report) "Taxi"))
     "Taxi")
    (t "Ship")))

(defun ship-lines (report)
  "Return the ship cluster lines for REPORT."
  (list (cons "Ship Name" (and report (report-name report)))
        (cons "Ship Type" (and report (report-type report)))
        (cons "Ident" (and report (report-ident report)))
        (cons "Pad Class" (and report (pad-class (report-type report))))
        (cons "Hull" (and report (percent-text (report-hull report))))
        (cons "Shields" (and report (shields-text (report-shields report))))
        (cons "Power" (and report (power-text (report-pips report))))
        (cons "Fuel" (fuel-text report))
        (cons "Cargo" (cargo-text report))
        (cons "Jump" (and report (jump-text (report-jump-range report))))
        (cons "Rebuy" (and report (credits-text (and report
                                                     (report-rebuy report)))))))

(defun blank-lines (count)
  "Return COUNT empty cluster lines."
  (loop repeat count collect (cons nil nil)))

(defun foot-lines (report)
  "Return the on-foot cluster lines for REPORT."
  (append (list (cons "Suit" (and report (report-suit report)))
                (cons "Health" (and report (percent-text (report-health report))))
                (cons "Oxygen" (and report (percent-text (report-oxygen report))))
                (cons "Gravity" (and report (gravity-text (report-gravity report))))
                (cons "Temperature"
                      (and report (temperature-text (report-temperature report))))
                (cons "Weapon" (and report (report-weapon report)))
                (cons "Air" (and report (air-text (report-breathable report)))))
          (blank-lines 4)))

(defun srv-lines (report)
  "Return the SRV cluster lines for REPORT."
  (append (list (cons "Vehicle" "SRV")
                (cons "Shields" (and report (shields-text (report-shields report))))
                (cons "Fuel" (fuel-text report))
                (cons "Cargo" (cargo-text report)))
          (blank-lines 7)))

(defun taxi-lines ()
  "Return the taxi cluster lines."
  (cons (cons "Vehicle" "Taxi") (blank-lines 10)))

(defun vehicle-lines (report)
  "Return the eleven lines of the vehicle cluster for REPORT.
A ship, an SRV, a taxi, and being on foot each use that same column."
  (cond
    ((report-on-foot? report) (foot-lines report))
    ((and report
          (stringp (report-situation report))
          (string-equal (report-situation report) "SRV"))
     (srv-lines report))
    ((and report
          (stringp (report-situation report))
          (string-equal (report-situation report) "Taxi"))
     (taxi-lines))
    (t (ship-lines report))))

(defparameter *vehicle-rows*
  '((name . name-label)
    (kind . kind-label)
    (ident . ident-label)
    (pad . pad-label)
    (hull . hull-label)
    (shields . shields-label)
    (power . power-label)
    (fuel . fuel-label)
    (cargo . cargo-label)
    (jump . jump-label)
    (rebuy . rebuy-label))
  "Value and caption panes of the vehicle cluster, top to bottom.")

(defun set-report-label (frame name text)
  "Set the label NAME of FRAME to TEXT when the text changed."
  (let ((pane (find-pane-named frame name)))
    (when (and pane (not (equal text (gadget-label pane))))
      (setf (gadget-label pane) text)))
  frame)

(defun present-line (frame value-pane caption-pane caption value blank)
  "Put CAPTION and VALUE on FRAME.
BLANK true leaves an unused row empty.  An unknown value is a dash."
  (set-report-label frame caption-pane (or caption (if blank "" "-")))
  (set-report-label frame value-pane
                    (cond
                      ((and (stringp value) (plusp (length value))) value)
                      (blank "")
                      (t "-"))))

(defun present-report (frame)
  "Put FRAME's report on its labels.
The top row is the game clock and the position.  The left cluster is
the commander.  The next cluster is the ship, or the suit when the
commander is on foot.  An empty value is shown as a dash."
  (let ((report (bag-report frame)))
    (set-report-label frame 'position (position-text report))
    (set-report-label frame 'time
                      (shown-text (and report
                                       (game-time-text
                                        (report-timestamp report)))))
    (set-report-label frame 'commander
                      (shown-text (and report (report-commander report))))
    (set-report-label frame 'combat (shown-text (rank-text report :combat)))
    (set-report-label frame 'trade (shown-text (rank-text report :trade)))
    (set-report-label frame 'explore (shown-text (rank-text report :explore)))
    (set-report-label frame 'exo (shown-text (rank-text report :exobiologist)))
    (set-report-label frame 'mercenary (shown-text (rank-text report :soldier)))
    (set-report-label frame 'cqc (shown-text (rank-text report :cqc)))
    (set-report-label frame 'federation
                      (shown-text (rank-text report :federation)))
    (set-report-label frame 'empire (shown-text (rank-text report :empire)))
    (set-report-label frame 'credits
                      (shown-text (credits-text
                                   (and report (report-balance report)))))
    (set-report-label frame 'legal
                      (shown-text (and report (legal-text (report-legal report)))))
    (set-report-label frame 'vehicle-title (vehicle-heading report))
    (loop for (value-pane . caption-pane) in *vehicle-rows*
          for line in (vehicle-lines report)
          do (present-line frame value-pane caption-pane
                           (car line) (cdr line)
                           (and (null (car line)) (null (cdr line))))))
  frame)

(behavior 'present-report
  (let ((frame (make-application-frame
                'bag-frame
                :report (make-report
                         :commander "HRC1"
                         :ranks (make-ranks :combat 8 :trade 1 :explore 4
                                            :exobiologist 0 :soldier 2
                                            :cqc 3 :federation 9 :empire 14)
                         :legal "Clean"
                         :name "Kipling's Ghost"
                         :type "Mandalay"
                         :ident "KG-07"
                         :system "Sol"
                         :station "Galileo"
                         :body "Earth"
                         :situation "Docked"
                         :destination "Hutton Orbital"
                         :timestamp "2026-10-21T01:15:10Z"
                         :fuel-main 10.5
                         :fuel-capacity 32
                         :cargo 4
                         :cargo-capacity 16
                         :balance 2500
                         :hull 1
                         :shields :up
                         :pips '(4 8 0)
                         :jump-range 72.5
                         :rebuy 1000))))
    (present-report frame)
    (should-eq (report-text-style)
               (gadget-text-style (find-pane-named frame 'name-label)))
    (should-eq (report-text-style)
               (gadget-text-style (find-pane-named frame 'time)))
    (should-equal "CMDR"
                  (gadget-label (find-pane-named frame 'cmdr-title)))
    (should-equal "HRC1"
                  (gadget-label (find-pane-named frame 'commander)))
    (should-equal "Elite"
                  (gadget-label (find-pane-named frame 'combat)))
    (should-equal "Mostly Penniless"
                  (gadget-label (find-pane-named frame 'trade)))
    (should-equal "Explorer"
                  (gadget-label (find-pane-named frame 'explore)))
    (should-equal "Directionless"
                  (gadget-label (find-pane-named frame 'exo)))
    (should-equal "Rookie"
                  (gadget-label (find-pane-named frame 'mercenary)))
    (should-equal "Semi Professional"
                  (gadget-label (find-pane-named frame 'cqc)))
    (should-equal "Lt. Commander"
                  (gadget-label (find-pane-named frame 'federation)))
    (should-equal "King"
                  (gadget-label (find-pane-named frame 'empire)))
    (should-equal "2,500 CR"
                  (gadget-label (find-pane-named frame 'credits)))
    (should-equal "Clean"
                  (gadget-label (find-pane-named frame 'legal)))
    (should-equal
     "Sol  /  Earth  /  Galileo  /  Docked  /  TO Hutton Orbital"
     (gadget-label (find-pane-named frame 'position)))
    (should-be-null (find-pane-named frame 'time-label :errorp nil))
    (should-be-null (find-pane-named frame 'position-label :errorp nil))
    (should-equal "3312-10-21  01:15:10"
                  (gadget-label (find-pane-named frame 'time)))
    (should-equal "Ship"
                  (gadget-label (find-pane-named frame 'vehicle-title)))
    (should-equal "Ship Name"
                  (gadget-label (find-pane-named frame 'name-label)))
    (should-equal "Kipling's Ghost"
                  (gadget-label (find-pane-named frame 'name)))
    (should-equal "Mandalay"
                  (gadget-label (find-pane-named frame 'kind)))
    (should-equal "KG-07"
                  (gadget-label (find-pane-named frame 'ident)))
    (should-equal "Medium"
                  (gadget-label (find-pane-named frame 'pad)))
    (should-equal "100%"
                  (gadget-label (find-pane-named frame 'hull)))
    (should-equal "Up"
                  (gadget-label (find-pane-named frame 'shields)))
    (should-equal "2.0 SYS  4.0 ENG  0.0 WEP"
                  (gadget-label (find-pane-named frame 'power)))
    (should-equal "10.5 / 32.0 t"
                  (gadget-label (find-pane-named frame 'fuel)))
    (should-equal "4.0 t used, 12.0 t free, 16.0 t total"
                  (gadget-label (find-pane-named frame 'cargo)))
    (should-equal "72.5 ly"
                  (gadget-label (find-pane-named frame 'jump)))
    (should-equal "1,000 CR"
                  (gadget-label (find-pane-named frame 'rebuy))))
  (let ((frame (make-application-frame
                'bag-frame
                :report (make-report :name "Parked"
                                     :type "Mandalay"
                                     :situation "On foot"
                                     :suit "Artemis Suit"
                                     :health 1/2
                                     :oxygen 1
                                     :gravity 0.12
                                     :temperature 290
                                     :weapon "Karma P-15"
                                     :breathable :yes
                                     :latitude 1.25
                                     :longitude -2.5
                                     :altitude 40
                                     :heading 12
                                     :system "Sol"))))
    (present-report frame)
    (should-equal "On Foot"
                  (gadget-label (find-pane-named frame 'vehicle-title)))
    (should-equal "Suit"
                  (gadget-label (find-pane-named frame 'name-label)))
    (should-equal "Artemis Suit"
                  (gadget-label (find-pane-named frame 'name)))
    (should-equal "Health"
                  (gadget-label (find-pane-named frame 'kind-label)))
    (should-equal "50%"
                  (gadget-label (find-pane-named frame 'kind)))
    (should-equal "100%"
                  (gadget-label (find-pane-named frame 'ident)))
    (should-equal "0.12 G"
                  (gadget-label (find-pane-named frame 'pad)))
    (should-equal "290 K"
                  (gadget-label (find-pane-named frame 'hull)))
    (should-equal "Karma P-15"
                  (gadget-label (find-pane-named frame 'shields)))
    (should-equal "Breathable"
                  (gadget-label (find-pane-named frame 'power)))
    (should-equal ""
                  (gadget-label (find-pane-named frame 'jump-label)))
    (should-equal ""
                  (gadget-label (find-pane-named frame 'jump)))
    (should-equal
     "Sol  /  On foot  /  LAT 1.25  LON -2.50  /  ALT 40 M  /  HDG 12"
     (gadget-label (find-pane-named frame 'position))))
  (let ((frame (make-application-frame
                'bag-frame
                :report (make-report :situation "SRV" :shields :down))))
    (present-report frame)
    (should-equal "SRV"
                  (gadget-label (find-pane-named frame 'vehicle-title)))
    (should-equal "Vehicle"
                  (gadget-label (find-pane-named frame 'name-label)))
    (should-equal "SRV"
                  (gadget-label (find-pane-named frame 'name)))
    (should-equal "Down"
                  (gadget-label (find-pane-named frame 'kind))))
  (let ((frame (make-application-frame
                'bag-frame
                :report (make-report :name "X" :type "Not A Ship"))))
    (present-report frame)
    (should-equal "Ship"
                  (gadget-label (find-pane-named frame 'vehicle-title)))
    (should-equal "Not A Ship"
                  (gadget-label (find-pane-named frame 'kind)))
    (should-equal "-" (gadget-label (find-pane-named frame 'pad)))
    (should-equal "-" (gadget-label (find-pane-named frame 'position))))
  (let ((frame (make-application-frame
                'bag-frame
                :report (make-report
                         :system "Heart Sector IR-V b2-0"
                         :station "BEYOND THE ZURARA"
                         :station-callsign "K2T-10F"
                         :station-kind "FleetCarrier"
                         :situation "Docked"))))
    (present-report frame)
    (should-equal
     "Heart Sector IR-V b2-0  /  K2T-10F BEYOND THE ZURARA  /  Docked"
     (gadget-label (find-pane-named frame 'position))))
  (let ((frame (make-application-frame 'bag-frame)))
    (present-report frame)
    (should-equal "-" (gadget-label (find-pane-named frame 'name)))
    (should-equal "-" (gadget-label (find-pane-named frame 'commander)))
    (should-equal "-" (gadget-label (find-pane-named frame 'time)))))

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
The top row is the game date and time, then the current position.
The left cluster is the commander: name, ranks, legal state, and
credits.
The next cluster is the ship when the commander is in one, including
the hull, shields, power distribution, fuel, and cargo.  On foot, that
cluster switches to the suit.  Labels use the standard sans serif,
in the orange on black of a cockpit display, inside an orange rule.
The files are read again every second until the window closes.
Returns the frame."
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
