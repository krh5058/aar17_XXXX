XXXX
As requested by Avery Rizio
9/6/13

Author: Ken Hwang
SLEIC, PSU

------------------------------

Package contents --

1) Package essentials: ./bin/
	- Output script: cell2csv
	- Primary class: main.m
	- Subclass: scan.m
	- Event class: evt.m
	- User Interface: javaui.m
	- Jitter timing file: jit.xlsx
	- Hide Windows 7 Taskbar C code: ShowHideFullWinTaskbarMex.c
	- Hide Windows 7 Taskbar Mex File: ShowHideFullWinTaskbarMex.mex
2) Output directory: ./out/
3) Primary call script: xxxx.m
4) ReadMe file

Usage instructions --

Standard call
>> xxxx

Scanner call
>> xxxx('scan')

Precision testing
>> xxxx('precision')

General details --

- Data from the standard call will output to the ./out/ folder as an "out1" csv.  "out1" consists of a trial breakdown.
- Data from the scanner call will output to the ./out/ folder as an "run#" csv.  "run#" consists of a trial breakdown for the corresponding run number.
- Precision testing will not output any data, but will display timing details.  
	First column: time stamp one refresh frame prior to display.
	Second column: time stamp of refresh display.
	Third column: empty RT matrix.
	Fourth column: fixation onset
	Fifth column: trial offset (after random fixation duration)

Primary script detail --

xxxx.m
-Argument handling for different calls
-Initializes directory structure
-Initializes object of class main, or subclass scan
-Initializes PsychToolBox window
-Hides desktop taskbar, start button, mouse cursor, and restricts keyboard input. (Non-debug only)
-Evaluates call arguments
-Standard call loops through trials: main.zCalc(), main.cycle(), main.outFormat(), main.delaydown()/delayup().  main.outWrite() after trial looping ends.
-Scanner call loops through the run order (beginning at requested run start number).  Within each run, triggering takes place and looping through trials: main.formatTrials(), scan.formatOnset, scan.delayAdjust(), scan.zCalc, scan.cycle(), scan.outFormat(), scan.outStore(), and a pause for exp.endfixdur.  scan.outWrite() after trial looping ends.
-Precision test call only executes main.precisionTest().

Primary Class definition details --

main.m
-Properties: debug, monitor, path, exp, misc, out
-Events: record
-Static Methods: disp, getSID
-Methods: main (constructor), recordLH, pathset, expset, dispfix, disptxt, formatTrials, testTrials, delayup, delaydown, zCalc, meanGo, cycle, precisionTest, outFormat, outWrite

Properties (main.m)
- debug (1/0) defines monitor screen selection and verbosity of task presentation feedback.
- monitor stores all display-related information, primarily driven from PsychToolbox.  Populated by 'disp'.
- path is the path directory structure, stored as strings.  Requires directory root and sub-directory list.  Populated by 'pathset'.
- exp are experimental parameters including: subject info, presentation structure and timing, delay and Z values, color information, relevant text, "record" event listener handles, and key mapping.  Populated by 'expset'.
- misc contains function handles for easy-access screen presentation, as well as flags and trial type information used by cycle().  Populated by 'expset'.
- out contains output information and headers.  Populated by 'expset'.

Events (main.m)
- record notifies listener handle in the exp.lh structure of class main.  The listener handle is defined by recordLH(), and executes outFormat()

Methods (main.m)
main (constructor)
	- Requires directory root and sub-directory list.  Executes pathset, disp, and expset.

recordLH
	- Defines a listener handle for event "record", which executes outFormat().  Stored in exp.lh.

pathset
	- Requires directory root and sub-directory list.  Populates 'path' properties for object instance of class main.  Path properties are strings associated with the sub-directory list.

disp
	- Populates 'monitor' properties.  Largely driven by PsychToolbox related screen-handling functions.  This method is static.

getSID
	- Prompts for SID input.  This method is static.

expset
	- Populates 'exp', 'misc', and 'out' properties.

dispfix
	- Displays a fixation cross on window pointer monitor.w.

disptxt
	- Displays formatted text on window pointer monitor.w.

formatTrials
	- Runs main.testTrials() until the result returns satisfactory.  Stores output to misc.trialtype.

testTrials
	- Assigns stop trials to a data series.  
	- Randomizes placement and restricts stop trials from appearing prior to the exp.go_hold value and reports unsuccessful if stop trials occur consecutively in exp.stop_max number of trials.
	- Output is a result value of 0/1 (unsuccessful/successful) and the trialtype data series.

delayup
	- Adds an increment of exp.T to misc.delay

delaydown
	- Subtracts an increment of exp.T from misc.delay, if it has not reached a value of 0.  Output of 1 means a step was successfully executed, otherwise a value of 0 is produced.

zCalc
	- misc.delay is initiated by subtracting the current value of misc.delay using running mean of RT.  If no mean RT, then the value of misc.defaultMeanRT is used.

meanGo
	- Adds RT input to misc.RTvect.  
	- Calculates mean of misc.RTvect.

cycle
	- Runs one trial instance.
	- Depending on Stop/Go condition, the entire trial length is calculated from timing information of the Stop duration value or the default duration value.  If it is a Stop trial, the Stop duration value is monitored with respect to the start of the trial onset.  When this time has passed, the presentation initiates the Stop condition presentation.
	- Records one key input until trial duration is reached.
	- Fixaton cross displayed after trial duration.  Fixation duration lasts for a random duration.
	- Output is as follows:
            % cyc1 = First time sample to meet "Stop" onset time
            % cyc2 = "Stop" onset, t1
            % cyc3 = Key press time, null if no response
            % cyc4 = Fixation onset time, t1 + 2000ms
            % cyc5 = Trial offset, after randsample of fixation duration
            % cyc6 = coding scheme
		1: successful stop
		2: failed stop
		3: successful go
		4: failed go

precisionTest
	- Sets up calibration parameters in "misc"
	- misc.cal_cycles allows for multiple loops
	- Runs exp.T*misc.steps number of test trials from longest to shortest
	- Records cyc1, cyc2, cyc4, and cyc5 from all trials

outFormat
	- Populates out.out1 with subject ID, Stop/Go Name, Stop/Go Value, Z duration (Stop only), Delay duration (Stop only), RT, Coding scheme (see method: cycle), total trial duration, and running mean RT

outWrite
	- Outputs "out1" csv from out.out1.

Class definition details --

scan.m (subclassed from main.m)
-Methods: scan (constructor), delayAdjust, formatOnset, fixdurRecord
-Overridden Methods: zCalc, cycle, outformat, outStore, outWrite

Methods (scan.m)
scan (constructor)
	- Requires directory root and sub-directory list.  Executes main.m construction
	- Calls javaui for experimental parameters
	- Adds/Modifies supplemental data fields: exp.sid, exp.TR, misc.delay, misc.delayshift, misc.i_meanRT, exp.trig, misc.runstart, misc.runorder, exp.iPAT, exp.DisDaq, misc.run, misc.start_t, misc.defaultDelay, exp.whilebuffer, exp.keys.tkey, exp.fixdur, exp.stopdur, exp.godur, exp.endfixdur, exp.trial_onset, exp.wait1, exp.wait2, exp.intro, exp.break, exp.txtsize, exp.wordsize, exp.max_n, exp.stop_ratio, exp.stop_n, exp.go_hold, exp.keys.key1, exp.keys.key2, exp.keys.key3, exp.keys.key4, out.f_out, out.head1, out.out1, out.out2

formatOnset
	- Evaluates each trial duration (without fixation) according to calculated Stop (exp.stopdur) and Go (exp.godur) durations.
	- Stop duration = (Mean RT - Delay) + exp.dur2 (2000ms)
	- Go duration = exp.dur1 (200ms) + exp.dur2 (2000ms)
	- Then, the cumulative sums of the trial durations are added to the DisDaq.
	- Finally, a 0 is added to the beginning of the trial onset vector and stored in obj.misc.trial_onset

delayAdjust
	- Randomly samples from 1-4.
	- A value of 3 sets misc.delayshift to exp.T.
	- A value of 4 sets misc.delayshift to -exp.T.
	- Values of 1 or 2 sets misc.delayshift to 0.

Overridden Methods (scan.m)
zCalc
	- Calculates misc.Z from the mean RT, delay, and delay shift.
	- If first trial, misc.meanRT is used (from input value), otherwise the running mean is used.

cycle
	- Runs one trial instance.
	- Records one key input until trial duration is reached.  Response is recorded
	- Does not advance presentation.
	- Fixaton cross displayed after trial duration. 
	- Output is as follows:
            % cyc1 = First time sample to meet "Stop" onset time
            % cyc2 = "Stop" onset, t11
            % cyc3 = Key press time, null if no response
            % cyc4 = Fixation onset time, t1 + 2000ms
            % cyc5 = Pass accuracy
            % cyc6 = Response key


outFormat
	- Populates out.out1 with subject ID, Run number, Trial number, ScheduledOnset (ms), RawOnset from start of run (ms), TROnset (converted into TRs), Stop/Go Name, Stop/Go Value, Z duration (Stop only), Delay duration (Stop only), Response, RT (s), Coding scheme (see method: cycle), total trial duration (s), Jittered duration (ms) -- Left blank (see method: fixdurRecord), and running mean RT (s)

fixdurRecord
	- Requires a time difference as an argument (s).  This time difference is expected to be this current trial's onset minus the last trial's onset.
	- The time difference is subtracted by the last trial's duration (without fixation)
	- The resulting value is entered (retroactively) as the last trial's fixation duration.

outStore
	- Stores current out.out1 into out.run#, where # is the current run number.
	- Resets out.out1

outWrite
	- Iterates through number of successful runs in misc.runorder up to the current run value.  Wrapped by a try/catch in case the run# was not entered into the 'out' structure.  (Occurs sometimes if block is aborted too early.)
	- Stores the out.run# into out2.
	- Writes to out/ folder

Class definition details --

evt.m
-Properties: RT, dur, code, t, resp
-Methods: evt (constructor)

Properties (evt.m)
- RT is the currently logged reaction time (s)
- dur is the currently logged duration length time (s)
- code is the numbering scheme: 1) success stop, 2) failed stop, 3) success go, 4) failed go
- t is the timestamp for the start of the trial (ms).  Used for 'scan' call.
- resp is the key-code for the response button pressed.  Used for 'scan' call.

Methods (evt.m)
evt (Constructor)
	- Fills RT, dur, code, t, and resp with values contained in the same field names contained within input, data.

UI script details --

javaui.m

-Import: javax.swing.*, javax.swing.table.*, java.awt.*

- Displays textfields for subject ID, TR, stop delay, and mean RT.  (Left pane)
- Displays radio buttons for manual/automated triggering, and run start number.  (Right pane)
- Displays "Confirm" button to verify information.  (Bottom pane)
- Checks to prevent omitted fields
- Checks to prevent stop delay duration to equal or extend mean RT.
- Cancels on user pressing "X"
- Sends data fields to scan.m (constructor method)
