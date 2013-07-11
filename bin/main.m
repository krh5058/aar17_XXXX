classdef main < handle
    %MAIN Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        debug = 1; % Debug on/off
        trial = 1; % Trial count
        step = 3; % Step in duration condition. 3 corresponds with starting condition of 200 ms.
        stop = 0; % Stop counter and flag.
        monitor
        path
        exp
        temp_t
        abort = 0;
    end
    
    properties (SetObservable)
        dat
    end
    
    events
       fix
       word
       txt
    end
    
    methods (Static)
        function [monitor] = disp()
            % Find out screen number.
            debug = 1;
            if debug
                %                 whichScreen = max(Screen('Screens'));
                whichScreen = 1;
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
            
            exp.sid = datestr(now,30);
            exp.dur1 = 200; % ms
            exp.dur2 = 2000; % ms
            exp.cond = 72:64:456; % ms
            exp.fixdur = 1000:3000; % ms
            exp.stopthresh = 80;
            exp.green = [0 255 0];
            exp.red = [255 0 0];
            exp.stop_max = 3;
            exp.break_n = 133;
            exp.kill_n = 10;
            exp.kill_acc = .7;            
            exp.f_out = [exp.sid '_out'];
            exp.intro = ['When a word appears in green\n' ...
                'press "m" as quickly as possible.\n\n\n' ...
                'If a word appears in red\n' ...
                'do not make a key press.\n\n\n' ...
                'Both speed and accuracy are equally important.\n\n\n' ...
                'Press space to continue.'];
            exp.word = 'test';
            
            % Keys
            fprintf('pres.m (pres): Defining key press identifiers...\n');
            KbName('UnifyKeyNames');
            keys.esckey = KbName('Escape');
            keys.spacekey = KbName('SPACE');
            keys.mkey = KbName('m');     
            exp.keys = keys;
            
            fprintf('main.m (expset): Storing experimental properties.\n');
            obj.exp = exp;
            
        end     
        
        function addl(obj,src)
            obj.exp.lh = addlistener(src,'temp_t','PostSet',@(src,evt)tset(obj,src,evt));
        end
        
        function tset(obj,src,evt) % Corresponding to lh
            try
                obj.temp_t = evt.AffectedObject.temp_t;
            catch ME
                throw(ME);
            end
        end
        
        function stepup(obj)
            if obj.step < length(obj.exp.cond)
                obj.step = obj.step + 1;
            end
        end
        
        function stepdown(obj)
            if obj.step > 0
                obj.step = obj.step - 1;
            end
        end
        
        function stopcount(obj)
            if randi(100) > obj.exp.stopthresh
                if obj.stop~=obj.exp.stop_max
                    obj.stop = obj.stop + 1;
                else
                    obj.stop = 0;
                end
            else
                obj.stop = 0;
            end
        end
        
        function cycle(obj)
            
            if obj.stop
                t1 = obj.exp.cond(obj.step)/1000;
                disp(t1);
                dispred = 1;
            else
                t1 = obj.exp.dur1/1000;
                dispred = 0;
            end
            
            dur = t1 + (obj.exp.dur2/1000);
            
            obj.dat.word_color = obj.exp.green;
            notify(obj,'word');
            
            t0 = GetSecs;
            tic;
            
            while (GetSecs - t0) < dur
%                 tnow = str2double(regexp(num2str(toc),'[.]\d{1,3}','match','once')); % String conversion of time
                tnow = str2double(regexp(num2str(GetSecs - t0),'[.]\d{1,3}','match','once')); % String conversion of time
                [keyIsDown,secs,keyCode]=KbCheck; % Re-occuring check
                
                if tnow > t1
                   if dispred
%                        t = str2double(regexp(num2str(t1),'[.]\d{1,3}','match','once'));
                       if obj.stop
                           disp(tnow);
                           dispred = 0;
                           DrawFormattedText(obj.monitor.w,txt,'center','center',obj.exp.red)
                           obj.temp_t = Screen('Flip',src.monitor.w);
                           disp(obj.temp_t - t0);
                           disp(GetSecs - t0);
                       end
                   end
                end
                
            end
            
            notify(obj,'fix');
            randsample(obj.exp.fixdur,1)/1000;
        end
        
        function stoproutine(obj)
            dur = obj.exp.cond(obj.step)/1000;
            DrawFormattedText(obj.monitor.w,obj.exp.word,'center','center',obj.exp.green);
            t1 = Screen('Flip',obj.monitor.w);
            DrawFormattedText(obj.monitor.w,obj.exp.word,'center','center',obj.exp.red);
            temp_t = Screen('Flip',obj.monitor.w,(t1+dur));
            disp(temp_t-t1);
            WaitSecs(obj.exp.dur2/1000);
            notify(obj,'fix');       
        end
    end
    
end

