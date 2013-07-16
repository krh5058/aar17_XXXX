% function xxxx
% XXXX
% As requested by Avery Rizio
% 7/9/13
%
% Author: Ken Hwang
% SLEIC, PSU

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
warning('OFF','MATLAB:mode:EmptyInput');
% ListenChar(2);
% HideCursor;
% ShowHideFullWinTaskbarMex(0);

% Wait for instructions
RestrictKeysForKbCheck([obj.exp.keys.spacekey]);
obj.disptxt(obj.exp.intro);
KbStrokeWait;

precision = 0;

if precision
    
    [x1,x2,x3] = obj.precisionTest;
    
else
    
    RestrictKeysForKbCheck([obj.exp.keys.esckey obj.exp.keys.mkey]);
    
    while ~obj.misc.kill
        
        obj.stopcount;
        [~,~,data.RT,data.dur,~,data.pass] = obj.cycle;
        
        if obj.misc.abort
            break;
        end
        
        notify(obj,'record',evt(data));
        notify(obj,'eval');
        
        if obj.misc.stop
            if data.pass
                obj.stepup; % Increase duration on success
            else
                obj.stepdown; % Decrease duration on fail
            end
        end
        
        obj.misc.trial = obj.misc.trial + 1;
        
    end
    
    obj.outWrite;
    
end
% % Clean up
% ListenChar(0);
% ShowCursor; 
% ShowHideFullWinTaskbarMex(1);
% warning('ON','MATLAB:mode:EmptyInput');

% Screen('Preference','VisualDebugLevel',obj.monitor.oldVisualDebugLevel);
% fclose('all');
% Screen('CloseAll');

% end