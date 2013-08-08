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
            obj.misc.delay = s{3}; % (ms)
            obj.exp.trig = s{4};
            obj.misc.runstart = s{5};
            obj.misc.runorder = obj.misc.runstart:4;
            
            obj.exp.iPAT = false;
            TRadd = 0;
            
            while TRadd <= 4
                TRadd = TRadd + obj.exp.TR/1000;
            end
            
            obj.exp.DisDaq = TRadd + obj.exp.iPAT*obj.exp.TR/1000 + .75; % (s)
            obj.misc.run = [];
            obj.misc.start_t = [];
            obj.exp.keys.tkey = KbName('t');
            obj.exp.fixdur = xlsread([obj.path.bin filesep 'jit.xlsx']);
            obj.exp.wait1 = 'Ready.';
            obj.exp.wait2 = 'Ready..';
            obj.exp.intro = ['When a word appears in green\n' ...
                'press as quickly as possible.\n\n\n' ...
                'If a word appears in red\n' ...
                'do not make a key press.\n\n\n' ...
                'Both speed and accuracy are equally important.\n\n\n' ...
                'Press any button to continue.'];
            obj.exp.stop_n = 50; % Max trial limit
            % Right button box
            obj.exp.keys.key1 = KbName('6^');
            obj.exp.keys.key2 = KbName('7&');
            obj.exp.keys.key3 = KbName('8*');
            obj.exp.keys.key4 = KbName('9(');  
            
            obj.out.f_out = [obj.exp.sid '_run'];
            obj.out.head1 = {'SID','Run','Trial','RawOnset (ms)','TROnset','Go/Stop','Stop','Delay','Response','RT (s)','Code','Duration (s)','Jitter (ms)','Mean (s)'};
            obj.out.out1 = cell([1 length(obj.out.head1)]);
            obj.out.out1(1,:) = obj.out.head1;
            
            fprintf('scan.m (scan): Class construction success!\n');
        end
        
        function [result] = stopcount(obj)
            if randi(100) > obj.exp.stopthresh
                if obj.misc.stop <= obj.exp.stop_max
                    obj.misc.stop = obj.misc.stop + 1;
                    
                    randZ = randsample(4,1);
                    if any(randZ==[1 2])
                        obj.misc.Z = obj.misc.delay/1000; % (s)
                    elseif randZ==3
                        obj.misc.Z = obj.misc.delay + obj.exp.T; % (s)
                    else
                        obj.misc.Z = obj.misc.delay - obj.exp.T; % (s)
                    end
                    
                    result = 1;
                else
                    obj.misc.stop = 0;
                    result = 0;
                end
            else
                obj.misc.stop = 0;
                result = 0;
            end
        end
        
        function [cyc1,cyc2,cyc3,cyc4,cyc5,cyc6,cyc7] = cycle(obj)
            % cyc1 = First time sample to meet "Stop" onset time
            % cyc2 = "Stop" onset, t1
            % cyc3 = Key press time, null if no response
            % cyc4 = Fixation onset time, t1 + 2000ms
            % cyc5 = Trial offset, after fixation duration
            % cyc6 = Pass accuracy
            % cyc7 = Response key

            % Initialization
            keyflag = 1;
            cyc1 = [];cyc2 = []; cyc3 = [];cyc4 = [];cyc5 = [];cyc6 = 0;cyc7 = [];
            
            % Calculate timing
            if obj.misc.stop
                t1 = obj.misc.Z/1000;
                dispred = 1;
            else
                t1 = obj.exp.dur1/1000;
                dispred = 0;
            end
            
            fixdur = obj.exp.fixdur(obj.misc.trial)/1000;
            dur = t1 + (obj.exp.dur2/1000);
            
            DrawFormattedText(obj.monitor.w,obj.exp.word,'center','center',obj.exp.green);
            t0 = Screen('Flip',obj.monitor.w);
            
            while (GetSecs - t0) < dur
                tnow = str2double(regexp(num2str(GetSecs - t0),'[.]\d{1,3}','match','once')); % String conversion of time
                [keyIsDown,secs,keyCode]=KbCheck; % Re-occuring check
                
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
                            cyc7 = resp;
                            cyc3 = secs-t0;
                            if obj.debug
                                disp(['scan.m (cycle) Response Time: ' num2str(cyc3)]);
                            end
                            
                            if obj.misc.stop
                                if obj.debug
                                    disp('scan.m (cycle) "Stop" trial response');
                                end
                                cyc6 = 2; % Failed Stop (2)
                            else
                                if obj.debug
                                    disp('scan.m (cycle) "Go" trial response');
                                end
                                cyc6 = 3; % Success Go (3)
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
            WaitSecs(fixdur);
            
            cyc5 = GetSecs-t0;
            if obj.debug
                disp(['scan.m (cycle) Trial Offset: ' num2str(cyc5)]);
            end
            
            if keyflag
                if obj.misc.stop
                    if obj.debug
                        disp('scan.m (cycle) "Stop" response withheld.');
                    end
                    cyc6 = 1; % Success Stop (1)
                else
                    if obj.debug
                        disp('scan.m (cycle) "Go" trial response: No');
                    end
                    cyc6 = 4; % Failed Go (4)
                end
            end
            
            if obj.debug
                disp('------------------');
            end
        end
         
        function outFormat(obj,src,evt)
            if src.misc.stop
                type = 'Stop';
                delay = obj.misc.Z;
                stopval = 1;
            else
                type = 'Go';
                delay = [];
                stopval = 0;
            end
            
            fixdur = (evt.offset - evt.dur)*1000; % (ms)
            
            obj.out.out1(end+1,1:end-1) = {src.exp.sid,src.misc.run,src.misc.trial,evt.t,evt.t/src.exp.TR,type,stopval,delay,evt.resp,evt.RT,evt.code,evt.dur,fixdur};
            obj.out.out1{end,end} = mean([obj.out.out1{2:end,10}]); % Mean RT
        end
        
        function outWrite(obj)
            
            fprintf('scan.m (outWrite): Storing accuracy data.\n');
            cell2csv([obj.path.out filesep obj.out.f_out int2str(obj.misc.run) '.csv'],obj.out.out1); % Output by run #
            
            % Reset
            obj.out.out1 = cell([1 length(obj.out.head1)]);
            obj.out.out1(1,:) = obj.out.head1;
            
        end
        
    end
    
end
