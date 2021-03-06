function xxxx(varargin)
% XXXX
% As requested by Avery Rizio
% 8/7/13
%
% Author: Ken Hwang
% SLEIC, PSU
%
% See ReadMe.txt

if ~ispc
    error('xxxx.m: PC support only.')
end

% Argument handling
arg_valid = {'precision','scan'}; % Valid arguments as opposed to switch statement
arglist = []; % Maybe for later

for argn = 1:length(arg_valid)
    arglist.(arg_valid{argn}) = 0;
end

if nargin > 0
    if any(strcmp(varargin{1},arg_valid)) % Only one argument allowed
        arglist.(varargin{1}) = 1;
        state = varargin{1};
    else
        error('Unknown input argument.');
    end
else
    state = 'none';
end

% Directory initialization
try
    fprintf('xxxx.m: Directory initialization...\n')
    
    mainpath = which('main.m');
    if ~isempty(mainpath)
        [mainext,~,~] = fileparts(mainpath);
        rmpath(mainext);
    end
    
    javauipath = which('javaui.m');
    if ~isempty(javauipath)
        [javauiext,~,~] = fileparts(javauipath);
        rmpath(javauiext);
    end
    
    p = mfilename('fullpath');
    [ext,~,~] = fileparts(p);
    [~,d] = system(['dir /ad-h/b ' ext]);
    d = regexp(strtrim(d),'\n','split');
    cellfun(@(y)(addpath([ext filesep y])),d);
    fprintf('xxxx.m: Directory initialization success!.\n')
catch ME
    throw(ME)
end

try
    fprintf('xxxx.m: Object Handling...\n')
    % Object construction and initial key restriction
    switch state
        case 'scan'
            obj = scan(ext,d);
            obj.exp.T = (1/75)*1000; % ms
            obj.misc.buffer = obj.exp.T/1000; % Buffer time (ms) to compensate for next retrace
            RestrictKeysForKbCheck([obj.exp.keys.key1 obj.exp.keys.key2 obj.exp.keys.key3 obj.exp.keys.key4]);
        otherwise
            obj = main(ext,d);
            RestrictKeysForKbCheck(obj.exp.keys.spacekey);
    end
    fprintf('xxxx.m: Object Handling success!.\n')
catch ME
    throw(ME)
end

try
    fprintf('xxxx.m: Window initialization...\n')
    % Open and format window
    obj.monitor.w = Screen('OpenWindow',obj.monitor.whichScreen,obj.monitor.white);
%     Screen('BlendFunction',obj.monitor.w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    Screen('TextSize',obj.monitor.w,obj.exp.txtsize);
    fprintf('xxxx.m: Window initialization success!.\n')
catch ME
    throw(ME)
end

fprintf('xxxx.m: Beginning presentation sequence...\n')

if ~obj.debug
    ListenChar(2);
    HideCursor;
    ShowHideWinTaskbarMex(0);
end

% Wait for instructions
obj.disptxt(obj.exp.intro);
KbStrokeWait;

% Presentation
switch state
    case 'precision'
        
        t = obj.precisionTest;
        disp(t);

    case 'scan'
        
        Screen('TextSize',obj.monitor.w,obj.exp.wordsize);
        
        for i = obj.misc.runorder
            
            % Formatting trials for each run
            obj.formatTrials;
            obj.formatOnset;
            
            % Reset trial number
            obj.misc.trial = 1;
            
            % Update run number
            obj.misc.run = i;
                        
            % Ignore last trial offset
            end_flag = 0;
            
            % Abort keyflag
            keyflag = 1;
                        
            % Parameters for first presentation
            obj.misc.stop = obj.misc.trialtype(obj.misc.trial);
            
            if obj.misc.stop
                obj.delayAdjust;
                obj.zCalc;
            end
            
            if obj.debug
                csvwrite(['run' int2str(obj.misc.run) '_onset.csv'], obj.misc.trial_onset);
            end
            
            % Wait for participant
            RestrictKeysForKbCheck([obj.exp.keys.esckey obj.exp.keys.key1 obj.exp.keys.key2 obj.exp.keys.key3 obj.exp.keys.key4]);
            obj.disptxt(obj.exp.break);
            KbStrokeWait;
            
            % Wait for experimenter
            RestrictKeysForKbCheck(obj.exp.keys.spacekey);
            obj.disptxt(obj.exp.advance);
            KbStrokeWait;
            
            % Triggering
            obj.disptxt(obj.exp.wait1);
            if obj.exp.trig % Auto-trigger
                RestrictKeysForKbCheck(obj.exp.keys.tkey);
                trig_t = KbStrokeWait; % Waiting for first trigger pulse, return timestamp
                obj.misc.start_t = (trig_t - obj.exp.DisDaq) + obj.exp.whilebuffer;
            else % Manual trigger
                RestrictKeysForKbCheck(obj.exp.keys.spacekey);
                KbStrokeWait; % Waiting for scanner operator
                obj.disptxt(obj.exp.wait2);
                obj.misc.start_t = GetSecs; % Return timestamp
                pause(obj.exp.DisDaq); % Simulating DisDaq
            end
            
            % Add button box keys
            RestrictKeysForKbCheck([obj.exp.keys.esckey obj.exp.keys.key1 obj.exp.keys.key2 obj.exp.keys.key3 obj.exp.keys.key4]);

            % Loop cycle
            while (GetSecs - obj.misc.start_t) < obj.misc.trial_onset(end)/1000
                
                [keyIsDown,~,keyCode]=KbCheck; % Re-occuring check
                
                if keyflag
                    if keyIsDown
                        keyflag = 0;
                        if find(keyCode)==obj.exp.keys.esckey
                            disp('xxxx.m: Aborted.');
                            obj.misc.abort = 1;
                            break;
                        end
                    end
                end
                
                if ~end_flag % Ignore last trial offset
                    if (GetSecs - obj.misc.start_t) >= obj.misc.trial_onset(obj.misc.trial)/1000
                        
                        data = [];
                        trial_start = GetSecs; % (s)
                        data.t = (trial_start - obj.misc.start_t)*1000; % Start timestamp (ms)
                        [~,~,data.RT,data.dur,data.code,data.resp] = obj.cycle;
                        
                        notify(obj,'record',evt(data));
                        
                        if obj.misc.trial > 1
                            obj.fixdurRecord(trial_start - trial_start0); % Record fixation duration
                        end
                        
                        trial_start0 = trial_start; % (s)
                        
                        if obj.misc.abort
                            break;
                        end
                        
                        obj.misc.trial = obj.misc.trial + 1; % Add
                        
                        if obj.misc.trial <= obj.exp.max_n
                            obj.misc.stop = obj.misc.trialtype(obj.misc.trial);
                            
                            if obj.misc.stop
                                obj.delayAdjust;
                                obj.zCalc;
                            end
                        else
                            end_flag = 1;
                        end
                    end
                end
            end
            
            if ~obj.misc.abort
                obj.fixdurRecord(GetSecs - trial_start0); % Final fixation duration, waits until while loop finishes execution
                pause(obj.exp.endfixdur);
            end
            
            obj.outStore;
            
            if obj.misc.abort
                break;
            end
            
        end
        
        obj.outWrite;
        
    otherwise
        
        RestrictKeysForKbCheck([]);
        
        while obj.misc.trial <= obj.exp.max_n
            
            obj.misc.stop = obj.misc.trialtype(obj.misc.trial);
            
            if any(obj.misc.trial==obj.exp.break_n)
                obj.disptxt(obj.exp.break);
                RestrictKeysForKbCheck(obj.exp.keys.spacekey);
                KbStrokeWait;
                RestrictKeysForKbCheck([]);
                pause(.5);
            end
            
            if obj.misc.trial >= obj.exp.go_hold
                if obj.misc.stop
                    obj.zCalc;
                end
            end
            
            [~,~,data.RT,data.dur,~,data.code] = obj.cycle;
            
            if obj.misc.abort
                break;
            end
            
            notify(obj,'record',evt(data));
            
            if obj.misc.stop
                if data.code==1
                    obj.delaydown; % Decrease delay duration on success
                else
                    obj.delayup; % Increase delay duration on fail
                end
            end
            
            obj.misc.trial = obj.misc.trial + 1;
            
            if obj.debug
                disp('------------------');
            end
            
        end
        
        obj.outWrite;
end

% Clean up
RestrictKeysForKbCheck([]);
if ~obj.debug
    ListenChar(0);
    ShowCursor;
    ShowHideWinTaskbarMex(1);
end

Screen('Preference','VisualDebugLevel',obj.monitor.oldVisualDebugLevel);
fclose('all');
Screen('CloseAll');

end