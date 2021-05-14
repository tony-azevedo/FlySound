classdef EpiOrLEDRig < ControlRig
    
    properties (Constant,Abstract)
        rigName
        IsContinuous;
    end
    
    properties (Constant)
    end
    
    properties (Hidden, SetAccess = protected)
        ardout_col
    end
    
    properties (SetAccess = protected)
    end
    
    events
        %InsufficientFunds, notify(BA,'InsufficientFunds')
    end
    
    methods
        function obj = EpiOrLEDRig(varargin)
            obj.addDevice('epi','LED_Arduino_Control')
            obj.addDevice('refchan','ReferenceChannelControl')
            obj.connectArduino;
            [ch,ad] = obj.getChannelNames;
            obj.ardout_col = find(strcmp(ch.in{~ad.in},'arduino_output'));
        end
        
        function obj = connectArduino(obj)
            addlistener(obj.devices.epi,'ControlFlag',@obj.setArduinoControl);
            addlistener(obj.devices.epi,'RoutineFlag',@obj.setArduinoControl);
            addlistener(obj.devices.epi,'BlueFlag',@obj.setArduinoControl);
            addlistener(obj.devices.epi,'Abort',@obj.turnOffEpi);
            addlistener(obj,'EndRun_Control',@obj.turnOffEpi);
            addlistener(obj,'EndTimer_Control',@obj.turnOffEpi);
        end
        
        function in = run(obj,protocol,varargin)
            
            if nargin>2
                repeats = varargin{1};
            else
                repeats = 1;
            end
            if isprop(obj,'TrialDisplay') && ~isempty(obj.TrialDisplay)
                if ishandle(obj.TrialDisplay)
                    delete(obj.TrialDisplay);
                end
            end
            obj.setDisplay([],[],protocol);
            obj.setTestDisplay();
            
            protocol.setParams('-q','samprateout',protocol.params.sampratein);
            obj.aoSession.Rate = protocol.params.samprateout;
            
            obj.setUpITITimer();
            [on_cntr, off_cntr] = obj.setUpWaitTimers();
            notify(obj,'StartRun_Control');
            
            for n = 1:repeats
                while protocol.hasNext()
                    
                    if obj.params.waitForLED
                        [on_cntr, off_cntr] = obj.handleTrialFailures(on_cntr,off_cntr);
                        if on_cntr<0
                            protocol.reset
                            return
                        end
                    end
                    
                    obj.setAOSession(protocol);
                    
                    % setup the data logger
                    notify(obj,'StartTrial_Control',PassProtocolData(protocol));
                    
                    in = obj.aoSession.startForeground; % both amp and signal monitor input
                    wait(obj.aoSession);
                    
                    % setup log data
                    % obj.transformInputs(in);
                    notify(obj,'EndTrial_Control');
                    
                    obj.itiWait()
                    
                    notify(obj,'SaveData_Control');
                    obj.displayTrial(protocol);
                    notify(obj,'DataSaved_Control');
                    notify(obj,'IncreaseTrialNum_Control');
                    obj.params.trialnum = obj.params.trialnum+1;
                    
                    % options for what to do if light is still on. Else,
                    % just leave the led on
                    if obj.params.turnoffLED
                        notify(obj,'EndTimer_Control')
                    elseif obj.params.waitForLED
                        LEDstate = in(end,obj.ardout_col);
                        if ~LEDstate && obj.devices.epi.params.blueToggle
                            on_cntr = 0;
                            off_cntr = off_cntr + 1;
                        elseif LEDstate
                            [on_cntr, off_cntr] = obj.waitForLEDOff(on_cntr,off_cntr);
                        end
                    end
                end
                protocol.reset;
            end
            fprintf(1,'Block complete.\n')
            notify(obj,'EndRun_Control');
            if obj.params.interTrialInterval >0
                t = timerfind('Name','ITItimer');
                delete(t)
            end
            if obj.params.waitForLED
                wflt = timerfind('Name','LEDTimeoutTimer');
                delete(wflt)
            end
        end
        
        function turnOffEpi(obj,callingobj,evntdata,varargin)
            % Now set the abort channel on briefly before turning it back
            % off
            
            output = obj.aoSession.UserData;
            if isempty(output)
                output = zeros(1,length(obj.outputchannelidx));
                
            else
                output = output.CurrentOutput;
                
            end
            output_a = output;
            for chidx = 1:length(obj.outputchannelidx)
                if contains(obj.aoSession.Channels(obj.outputchannelidx(chidx)).Name,'abort')
                    output_a(chidx) = 1;
                end
                if contains(obj.aoSession.Channels(obj.outputchannelidx(chidx)).Name,'epittl')
                    output_a(chidx) = 0;
                    output(chidx) = 0;
                end
            end
            obj.aoSession.outputSingleScan(output_a);
            obj.aoSession.outputSingleScan(output);
            
            fprintf(1,'LED Off\n')
        end
        
        function turnOnEpi(obj,callingobj,evntdata,varargin)
            % Now set epittl channel on
            
            output = obj.aoSession.UserData;
            if isempty(output)
                output = zeros(1,length(obj.outputchannelidx));
            else
                output = output.CurrentOutput;
            end
            output_a = output;
            for chidx = 1:length(obj.outputchannelidx)
                if contains(obj.aoSession.Channels(obj.outputchannelidx(chidx)).Name,'epittl')
                    output_a(chidx) = 1;
                end
            end
            obj.aoSession.outputSingleScan(output_a);
            obj.aoSession.outputSingleScan(output);
            fprintf(1,'LED On\n')
        end
        
        function setArduinoControl(obj,callingobj,evntdata,varargin)
            % Now set the control channel
            
            output = obj.aoSession.UserData;
            if isempty(output)
                output = zeros(1,length(obj.outputchannelidx));
            else
                output = output.CurrentOutput;
            end
            output_a = output;
            ardparams = callingobj.getParams;
            for chidx = 1:length(obj.outputchannelidx)
                if contains(obj.aoSession.Channels(obj.outputchannelidx(chidx)).Name,...
                        'control')
                    output_a(chidx) = ardparams.controlToggle;
                end
                if contains(obj.aoSession.Channels(obj.outputchannelidx(chidx)).Name,...
                        'routine')
                    output_a(chidx) = ardparams.routineToggle;
                end
                if contains(obj.aoSession.Channels(obj.outputchannelidx(chidx)).Name,...
                        'bluettl')
                    output_a(chidx) = ardparams.blueToggle;
                end
            end
            obj.aoSession.outputSingleScan(output_a);
            % obj.aoSession.outputSingleScan(output);
            obj.aoSession.UserData.CurrentOutput = output_a;
        end
        
        function setParams(obj,varargin)
            p = inputParser;
            p.PartialMatching = 0;
            names = fieldnames(obj.params);
            for i = 1:length(names)
                p.addParameter(names{i},obj.params.(names{i}),@(x) strcmp(class(x),class(obj.params.(names{i}))));
            end
            parse(p,varargin{:});
            results = fieldnames(p.Results);
            for r = 1:length(results)
                obj.params.(results{r}) = p.Results.(results{r});
            end
            if p.Results.waitForLED
                obj.params.turnoffLED = 0;
            elseif p.Results.turnoffLED
                obj.params.waitForLED = 0;
            end
        end
        
    end
    
    methods (Access = protected)
        
        function setUpITITimer(obj)
            % Start some timers
            if obj.params.interTrialInterval >0
                t = timerfind('Name','ITItimer');
                if isempty(t)
                    t = timer;
                end
                t.StartDelay = obj.params.interTrialInterval;
                t.TimerFcn = @(tObj, thisEvent) ...
                    fprintf('\t\t\t%.1f sec inter trial\n',tObj.StartDelay);
                set(t,'Name','ITItimer')
            end
        end
        
        function itiWait(obj)
            if obj.params.interTrialInterval >0
                t = timerfind('Name','ITItimer');
                start(t)
                wait(t)
                if obj.params.iTIInterval>0
                    %                   0 <= x <=iTIInterval
                    randdelay = round(((rand(1)-1/2)*2)*obj.params.iTIInterval*1000)/1000;
                    t.StartDelay = obj.params.interTrialInterval+randdelay;
                    t.StartDelay = max(0,t.StartDelay);
                end
            end
        end
        
        function [on_cntr, off_cntr] = setUpWaitTimers(obj)
            if obj.params.waitForLED
                wflt = timerfind('Name','LEDTimeoutTimer');
                if isempty(wflt)
                    wflt = timer;
                end
                wflt.StartDelay = .5;
                wflt.TimerFcn = @(tObj, thisEvent) ...
                    fprintf('.');
                set(wflt,'Name','LEDTimeoutTimer')
                
                % Counter for trials with no movement
                on_cntr = 0;
                % logical flag indicating fly moved after turning on blue
                % led
                off_cntr = 0;
            end
        end
        
        function [on_cntr, off_cntr] = handleTrialFailures(obj,on_cntr,off_cntr)
            if ~obj.devices.epi.params.blueToggle && on_cntr >= obj.params.blueOnCount
                % turn on the blue led
                obj.devices.epi.setParams('blueToggle',1)
                off_cntr = 0;
            end
            if obj.devices.epi.params.blueToggle && off_cntr >= obj.params.blueOffCount
                % turn off the blue led
                obj.devices.epi.setParams('blueToggle',0)
                on_cntr = 0;
            end
            if obj.params.waitForLED && on_cntr >= obj.params.enforcedRestCount
                % turn off the blue led, reset the protocol and
                % quit!
                obj.devices.epi.setParams('blueToggle',0)
                % protocol.reset;
                fprintf(1,'Failed trial threshold exceeded\n')
                notify(obj,'EndRun_Control');
                if obj.params.interTrialInterval >0
                    t = timerfind('Name','ITItimer');
                    delete(t)
                end
                if obj.params.waitForLED
                    wflt = timerfind('Name','LEDTimeoutTimer');
                    delete(wflt)
                end
                on_cntr = -1;
                return
            end
        end
        
        function [on_cntr,off_cntr] = waitForLEDOff(obj,on_cntr,off_cntr)
            elapsedtime = 0;
            wflt = timerfind('Name','LEDTimeoutTimer');
            fprintf(1,'Waiting: ')
            while elapsedtime<obj.params.LEDTimeout
                % timer goes for .5;
                start(wflt)
                wait(wflt)
                
                elapsedtime = elapsedtime+wflt.StartDelay;
                in = inputSingleScan(obj.aoSession);
                LEDstate = in(end,obj.ardout_col);
                if ~LEDstate
                    fprintf(1,'Fly turned LED off in %g s\n',elapsedtime)
                    on_cntr = 0;
                    if  obj.devices.epi.params.blueToggle
                        off_cntr = off_cntr + 1;
                    end
                    break
                end
            end
            if LEDstate
                fprintf(1,'Timeout reached.\n')
                notify(obj,'EndTimer_Control')
                on_cntr = on_cntr+1;
            end
        end
        
        function defineParameters(obj)
            % rmacqpref('defaultsLEDArduinoControlRig')
            % obj.params.sampratein = 10000;
            obj.params.samprateout = 50000;
            obj.params.testcurrentstepamp = -5;
            obj.params.testvoltagestepamp = -2.5;
            obj.params.teststep_start = 0.010;
            obj.params.teststep_dur = 0.050;
            obj.params.interTrialInterval = 0;
            obj.params.iTIInterval = 0;
            obj.params.trialnum = 0;
            obj.params.turnoffLED = 0;
            obj.params.waitForLED = 0;      % Logical, keeps LED on for extended time
            obj.params.LEDTimeout = 10;     % seconds to wait
            obj.params.blueOffCount = 4;    % failed trials before turning on blue LED
            obj.params.blueOnCount = 4;     % successful trials before turnin off blue LED (succes is moving and turnning off light)
            obj.params.enforcedRestCount = 10;   % number of failed trials before aborting
        end
        
    end
end
