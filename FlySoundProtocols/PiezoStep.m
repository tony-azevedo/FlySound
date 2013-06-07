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
            obj = obj@FlySoundProtocol(varargin{:});
        end

        function varargout = generateStimulus(obj,varargin)
            trialstim = obj.stim* obj.params.displacement;%*obj.dataBoilerPlate.displFactor;
            varargout = {trialstim,obj.stimx};
        end
        
        function run(obj,varargin)
            trialdata = runtimeParameters(obj,varargin{:});
            obj.writePrologueNotes()

            obj.aiSession.Rate = trialdata.sampratein;
            obj.aiSession.DurationInSeconds = trialdata.durSweep;

            obj.aoSession.Rate = trialdata.samprateout;

            obj.x_units = 's';
            
            for repeat = 1:trialdata.repeats
                tic
                obj.writeTrialNotes('displacement');
                
                stim = obj.generateStimulus();
                obj.aoSession.wait;
                obj.aoSession.queueOutputData(stim)
                obj.aoSession.startBackground; % Start the session that receives start trigger first
                obj.y = obj.aiSession.startForeground; % both amp and signal monitor input
                if size(obj.y,1)~= length(obj.x)
                    obj.y = obj.y(2:1+length(obj.x),:);
                else
                    warning('***** vectors are same length!  aiSession produces variable input sizes')
                end
                
                voltage = obj.y(:,1);
                current = obj.y(:,2);
                obj.sensorMonitor = obj.y(:,3);
                
                % apply scaling factors
                voltage = (voltage-trialdata.scaledvoltageoffset)*trialdata.scaledvoltagescale;
                % Note: collecting hard current here, not scaled
                % current
                current = current/trialdata.hardcurrentscale+trialdata.daqCurrentOffset; % in nA
                current = current*1000;
                                
                obj.y(:,1) = voltage;
                obj.y(:,2) = current;
                obj.y(:,3) = obj.sensorMonitor;
                obj.y_units = 'mV';
                
                obj.saveData(trialdata,current,voltage,'sgsmonitor',obj.sensorMonitor) % TODO: save signal monitor
                
                obj.displayTrial()
                toc
            end
        end
                
        function displayTrial(obj)
            figure(1);
            ax1 = subplot(4,1,[1 2 3]);
            
            redlines = findobj(1,'Color',[1, 0, 0]);
            set(redlines,'color',[1 .8 .8]);
            line(obj.x,obj.y(1:length(obj.x),1),'parent',ax1,'color',[1 0 0],'linewidth',1);
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
            y = obj.generateStimulus;
            line(obj.stimx,y(1:length(obj.stimx)),'parent',ax2,'color',[.7 .7 .7],'linewidth',1);
            line(obj.x,obj.sensorMonitor(1:length(obj.x)),'parent',ax2,'color',[0 0 1],'linewidth',1);
            box off; set(gca,'TickDir','out');

        end

    end % methods
    
    methods (Access = protected)
                        
        function createAIAOSessions(obj)
            % configureAIAO is to start an acquisition routine
            
            obj.aiSession = daq.createSession('ni');
            obj.aiSession.addAnalogInputChannel('Dev1',0, 'Voltage'); % from amp
            obj.aiSession.addAnalogInputChannel('Dev1',3, 'Voltage'); % from amp
            obj.aiSession.addAnalogInputChannel('Dev1',5, 'Voltage'); % PZT Sensor monitor
            
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
            obj.params.sampratein = 10000;
            obj.params.samprateout = 10000;
            obj.params.displacement = 1;
            obj.params.stimDurInSec = .5;
            obj.params.preDurInSec = .5;
            obj.params.postDurInSec = .5;
            obj.params.durSweep = obj.params.stimDurInSec+obj.params.preDurInSec+obj.params.postDurInSec;

            obj.params.Vm_id = 0;

            obj.params = obj.getDefaults;
        end
        
        function setupStimulus(obj,varargin)
            obj.params.durSweep = obj.params.stimDurInSec+obj.params.preDurInSec+obj.params.postDurInSec;
            obj.stimx = ((1:obj.params.samprateout*(obj.params.preDurInSec+obj.params.stimDurInSec+obj.params.postDurInSec))-obj.params.preDurInSec*obj.params.samprateout)/obj.params.samprateout;
            obj.stimx = obj.stimx(:);
            obj.stim = zeros(size(obj.stimx));
            obj.stim(obj.params.samprateout*(obj.params.preDurInSec)+1: obj.params.samprateout*(obj.params.preDurInSec+obj.params.stimDurInSec)) = 1;
            obj.x = ((1:obj.params.sampratein*(obj.params.preDurInSec+obj.params.stimDurInSec+obj.params.postDurInSec))-obj.params.preDurInSec*obj.params.sampratein)/obj.params.sampratein;
            obj.x = obj.x(:);
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