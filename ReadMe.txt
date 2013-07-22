XXXX
As requested by Avery Rizio
7/22/13

Author: Ken Hwang
SLEIC, PSU

------------------------------

Package contents --

1) Package essentials: ./bin/
	- Output script: cell2csv
	- Primary class: main.m
	- Event class: evt.m
	- Hide Windows 7 Taskbar Mex File: ShowHideFullWinTaskbarMex.mex
2) Output directory: ./out/
3) Primary call script: xxxx.m
4) ReadMe file

Usage instructions and general details --

Standard call
>> xxxx

Precision testing
>> xxxx('precision')

- Data from the standard call will output to the ./out/ folder as out1 and out2 csv's.  "out1" is the trial breakdown.  "out2" contains the "Stop" trial accuracy information.
- Precision testing will not output any data, but will display warnings afterwards detailing which criteria was not met during presentation testing.

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
- exp are experimental parameters including: subject info, presentation structure and timing, condition values, threshold values, color information, relevant text, "record" and "eval" event listener handles, and key mapping.  Populated by 'expset'.
- misc contains function handles for easy-access screen presentation, as well as flags and counters used by cycle().  Populated by 'expset'.
- out contains output information and headers.  Populated by 'expset'.

Events (main.m)
- record notifies listener handle in the exp.lh structure of class main.  The listener handle is defined by recordLH(), and executes outFormat()
- eval notifies listener handle in the exp.lh structure of class main.  The listener handle is defined by evalLH(), and executes outEval()

Methods (main.m)
main (constructor)
	- Requires directory root and sub-directory list.  Executes pathset, disp, and expset.

recordLH
	- Defines a listener handle for event "record", which executes outFormat().  Stored in exp.lh.

evalLH
	- Defines a listener handle for event "eval", which executes outEval().  Stored in exp.lh

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
	- Adds to the value of misc.step, if it has not reached the maximum step for exp.cond.  Output of 1 means a step was successfully executed, otherwise a value of 0 is produced.

stepdown
	- Subtracts from the value of misc.step, if it has not reached the minimum step for exp.cond (0).  Output of 1 means a step was successfully executed, otherwise a value of 0 is produced.

stopcount
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
            % cyc6 = Pass accuracy

precisionTest
	- Sets up calibration parameters in "misc"
	- Runs all conditions from longest to shortest twice.
	- Records cyc1, cyc2, and cyc4 from all trials.
	- cyc1 values are replicated by subtracting all exp.cond values by 1 frame refresh period (x1)
	- cyc2 values are replicated by recreating exp.cond values (x2)
	- cyc4 values are created by adding exp.cond values to exp.dur2 and subtracting by 1 frame refresh period. (x3)
	- If x1, x2, or x3 deviate by more than misc.cal_thresh, then warnings are produced.

outFormat
	- Populates out.out1 with subject ID, Stop/Go, RT, and total trial duration
	- If Stop trial, then out.evalMat is edited to include an entry for trial number and accuracy according to the duration condition.

outEval
	- Evaluates if any of the accuracy tallies in out.evalMat have reached the exp.kill_n trial length and surpass the exp.kill_acc percentage.
	- If these conditions are met, then trial cycling ends, and the final condition is logged in misc.final

outWrite
	- Adds a final row for calculating final accuracy for all columns in out.evalMat.  This is output as "out2" csv and stored in out.out2.
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