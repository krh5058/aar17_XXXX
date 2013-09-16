classdef main < handle
    %MAIN Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        debug = 0; % Debug on/off
        monitor
        path
        exp
        misc
        out
    end
    
    events
        record
    end
    
    methods (Static)
        function [monitor] = disp()
            % Find out screen number.
            debug = 0;
            if debug
                %                 whichScreen = max(Screen('Screens'));
                whichScreen = 2;
                Screen('Preference', 'Verbosity', 5);
            else
                whichScreen = 0;
            end
            oldVisualDebugLevel = Screen('Preference', 'VisualDebugLevel',0);
            %             oldOverrideMultimediaEngine = Screen('Preference', 'OverrideMultimediaEngine', 1);
            %             Screen('Preference', 'ConserveVRAM',4096);
            %             Screen('Preference', 'VBLTimestampingMode', 1);
            
            % Opens a graphics window on the main monitor (screen 0).  If you have
            % multiple monitors connected to your computer, then you can specify
            % a different monitor by supplying a different number in the second
            % argument to OpenWindow, e.g. Screen('OpenWindow', 2).
            [window,rect] = Screen('OpenWindow', whichScreen);
            
            % Screen center calculations
            center_W = rect(3)/2;
            center_H = rect(4)/2;
            
            % ---------- Color Setup ----------
            % Gets color values.
            
            % Retrieves color codes for black and white and gray.
            black = BlackIndex(window);  % Retrieves the CLUT color code for black.
            white = WhiteIndex(window);  % Retrieves the CLUT color code for white.
            
            gray = (black + white) / 2;  % Computes the CLUT color code for gray.
            if round(gray)==white
                gray=black;
            end
            
            gray2 = gray*1.5;  % Lighter gray
            
            % Taking the absolute value of the difference between white and gray will
            % help keep the grating consistent regardless of whether the CLUT color
            % code for white is less or greater than the CLUT color code for black.
            absoluteDifferenceBetweenWhiteAndGray = abs(white - gray);
            
            % Data structure for monitor info
            monitor.whichScreen = whichScreen;
            monitor.rect = rect;
            monitor.center_W = center_W;
            monitor.center_H = center_H;
            monitor.black = black;
            monitor.white = white;
            monitor.gray = gray;
            monitor.gray2 = gray2;
            monitor.absoluteDifferenceBetweenWhiteAndGray = absoluteDifferenceBetweenWhiteAndGray;
            monitor.oldVisualDebugLevel = oldVisualDebugLevel;
            %             monitor.oldOverrideMultimediaEngine = oldOverrideMultimediaEngine;
            
            Screen('CloseAll');
        end
        
        function sid = getSID()
            sid = inputdlg('Subject ID: ');
            
            if isempty(sid)
                error('main.m (getSID): User Cancelled.')
            else
                sid = sid{1};
                if isempty(sid)
                    error('main.m (getSID): SID is blank.')
                end
            end
        end
    end
    
    methods
        function obj = main(varargin)
            ext = [];
            d = [];
            
            % Argument evaluation
            for i = 1:nargin
                if ischar(varargin{i}) % Assume main directory path string
                    ext = varargin{i};
                elseif iscell(varargin{i}) % Assume associated directories
                    d = varargin{i};
                else
                    fprintf(['main.m (main): Other handles required for argument value: ' int2str(i) '\n']);
                end
            end
            
            % Path property set-up
            if isempty(ext) || isempty(d)
                error('main.m (main): Empty path string or subdirectory list.');
            else
                try
                    fprintf('main.m (main): Executing path directory construction...\n');
                    obj.pathset(d,ext);
                    fprintf('main.m (main): obj.pathset() success!\n');
                catch ME
                    throw(ME);
                end
            end
            
            % Display properties set-up
            try
                fprintf('main.m (main): Gathering screen display details (Static)...\n');
                monitor = obj.disp; % Static method
                fprintf('main.m (disp): Storing monitor property.\n');
                obj.monitor = monitor;
                fprintf('main.m (main): obj.disp success!\n');
            catch ME
                throw(ME);
            end
            
            % Experimental properties set-up
            try
                fprintf('main.m (main): Gathering experimental details...\n');
                obj.expset();
                fprintf('main.m (main): obj.expset() success!\n');
            catch ME
                throw(ME);
            end
            
            % Trial set-up
            try
                fprintf('main.m (main): Setting up trial types...\n');
                obj.formatTrials;
                fprintf('main.m (main): obj.expset() success!\n');
            catch ME
                throw(ME);
            end
            
        end
        
        function [lh] = recordLh(obj)
            fprintf('main.m (recordLh): Adding "record" listener handle...\n');
            lh = addlistener(obj,'record',@(src,evt)outFormat(obj,src,evt));
        end
        
        function [path] = pathset(obj,d,ext)
            if all(cellfun(@(y)(ischar(y)),d))
                for i = 1:length(d)
                    path.(d{i}) = [ext filesep d{i}];
                    [~,d2] = system(['dir /ad-h/b ' ext filesep d{i}]);
                    if ~isempty(d2)
                        d2 = regexp(strtrim(d2),'\n','split');
                        for j = 1:length(d2)
                            path.(d2{j}) = [ext filesep d{i} filesep d2{j}];
                        end
                    end
                end
                fprintf('main.m (pathset): Storing path property.\n');
                obj.path = path;
            else
                error('main.m (pathset): Check subdirectory argument.')
            end
        end
        
        function [exp] = expset(obj)
            
            % Experimental parameters
            ST = dbstack;
            if strcmp(ST(end-1).file(1:end-2),'scan');
                exp.sid = '';
            else
                exp.sid = main.getSID();
            end
            
            exp.dur1 = 200; % ms
            exp.dur2 = 2000; % ms
            exp.T = (1/60)*1000; % ms
            exp.fixdur = 1000:3000; % ms
            exp.stopthresh = 80;
            exp.green = [0 255 0];
            exp.red = [255 0 0];
            exp.word = 'test';
            exp.stop_max = 3;
            exp.go_hold = 15; % Trials prior to stop
            exp.break_n = [150 100 50]; % Break intervals (trial #)
            exp.max_n = 200; % Max trial limit
            exp.stop_ratio = .2; % Ratio of stop to go trials
            exp.stop_n = round(exp.max_n*exp.stop_ratio);
            exp.intro = ['When a word appears in green\n' ...
                'press "m" as quickly as possible.\n\n\n' ...
                'If a word appears in red\n' ...
                'do not make a key press.\n\n\n' ...
                'Both speed and accuracy are equally important.\n\n\n' ...
                'Press space to continue.'];
            exp.break = ['Please take a break.\n\n\n' ...
                'Press the Spacebar to continue.'];
            exp.txtsize = 30;
            exp.lh.lh1 = obj.recordLh;
            
            % Keys
            KbName('UnifyKeyNames');
            keys.esckey = KbName('Escape');
            keys.spacekey = KbName('SPACE');
            keys.mkey = KbName('m');
            
            fprintf('pres.m (pres): Defining key press identifiers...\n');
            exp.keys = keys;
            
            fprintf('main.m (expset): Storing experimental properties.\n');
            obj.exp = exp;
            
            out.f_out = [exp.sid '_out'];
            out.head1 = {'SID','Trial','Stop','Z (s)','Delay (ms)','RT (s)','Code','Duration (s)','Mean (ms)'};
%             out.head2 = ['Trial',cellfun(@(y)(num2str(y)),num2cell(floor(obj.exp.cond)),'UniformOutput',false)];
            out.out1 = cell([1 length(out.head1)]);
%             out.out2 = [];
            out.out1(1,:) = out.head1;
            out.evalMat = [];
            
            fprintf('main.m (expset): Initializing output.\n');
            obj.out = out;
            
            % Misc
            misc.fix1 = @(monitor)(Screen('DrawLine',monitor.w,monitor.black,monitor.center_W-20,monitor.center_H,monitor.center_W+20,monitor.center_H,7));
            misc.fix2 = @(monitor)(Screen('DrawLine',monitor.w,monitor.black,monitor.center_W,monitor.center_H-20,monitor.center_W,monitor.center_H+20,7));
            misc.text = @(monitor,txt,color)(DrawFormattedText(monitor.w,txt,'center','center',color));
            
            misc.trialtype = []; % Trial type (stop/go)
            misc.delay = 250/1000; % Duration delay (s)
            misc.defaultMeanRT = 600/1000; % Default mean RT (s)
            misc.RTvect = []; % Running RT vector (Go trials only) 
            misc.meanRT = []; % Running mean RT (Go trials only) (s)
            misc.Z = []; % Stop signal offset (s)
            misc.buffer = obj.exp.T/1000; % Buffer time (ms) to compensate for next retrace
            misc.stop = 0; % Stop counter and flag.
%             misc.step = 3; % Step in duration condition. 3 corresponds with starting condition of 200 ms.
            misc.trial = 1; % Trial count
            misc.abort = 0;
%             misc.kill = 0; % Kill flag
            misc.final = []; % Final duration
            
            fprintf('main.m (expset): Storing miscellaneous properties.\n');
            obj.misc = misc;
        end
        
        function [t] = dispfix(obj) % Corresponding to lh1
            obj.misc.fix1(obj.monitor);
            obj.misc.fix2(obj.monitor);
            t = Screen('Flip',obj.monitor.w);
        end
        
        function [t] = disptxt(obj,txt) % Corresponding to lh3
            obj.misc.text(obj.monitor,txt,obj.monitor.black);
            t = Screen('Flip',obj.monitor.w);
        end
        
        function formatTrials(obj)
           [r,trialtype] = obj.testTrials; 
           
           while ~r
               [r,trialtype] = obj.testTrials; 
           end
           
           obj.misc.trialtype = trialtype;
           
        end
        
        function [result,trialtype] = testTrials(obj)
           trialtype = zeros([obj.exp.max_n 1]); 
           result = 1;
           
           stop_i = sort(randsample(obj.exp.go_hold:obj.exp.max_n,obj.exp.stop_n));
           
           range1 = 1;
           range2 = range1 + obj.exp.stop_max;
           
           while range2 <= length(stop_i)
               
               if all(diff(stop_i(range1:range2))==1)
                   result = 0;
                   break;
               end
               
               range1 = range1 + 1;
               range2 = range2 + 1;
               
           end
           
           trialtype(stop_i) = 1;
           
        end
        
        function delayup(obj)
            obj.misc.delay = obj.misc.delay + obj.exp.T/1000;
            if obj.debug
                disp(['main.m (delayup) Delay value (s): ' num2str(obj.misc.delay)]);
            end
        end
        
        function [result] = delaydown(obj)
            if obj.misc.delay > obj.exp.T/1000
                obj.misc.delay = obj.misc.delay - obj.exp.T/1000;
                result = 1;
            else
                result = 0;
            end
            
            if obj.debug
                disp(['main.m (delaydown) Delay value (s): ' num2str(obj.misc.delay)]);
            end
            
        end
        
        function zCalc(obj)
            if isempty(obj.misc.meanRT)
                obj.misc.Z = obj.misc.defaultMeanRT - obj.misc.delay;
            else
                obj.misc.Z = obj.misc.meanRT - obj.misc.delay;
            end
            if obj.debug
                disp(['main.m (zCalc) Z value (s): ' num2str(obj.misc.Z)]);
            end
        end
        
        function meanGo(obj,RT)
            obj.misc.RTvect = [obj.misc.RTvect RT];
            obj.misc.meanRT = nanmean(obj.misc.RTvect);
        end
        
        function [cyc1,cyc2,cyc3,cyc4,cyc5,cyc6] = cycle(obj)
            % cyc1 = First time sample to meet "Stop" onset time
            % cyc2 = "Stop" onset, t1
            % cyc3 = Key press time, null if no response
            % cyc4 = Fixation onset time, t1 + 2000ms
            % cyc5 = Trial offset, after randsample of fixation duration
            % cyc6 = Pass accuracy
            
            % Initialization
            keyflag = 1;
            cyc1 = [];cyc2 = []; cyc3 = [];cyc4 = [];cyc5 = [];cyc6 = 0;
            
            % Calculate timing
            if obj.misc.stop
                t1 = obj.misc.Z;
                dispred = 1;
            else
                t1 = obj.exp.dur1/1000;
                dispred = 0;
            end
            
            fixdur = randsample(obj.exp.fixdur,1)/1000;
            dur = t1 + (obj.exp.dur2/1000);
            
            DrawFormattedText(obj.monitor.w,obj.exp.word,'center','center',obj.exp.green);
            Screen('Flip',obj.monitor.w);
            t0 = GetSecs;
            while (GetSecs - t0) < dur
                tnow = GetSecs - t0;
                [keyIsDown,secs,keyCode]=KbCheck; % Re-occuring check
                
                if tnow > (t1 - obj.misc.buffer)
                    if dispred
                        if obj.misc.stop
                            cyc1 = tnow;
                            if obj.debug
                                disp(['main.m (cycle) Current Time: ' num2str(cyc1)]);
                            end
                            
                            dispred = 0;
                            DrawFormattedText(obj.monitor.w,obj.exp.word,'center','center',obj.exp.red);
                            t = Screen('Flip',obj.monitor.w);
                            
                            cyc2 = t-t0;
                            if obj.debug
                                disp(['main.m (cycle) Display Onset: ' num2str(cyc2)]);
                            end
                        end
                    end
                end
                
                if keyIsDown
                    if find(keyCode)==obj.exp.keys.esckey
                        disp('main.m (cycle) Aborted.');
                        obj.misc.abort = 1;
                    else
                        if keyflag
                            cyc3 = secs-t0;
                            if obj.debug
                                disp(['main.m (cycle) Response Time: ' num2str(cyc3)]);
                            end
                            
                            keyflag = 0;
                            
                            if obj.misc.stop
                                if obj.debug
                                    disp('main.m (cycle) "Stop" trial response');
                                end
                                cyc6 = 2; % Failed Stop (2)
                            else
                                if obj.debug
                                    disp('main.m (cycle) "Go" trial response');
                                end
                                cyc6 = 3; % Success Go (3)
                                obj.meanGo(cyc3);
                            end
                        end
                    end
                    break; % Break if any key press
                end
                
            end
            
            t = obj.dispfix;
            cyc4 = t-t0;
            if obj.debug
                disp(['main.m (cycle) Fixation Onset: ' num2str(cyc4)]);
            end
            WaitSecs(fixdur);
                
            cyc5 = GetSecs-t0;
            if obj.debug
                disp(['main.m (cycle) Trial Offset: ' num2str(cyc5)]);
            end
            
            if keyflag
                if obj.misc.stop
                    if obj.debug
                        disp('main.m (cycle) "Stop" response withheld.');
                    end
                    cyc6 = 1; % Success Stop (1)
                else
                    if obj.debug
                        disp('main.m (cycle) "Go" trial response: No');
                    end
                    cyc6 = 4; % Failed Go (4)
                end
            end
        end
        
        function [t] = precisionTest(obj)
            % cyc1 = First time sample to meet "Stop" onset time
            % cyc2 = "Stop" onset, t1
            % cyc3 = Key press time, null if no response
            % cyc4 = Fixation onset time, t1 + 2000ms
            % cyc5 = Trial offset, after randsample of fixation duration
            % cyc6 = Pass accuracy
            
            obj.misc.cal_cycles = 5;
            obj.misc.steps = 10;
            obj.misc.cal_thresh = 4; % ms
            obj.misc.stop = 1;
            obj.misc.Z = obj.exp.T*obj.misc.steps/1000; % Descending
            obj.misc.buffer = obj.exp.T/1000; % Buffer time (ms) to compensate for next retrace
            obj.debug = 1; % Debug on
            
            disp('main.m (precisionTest): Running precision test.');
            
            t = zeros([obj.misc.cal_cycles*obj.misc.steps 5]);
            
            RestrictKeysForKbCheck(obj.exp.keys.esckey);
            
            for i = 1:obj.misc.cal_cycles*obj.misc.steps
                disp(['main.m (precisionTest) "Stop" duration (s): ' num2str(obj.misc.Z)]);
                [t(i,1),t(i,2),~,t(i,4),t(i,5),~] = obj.cycle;
                disp(['main.m (precisionTest) First valid time sample: ' num2str(t(i,1))]);
                disp(['main.m (precisionTest) "Stop" onset: ' num2str(t(i,2))]);
                %                 disp(['main.m (precisionTest) Reaction time: ' num2str(t(i,3))]);
                disp(['main.m (precisionTest) Fixation onset: ' num2str(t(i,4))]);
                disp(['main.m (precisionTest) Trial offset: ' num2str(t(i,5))]);
                disp('------------------------');
                obj.misc.Z = obj.misc.Z - obj.exp.T/1000;
                if round(obj.misc.Z*1000) <= 0
                    obj.misc.Z = obj.exp.T*obj.misc.steps/1000;
                end
                
                if obj.misc.abort
                    break;
                end
                
            end
            
%             x1 = (repmat(sort(obj.exp.cond,2,'descend'),[1 obj.misc.cal_cycles]) - (t(:,1)')*1000) - obj.exp.T; % First measured time sample subtracting retrace period
%             x2 = repmat(sort(obj.exp.cond,2,'descend'),[1 obj.misc.cal_cycles]) - (t(:,2)')*1000; % Measured flip time stamp
%             x3 = ((t(:,4)')*1000 - (repmat(sort(obj.exp.cond,2,'descend'),[1 2]) + repmat(obj.exp.dur2,[1 obj.misc.cal_cycles*length(obj.)]))) - obj.exp.T; % Entire trial duration (without fixation) subtracting retrace period
%             
%             if abs(mean(x1)) > obj.misc.cal_thresh
%                 warning(['Average time sample prior to retrace period out of threshold range (ms): ' num2str(mean(x1))]);
%             end
%             
%             if abs(mean(x2)) > obj.misc.cal_thresh
%                 warning(['Average flip time stamp out of threshold range (ms): ' num2str(mean(x2))]);
%             end
%             
%             if abs(mean(x3)) > obj.misc.cal_thresh
%                 warning(['Average trial duration out of threshold range (ms): ' num2str(mean(x3))]);
%             end
            
        end
        
        function outFormat(obj,src,evt)
            if src.misc.stop
                type = 'Stop';
                Z = obj.misc.Z;
                delay = obj.misc.delay*1000; % (ms)
                stopval = 1;
            else
                type = 'Go';
                Z = [];
                delay = [];
                stopval = 0;
            end
            
            meanRT = obj.misc.meanRT*1000; % (ms)
            
            obj.out.out1(end+1,:) = {src.exp.sid,type,stopval,Z,delay,evt.RT,evt.code,evt.dur,meanRT};
        end
        
        function outWrite(obj)
                        
            fprintf('main.m (outWrite): Storing accuracy data.\n');
            cell2csv([obj.path.out filesep obj.out.f_out '1.csv'],obj.out.out1)
        
        end
        
    end
    
end

