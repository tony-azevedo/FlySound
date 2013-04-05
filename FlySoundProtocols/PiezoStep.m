classdef PiezoStep < FlySoundProtocol
    
    properties (Constant)
        protocolName = 'PiezoStep';
    end
    
    properties (Hidden)
        sensorMonitor
    end
    
    % The following properties can be set only by class methods
    properties (SetAccess = private)
    end
    
    events
        %InsufficientFunds, notify(BA,'InsufficientFunds')
    end
    
    methods
        
        function obj = PiezoStep(varargin)
            % In case more construction is needed
            % obj = obj@FlySoundProtocol(varargin);
        end

        function stim = generateStimulus(obj,varargin)
            global globalPiezoStepStimulus
            
            if isempty(globalPiezoStepStimulus) ||...
                    length(globalPiezoStepStimulus) ~= obj.params.samprateout*(obj.params.preDurInSec+obj.params.stepDurInSec+obj.params.postDurInSec) ||...
                    sum(globalPiezoStepStimulus)~= obj.params.samprateout*obj.params.stepDurInSec;
            
                globalPiezoStepStimulus = (1:obj.params.samprateout*(obj.params.preDurInSec+obj.params.stepDurInSec+obj.params.postDurInSec));
                globalPiezoStepStimulus = globalPiezoStepStimulus(:);
                globalPiezoStepStimulus(:) = 0;
                globalPiezoStepStimulus(...
                    obj.params.samprateout*obj.params.preDurInSec+1:...
                    obj.params.samprateout*(obj.params.preDurInSec+obj.params.stepDurInSec)) = 1;
            end
            stim = globalPiezoStepStimulus* obj.params.displacement;%*obj.dataBoilerPlate.displFactor;
        end
        
        function run(obj,varargin)
            % Runtime routine for the protocol. obj.run(numRepeats)
            % preassign space in data for all the trialdata structs
            p = inputParser;
            addOptional(p,'repeats',1);
            addOptional(p,'vm_id',obj.params.Vm_id);
            parse(p,varargin{:});
            
            % stim_mat = generateStimFamily(obj);
            trialdata = appendStructure(obj.dataBoilerPlate,obj.params);
            trialdata.Vm_id = p.Results.vm_id;
            
            obj.aiSession.Rate = trialdata.sampratein;
            obj.aiSession.DurationInSeconds = trialdata.durSweep;

            obj.aoSession.Rate = trialdata.samprateout;

            obj.x = ((1:obj.aiSession.Rate*obj.aiSession.DurationInSeconds) - 1)/obj.aiSession.Rate;
            obj.x_units = 's';
            
            for repeat = 1:p.Results.repeats

                fprintf('Trial %d\n',obj.n);
                
                obj.aoSession.queueOutputData(obj.generateStimulus())                
                obj.aoSession.startBackground; % Start the session that receives start trigger first
                obj.y = obj.aiSession.startForeground; % both amp and signal monitor input
                
                voltage = obj.y(:,1);
                current = obj.y(:,1);
                obj.sensorMonitor = obj.y(:,2);
                
                % apply scaling factors
                current = (current-trialdata.currentoffset)*trialdata.currentscale;
                voltage = voltage*trialdata.voltagescale-trialdata.voltageoffset;
                
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
        end
                
        function displayTrial(obj)
            figure(1);
            ax1 = subplot(4,1,[1 2 3]);
            
            redlines = findobj(1,'Color',[1, 0, 0]);
            set(redlines,'color',[1 .8 .8]);
            line(obj.x,obj.y(:,2),'parent',ax1,'color',[1 0 0],'linewidth',1);
            box off; set(gca,'TickDir','out');
            switch obj.recmode
                case 'VClamp'
                    ylabel('I (pA)'); %xlim([0 max(t)]);
                case 'IClamp'
                    ylabel('V_m (mV)'); %xlim([0 max(t)]);
            end
            xlabel('Time (s)'); %xlim([0 max(t)]);
            
            ax2 = subplot(4,1,4);
            bluelines = findobj(1,'Color',[0, 0, 1]);
            set(bluelines,'color',[.8 .8 1]);
            line(obj.x,obj.generateStimulus,'parent',ax2,'color',[.7 .7 .7],'linewidth',1);
            %line(obj.x,obj.sensorMonitor,'parent',ax2,'color',[0 0 1],'linewidth',1);
            box off; set(gca,'TickDir','out');

        end

    end % methods
    
    methods (Access = protected)
                        
        function createAIAOSessions(obj)
            % configureAIAO is to start an acquisition routine
            
            obj.aiSession = daq.createSession('ni');
            obj.aiSession.addAnalogInputChannel('Dev1',0, 'Voltage'); % from amp
            obj.aiSession.addAnalogInputChannel('Dev1',3, 'Voltage'); % PZT Sensor monitor
            
            % configure AO
            obj.aoSession = daq.createSession('ni');
            obj.aoSession.addAnalogOutputChannel('Dev1',2, 'Voltage');
            
            obj.aiSession.addTriggerConnection('Dev1/PFI0','External','StartTrigger');
            obj.aoSession.addTriggerConnection('External','Dev1/PFI2','StartTrigger');
        end

        function createDataStructBoilerPlate(obj)
            % TODO, make this a map.Container array, so you can add
            % whatever keys you want.  Or cell array of maps?  Or a java
            % hashmap?            
            createDataStructBoilerPlate@FlySoundProtocol(obj);
            obj.dataBoilerPlate.displFactor = 10/30; %V/um
        end
        
        function defineParameters(obj)
            defineParameters@FlySoundProtocol(obj);
            obj.params.sampratein = 10000;
            obj.params.samprateout = 10000;
            obj.params.displacement = 1;
            obj.params.stepDurInSec = .5;
            obj.params.preDurInSec = .5;
            obj.params.postDurInSec = .5;
            obj.params.durSweep = obj.params.stepDurInSec+obj.params.preDurInSec+obj.params.postDurInSec;

            obj.params.Vm_id = 0;

            obj.setDefaults;
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