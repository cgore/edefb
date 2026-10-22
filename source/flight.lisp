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
  (:export :make-ranks
           :make-report
           :make-ship
           :pad-class
           :rank-name
           :read-report
           :read-ship
           :report
           :report-altitude
           :report-balance
           :report-body
           :report-breathable
           :report-cargo
           :report-cargo-capacity
           :report-commander
           :report-destination
           :report-fuel-capacity
           :report-fuel-main
           :report-gravity
           :report-heading
           :report-health
           :report-hull
           :report-ident
           :report-in-ship?
           :report-jump-range
           :report-latitude
           :report-legal
           :report-longitude
           :report-name
           :report-on-foot?
           :report-oxygen
           :report-pips
           :report-rank
           :report-rebuy
           :report-shields
           :report-situation
           :report-station
           :report-station-callsign
           :report-station-kind
           :report-suit
           :report-system
           :report-temperature
           :report-timestamp
           :report-type
           :report-weapon
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

(defstruct ranks
  "The rank integers from a Rank event.
NIL means that ladder has not been seen.  COMBAT, TRADE, EXPLORE,
EXOBIOLOGIST, SOLDIER, and CQC are the pilot ladders.  FEDERATION and
EMPIRE are the naval ladders."
  combat
  trade
  explore
  exobiologist
  soldier
  cqc
  federation
  empire)

(defstruct report
  "A live picture of the commander and the current vehicle.
NAME, TYPE, and IDENT name the ship.  SYSTEM, STATION, and BODY say
where the commander is.  STATION-KIND is the journal station type,
such as FleetCarrier.  STATION-CALLSIGN is a carrier's callsign when
STATION is its given name.  SITUATION is the cockpit state, such as
Docked or Supercruise.  LATITUDE, LONGITUDE, HEADING, and ALTITUDE
are set near a planet.  FUEL-MAIN and FUEL-CAPACITY are tons.  CARGO
and CARGO-CAPACITY are tons.  BALANCE is credits.  DESTINATION is the
selected navigation target.  COMMANDER is the commander name.  RANKS
are the journal rank integers.  HULL is the hull fraction from the
last Loadout or HullDamage.  SHIELDS is :UP or :DOWN.  PIPS is the
SYS, ENG, and WEP distribution in half-pips.  JUMP-RANGE is light
years.  REBUY is credits.  LEGAL is the legal state.  TIMESTAMP is
the UTC time the game wrote.  CARRIERS are callsigns and given names
seen in this journal.  SUIT, HEALTH, OXYGEN, GRAVITY,
TEMPERATURE, and WEAPON describe the commander on foot.  BREATHABLE
is :YES or :NO."
  name
  type
  system
  station
  station-kind
  station-callsign
  body
  situation
  fuel-main
  fuel-capacity
  cargo
  balance
  destination
  commander
  ranks
  ident
  latitude
  longitude
  heading
  altitude
  cargo-capacity
  hull
  shields
  pips
  jump-range
  rebuy
  legal
  timestamp
  carriers
  suit
  health
  oxygen
  gravity
  temperature
  weapon
  breathable)

(defparameter *rank-names*
  '((:combat
     "Harmless" "Mostly Harmless" "Novice" "Competent" "Expert"
     "Master" "Dangerous" "Deadly" "Elite")
    (:trade
     "Penniless" "Mostly Penniless" "Peddler" "Dealer" "Merchant"
     "Broker" "Entrepreneur" "Tycoon" "Elite")
    (:explore
     "Aimless" "Mostly Aimless" "Scout" "Surveyor" "Explorer"
     "Pathfinder" "Ranger" "Pioneer" "Elite")
    (:cqc
     "Helpless" "Mostly Helpless" "Amateur" "Semi Professional"
     "Professional" "Champion" "Hero" "Legend" "Elite")
    (:soldier
     "Defenceless" "Mostly Defenceless" "Rookie" "Soldier"
     "Gunslinger" "Warrior" "Gladiator" "Deadeye" "Elite")
    (:exobiologist
     "Directionless" "Mostly Directionless" "Compiler" "Collector"
     "Cataloguer" "Taxonomist" "Ecologist" "Geneticist" "Elite")
    (:federation
     "None" "Recruit" "Cadet" "Midshipman" "Petty Officer"
     "Chief Petty Officer" "Warrant Officer" "Ensign" "Lieutenant"
     "Lt. Commander" "Post Commander" "Post Captain" "Rear Admiral"
     "Vice Admiral" "Admiral")
    (:empire
     "None" "Outsider" "Serf" "Master" "Squire" "Knight" "Lord"
     "Baron" "Viscount" "Count" "Earl" "Marquis" "Duke" "Prince"
     "King"))
  "Rank names by ladder, index zero first.
The six pilot ladders continue past Elite as Elite I through Elite V.
Federation stops at Admiral and Empire stops at King.")

(defparameter *pilot-ladders*
  '(:combat :trade :explore :cqc :soldier :exobiologist)
  "Ladders that continue Elite I through Elite V.")

(defun rank-name (ladder index)
  "Return the rank name for LADDER at INDEX.
INDEX is the integer the journal writes.  An index with no name is
shown as its digits.  NIL means the rank has not been seen."
  (when (integerp index)
    (let ((names (rest (assoc ladder *rank-names*))))
      (cond
        ((and names (<= 0 index (1- (length names))))
         (nth index names))
        ((and (member ladder *pilot-ladders*) (<= 9 index 13))
         (format nil "Elite ~@R" (- index 8)))
        (t
         (format nil "~D" index))))))

(behavior 'rank-name
  (should-equal "Harmless" (rank-name :combat 0))
  (should-equal "Mostly Penniless" (rank-name :trade 1))
  (should-equal "Explorer" (rank-name :explore 4))
  (should-equal "Semi Professional" (rank-name :cqc 3))
  (should-equal "Elite" (rank-name :soldier 8))
  (should-equal "Elite I" (rank-name :explore 9))
  (should-equal "Elite V" (rank-name :exobiologist 13))
  (should-equal "14" (rank-name :combat 14))
  (should-equal "Lt. Commander" (rank-name :federation 9))
  (should-equal "Admiral" (rank-name :federation 14))
  (should-equal "15" (rank-name :federation 15))
  (should-equal "King" (rank-name :empire 14))
  (should-equal "Defenceless" (rank-name :soldier 0))
  (should-equal "Directionless" (rank-name :exobiologist 0))
  (should-be-null (rank-name :combat nil))
  (should-equal "-1" (rank-name :trade -1)))

(defun report-rank (report ladder)
  "Return REPORT's integer rank on LADDER, or NIL."
  (let ((ranks (and report (report-ranks report))))
    (when ranks
      (ecase ladder
        (:combat (ranks-combat ranks))
        (:trade (ranks-trade ranks))
        (:explore (ranks-explore ranks))
        (:exobiologist (ranks-exobiologist ranks))
        (:soldier (ranks-soldier ranks))
        (:cqc (ranks-cqc ranks))
        (:federation (ranks-federation ranks))
        (:empire (ranks-empire ranks))))))

(defparameter *pad-classes*
  '(("Small"
     "SideWinder" "Sidewinder Mk I"
     "Eagle" "Eagle Mk II"
     "Hauler"
     "Adder"
     "Empire_Eagle" "Imperial Eagle"
     "Viper" "Viper MkIII" "Viper Mk III"
     "Viper_MkIV" "Viper MkIV" "Viper Mk IV"
     "CobraMkIII" "Cobra MkIII" "Cobra Mk III"
     "CobraMkIV" "Cobra MkIV" "Cobra Mk IV"
     "DiamondBack" "Diamondback Scout"
     "DiamondBackXL" "Diamondback Explorer"
     "Empire_Courier" "Imperial Courier"
     "Vulture"
     "CobraMkV" "Cobra MkV" "Cobra Mk V"
     "SmallCombat01_NX" "Kestrel Mk II" "Kestrel MkII")
    ("Medium"
     "Asp_Scout" "Asp Scout"
     "Asp" "Asp Explorer"
     "Federation_Dropship" "Federal Dropship"
     "Federation_Dropship_MkII" "Federal Assault Ship"
     "Federation_Gunship" "Federal Gunship"
     "Independant_Trader" "Keelback"
     "Type6" "Type-6 Transporter" "Type-6"
     "Dolphin"
     "TypeX" "Alliance Chieftain"
     "TypeX_2" "Alliance Crusader"
     "TypeX_3" "Alliance Challenger"
     "Krait_MkII" "Krait MkII" "Krait Mk II"
     "Krait_Light" "Krait Phantom"
     "Python"
     "FerDeLance" "Fer-de-Lance"
     "Mamba"
     "Python_NX" "Python MkII" "Python Mk II"
     "Type8" "Type-8 Transporter" "Type-8"
     "Mandalay"
     "Corsair"
     "LakonMiner" "Type-11 Prospector" "Type-11"
     "MediumTransport01" "Lynx Highliner")
    ("Large"
     "Type7" "Type-7 Transporter" "Type-7"
     "Empire_Trader" "Imperial Clipper"
     "Orca"
     "Type9" "Type-9 Heavy" "Type-9"
     "BelugaLiner" "Beluga Liner"
     "Anaconda"
     "Anaconda Mk II" "Anaconda MkII" "Anaconda Mk.II"
     "Federation_Corvette" "Federal Corvette"
     "Cutter" "Imperial Cutter"
     "Type9_Military" "Type-10 Defender" "Type-10"
     "PantherMkII" "Panther Clipper MkII" "Panther Clipper Mk II"
     "Explorer_NX" "Caspian Explorer"))
  "Landing pad class of each known ship type.
The journal names the type, such as Mandalay or CobraMkIII, and does
not name the pad.  Independant_Trader is the Keelback: that is the
spelling in the journal.  A type that is not listed has no known pad.")

(defun pad-class (ship-type)
  "Return the landing pad class of SHIP-TYPE, or NIL when it is unknown.
Elite Dangerous sizes a ship Small, Medium, or Large."
  (when (stringp ship-type)
    (dolist (group *pad-classes*)
      (when (member ship-type (rest group) :test #'string-equal)
        (return (first group))))))

(behavior 'pad-class
  (should-equal "Medium" (pad-class "Mandalay"))
  (should-equal "Medium" (pad-class "mandalay"))
  (should-equal "Small" (pad-class "SideWinder"))
  (should-equal "Small" (pad-class "Cobra Mk V"))
  (should-equal "Medium" (pad-class "Dolphin"))
  (should-equal "Medium" (pad-class "Independant_Trader"))
  (should-equal "Medium" (pad-class "Federation_Dropship"))
  (should-equal "Large" (pad-class "Empire_Trader"))
  (should-equal "Large" (pad-class "Anaconda"))
  (should-equal "Large" (pad-class "Anaconda Mk II"))
  (should-be-null (pad-class "Not A Ship"))
  (should-be-null (pad-class nil))
  (let ((seen (make-hash-table :test #'equal)))
    (dolist (group *pad-classes*)
      (should-be-true (member (first group)
                              '("Small" "Medium" "Large")
                              :test #'string=))
      (should-be-true (rest group))
      (dolist (name (rest group))
        (should-be-true (stringp name))
        (let ((key (string-downcase name)))
          (should-be-null (gethash key seen))
          (setf (gethash key seen) t))
        (should-equal (first group) (pad-class name))))))

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

(defparameter +carrier-callsign-length+ 7
  "The length of a fleet carrier callsign, such as K2T-10F.")

(defun carrier-callsign? (text)
  "Return true when TEXT is a fleet carrier callsign.
A callsign is three characters, a hyphen, and three characters."
  (and (stringp text)
       (= (length text) +carrier-callsign-length+)
       (char= #\- (char text 3))))

(behavior 'carrier-callsign?
  (should-be-true (carrier-callsign? "K2T-10F"))
  (should-be-false (carrier-callsign? "Galileo"))
  (should-be-false (carrier-callsign? "K2T-10"))
  (should-be-false (carrier-callsign? nil)))

(defun note-carrier-name (report callsign name)
  "Remember CALLSIGN and NAME as REPORT's current carrier.
The spelling is the spelling the journal wrote.  A later event for
another callsign replaces both."
  (let ((callsign (text-value callsign))
        (name (text-value name)))
    (when (and (carrier-callsign? callsign) name)
      (setf (report-station-callsign report) callsign
            (report-station report) name)))
  report)

(defun remember-carrier (report callsign name)
  "Remember that CALLSIGN has the given name NAME.
The spelling is the spelling the journal wrote.  A repeated callsign
keeps the latest name."
  (let ((callsign (text-value callsign))
        (name (text-value name)))
    (when (and (carrier-callsign? callsign) name)
      (setf (report-carriers report)
            (acons callsign name
                   (remove callsign (report-carriers report)
                           :key #'car :test #'string-equal)))))
  report)

(defun known-carrier-name (report callsign)
  "Return the given name REPORT has seen for CALLSIGN."
  (cdr (assoc callsign (and report (report-carriers report))
              :test #'string-equal)))

(defun carrier-known? (report callsign)
  "Return true when REPORT already names the carrier CALLSIGN."
  (and (carrier-callsign? callsign)
       (string-equal callsign (report-station-callsign report))
       (text-value (report-station report))))

(defun note-carrier-signal (report signal)
  "Remember the carrier named by SIGNAL, and use it when it is current.
The spelling is left as the journal wrote it."
  (multiple-value-bind (callsign name) (split-carrier-signal signal)
    (remember-carrier report callsign name)
    (when (or (string-equal callsign (report-station report))
              (string-equal callsign (report-station-callsign report)))
      (note-carrier-name report callsign name)))
  report)

(defun note-station (report name kind)
  "Copy station NAME and KIND onto REPORT.
A carrier whose given name is already known keeps that name and
records NAME as its callsign.  Other stations use NAME as written."
  (let ((name (text-value name))
        (kind (text-value kind)))
    (when kind
      (setf (report-station-kind report) kind))
    (when name
      (cond
        ((carrier-known? report name))
        ((and (string-equal kind "FleetCarrier") (carrier-callsign? name))
         (let ((known (known-carrier-name report name)))
           (if known
               (note-carrier-name report name known)
               (setf (report-station report) name
                     (report-station-callsign report) name))))
        (t
         (setf (report-station report) name
               (report-station-callsign report) nil)))))
  report)

(defun split-carrier-signal (signal)
  "Return the callsign and given name in a fleet carrier SIGNAL.
The journal writes the given name, a space, and the callsign.  A
signal that does not end in a callsign has no pair.  The spelling is
left as the journal wrote it."
  (when (and (stringp signal)
             (> (length signal) +carrier-callsign-length+)
             (char= #\Space (char signal (- (length signal)
                                            +carrier-callsign-length+
                                            1))))
    (let ((callsign (subseq signal (- (length signal)
                                      +carrier-callsign-length+))))
      (when (carrier-callsign? callsign)
        (values callsign
                (subseq signal 0 (- (length signal)
                                    +carrier-callsign-length+
                                    1)))))))

(behavior 'split-carrier-signal
  (multiple-value-bind (callsign name)
      (split-carrier-signal "BEYOND THE ZURARA K2T-10F")
    (should-equal "K2T-10F" callsign)
    (should-equal "BEYOND THE ZURARA" name))
  (multiple-value-bind (callsign name)
      (split-carrier-signal "[VANG] CAUSTIC-Crusade XZT-21L")
    (should-equal "XZT-21L" callsign)
    (should-equal "[VANG] CAUSTIC-Crusade" name))
  (multiple-value-bind (callsign name)
      (split-carrier-signal "GLORIANA JNG-3HL")
    (should-equal "JNG-3HL" callsign)
    (should-equal "GLORIANA" name))
  (should-be-null (split-carrier-signal "Farsight Expedition Base"))
  (should-be-null (split-carrier-signal "K2T-10F"))
  (should-be-null (split-carrier-signal nil)))

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

(defun report-on-foot? (report)
  "Return true when REPORT says the commander is on foot."
  (and report
       (stringp (report-situation report))
       (string-equal (report-situation report) "On foot")))

(defun report-in-ship? (report)
  "Return true when REPORT says the commander is in a ship.
On foot, in a taxi, and in an SRV are not a ship.  A fighter and
multicrew still are.  With no status yet, a ship the journal named
counts as being aboard."
  (when report
    (let ((situation (report-situation report)))
      (cond
        ((null situation)
         (or (text-value (report-name report))
             (text-value (report-type report))))
        ((member situation '("On foot" "Taxi" "SRV") :test #'string-equal)
         nil)
        (t t)))))

(behavior 'report-in-ship?
  (should-be-true (report-in-ship? (make-report :situation "Docked")))
  (should-be-true (report-in-ship? (make-report :situation "In space")))
  (should-be-true (report-in-ship? (make-report :situation "Fighter")))
  (should-be-true (report-in-ship? (make-report :situation "Multicrew")))
  (should-be-true (report-in-ship? (make-report :name "Kipling's Ghost")))
  (should-be-false (report-in-ship? (make-report)))
  (should-be-false (report-in-ship?
                    (make-report :situation "On foot" :name "Parked")))
  (should-be-false (report-in-ship? (make-report :situation "SRV")))
  (should-be-false (report-in-ship? (make-report :situation "Taxi")))
  (should-be-true (report-on-foot? (make-report :situation "On foot")))
  (should-be-false (report-on-foot? (make-report :situation "Docked")))
  (should-be-false (report-on-foot? nil))
  (should-be-false (report-in-ship? nil)))

(defun note-number (report event key writer)
  "Copy a numeric field KEY of EVENT onto REPORT through WRITER."
  (let ((value (gethash key event)))
    (when (numberp value)
      (funcall writer value report)))
  report)

(defun note-fuel-capacity (report event)
  "Copy the main tank size from EVENT onto REPORT.
LoadGame writes a number.  Loadout writes Main and Reserve."
  (let ((capacity (gethash "FuelCapacity" event)))
    (cond
      ((numberp capacity)
       (setf (report-fuel-capacity report) capacity))
      ((hash-table-p capacity)
       (note-number report capacity "Main"
                    #'(setf report-fuel-capacity)))))
  report)

(defun note-timestamp (report event)
  "Copy EVENT's UTC timestamp onto REPORT."
  (let ((stamp (text-value (gethash "timestamp" event))))
    (when stamp
      (setf (report-timestamp report) stamp)))
  report)

(defun note-ranks (report event)
  "Copy the rank integers present on EVENT onto REPORT.
A missing key leaves the previous rank in place."
  (let ((ranks (or (report-ranks report)
                   (setf (report-ranks report) (make-ranks)))))
    (flet ((take (key writer)
             (let ((value (gethash key event)))
               (when (integerp value)
                 (funcall writer value ranks)))))
      (take "Combat" #'(setf ranks-combat))
      (take "Trade" #'(setf ranks-trade))
      (take "Explore" #'(setf ranks-explore))
      (take "Exobiologist" #'(setf ranks-exobiologist))
      (take "Soldier" #'(setf ranks-soldier))
      (take "CQC" #'(setf ranks-cqc))
      (take "Federation" #'(setf ranks-federation))
      (take "Empire" #'(setf ranks-empire))))
  report)

(defun suit-model (name)
  "Return the suit model NAME names, or NIL."
  (when (stringp name)
    (cond
      ((search "flight" name :test #'char-equal) "Flight Suit")
      ((search "utility" name :test #'char-equal) "Maverick Suit")
      ((search "tactical" name :test #'char-equal) "Dominator Suit")
      ((search "exploration" name :test #'char-equal) "Artemis Suit"))))

(behavior 'suit-model
  (should-equal "Flight Suit" (suit-model "flightsuit"))
  (should-equal "Maverick Suit" (suit-model "utilitysuit_class3"))
  (should-equal "Dominator Suit" (suit-model "tacticalsuit_class5"))
  (should-equal "Artemis Suit" (suit-model "explorationsuit_class2"))
  (should-be-null (suit-model "wpn_m_sniper")))

(defun note-suit (report event)
  "Copy the suit model from EVENT onto REPORT."
  (let ((model (or (suit-model (gethash "SuitName" event))
                   (text-value (gethash "SuitName_Localised" event))
                   (text-value (gethash "SuitName" event))
                   (text-value (gethash "LoadoutName" event)))))
    (when model
      (setf (report-suit report) model)))
  report)

(defun number-list (value length)
  "Return VALUE as a list of LENGTH numbers, or NIL."
  (when (and (or (vectorp value) (listp value))
             (= (length value) length)
             (every #'numberp value))
    (coerce value 'list)))

(defun note-report-event (report event)
  "Copy commander, ship, place, and suit facts from EVENT onto REPORT."
  (note-timestamp report event)
  (cond
    ((event-one-of? event '("LoadGame" "Loadout"))
     (setf (report-name report)
           (assign-text (report-name report) (gethash "ShipName" event))
           (report-type report)
           (assign-text (report-type report) (gethash "Ship" event))
           (report-ident report)
           (assign-text (report-ident report) (gethash "ShipIdent" event)))
     (note-fuel-capacity report event)
     (note-number report event "CargoCapacity"
                  #'(setf report-cargo-capacity))
     (note-number report event "HullHealth" #'(setf report-hull))
     (note-number report event "MaxJumpRange" #'(setf report-jump-range))
     (note-number report event "Rebuy" #'(setf report-rebuy))
     (when (event-named? event "LoadGame")
       (setf (report-commander report)
             (assign-text (report-commander report)
                          (gethash "Commander" event)))
       (note-number report event "Credits" #'(setf report-balance))
       (note-number report event "FuelLevel" #'(setf report-fuel-main))))
    ((event-named? event "Location")
     (setf (report-system report)
           (assign-text (report-system report) (gethash "StarSystem" event))
           (report-body report)
           (text-value (gethash "Body" event)))
     (if (eq t (gethash "Docked" event))
         (note-station report
                       (gethash "StationName" event)
                       (gethash "StationType" event))
         (setf (report-station report) nil
               (report-station-callsign report) nil
               (report-station-kind report) nil)))
    ((event-named? event "FSDJump")
     (setf (report-system report)
           (assign-text (report-system report) (gethash "StarSystem" event))
           (report-station report) nil
           (report-station-callsign report) nil
           (report-station-kind report) nil
           (report-body report) nil))
    ((event-named? event "CarrierJump")
     (setf (report-system report)
           (assign-text (report-system report) (gethash "StarSystem" event))
           (report-body report) nil)
     (if (eq t (gethash "Docked" event))
         (note-station report
                       (gethash "StationName" event)
                       (gethash "StationType" event))
         (setf (report-station report) nil
               (report-station-callsign report) nil
               (report-station-kind report) nil)))
    ((event-named? event "Docked")
     (setf (report-system report)
           (assign-text (report-system report) (gethash "StarSystem" event)))
     (note-station report
                   (gethash "StationName" event)
                   (gethash "StationType" event)))
    ((event-named? event "Undocked")
     (setf (report-station report) nil
           (report-station-callsign report) nil
           (report-station-kind report) nil))
    ((event-named? event "CarrierStats")
     (remember-carrier report
                       (gethash "Callsign" event)
                       (gethash "Name" event))
     (note-carrier-name report
                        (gethash "Callsign" event)
                        (gethash "Name" event)))
    ((and (event-named? event "FSSSignalDiscovered")
          (string-equal (gethash "SignalType" event) "FleetCarrier"))
     (note-carrier-signal report (gethash "SignalName" event)))
    ((event-one-of? event '("ApproachBody" "SupercruiseExit" "Touchdown"))
     (setf (report-body report)
           (assign-text (report-body report) (gethash "Body" event))))
    ((event-named? event "LeaveBody")
     (setf (report-body report) nil))
    ((event-named? event "Commander")
     (setf (report-commander report)
           (assign-text (report-commander report) (gethash "Name" event))))
    ((event-named? event "Rank")
     (note-ranks report event))
    ((event-named? event "HullDamage")
     (let ((health (gethash "Health" event)))
       (when (and (numberp health)
                  (not (eq t (gethash "Fighter" event))))
         (setf (report-hull report) health))))
    ((event-named? event "ShieldState")
     (multiple-value-bind (up present) (gethash "ShieldsUp" event)
       (when present
         (setf (report-shields report) (if up :up :down)))))
    ((event-one-of? event '("SuitLoadout" "SwitchSuitLoadout"
                            "CreateSuitLoadout"))
     (note-suit report event)))
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
    (should-be-null (report-station-callsign report))
    (should-be-null (report-body report)))
  (let ((report (report-from-events
                 (list (parse "{\"event\":\"FSSSignalDiscovered\",\"SignalName\":\"GLORIANA JNG-3HL\",\"SignalType\":\"FleetCarrier\"}")
                       (parse "{\"event\":\"FSSSignalDiscovered\",\"SignalName\":\"BEYOND THE ZURARA K2T-10F\",\"SignalType\":\"FleetCarrier\"}")
                       (parse "{\"event\":\"Docked\",\"StarSystem\":\"Heart Sector IR-V b2-0\",\"StationName\":\"K2T-10F\",\"StationType\":\"FleetCarrier\"}")))))
    (should-equal "BEYOND THE ZURARA" (report-station report))
    (should-equal "K2T-10F" (report-station-callsign report))
    (should-equal "FleetCarrier" (report-station-kind report)))
  (let ((report (report-from-events
                 (list (parse "{\"event\":\"FSSSignalDiscovered\",\"SignalName\":\"GLORIANA JNG-3HL\",\"SignalType\":\"FleetCarrier\"}")
                       (parse "{\"event\":\"Docked\",\"StationName\":\"K2T-10F\",\"StationType\":\"FleetCarrier\"}")))))
    (should-equal "K2T-10F" (report-station report))
    (should-equal "K2T-10F" (report-station-callsign report)))
  (let ((report (report-from-events
                 (list (parse "{\"event\":\"FSSSignalDiscovered\",\"SignalName\":\"BEYOND THE ZURARA K2T-10F\",\"SignalType\":\"FleetCarrier\"}")
                       (parse "{\"event\":\"Location\",\"Docked\":true,\"StationName\":\"K2T-10F\",\"StationType\":\"FleetCarrier\",\"StarSystem\":\"Heart Sector IR-V b2-0\"}")))))
    (should-equal "BEYOND THE ZURARA" (report-station report))
    (should-equal "K2T-10F" (report-station-callsign report)))
  (let ((report (report-from-events
                 (list (parse "{\"event\":\"CarrierStats\",\"Callsign\":\"K2T-10F\",\"Name\":\"BEYOND THE ZURARA\"}")
                       (parse "{\"event\":\"Location\",\"Docked\":true,\"StarSystem\":\"Sol\",\"StationName\":\"K2T-10F\",\"StationType\":\"FleetCarrier\"}")))))
    (should-equal "BEYOND THE ZURARA" (report-station report))
    (should-equal "K2T-10F" (report-station-callsign report)))
  (let ((report (report-from-events
                 (list (parse "{\"event\":\"Docked\",\"StationName\":\"K2T-10F\",\"StationType\":\"FleetCarrier\"}")
                       (parse "{\"event\":\"Undocked\",\"StationName\":\"K2T-10F\"}")
                       (parse "{\"event\":\"FSDJump\",\"StarSystem\":\"Sol\"}")))))
    (should-be-null (report-station report))
    (should-be-null (report-station-callsign report))
    (should-be-null (report-station-kind report))))

(behavior 'report-commander
  (let ((report (report-from-events
                 (list (parse "{\"event\":\"Commander\",\"Name\":\"HRC1\"}")
                       (parse "{\"timestamp\":\"2026-10-21T01:00:00Z\",\"event\":\"LoadGame\",\"Commander\":\"hrc1\",\"Credits\":2500,\"Ship\":\"Mandalay\",\"ShipName\":\"Kipling's Ghost\",\"ShipIdent\":\"KG-07\",\"FuelCapacity\":32,\"FuelLevel\":10}")
                       (parse "{\"event\":\"Rank\",\"Combat\":5,\"Trade\":1,\"Explore\":9,\"Empire\":14,\"Federation\":9,\"CQC\":3,\"Soldier\":0,\"Exobiologist\":13}")
                       (parse "{\"event\":\"Rank\",\"Combat\":4}")
                       (parse "{\"event\":\"Loadout\",\"Ship\":\"mandalay\",\"CargoCapacity\":8,\"HullHealth\":0.8,\"MaxJumpRange\":72.5,\"Rebuy\":1000,\"FuelCapacity\":{\"Main\":48,\"Reserve\":0.5},\"ShipIdent\":\"KG-07\"}")
                       (parse "{\"event\":\"HullDamage\",\"Health\":0.2,\"Fighter\":true}")
                       (parse "{\"event\":\"HullDamage\",\"Health\":0.6,\"Fighter\":false}")
                       (parse "{\"event\":\"ShieldState\",\"ShieldsUp\":true}")
                       (parse "{\"event\":\"SuitLoadout\",\"SuitName\":\"explorationsuit_class2\",\"LoadoutName\":\"Field\"}")))))
    (should-equal "HRC1" (report-commander report))
    (should= 2500 (report-balance report))
    (should-equal "KG-07" (report-ident report))
    (should= 10 (report-fuel-main report))
    (should= 48 (report-fuel-capacity report))
    (should= 8 (report-cargo-capacity report))
    (should= 0.6d0 (report-hull report))
    (should-eq :up (report-shields report))
    (should= 72.5 (report-jump-range report))
    (should= 1000 (report-rebuy report))
    (should-equal "2026-10-21T01:00:00Z" (report-timestamp report))
    (should= 4 (report-rank report :combat))
    (should= 1 (report-rank report :trade))
    (should= 9 (report-rank report :explore))
    (should= 14 (report-rank report :empire))
    (should= 9 (report-rank report :federation))
    (should= 3 (report-rank report :cqc))
    (should= 0 (report-rank report :soldier))
    (should= 13 (report-rank report :exobiologist))
    (should-equal "Artemis Suit" (report-suit report))))

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

(defun status-number (status key)
  "Return the number KEY of STATUS, or NIL."
  (let ((value (gethash key status)))
    (when (numberp value)
      value)))

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
        (setf (report-station report) nil
              (report-station-callsign report) nil
              (report-station-kind report) nil))
      (setf (report-situation report) (situation-from-flags flags flags2))
      (setf (report-destination report)
            (when (hash-table-p destination)
              (text-value (gethash "Name" destination))))
      (note-timestamp report status)
      (when (integerp flags)
        (setf (report-shields report)
              (if (status-flag? flags 3) :up :down)))
      (setf (report-pips report) (number-list (gethash "Pips" status) 3))
      (setf (report-legal report) (text-value (gethash "LegalState" status)))
      (setf (report-latitude report) (status-number status "Latitude")
            (report-longitude report) (status-number status "Longitude")
            (report-heading report) (status-number status "Heading")
            (report-altitude report) (status-number status "Altitude"))
      (if (status-flag? flags2 0)
          (setf (report-health report) (status-number status "Health")
                (report-oxygen report) (status-number status "Oxygen")
                (report-gravity report) (status-number status "Gravity")
                (report-temperature report)
                (status-number status "Temperature")
                (report-weapon report)
                (or (text-value (gethash "SelectedWeapon_Localised" status))
                    (text-value (gethash "SelectedWeapon" status)))
                (report-breathable report)
                (if (status-flag? flags2 16) :yes :no))
          (setf (report-health report) nil
                (report-oxygen report) nil
                (report-gravity report) nil
                (report-temperature report) nil
                (report-weapon report) nil
                (report-breathable report) nil))))
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
    (should-equal "Sol" (report-system report))
    (should-eq :down (report-shields report))
    (should-be-null (report-pips report))
    (should-be-null (report-health report)))
  (let ((report (make-report :balance 5 :hull 1 :shields :up
                             :oxygen 1 :suit "Flight Suit")))
    (apply-status report
                  (parse "{\"timestamp\":\"2026-10-21T01:15:10Z\",\"Flags\":16777224,\"Flags2\":0,\"Pips\":[4,8,0],\"LegalState\":\"Clean\",\"Balance\":9,\"Latitude\":1.5,\"Longitude\":-2,\"Heading\":90,\"Altitude\":404}"))
    (should-eq :up (report-shields report))
    (should-equal "In space" (report-situation report))
    (should-equal '(4 8 0) (report-pips report))
    (should-equal "Clean" (report-legal report))
    (should= 1.5 (report-latitude report))
    (should= -2 (report-longitude report))
    (should= 90 (report-heading report))
    (should= 404 (report-altitude report))
    (should-equal "2026-10-21T01:15:10Z" (report-timestamp report))
    (should= 9 (report-balance report))
    (should= 1 (report-hull report))
    (should-be-null (report-oxygen report))
    (should-be-true (report-in-ship? report)))
  (let ((report (make-report :name "Parked" :type "Mandalay")))
    (apply-status report
                  (parse "{\"Flags\":0,\"Flags2\":65537,\"Oxygen\":0.5,\"Health\":0.25,\"Temperature\":290,\"Gravity\":0.12,\"SelectedWeapon_Localised\":\"Karma P-15\",\"LegalState\":\"Wanted\"}"))
    (should-equal "On foot" (report-situation report))
    (should-be-true (report-on-foot? report))
    (should-be-false (report-in-ship? report))
    (should= 0.5 (report-oxygen report))
    (should= 0.25 (report-health report))
    (should= 290 (report-temperature report))
    (should= 0.12d0 (report-gravity report))
    (should-equal "Karma P-15" (report-weapon report))
    (should-eq :yes (report-breathable report))
    (should-equal "Wanted" (report-legal report)))
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
