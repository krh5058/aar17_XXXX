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
    Screen('BlendFunction',obj.monitor.w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    Screen('TextSize',obj.monitor.w,30);
    fprintf('xxxx.m: Window initialization success!.\n')
catch ME
    throw(ME)
end

fprintf('xxxx.m: Beginning presentation sequence...\n')

if ~obj.debug
    ListenChar(2);
    HideCursor;
    ShowHideFullWinTaskbarMex(0);
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
        
        for i = obj.misc.runorder
            
            % Formatting trials for each run
            obj.formatTrials;
            obj.formatOnset;
            
            % Reset trial number
            obj.misc.trial = 1;
            
            % Update run number
            obj.misc.run = i;
                        
            % Triggering
            obj.disptxt(obj.exp.wait1);
            if obj.exp.trig % Auto-trigger
                RestrictKeysForKbCheck(obj.exp.keys.tkey);
                obj.misc.start_t = GetSecs; % Return timestamp
                KbStrokeWait; % Waiting for first trigger pulse, return timestamp
            else % Manual trigger
                RestrictKeysForKbCheck(obj.exp.keys.spacekey);
                KbStrokeWait; % Waiting for scanner operator
                obj.disptxt(obj.exp.wait2);
                obj.misc.start_t = GetSecs; % Return timestamp
                pause(obj.exp.DisDaq); % Simulating DisDaq
            end
            
            % Add button box keys
            RestrictKeysForKbCheck([obj.exp.keys.esckey obj.exp.keys.key1 obj.exp.keys.key2 obj.exp.keys.key3 obj.exp.keys.key4]);
            
            % First presentation
            obj.misc.stop = obj.misc.trialtype(obj.misc.trial);
            
            if obj.misc.stop
                obj.delayAdjust;
                obj.zCalc;
            end
            
            data = [];
            data.t = (GetSecs - obj.misc.start_t)*1000; % Start timestamp (ms)
            [~,~,data.RT,data.dur,data.offset,data.code,data.resp] = obj.cycle;
            
            notify(obj,'record',evt(data));
            
            if obj.misc.abort
                break;
            end
            
            obj.misc.trial = obj.misc.trial + 1; % Add
            
            obj.misc.stop = obj.misc.trialtype(obj.misc.trial);
            
            if obj.misc.stop
                obj.delayAdjust;
                obj.zCalc;
            end
                
            % Loop cycle
            while (GetSecs - obj.misc.start_t) < obj.misc.trial_onset(end)/1000
                
                if (GetSecs - obj.misc.start_t) >= obj.misc.trial_onset(obj.misc.trial)/1000
                    
                    data = [];
                    data.t = (GetSecs - obj.misc.start_t)*1000; % Start timestamp (ms)
                    [~,~,data.RT,data.dur,~,data.code,data.resp] = obj.cycle;
                    
                    notify(obj,'record',evt(data));
                    
                    if obj.misc.abort
                        break;
                    end
                    
                    obj.misc.trial = obj.misc.trial + 1; % Add
                    
                    if ~(obj.misc.trial > obj.exp.max_n)
                        obj.misc.stop = obj.misc.trialtype(obj.misc.trial);
                        
                        if obj.misc.stop
                            obj.delayAdjust;
                            obj.zCalc;
                        end
                    end
                    
                end
            end
            
            obj.outStore;
            
            if obj.misc.abort
                break;
            end
            
        end
        
        obj.outWrite;
        
    otherwise
        
        RestrictKeysForKbCheck([obj.exp.keys.esckey obj.exp.keys.mkey]);
        
        while obj.misc.trial <= obj.exp.max_n
            
            obj.misc.stop = obj.misc.trialtype(obj.misc.trial);
            
            if any(obj.misc.trial==obj.exp.break_n)
                obj.disptxt(obj.exp.break);
                RestrictKeysForKbCheck(obj.exp.keys.spacekey);
                KbStrokeWait;
                RestrictKeysForKbCheck([obj.exp.keys.esckey obj.exp.keys.mkey]);
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
    ShowHideFullWinTaskbarMex(1);
end

Screen('Preference','VisualDebugLevel',obj.monitor.oldVisualDebugLevel);
fclose('all');
Screen('CloseAll');

end