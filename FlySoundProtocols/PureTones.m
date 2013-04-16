classdef PureTones < FlySoundProtocol
    
    properties (Constant)
        protocolName = 'PureTones';
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
        
        function obj = PureTones(varargin)
            % In case more construction is needed
            obj = obj@FlySoundProtocol(varargin{:});
        end
        
        function varargout = generateStimulus(obj,varargin)
            if nargin>1
                tone = varargin{1};
            else
                tone = obj.params.tone;
            end
            trialstim = obj.params.amplitude * obj.stim .* sin(tone*2*pi*obj.stimx);
            % dbp.vdivideroffset = 0.00292; % offest for the ext command.
            
            varargout = {trialstim,obj.stimx};
        end
        
        function run(obj,varargin)
            % Runtime routine for the protocol. obj.run(numRepeats)
            % preassign space in data for all the trialdata structs
            trialdata = runtimeParameters(obj,varargin{:});
            
            obj.aiSession.Rate = trialdata.sampratein;
            obj.aiSession.DurationInSeconds = trialdata.durSweep;

            obj.aoSession.Rate = trialdata.samprateout;

            trialstim = nan(length(obj.generateStimulus()),length((obj.aoSession.Channels)));

            for repeat = 1:trialdata.repeats
                for vi = 1:length(obj.params.tones)
                    fprintf('Trial %d\n',obj.n);
                    obj.params.tone = obj.params.tones(vi);
                    trialdata.tone = obj.params.tone;
                    trialstim(:,1) = obj.generateStimulus();
                    %trialstim(:,2) = obj.generateStimulus();
                    tic
                    obj.aoSession.wait;
                    obj.aoSession.queueOutputData(trialstim)
                    toc
                    obj.aoSession.startBackground; % Start the session that receives start trigger first
                    obj.y = obj.aiSession.startForeground; % 
                    
                    voltage = obj.y(:,1);
                    current = obj.y(:,1);
                    
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
            ax1 = subplot(3,1,[1 2]);
            cla(ax1)
            %line(obj.stimx,obj.generateStimulus,'parent',ax1,'color',[0 0 1],'linewidth',1);
            line(obj.x,obj.y(:,1),'parent',ax1,'color',[1 0 0],'linewidth',1);
            box off; set(gca,'TickDir','out');
            
            switch obj.recmode
                case 'VClamp'
                    ylabel('I (pA)'); %xlim([0 max(t)]);
                case 'IClamp'
                    ylabel('V_m (mV)'); %xlim([0 max(t)]);
            end
            xlabel('Time (s)'); %xlim([0 max(t)]);
            
            ax2 = subplot(3,1,3);
            cla(ax2)
            line(obj.stimx,obj.generateStimulus,'parent',ax2,'color',[.7 .7 .7],'linewidth',1);
            %line(obj.x,obj.sensorMonitor,'parent',ax2,'color',[0 0 1],'linewidth',1);
            box off; set(gca,'TickDir','out');
            
            figure(2);
            currtone = find(obj.params.tones==obj.params.tone);
            ax1 = subplot(2,length(obj.params.tones),currtone);
            
            redlines = findobj(2,'Color',[1, 0, 0]);
            set(redlines,'color',[1 .8 .8]);
            bluelines = findobj(2,'Color',[0, 0, 1]);
            set(bluelines,'color',[.8 .8 1]);

            %line(obj.stimx,obj.generateStimulus,'parent',ax1,'color',[0 0 1],'linewidth',1);
            line(obj.x,obj.y(:,1),'parent',ax1,'color',[1 0 0],'linewidth',1);
            box off; set(gca,'TickDir','out');axis tight
            
            switch obj.recmode
                case 'VClamp'
                    ylabel('I (pA)'); %xlim([0 max(t)]);
                case 'IClamp'
                    ylabel('V_m (mV)'); %xlim([0 max(t)]);
            end
            xlabel('Time (s)'); %xlim([0 max(t)]);
            
            ax2 = subplot(2,length(obj.params.tones),length(obj.params.tones)+currtone);
            line(obj.stimx,obj.generateStimulus,'parent',ax2,'color',[.7 .7 .7],'linewidth',1);
            %line(obj.x,obj.sensorMonitor,'parent',ax2,'color',[0 0 1],'linewidth',1);
            box off; set(gca,'TickDir','out');axis tight

        end

    end % methods
    
    methods (Access = protected)
                        
        function createAIAOSessions(obj)
            % configureAIAO is to start an acquisition routine
            
            obj.aiSession = daq.createSession('ni');
            obj.aiSession.addAnalogInputChannel('Dev1',0, 'Voltage'); % from amp
            
            % configure AO
            obj.aoSession = daq.createSession('ni');
            obj.aoSession.addAnalogOutputChannel('Dev1',1, 'Voltage');
            
            obj.aiSession.addTriggerConnection('Dev1/PFI0','External','StartTrigger');
            obj.aoSession.addTriggerConnection('External','Dev1/PFI2','StartTrigger');
        end

        function createDataStructBoilerPlate(obj)
            % TODO, make this a map.Container array, so you can add
            % whatever keys you want.  Or cell array of maps?  Or a java
            % hashmap?            
            createDataStructBoilerPlate@FlySoundProtocol(obj);
            % obj.dataBoilerPlate.displFactor = 20/30; %V/um
        end
        
        function defineParameters(obj)
            obj.params.sampratein = 10000;
            obj.params.samprateout = 40000;
            obj.params.Vm_id = 0;
            
            obj.params.tones = [64 128 256 512 1024 2048];
            obj.params.tone = obj.params.tones(1);

            obj.params.amplitude = 1;
            
            obj.params.stimDurInSec = 2;
            obj.params.preDurInSec = 0.5;
            obj.params.postDurInSec = 0.5;
            obj.params.durSweep = obj.params.stimDurInSec+obj.params.preDurInSec+obj.params.postDurInSec;
            obj.params = obj.getDefaults;

        end
        
        function setupStimulus(obj,varargin)
            ramp = 0.02;
            obj.params.durSweep = obj.params.stimDurInSec+obj.params.preDurInSec+obj.params.postDurInSec;
            obj.stimx = ((1:obj.params.samprateout*(obj.params.preDurInSec+obj.params.stimDurInSec+obj.params.postDurInSec))-obj.params.preDurInSec*obj.params.samprateout)/obj.params.samprateout;
            obj.stim = zeros(size(obj.stimx));
            obj.stim(obj.params.samprateout*(obj.params.preDurInSec)+1: obj.params.samprateout*(obj.params.preDurInSec+obj.params.stimDurInSec)) = 1;
            obj.stim(obj.params.samprateout*(obj.params.preDurInSec):round(obj.params.samprateout*(obj.params.preDurInSec + ramp))) = (0:obj.params.samprateout*ramp)/(obj.params.samprateout*ramp);
            obj.stim(round(obj.params.samprateout*(obj.params.preDurInSec+obj.params.stimDurInSec - ramp)):obj.params.samprateout*(obj.params.preDurInSec+obj.params.stimDurInSec)) = fliplr(0:obj.params.samprateout*ramp)/(obj.params.samprateout*ramp);

            obj.x = ((1:obj.params.sampratein*(obj.params.preDurInSec+obj.params.stimDurInSec+obj.params.postDurInSec))-obj.params.preDurInSec*obj.params.sampratein)/obj.params.sampratein;
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