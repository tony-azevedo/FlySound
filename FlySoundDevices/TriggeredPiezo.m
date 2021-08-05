classdef TriggeredPiezo < Device
    % A triggered Piezo is model of a general device that is controlled by
    % the arduino, that is running it's own session on the DAQ in the 
    % background waiting for a trigger, and that sends an output while
    % running 
    
    properties (Constant)
    end
    
    properties (Hidden, SetAccess = protected)
        triggeredOutputLabel
        triggeredOutputUnit
        triggeredOutputPort
        triggerPort
        trigDev
    end
    
    properties 
        deviceName = 'TriggeredPiezo';
    end
    
    properties (SetAccess = protected)
        aoSession
        stimulus
    end
    
    events
        %InsufficientFunds, notify(BA,'InsufficientFunds')
    end
    
    methods
        function obj = TriggeredPiezo(varargin)
                        
            % goes to the arduino to trigger the initial piezo pulse
            obj.digitalOutputLabels = {'piezotrigger'};
            obj.digitalOutputUnits = {'bits'};
            obj.digitalOutputPorts = [23];
            
            % TriggeredPiezo device runs its own session off the DAC, loads
            % it's own data, waits for triggers, runs the stimulus and then
            % resets.
            obj.triggeredOutputLabel = {'piezo'};
            obj.triggeredOutputUnit = {'V'};
            obj.triggeredOutputPort = [0];
            
            % the rig can trigger the arduino and the arduino then uses
            % this port to trigger the TriggeredPiezo
            obj.triggerPort = ['PFI1'];
            
            obj.trigDev = getacqpref('AcquisitionHardware','triggeredDev');
            obj.aoSession = daq.createSession('ni');
            
            ch = obj.aoSession.addAnalogOutputChannel(obj.trigDev,obj.triggeredOutputPort(1), 'Voltage');
            ch.Name = obj.triggeredOutputLabel{1};
            %obj.outputs.portlabels{obj.triggeredOutputPort(1)+1} = obj.triggeredOutputLabel{1};
            %obj.outputs.device{obj.triggeredOutputPort(1)+1} = obj;

            tc = obj.aoSession.addTriggerConnection('External',[obj.trigDev '/' obj.triggerPort],'StartTrigger');
            obj.aoSession.ExternalTriggerTimeout = Inf;
            obj.aoSession.NotifyWhenScansQueuedBelow = 1000;
            % addlistener(obj.aoSession,'DataRequired', @obj.start);
            % addlistener(obj,'StartTrial',@obj.start)
            obj.setupDevice()
            
        end
        
        function in = transformInputs(obj,in,varargin)
        end
        
        function out = transformOutputs(obj,out,varargin)
        end
        
        function start(obj,in,varargin)
            %obj.aoSession.IsContinuous = true;
            %obj.aoSession.NotifyWhenDataAvailableExceeds = numel(obj.stimulus);
                %@(src,event) src.queueOutputData(obj.stimulus));
            obj.resetPiezo            
            startBackground(obj.aoSession);
        end
        
        function resetPiezo(obj)
            obj.aoSession.stop;
            obj.aoSession.queueOutputData(obj.stimulus)
        end
        
        function stop(obj,in,varargin)
            fprintf(1,'TriggeredPiezo stopped\n');
            fprintf(1,'Scans queued: %d \t Scans acquired: %d\n',obj.aoSession.ScansQueued,obj.aoSession.ScansAcquired);
            obj.aoSession.stop;
        end
        
        function setuplistener(obj,rig)
            addlistener(rig,'StartTrial',@obj.start)
            addlistener(rig,'DataSaved',@obj.stop)
        end
        
        function setSession(obj,in,varargin)
            
        end

    end
    
    methods (Access = protected)
        function setupDevice(obj)
            ramptime = abs(obj.params.displacement)/obj.params.speed;
            nstimpnts = round(obj.params.samprateout*obj.params.stimDurInSec);
            if ramptime*2>obj.params.stimDurInSec
                warning('Stimulus is too slow to get to displacement');
                ramp = round(obj.params.stimDurInSec*obj.params.samprateout/2);
                w = window(@triang,2*ramp);
            else
                ramp = round(ramptime*obj.params.samprateout);
                w = window(@triang,2*ramp);
                w = [w(1:ramp);...
                    ones(nstimpnts-length(w),1);...
                    w(ramp+1:end)];
            end
            
            obj.stimulus = w*obj.params.displacement+obj.params.displacementOffset;
            obj.aoSession.Rate = obj.params.samprateout;
        end
                
        function defineParameters(obj)
            obj.params.sampratein = 50000;
            obj.params.samprateout = 50000;
            obj.params.stimDurInSec = .5;
            obj.params.displacement = -10;
            obj.params.speed = 150;
            obj.params.displacementOffset = 10;

        end
    end
end
