classdef CurrentSteps < FlySoundProtocol
    
    properties (Constant)
        protocolName = 'CurrentSteps';
    end
    
    properties (Hidden)
    end
    
    % The following properties can be set only by class methods
    properties (SetAccess = private)
    end
    
    events
        %InsufficientFunds, notify(BA,'InsufficientFunds')
    end
    
    methods
        
        function obj = CurrentSteps(varargin)
            % In case more construction is needed
            obj = obj@FlySoundProtocol(varargin{:});
        end
        
        function varargout = generateStimulus(obj,varargin)
            if nargin>1
                nA = varargin{1};
            else
                nA = obj.params.step;
            end
            nA = nA/1000; % steps in pA
            DAQ_out_voltage = nA/(obj.dataBoilerPlate.iclampextcontrolfactor/obj.dataBoilerPlate.vdividerfactor); %nA / [nA/V] / [Vout/Vin] = Vin
            trialstim = obj.stim * DAQ_out_voltage ; 
            % dbp.vdivideroffset = 0.00292; % offest for the ext command.
            
            varargout = {trialstim,obj.stimx};
        end
        
        function run(obj,varargin)
            % Runtime routine for the protocol. obj.run(numRepeats)
            % preassign space in data for all the trialdata structs
            trialdata = runtimeParameters(obj,varargin{:});
            if ~strcmp(readMode(),'IClamp')
                error('Not in current clamp (IClamp)');
            end
            
            obj.aiSession.Rate = trialdata.sampratein;
            obj.aiSession.DurationInSeconds = trialdata.durSweep;

            obj.aoSession.Rate = trialdata.samprateout;

            trialstim = nan(length(obj.generateStimulus()),length((obj.aoSession.Channels)));

            for repeat = 1:trialdata.repeats
                for vi = 1:length(obj.params.steps)
                    fprintf('Trial %d\n',obj.n);
                    obj.params.step = obj.params.steps(vi);
                    trialdata.step = obj.params.step;
                    trialstim(:,1) = obj.generateStimulus();
                    %stim(:,2) = obj.generateStimulus();
                    tic
                    obj.aoSession.wait;
                    obj.aoSession.queueOutputData(trialstim)
                    toc
                    obj.aoSession.startBackground; % Start the session that receives start trigger first
                    obj.y = obj.aiSession.startForeground; % 
                    
                    voltage = obj.y(:,1);
                    current = obj.y(:,2);
                    
                    % apply scaling factors
                    % current = (current-trialdata.currentoffset)*trialdata.currentscale;
                    current = current*trialdata.currentscale;
                    % voltage = voltage*trialdata.voltagescale-trialdata.voltageoffset;
                    voltage = voltage*trialdata.voltagescale;
                    
                    switch obj.recmode
                        case 'VClamp'
                            obj.y = current;
                            obj.y_units = 'pA';
                        case 'IClamp'
                            obj.y = voltage;
                            obj.y_units = 'mV';
                    end
                    
                    obj.saveData(trialdata,current,voltage) % TODO: save signal monitor
                    
                    obj.displayTrial()
                end
                % obj.displayFamily()
            end
        end
                
        function displayTrial(obj)
            figure(1);
            ax1 = subplot(4,1,[2 3 4]);
            
            redlines = findobj(1,'Color',[1, 0, 0]);
            set(redlines,'color',[1 .8 .8]);
            bluelines = findobj(1,'Color',[0, 0, 1]);
            set(bluelines,'color',[.8 .8 1]);

            %line(obj.stimx,obj.generateStimulus,'parent',ax1,'color',[0 0 1],'linewidth',1);
            line(obj.x,obj.y(1:length(obj.x),1),'parent',ax1,'color',[1 0 0],'linewidth',1);
            box off; set(gca,'TickDir','out');
            switch obj.recmode
                case 'VClamp'
                    ylabel('I (pA)'); %xlim([0 max(t)]);
                case 'IClamp'
                    ylabel('V_m (mV)'); %xlim([0 max(t)]);
            end
            xlabel('Time (s)'); %xlim([0 max(t)]);
            
            ax2 = subplot(4,1,1);
            line(obj.stimx,obj.generateStimulus,'parent',ax2,'color',[.7 .7 .7],'linewidth',1);
            %line(obj.x,obj.sensorMonitor,'parent',ax2,'color',[0 0 1],'linewidth',1);
            box off; set(gca,'TickDir','out');

        end

    end % methods
    
    methods (Access = protected)
                        
        function createAIAOSessions(obj)
            % configureAIAO is to start an acquisition routine
            
            obj.aiSession = daq.createSession('ni');
            obj.aiSession.addAnalogInputChannel('Dev1',0, 'Voltage'); % from amp
            obj.aiSession.addAnalogInputChannel('Dev1',3, 'Voltage'); % from amp
            
            % configure AO
            obj.aoSession = daq.createSession('ni');
            obj.aoSession.addAnalogOutputChannel('Dev1',0, 'Voltage');
            
            obj.aiSession.addTriggerConnection('Dev1/PFI0','External','StartTrigger');
            obj.aoSession.addTriggerConnection('External','Dev1/PFI2','StartTrigger');
        end

        function createDataStructBoilerPlate(obj)
            % TODO, make this a map.Container array, so you can add
            % whatever keys you want.  Or cell array of maps?  Or a java
            % hashmap?            
            createDataStructBoilerPlate@FlySoundProtocol(obj);
            obj.dataBoilerPlate.displFactor = 20/30; %V/um
        end
        
        function defineParameters(obj)
            obj.params.sampratein = 10000;
            obj.params.samprateout = 10000;
            obj.params.Vm_id = 0;
            
            obj.params.steps = [-30 -20 -10 0 10 20 30];
            obj.params.step = obj.params.steps(1);
            
            obj.params.stimDurInSec = 0.5;
            obj.params.preDurInSec = .5;
            obj.params.postDurInSec = .5;
            obj.params.durSweep = obj.params.stimDurInSec+obj.params.preDurInSec+obj.params.postDurInSec;
            obj.params = obj.getDefaults;

        end
        
        function setupStimulus(obj,varargin)
            obj.params.durSweep = obj.params.stimDurInSec+obj.params.preDurInSec+obj.params.postDurInSec;
            obj.stimx = ((1:obj.params.samprateout*(obj.params.preDurInSec+obj.params.stimDurInSec+obj.params.postDurInSec))-obj.params.preDurInSec*obj.params.samprateout)/obj.params.samprateout;
            obj.stim = zeros(size(obj.stimx));
            obj.stim(obj.params.sampratein*(obj.params.preDurInSec)+1: obj.params.sampratein*(obj.params.preDurInSec+obj.params.stimDurInSec)) = 1;
            obj.x = ((1:obj.params.sampratein*(obj.params.preDurInSec+obj.params.stimDurInSec+obj.params.postDurInSec))-obj.params.preDurInSec*obj.params.samprateout)/obj.params.sampratein;
            obj.y = obj.x;
        end
        
        function stim_mat = generateStimFamily(obj)
            for paramsToVary = obj.params
                stim_mat = generateStimulus;
            end
        end
        
    end % protected methods
    
    methods (Static)
    end
end % classdef