classdef Sweep < FlySoundProtocol
    
    properties (Constant)
        protocolName = 'Sweep';
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
        
        function obj = Sweep(varargin)
            % In case more construction is needed
            obj = obj@FlySoundProtocol(varargin{:});
        end
        
        function stim = generateStimulus(obj,varargin)
            % no stimulus for a sweep
            stim = [];
        end
        
        function run(obj,varargin)
            % Runtime routine for the protocol. obj.run(numRepeats)
            % preassign space in data for all the trialdata structs
            trialdata = runtimeParameters(obj,varargin{:});
            obj.writePrologueNotes()
            
            obj.aiSession.Rate = trialdata.sampratein;
            obj.aiSession.DurationInSeconds = trialdata.durSweep;
            
            obj.x = ((1:obj.aiSession.Rate*obj.aiSession.DurationInSeconds) - 1)/obj.aiSession.Rate;
            obj.x_units = 's';
            
            for repeat = 1:trialdata.repeats

                obj.writeTrialNotes('durSweep');

                trialdata.trial = obj.n;

                obj.y = obj.aiSession.startForeground; %plot(x); drawnow
                current = obj.y(:,2);
                voltage = obj.y(:,3);
                
                % when do I multiply by 1000?
                % apply scaling factors 
                current = (current-trialdata.hardcurrentoffset)*trialdata.hardcurrentscale * 1000;
                obj.y(:,2) = current;
                voltage = (voltage-trialdata.hardvoltageoffset)*trialdata.hardvoltagescale * 1000;
                obj.y(:,3) = voltage;

                switch obj.recmode
                    case 'VClamp'
                        current = (obj.y(:,1)-trialdata.scaledcurrentoffset)*trialdata.scaledcurrentscale;
                        obj.y(:,1) = current;
                        obj.y_units = 'pA';
                    case 'IClamp'
                        voltage = (obj.y(:,1)-trialdata.scaledvoltageoffset)*trialdata.scaledvoltagescale;
                        obj.y(:,1) = voltage;
                        obj.y_units = 'mV';
                end
                
                obj.saveData(trialdata,current,voltage)% save data(n)
                
                obj.displayTrial()
            end
        end
                
        function displayTrial(obj)
            figure(1);
            ax1 = subplot(4,1,1);
            ax2 = subplot(4,1,[2 3 4]);
            redlines = findobj(1,'Color',[1, 0, 0]);
            set(redlines,'color',[1 .8 .8]);
            line(obj.x,obj.y(:,1),'parent',ax2,'color',[1 0 0],'linewidth',1);
            box off; set(gca,'TickDir','out');
            switch obj.recmode
                case 'VClamp'
                    ylabel(ax2,'I (pA)'); %xlim([0 max(t)]);
                    line(obj.x,obj.y(:,3),'parent',ax1,'color',[1 0 0],'linewidth',1);
                    ylabel(ax1,'V_m (mV)'); %xlim([0 max(t)]);
                    title(ax1,[num2str(mean(obj.y(:,3))) ' mV']);
                case 'IClamp'
                    ylabel('V_m (mV)'); %xlim([0 max(t)]);
                    line(obj.x,obj.y(:,2),'parent',ax1,'color',[1 0 0],'linewidth',1);
                    ylabel(ax1,'I (pA)'); %xlim([0 max(t)]);
                    title(ax1,[num2str(mean(obj.y(:,2))) ' pA']);
            end
            xlabel('Time (s)'); %xlim([0 max(t)]);
        end

    end % methods
    
    methods (Access = protected)
        
        function createAIAOSessions(obj)
            % configureAIAO is to start an acquisition routine
            
            obj.aiSession = daq.createSession('ni');
            obj.aiSession.addAnalogInputChannel('Dev1',0, 'Voltage'); % from amp
            obj.aiSession.addAnalogInputChannel('Dev1',3, 'Voltage'); % 100 beta mV/pA
            obj.aiSession.addAnalogInputChannel('Dev1',4, 'Voltage'); % 10 Vm

            % configure AO
            % obj.aoSession = daq.createSession('ni');
            % obj.aoSession.addAnalogOutputChannel('Dev1',2, 'Voltage');
            % obj.aoSession.addAnalogOutputChannel('Dev1',1, 'Voltage');
            %
            % obj.aiSession.addTriggerConnection('Dev1/PFI0','External','StartTrigger');
            % obj.aoSession.addTriggerConnection('External','Dev1/PFI2','StartTrigger');
        end
        
        function createDataStructBoilerPlate(obj)
            % TODO, make this a map.Container array, so you can add
            % whatever keys you want.  Or cell array of maps?  Or a java
            % hashmap?            
            createDataStructBoilerPlate@FlySoundProtocol(obj);
            dbp = obj.dataBoilerPlate;
            
            obj.dataBoilerPlate = dbp;
        end
        
        function defineParameters(obj)
            % This will set up parameters only for the first time, then
            % will use defaults
            obj.params.sampratein = 10000;
            obj.params.samprateout = 10000;
            obj.params.durSweep = 2;
            obj.params.Vm_id = 0;
            obj.params = obj.getDefaults;
        end
       
        function setupStimulus(obj,varargin)
            obj.stimx = [];
            obj.stim = [];
            obj.x = ((1:obj.params.sampratein*obj.params.durSweep) - 1)/obj.params.sampratein;
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