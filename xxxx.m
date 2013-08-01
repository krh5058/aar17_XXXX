function xxxx(varargin)
% XXXX
% As requested by Avery Rizio
% 7/9/13
%
% Author: Ken Hwang
% SLEIC, PSU
%
% See ReadMe.txt

if ~ispc
    error('xxxx.m: PC support only.')
end

% Directory initialization
try
    fprintf('xxxx.m: Directory initialization...\n')
    
    mainpath = which('main.m');
    if ~isempty(mainpath)
        [mainext,~,~] = fileparts(mainpath);
        rmpath(mainext);
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
    % Object construction and event handling
    obj = main(ext,d);
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
ListenChar(2);
HideCursor;
ShowHideFullWinTaskbarMex(0);

% Wait for instructions
RestrictKeysForKbCheck([obj.exp.keys.spacekey]);
obj.disptxt(obj.exp.intro);
KbStrokeWait;

precision = 0;

if nargin > 0
    switch varargin{1}
        case 'precision'
            precision = 1;
        otherwise
            error('Unknown input argument.');
    end
end

if precision
    
    t = obj.precisionTest;
    disp(t);
    
else
    
    RestrictKeysForKbCheck([obj.exp.keys.esckey obj.exp.keys.mkey]);
    
    while obj.misc.trial <= obj.exp.stop_n
        
        if any(obj.misc.trial==(obj.exp.stop_n:-obj.exp.break_n:1))
            obj.disptxt(obj.exp.break);
            RestrictKeysForKbCheck(obj.exp.keys.spacekey);
            KbStrokeWait;
            RestrictKeysForKbCheck([obj.exp.keys.esckey obj.exp.keys.mkey]);
            pause(.5);
        end
        
        obj.stopcount;
        [~,~,data.RT,data.dur,~,data.code] = obj.cycle;
        
        if obj.misc.abort
            break;
        end
        
        notify(obj,'record',evt(data));
%         notify(obj,'eval');
        
        if obj.misc.stop
            if data.code==1
                obj.stepup; % Increase duration on success
            else
                obj.stepdown; % Decrease duration on fail
            end
        end
        
        obj.misc.trial = obj.misc.trial + 1;
        
    end
    
    obj.outWrite;
    
end

% Clean up
ListenChar(0);
ShowCursor; 
ShowHideFullWinTaskbarMex(1);

Screen('Preference','VisualDebugLevel',obj.monitor.oldVisualDebugLevel);
fclose('all');
Screen('CloseAll');

end