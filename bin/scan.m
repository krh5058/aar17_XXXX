classdef scan < main
    %SCAN Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
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
            
            fprintf('scan.m (scan): Adding supplemental data fields...\n');
            obj.exp.sid = s{1};
            obj.exp.TR = s{2};
            obj.misc.Z = s{3}/1000; % (s)
            obj.exp.trig = s{4};
            obj.misc.runstart = s{5};
            obj.misc.runorder = obj.misc.runstart:4;
            
            obj.exp.iPAT = false;
            TRadd = 0;
            
            while TRadd <= 4
                TRadd = TRadd + obj.exp.TR/1000;
            end
            
            obj.exp.DisDaq = TRadd + obj.exp.iPAT*obj.exp.TR/1000 + .75; % (s)
            obj.exp.fixdur = xlsread([obj.path.bin filesep 'jit.xlsx']);
            obj.exp.wait1 = 'Ready.';
            obj.exp.wait2 = 'Ready..';
            obj.exp.keys.tkey = KbName('t');
            % Add button box keys
            % Change trial max number, remove break, etc.
            
            fprintf('scan.m (scan): Class construction success!\n');
        end
        
        function [result] = stopcount(obj)
            %             if obj.misc.trial == obj.exp.go_hold
            %                 if isnan(obj.out.out1{end,end})
            %                     obj.misc.Z = obj.exp.dur1/1000;
            %                 else
            %                     obj.misc.Z = obj.out.out1{end,end};
            %                 end
            %             elseif obj.misc.trial > obj.exp.go_hold
            %                 if randi(100) > obj.exp.stopthresh
            %                     if obj.misc.stop <= obj.exp.stop_max
            %                         obj.misc.stop = obj.misc.stop + 1;
            %                         result = 1;
            %                     else
            %                         obj.misc.stop = 0;
            %                         result = 0;
            %                     end
            %                 else
            %                     obj.misc.stop = 0;
            %                     result = 0;
            %                 end
            %             end
            disp('stopcount');
            result = [];
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
            
            %             % Calculate timing
            %             if obj.misc.stop
            % %                 t1 = obj.exp.cond(obj.misc.step)/1000;
            %                 t1 = obj.misc.Z;
            %                 dispred = 1;
            %             else
            %                 t1 = obj.exp.dur1/1000;
            %                 dispred = 0;
            %             end
            %
            %             fixdur = randsample(obj.exp.fixdur,1)/1000;
            %             dur = t1 + (obj.exp.dur2/1000);
            %
            %             DrawFormattedText(obj.monitor.w,obj.exp.word,'center','center',obj.exp.green);
            %             t0 = Screen('Flip',obj.monitor.w);
            %
            %             while (GetSecs - t0) < dur
            %                 tnow = str2double(regexp(num2str(GetSecs - t0),'[.]\d{1,3}','match','once')); % String conversion of time
            %                 [keyIsDown,secs,keyCode]=KbCheck; % Re-occuring check
            %
            %                 if tnow > (t1 - obj.misc.buffer)
            %                     if dispred
            %                         if obj.misc.stop
            %                             cyc1 = tnow;
            %                             if obj.debug
            %                                 disp(['main.m (cycle) Current Time: ' num2str(cyc1)]);
            %                             end
            %
            %                             dispred = 0;
            %                             DrawFormattedText(obj.monitor.w,obj.exp.word,'center','center',obj.exp.red);
            %                             t = Screen('Flip',obj.monitor.w);
            %
            %                             cyc2 = t-t0;
            %                             if obj.debug
            %                                 disp(['main.m (cycle) Display Onset: ' num2str(cyc2)]);
            %                             end
            %                         end
            %                     end
            %                 end
            %
            %                 if keyIsDown
            %                     if find(keyCode)==obj.exp.keys.esckey
            %                         disp('main.m (cycle) Aborted.');
            %                         obj.misc.abort = 1;
            %                     elseif find(keyCode)==obj.exp.keys.mkey
            %                         if keyflag
            %                             cyc3 = secs-t0;
            %                             if obj.debug
            %                                 disp(['main.m (cycle) Response Time: ' num2str(cyc3)]);
            %                             end
            %
            %                             keyflag = 0;
            %
            %                             if obj.misc.stop
            %                                 if obj.debug
            %                                     disp('main.m (cycle) "Stop" trial response');
            %                                 end
            %                                 cyc6 = 2; % Failed Stop (2)
            %                             else
            %                                 if obj.debug
            %                                     disp('main.m (cycle) "Go" trial response');
            %                                 end
            %                                 cyc6 = 3; % Success Go (3)
            %                             end
            %                         end
            %                     end
            %                     break; % Break if any key press
            %                 end
            %
            %             end
            %
            %             t = obj.dispfix;
            %             cyc4 = t-t0;
            %             if obj.debug
            %                 disp(['main.m (cycle) Fixation Onset: ' num2str(cyc4)]);
            %             end
            %             WaitSecs(fixdur);
            %
            %             cyc5 = GetSecs-t0;
            %             if obj.debug
            %                 disp(['main.m (cycle) Trial Offset: ' num2str(cyc5)]);
            %             end
            %
            %             if keyflag
            %                 if obj.misc.stop
            %                     if obj.debug
            %                         disp('main.m (cycle) "Stop" response withheld.');
            %                     end
            %                     cyc6 = 1; % Success Stop (1)
            %                 else
            %                     if obj.debug
            %                         disp('main.m (cycle) "Go" trial response: No');
            %                     end
            %                     cyc6 = 4; % Failed Go (4)
            %                 end
            %             end
            %
            %             if obj.debug
            %                 disp('------------------');
            %             end
            
            disp('cycle');
        end
         
         function outFormat(obj,src,evt)
             %              if src.misc.stop
             %                  type = 'Stop';
             %                  delay = obj.misc.Z;
             %                  stopval = 1;
             %                  %                 temp = nan([1 length(src.out.head2)]);
             %                  %                 temp(1) = src.misc.trial;
             %                  %                 temp(src.misc.step+1) = evt.pass;
             %                  %                 obj.out.evalMat(end+1,:) = temp;
             %              else
             %                  type = 'Go';
             %                  delay = [];
             %                  stopval = 0;
             %              end
             %              obj.out.out1(end+1,1:end-1) = {src.exp.sid,type,stopval,delay,evt.RT,evt.code,evt.dur};
             %              obj.out.out1{end,end} = mean([obj.out.out1{2:end,5}]);
             
             disp('outFormat');
         end
        
    end
    
end

