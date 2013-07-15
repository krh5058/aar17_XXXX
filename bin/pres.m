classdef pres < handle
    % pres.m class for ecig.m
    % See dated ReadMe file
    
    properties
        txt
        word_color
        misc
        lh
    end
    
    properties (SetObservable)
        temp_t
    end
    
    methods
        function obj = pres(src)
                        
            % Function handles
            fprintf('pres.m (pres): Defining presentation function handles...\n');
            misc.fix1 = @(monitor)(Screen('DrawLine',monitor.w,monitor.black,monitor.center_W-20,monitor.center_H,monitor.center_W+20,monitor.center_H,7));
            misc.fix2 = @(monitor)(Screen('DrawLine',monitor.w,monitor.black,monitor.center_W,monitor.center_H-20,monitor.center_W,monitor.center_H+20,7));
            misc.text = @(monitor,txt,color)(DrawFormattedText(monitor.w,txt,'center','center',color));
            
            % Listeners
            fprintf('pres.m (pres): Defining listener function handles...\n');
            lh.lh1 = addlistener(src,'fix',@(src,evt)dispfix(obj,src,evt));
            lh.lh3 = addlistener(src,'txt',@(src,evt)disptxt(obj,src,evt));
            lh.lh4 = addlistener(src,'dat','PostSet',@(src,evt)propset(obj,src,evt));
            
            fprintf('pres.m (pres): Storing object properties...\n');
            obj.misc = misc;
            obj.lh = lh;
            
            fprintf('pres.m (pres): Success!\n');
        end
        
        function [t] = dispfix(obj,src,evt) % Corresponding to lh1
            obj.misc.fix1(src.monitor);
            obj.misc.fix2(src.monitor);
            t = Screen('Flip',src.monitor.w);
        end
        
        function [t] = disptxt(obj,src,evt) % Corresponding to lh3
            obj.misc.text(src.monitor,obj.txt,src.monitor.black);
            t = Screen('Flip',src.monitor.w);
        end
        
        function propset(obj,src,evt) % Corresponding to lh4
            try
                f = fieldnames(evt.AffectedObject.dat);
                for i = 1:length(f)
                    obj.(f{i}) = evt.AffectedObject.dat.(f{i});
                end
            catch ME 
                throw(ME);
            end
        end
    end
    
end

