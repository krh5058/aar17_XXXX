classdef scan < main
    
    methods
        function obj = scan(ext,d)
            fprintf('scan.m (scan): Initializing sub-class of main, scan...\n');
            fprintf('scan.m (scan): Attempting superclass construction...\n');
            obj = obj@main(ext,d);
            
            fprintf('scan.m (scan): Gathering experimental parameters.\n');
            frame = javaui;
            waitfor(frame,'Visible','off'); % Wait for visibility to be off
            s = getappdata(frame,'UserData'); % Get frame data
            java.lang.System.gc();
            
            if isempty(s)
                error('scan.m (scan): User Cancelled.')
            end
            
            fprintf('scan.m (scan): Adding/Modifying supplemental data fields...\n');
            obj.exp.sid = s{1};
            obj.exp.TR = s{2}; % (ms)
            obj.misc.delay = s{3}/1000; % (s)
            obj.misc.delayshift = 0; % (s)
            obj.misc.i_meanRT = s{4}/1000; % Initial mean RT (s)
            obj.exp.trig = s{5};
            obj.misc.runstart = s{6};
            obj.misc.runorder = obj.misc.runstart:4;
            
            obj.exp.iPAT = false;
            TRadd = 0;
            
            while TRadd <= 4
                TRadd = TRadd + obj.exp.TR/1000;
            end
            
            obj.exp.DisDaq = TRadd + obj.exp.iPAT*obj.exp.TR/1000 + .75; % (s)
            obj.misc.run = [];
            obj.misc.start_t = [];
            obj.misc.defaultDelay = 250/1000; % (s)
            obj.exp.whilebuffer = .13;
            obj.exp.keys.tkey = KbName('t');
            obj.exp.fixdur = xlsread([obj.path.bin filesep 'jit.xlsx']);
            obj.exp.stopdur = (obj.misc.defaultMeanRT - obj.misc.defaultDelay)*1000 + obj.exp.dur2; % ms
            obj.exp.godur = obj.exp.dur1  + obj.exp.dur2; % ms
            obj.exp.endfixdur = 10; % (s)
            obj.exp.trial_onset = [];
            obj.exp.wait1 = 'Ready.';
            obj.exp.wait2 = 'Ready..';
            obj.exp.intro = ['When a word appears in green\n' ...
                'press as quickly as possible.\n\n\n' ...
                'If a word appears in red\n' ...
                'do not make a button press.\n\n\n' ...
                'Both speed and accuracy are equally important.\n\n\n' ...
                'Press any button to continue.'];
            obj.exp.break = 'Press when you are ready for the next block.';
            obj.exp.advance = 'Press spacebar.';
            obj.exp.txtsize = 20;
            obj.exp.wordsize = 30;
            obj.exp.max_n = 50; % Max trial limit
            obj.exp.stop_ratio = .2; % Ratio of stop to go trials
            obj.exp.stop_n = round(obj.exp.max_n*obj.exp.stop_ratio);
            obj.exp.go_hold = 1; % Remove go trial hold
            % Right button box
            obj.exp.keys.key1 = KbName('1!');
            obj.exp.keys.key2 = KbName('2@');
            obj.exp.keys.key3 = KbName('3#');
            obj.exp.keys.key4 = KbName('4$');  
            
            obj.out.f_out = [obj.exp.sid '_run'];
            obj.out.head1 = {'SID','Run','Trial','ScheduledOnset (ms)','RawOnset (ms)','TROnset','Go/Stop','Stop','Z (s)','Delay (ms)','Response','RT (s)','Code','Duration (s)','Jitter (ms)','Mean (ms)'};
            obj.out.out1 = cell([1 length(obj.out.head1)]);
            obj.out.out1(1,:) = obj.out.head1;
            obj.out.out2 = cell([1 length(obj.out.head1)]);
            obj.out.out2(1,:) = obj.out.head1;
            
            fprintf('scan.m (scan): Class construction success!\n');
        end
        
        function formatOnset(obj)
           trial_dur = obj.misc.trialtype*obj.exp.stopdur + ~obj.misc.trialtype*obj.exp.godur;
           onset_raw = cumsum(trial_dur + obj.exp.fixdur) + obj.exp.DisDaq*1000;
           obj.misc.trial_onset = [0; onset_raw];
        end
        
        function delayAdjust(obj)
            switch randsample(1:4,1)
                case 3
                    obj.misc.delayshift = obj.exp.T/1000;
                case 4
                    obj.misc.delayshift = -obj.exp.T/1000;
                otherwise
                    obj.misc.delayshift = 0;
            end
            
            if obj.debug
                disp(['main.m (delayAdjust) Delay shift value (s): ' num2str(obj.misc.delayshift)]);
            end
            
        end
            
        function zCalc(obj)
            
            if obj.misc.trial == 1 % Entered mean RT
                obj.misc.Z = obj.misc.i_meanRT - (obj.misc.delay + obj.misc.delayshift);
            elseif isempty(obj.misc.meanRT) % Entered mean RT
                obj.misc.Z = obj.misc.i_meanRT - (obj.misc.delay + obj.misc.delayshift);
            else % Running mean RT
                obj.misc.Z = obj.misc.meanRT - (obj.misc.delay + obj.misc.delayshift);
            end
            if obj.debug
                disp(['main.m (zCalc) Z value (s): ' num2str(obj.misc.Z)]);
            end
        end
        
        function [cyc1,cyc2,cyc3,cyc4,cyc5,cyc6] = cycle(obj)
            % cyc1 = First time sample to meet "Stop" onset time
            % cyc2 = "Stop" onset, t11
            % cyc3 = Key press time, null if no response
            % cyc4 = Fixation onset time, t1 + 2000ms
            % cyc5 = Pass accuracy
            % cyc6 = Response key

            % Initialization
            keyflag = 1;
            cyc1 = [];cyc2 = []; cyc3 = [];cyc4 = [];cyc5 = [];cyc6 = [];
            
            % Calculate timing
            if obj.misc.stop
                t1 = obj.misc.Z;
                dispred = 1;
            else
                t1 = obj.exp.dur1/1000;
                dispred = 0;
            end
            
            dur = t1 + (obj.exp.dur2/1000); % Actual trial duration (prior to fixation) (s)
            
            DrawFormattedText(obj.monitor.w,obj.exp.word,'center','center',obj.exp.green);
            t0 = Screen('Flip',obj.monitor.w);
            
            while (GetSecs - t0) < (dur - obj.misc.buffer)
%             while (GetSecs - t0) < dur
                tnow = GetSecs - t0;
                [keyIsDown,secs,keyCode]=KbCheck; % Re-occuring check
                
%                 if tnow > (t1 - obj.misc.buffer)
                if tnow > (t1 - obj.misc.buffer)
                    if dispred
                        if obj.misc.stop
                            cyc1 = tnow;
                            if obj.debug
                                disp(['scan.m (cycle) Current Time: ' num2str(cyc1)]);
                            end
                            
                            dispred = 0;
                            DrawFormattedText(obj.monitor.w,obj.exp.word,'center','center',obj.exp.red);
                            t = Screen('Flip',obj.monitor.w);
                            
                            cyc2 = t-t0;
                            if obj.debug
                                disp(['scan.m (cycle) Display Onset: ' num2str(cyc2)]);
                            end
                        end
                    end
                end
                        
                if keyflag
                    if keyIsDown
                        keyflag = 0;
                        if find(keyCode)==obj.exp.keys.esckey
                            disp('scan.m (cycle) Aborted.');
                            obj.misc.abort = 1;
                            break;
                        else
                            resp = find(keyCode);
                            if obj.debug
                                disp(['scan.m (cycle) Response: ' num2str(resp)]);
                            end
                            cyc6 = resp;
                            cyc3 = secs-t0;
                            if obj.debug
                                disp(['scan.m (cycle) Response Time: ' num2str(cyc3)]);
                            end
                            
                            if obj.misc.stop
                                if obj.debug
                                    disp('scan.m (cycle) "Stop" trial response');
                                end
                                cyc5 = 2; % Failed Stop (2)
                            else
                                if obj.debug
                                    disp('scan.m (cycle) "Go" trial response');
                                end
                                cyc5 = 3; % Success Go (3)
                                obj.meanGo(cyc3);
                            end
                        end
                        %                     break; % Break if any key press
                    end
                end
            end
            
            if obj.misc.abort
                return;
            end
            
            t = obj.dispfix;
            cyc4 = t-t0;
            if obj.debug
                disp(['scan.m (cycle) Fixation Onset: ' num2str(cyc4)]);
            end
            
            if keyflag
                if obj.misc.stop
                    if obj.debug
                        disp('scan.m (cycle) "Stop" response withheld.');
                    end
                    cyc5 = 1; % Success Stop (1)
                else
                    if obj.debug
                        disp('scan.m (cycle) "Go" trial response: No');
                    end
                    cyc5 = 4; % Failed Go (4)
                end
            end
            
            if obj.debug
                disp('------------------');
            end
        end
         
        function outFormat(obj,src,evt)
            if src.misc.stop
                type = 'Stop';
                Z = obj.misc.Z;
                delay = (obj.misc.delay + obj.misc.delayshift)*1000; % (ms)
                stopval = 1;
            else
                type = 'Go';
                Z = [];
                delay = [];
                stopval = 0;
            end
            
            meanRT = obj.misc.meanRT*1000; % (ms)
            
            obj.out.out1(end+1,:) = {src.exp.sid,src.misc.run,src.misc.trial,obj.misc.trial_onset(obj.misc.trial),evt.t,evt.t/src.exp.TR,type,stopval,Z,delay,evt.resp,evt.RT,evt.code,evt.dur,[],meanRT};
        end
        
        function fixdurRecord(obj,t)
            obj.out.out1{obj.misc.trial,15} = (t - obj.out.out1{obj.misc.trial,14})*1000; % (ms) (Last trial (-1) + col header row (+1)): Last trial's jitter duration == between trial offset time minus last trial's duration time
        end
        
        function outStore(obj)
            
            % Store
            fprintf('scan.m (outStore): Storing data.\n');
            obj.out.(['run' int2str(obj.misc.run)]) = obj.out.out1;

            % Reset
            obj.out.out1 = cell([1 length(obj.out.head1)]);
            obj.out.out1(1,:) = obj.out.head1;
            
        end
        
        function outWrite(obj)
            
            fprintf('scan.m (outWrite): Saving data.\n');
            
            for i = obj.misc.runorder(1):obj.misc.run
                try
                    obj.out.out2 = [obj.out.out2; obj.out.(['run' int2str(i)])(2:end,:)];
                catch ME
                    disp(ME);
                end
            end
            
            cell2csv([obj.path.out filesep obj.out.f_out '.csv'],obj.out.out2); % Output by run #
            
        end
        
    end
    
end

