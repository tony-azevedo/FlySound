classdef TriggeredPiezo_Control < Device
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
        stimshowax
    end
    
    properties 
        deviceName = 'TriggeredPiezo_Control';
    end
    
    properties (SetAccess = protected)
        daq
        triggerconnect
        stimulus
        stimshowfig
        normalizedstim
    end
    
    events
        
    end
    
    methods
        function obj = TriggeredPiezo_Control(varargin)
                        
            % goes to the arduino to trigger the initial piezo pulse
            obj.digitalOutputLabels = {'piezotrigger'};
            obj.digitalOutputUnits = {'Bit'};
            obj.digitalOutputPorts = [1];

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
            obj.daq = daq('ni');
            
            ch = obj.daq.addoutput(obj.trigDev,obj.triggeredOutputPort(1), 'Voltage');
            ch.Name = obj.triggeredOutputLabel{1};
            %obj.outputs.portlabels{obj.triggeredOutputPort(1)+1} = obj.triggeredOutputLabel{1};
            %obj.outputs.device{obj.triggeredOutputPort(1)+1} = obj;

            % obj.triggerconnect = obj.daq.addTriggerConnection('External',[obj.trigDev '/' obj.triggerPort],'StartTrigger');
            obj.triggerconnect = obj.daq.addtrigger("Digital","StartTrigger","External",[obj.trigDev '/' obj.triggerPort]);
            obj.daq.DigitalTriggerTimeout = Inf;
            obj.triggerconnect.Condition = 'FallingEdge';

            obj.setupDevice()
            obj.plotStimulus()
        end
        
        function in = transformInputs(obj,in,varargin)
        end
        
        function out = transformOutputs(obj,out,varargin)
        end
        
        function start(obj,in,varargin)
            obj.resetPiezo            
            obj.daq.NumDigitalTriggersPerRun = 2;
            obj.daq.start;
        end
        
        function resetPiezo(obj)
            obj.daq.stop;
            obj.daq.preload(obj.stimulus)
            obj.daq.ScansRequiredFcnCount = ceil(obj.daq.Rate/2);
        end

        function reloadPiezo(obj,src,event)
            obj.daq.preload(obj.stimulus)
        end
        
        function setStimulus(obj,stim)
            obj.stimulus = stim;
            obj.plotStimulus()
        end

        function plotStimulus(obj)
            cla(obj.stimshowax);
            plot(obj.stimshowax,obj.stimulus)
            obj.stimshowax.XLim = [1 length(obj.stimulus)];
            obj.stimshowax.YLim = [0 10];
            figure(obj.stimshowfig)
        end

        function stim = getStimulus(obj)
            stim = obj.stimulus;
        end
        
        function stop(obj,in,varargin)
            % fprintf(1,'TriggeredPiezo Running?: %d\n',obj.aoSession.IsRunning);
            % fprintf(1,'Remaining trigger: %d of %d\n',obj.aoSession.TriggersRemaining,obj.aoSession.TriggersPerRun);
            obj.daq.stop;
        end
        
        function setuplistener(obj,rig)
            addlistener(rig,'StartTrial',@obj.start)
            addlistener(rig,'DataSaved',@obj.stop)
        end
        
        function setDaq(obj,in,varargin)
            
        end

        function delete(obj)
            try
                close(obj.stimshowfig);
            catch e
                %disp(e)
            end
        end

        
    end
    
    methods (Access = protected)
        function setupDevice(obj)
            obj.daq.Rate = obj.params.samprateout;
            obj.daq.ScansRequiredFcnCount = ceil(obj.daq.Rate/2);
            obj.daq.ScansRequiredFcn = @obj.reloadPiezo;

            stimpnts = round(obj.params.samprateout*obj.params.cueStimDurInSec);
            
            ramp = round(obj.params.cueRampDurInSec*obj.params.samprateout);
            w = window(@triang,2*ramp);
            w = [w(1:ramp);...
                ones(stimpnts-length(w),1);...
                w(ramp+1:end)];
            
            obj.normalizedstim = [zeros(obj.params.samprateout*obj.params.posttriggerdelay,1); w; zeros(obj.params.samprateout*obj.params.posttriggerdelay,1)];
            obj.stimulus = obj.normalizedstim*obj.params.displacement+obj.params.displacementOffset;
            obj.stimshowfig = figure;
            obj.stimshowfig.Position = [1 238 560 229];
            obj.stimshowax = subplot(1,1,1,'parent',obj.stimshowfig);
        end
                
        function defineParameters(obj)
            % rmacqpref('defaultsTriggeredPiezo_Control')
            obj.params.sampratein = 50000;
            obj.params.samprateout = 50000;
            obj.params.cueStimDurInSec = .3;
            obj.params.cueRampDurInSec = .07;
            obj.params.posttriggerdelay = .05;
            obj.params.displacement = -5;
            obj.params.displacementOffset = 5;
        end
        
    end
end
