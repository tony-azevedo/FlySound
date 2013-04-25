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
                nA = varargin{1}/1000;
            else
                nA = obj.params.step/1000;
            end
            
            trialstim = obj.stim * nA;

            trialstim = (trialstim-obj.dataBoilerPlate.daqout_to_current_offset)/obj.dataBoilerPlate.daqout_to_current; 

            % subtract some voltage to remove the static current
            DAQ_V_to_subtract_static_current = obj.dataBoilerPlate.daqCurrentOffset/obj.dataBoilerPlate.daqout_to_current;
            trialstim = trialstim - DAQ_V_to_subtract_static_current; 
            
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
                    %hardvoltage = obj.y(:,3);
                    
                    % apply scaling factors
                    voltage = (voltage-trialdata.scaledvoltageoffset)*trialdata.scaledvoltagescale;
                    % Note: collecting hard current here, not scaled
                    % current
                    current = current/trialdata.hardcurrentscale+trialdata.daqCurrentOffset; % in nA
                    current = current*1000;
                    
                    obj.y(:,1) = voltage;
                    obj.y(:,2) = current; % 'pA'
                    obj.y_units = 'mV';
                    
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
            greylines = findobj(1,'Color',[.6 .6 .6]);
            set(greylines,'color',[.8 .8 .8]);
            pinklines = findobj(1,'Color',[.5 1 1]);
            set(pinklines,'color',[.8 .8 .8]);

            %line(obj.stimx,obj.generateStimulus,'parent',ax1,'color',[0 0 1],'linewidth',1);
            line(obj.x,obj.y(1:length(obj.x),1),'parent',ax1,'color',[1 0 0],'linewidth',1);
            box off; set(gca,'TickDir','out');
            ylabel('V_m (mV)'); %xlim([0 max(t)]);
            xlabel('Time (s)'); %xlim([0 max(t)]);
            
            ax2 = subplot(4,1,1);
            line(obj.stimx,obj.y(1:length(obj.x),2),'parent',ax2,'color',[.6 .6 .6],'linewidth',1);
            line(obj.stimx,obj.params.step*obj.stim,'parent',ax2,'color',[.5 1 1],'linewidth',1);
            %line(obj.x,obj.sensorMonitor,'parent',ax2,'color',[0 0 1],'linewidth',1);
            box off; set(gca,'TickDir','out');
            ylabel('I (pA)'); %xlim([0 max(t)]);

        end

    end % methods
    
    methods (Access = protected)
                        
        function createAIAOSessions(obj)
            % configureAIAO is to start an acquisition routine
            
            obj.aiSession = daq.createSession('ni');
            obj.aiSession.addAnalogInputChannel('Dev1',0, 'Voltage'); % scaled output
            obj.aiSession.addAnalogInputChannel('Dev1',3, 'Voltage'); % 100 beta mV/pA
            obj.aiSession.addAnalogInputChannel('Dev1',4, 'Voltage'); % 10 Vm
            
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