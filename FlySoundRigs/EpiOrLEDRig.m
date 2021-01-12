classdef EpiOrLEDRig < ControlRig
    
    properties (Constant,Abstract)
        rigName
        IsContinuous;
    end
    
    properties (Constant)
    end

    properties (Hidden, SetAccess = protected)
    end
    
    properties (SetAccess = protected)
    end
    
    events
        %InsufficientFunds, notify(BA,'InsufficientFunds')
    end
    
    methods
        function obj = EpiOrLEDRig(varargin)
            ...
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
            
            % Start some timers
            if obj.params.interTrialInterval >0
                t = timerfind('Name','ITItimer');
                if isempty(t)
                    t = timer;
                end
                t.StartDelay = obj.params.interTrialInterval;
                t.TimerFcn = @(tObj, thisEvent) ... 
                    fprintf('%.1f sec inter trial\n',tObj.StartDelay);
                set(t,'Name','ITItimer')
            end

            notify(obj,'StartRun_Control');
            if obj.params.scheduletimeout
                runtime = now;
                timeoutinterval = seconds(obj.params.timeoutinterval);
            end
            for n = 1:repeats
                while protocol.hasNext()
                    obj.setAOSession(protocol);
                    
                    % setup the data logger
                    notify(obj,'StartTrial_Control',PassProtocolData(protocol));
                    % start the videoinput object
                    % notify(obj,'StartTrialCamera');
                    
                    in = obj.aoSession.startForeground; % both amp and signal monitor input
                    wait(obj.aoSession);
                    notify(obj,'EndTrial_Control');
                    
                    % There could be a thing here to briefly look at the
                    % state of the led. This could trigger some control ove
                    % when timeouts happen or something
                    
                    % disp(obj.aiSession)
                    % obj.transformInputs(in);
                    if obj.params.interTrialInterval >0
                        t = timerfind('Name','ITItimer');
                        start(t)
                        wait(t)
                        if obj.params.iTIInterval>0
                            t.StartDelay = round((obj.params.interTrialInterval+((rand(1)-1/2)*2)*obj.params.iTIInterval)*1000)/1000;
                            t.StartDelay = max(0,t.StartDelay);
                        end
                    end
                    notify(obj,'SaveData_Control');
                    % obj.displayTrial(protocol);
                    notify(obj,'DataSaved_Control');
                    notify(obj,'IncreaseTrialNum_Control');
                    obj.params.trialnum = obj.params.trialnum+1;
                    if obj.params.scheduletimeout && now-runtime > timeoutinterval
                        notify(obj,'EndTimer_Control')
                        runtime = now;
                    elseif obj.params.turnoffLED
                        notify(obj,'EndTimer_Control')
                    end
                        
                end
                protocol.reset;
            end
            notify(obj,'EndRun_Control');
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
            end
            obj.aoSession.outputSingleScan(output_a);
            % obj.aoSession.outputSingleScan(output);
            obj.aoSession.UserData.CurrentOutput = output_a;
        end
    end
    
    methods (Access = protected)

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
            obj.params.scheduletimeout = 0;
            obj.params.timeoutinterval = 30;
            obj.params.turnoffLED = 0;
        end

    end
end
