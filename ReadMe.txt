XXXX
As requested by Avery Rizio
7/31/13

Author: Ken Hwang
SLEIC, PSU

------------------------------

Package contents --

1) Package essentials: ./bin/
	- Example R script: REACT/
	- Output script: cell2csv
	- Primary class: main.m
	- Event class: evt.m
	- Hide Windows 7 Taskbar C code: ShowHideFullWinTaskbarMex.c
	- Hide Windows 7 Taskbar Mex File: ShowHideFullWinTaskbarMex.mex
2) Output directory: ./out/
3) Primary call script: xxxx.m
4) ReadMe file

Usage instructions --

Standard call
>> xxxx

Precision testing
>> xxxx('precision')

General details --

- Data from the standard call will output to the ./out/ folder as an "out1" csv.  "out1" consists of a trial breakdown.
- Precision testing will not output any data, but will display timing details.  
	First column: time stamp one refresh frame prior to display.
	Second column: time stamp of refresh display.
	Third column: empty RT matrix.
	Fourth column: fixation onset
	Fifth column: trial offset (after random fixation duration)

Primary script detail --

xxxx.m
-Initializes directory structure
-Initializes object of class main
-Initializes PsychToolBox window
-Hides desktop taskbar, start button, mouse cursor, and restricts keyboard input.
-Evaluates call arguments
-Standard call loops through trials: main.stopcount(), main.cycle(), main.outFormat(), main.outEval(), main.stepup()/stepdown().  main.outWrite() after trial looping ends.
-Precision test call only executes main.precisionTest().

Primary Class definition details --

main.m
-Properties: debug, monitor, path, exp, misc, out
-Events: record, eval
-Static Methods: disp
-Methods: main (constructor), recordLH, evalLH, pathset, expset, dispfix, disptxt, stepup, stepdown, stopcount, cycle, precisionTest, outFormat, outEval, outWrite

Properties (main.m)
- debug (1/0) defines monitor screen selection and verbosity of task presentation feedback.
- monitor stores all display-related information, primarily driven from PsychToolbox.  Populated by 'disp'.
- path is the path directory structure, stored as strings.  Requires directory root and sub-directory list.  Populated by 'pathset'.
- exp are experimental parameters including: subject info, presentation structure and timing, delay values, threshold values, color information, relevant text, "record" and "eval" event listener handles, and key mapping.  Populated by 'expset'.
- misc contains function handles for easy-access screen presentation, as well as flags and counters used by cycle().  Populated by 'expset'.
- out contains output information and headers.  Populated by 'expset'.

Events (main.m)
- record notifies listener handle in the exp.lh structure of class main.  The listener handle is defined by recordLH(), and executes outFormat()
- eval notifies listener handle in the exp.lh structure of class main.  The listener handle is defined by evalLH(), and executes outEval().  (Deprecated.)

Methods (main.m)
main (constructor)
	- Requires directory root and sub-directory list.  Executes pathset, disp, and expset.

recordLH
	- Defines a listener handle for event "record", which executes outFormat().  Stored in exp.lh.

evalLH
	- Defines a listener handle for event "eval", which executes outEval().  Stored in exp.lh.  (Deprecated.)

pathset
	- Requires directory root and sub-directory list.  Populates 'path' properties for object instance of class main.  Path properties are strings associated with the sub-directory list.

disp
	- Populates 'monitor' properties.  Largely driven by PsychToolbox related screen-handling functions.  This method is static.

expset
	- Populates 'exp', 'misc', and 'out' properties.

dispfix
	- Displays a fixation cross on window pointer monitor.w.

disptxt
	- Displays formatted text on window pointer monitor.w.

stepup
	- Adds an increment from misc.Z.

stepdown
	- Subtracts an increment from misc.Z, if it has not reached a value of 0.  Output of 1 means a step was successfully executed, otherwise a value of 0 is produced.

stopcount
	- Only begins after the number of trials has reached exp.go_hold.
	- If exp.go_hold is reached, misc.Z is initiated by using running mean of RT.  If no mean RT, then exp.dur1/1000 is set as misc.Z
	- Evaluates a randomly generated value against the designated stop threshold (exp.stopthresh).  If it surpasses the threshold, then the misc.stop counter is added upon.  If this counter becomes larger than exp.stop_max, then the counter is reset to 0.  Output of 1 means the stop counter was successfully added upon, otherwise a value of 0 is produced.

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
	- Populates out.out1 with subject ID, Stop/Go Name, Stop/Go Value, Delay duration (Stop only), RT, Coding scheme (see method: cycle), total trial duration, and running mean RT

outEval (Deprecated)
	- Evaluates if any of the accuracy tallies in out.evalMat have reached the exp.kill_n trial length and surpass the exp.kill_acc percentage
	- If these conditions are met, then trial cycling ends, and the final condition is logged in misc.final

outWrite
	- Outputs "out1" csv from out.out1.

Class definition details --

evt.m
-Properties: RT, dur, pass
-Methods: evt (constructor)

Properties (evt.m)
- RT is the currently logged reaction time
- dur is the currently logged duration length time
- pass is the flag for whether or not the last trial was passed or not (1/0)

Methods (evt.m)
evt (Constructor)
	- Fills RT, dur, and pass with values contained in the same field names contained within input, data.