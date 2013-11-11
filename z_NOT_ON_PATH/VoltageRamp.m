classdef VoltageRamp < FlySoundProtocol
    
    properties (Constant)
        protocolName = 'VoltageRamp';
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
        
        function obj = VoltageRamp(varargin)
            % In case more construction is needed
            obj = obj@FlySoundProtocol(varargin{:});
        end

        function varargout = generateStimulus(obj,varargin)
            stim = obj.stim/1000;  % mV, convert, this is the desired V injected
            stim = (stim - obj.dataBoilerPlate.daqout_to_voltage_offset)/obj.dataBoilerPlate.daqout_to_voltage; 
            varargout = {stim,obj.x};
        end
        
        function run(obj,varargin)
            trialdata = runtimeParameters(obj,varargin{:});
            if ~strcmp(readMode(),'VClamp')
                error('Not in current clamp (VClamp)');
            end
            obj.writePrologueNotes()

            obj.aiSession.Rate = trialdata.sampratein;
            obj.aiSession.DurationInSeconds = trialdata.durSweep;

            obj.aoSession.Rate = trialdata.samprateout;

            stim = nan(length(obj.generateStimulus()),length((obj.aoSession.Channels)));
            voltage = nan(size(obj.x));
            current = nan(size(obj.x));
            for repeat = 1:trialdata.repeats

                obj.writeTrialNotes();
                
                stim(:,1) = obj.generateStimulus();
                obj.aoSession.wait;

                obj.aoSession.queueOutputData(stim)                
                obj.aoSession.startBackground; % Start the session that receives start trigger first
                obj.y = obj.aiSession.startForeground; % both amp and signal monitor input
                if size(obj.y,1)~= length(obj.x)
                    obj.y = obj.y(2:1+length(obj.x),:);
                else
                    warning('***** vectors are same length!  aiSession produces variable input sizes')
                end
                current(:) = obj.y(:,1);
                voltage(:) = obj.y(:,3);
                
                % apply scaling factors
                current = (current-trialdata.scaledcurrentoffset)*trialdata.scaledcurrentscale;
                % Note: collecting hard voltage here, not scaled
                % current
                voltage = voltage*trialdata.hardvoltagescale - trialdata.hardvoltageoffset; % in V
                voltage = voltage*1000;
                
                obj.y(:,1) = current;
                obj.y(:,3) = voltage; % 'pA'

                obj.saveData(trialdata,current,voltage) % TODO: save signal monitor                
                obj.displayTrial()
            end
        end
                
        function displayTrial(obj)
            figure(1);
            ax1 = subplot(2,2,3);
            
            redlines = findobj(1,'Color',[1, 0, 0]);
            set(redlines,'color',[1 .8 .8]);
            bluelines = findobj(1,'Color',[0, 0, 1]);
            set(bluelines,'color',[.8 .8 1]);
            greylines = findobj(1,'Color',[.6 .6 .6]);
            set(greylines,'color',[.8 .8 .8]);
            pinklines = findobj(1,'Color',[.5 1 1]);
            set(pinklines,'color',[.8 .8 .8]);

            line(obj.x,obj.y(:,1),'parent',ax1,'color',[1 0 0],'linewidth',1);
            box off; set(gca,'TickDir','out');
            xlabel('Time (s)'); %xlim([0 max(t)]);
            ylabel('pA'); %xlim([0 max(t)]);
            
            ax2 = subplot(2,2,1);
            line(obj.x,obj.y(:,3),'parent',ax2,'color',[.6 .6 .6],'linewidth',1);
            line(obj.stimx,obj.stim,'parent',ax2,'color',[.5 1 1],'linewidth',1);
            box off; set(gca,'TickDir','out');
            xlabel('Time (s)'); %xlim([0 max(t)]);
            ylabel('V (mV)'); %xlim([0 max(t)]);
            
            linearRegion = obj.x > .05 & obj.x < obj.params.stimDurInSec-0.05; % stim window without the 50 ms on either end 
            
            % calculate seal resistance (mV/pA = GOhm)
            ax3 = subplot(2,2,4);
            p = polyfit(obj.y(linearRegion,3),obj.y(linearRegion,1),1);
            line(obj.y(linearRegion,3),obj.y(linearRegion,1),'parent',ax3,'color',[1 0 0],'linewidth',1);
            line(obj.y(linearRegion,3),p(1)*obj.y(linearRegion,3)+p(2),'parent',ax3,'color',[0 0 1],'linewidth',1);
            xlabel('V (mV)'); ylabel('pA'); 
            %     fitFn = p(1).*([1:length(rampSamps)]./data(n).sampratein) + p(2);
            %     subplot(2,4,[3 4 7 8]); plot(fitFn,'r','linewidth',2);
            sealRes = 1/p(1);   % seal resistance = 1/slope
            disp(['seal resistance = ',num2str(sealRes),' gigaohms']);
                        
        end

    end % methods
    
    methods (Access = protected)
                        
        function createAIAOSessions(obj)
            % configureAIAO is to start an acquisition routine
            
            obj.aiSession = daq.createSession('ni');
            obj.aiSession.addAnalogInputChannel('Dev1',0, 'Voltage'); % from amp
            obj.aiSession.addAnalogInputChannel('Dev1',3, 'Voltage'); % from amp
            obj.aiSession.addAnalogInputChannel('Dev1',4, 'Voltage'); % Voltage
            
            % configure AO
            obj.aoSession = daq.createSession('ni');
            obj.aoSession.addAnalogOutputChannel('Dev1',0, 'Voltage'); % Output channel
            
            obj.aiSession.addTriggerConnection('Dev1/PFI0','External','StartTrigger');
            obj.aoSession.addTriggerConnection('External','Dev1/PFI2','StartTrigger');
        end

        function createDataStructBoilerPlate(obj)
            % TODO, make this a map.Container array, so you can add
            % whatever keys you want.  Or cell array of maps?  Or a java
            % hashmap?            
            createDataStructBoilerPlate@FlySoundProtocol(obj);
        end
        
        function defineParameters(obj)
            obj.params.sampratein = 50000;
            obj.params.samprateout = 10000;
            obj.params.vstart = -5; %mV;
            obj.params.vstop = 5; %mV
            obj.params.stimDurInSec = 3;
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
            
            stim = (1:obj.params.samprateout*(obj.params.preDurInSec+obj.params.stimDurInSec+obj.params.postDurInSec));
            stim = stim(:);
            stim(:) = 0;
            
            stimpnts = obj.params.samprateout*obj.params.preDurInSec+1:...
                obj.params.samprateout*(obj.params.preDurInSec+obj.params.stimDurInSec);
                                    
            stim(stimpnts) = (1:1:(length(stimpnts)))/(length(stimpnts)) * ...
                (obj.params.vstop - obj.params.vstart) + obj.params.vstart;

            obj.stim = stim;            
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