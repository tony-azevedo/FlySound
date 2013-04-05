classdef VoltageSteps < FlySoundProtocol
    
    properties (Constant)
        protocolName = 'VoltageSteps';
    end
    
    properties (Hidden)
        sensorMonitor
        stimx
        stim
        x
    end
    
    % The following properties can be set only by class methods
    properties (SetAccess = private)
    end
    
    events
        %InsufficientFunds, notify(BA,'InsufficientFunds')
    end
    
    methods
        
        function obj = VoltageSteps(varargin)
            % In case more construction is needed
            obj = obj@FlySoundProtocol(varargin{:});
            obj.stimx = ((1:obj.params.samprateout*(obj.params.preDurInSec+obj.params.stimDurInSec+obj.params.postDurInSec))-obj.params.preDurInSec)/obj.params.samprateout;
            obj.stim = zeros(size(obj.stimx));
            obj.stim(obj.params.sampratein*(obj.params.preDurInSec)+1: obj.params.sampratein*(obj.params.preDurInSec+obj.params.stimDurInSec)) = 1;
            obj.x = ((1:obj.params.sampratein*(obj.params.preDurInSec+obj.params.stimDurInSec+obj.params.postDurInSec))-obj.params.preDurInSec)/obj.params.sampratein;
        end

        function varargout = generateStimulus(obj,varargin)
            if nargin>1
                v = varargin{1};
            end
            stim = obj.stim * v; %*obj.dataBoilerPlate.displFactor;
            varargout = {stim,obj.x};
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

            stim = nan(length(obj.generateStimulus()),length((obj.aoSession.Channels)));

            for repeat = 1:p.Results.repeats

                fprintf('Trial %d\n',obj.n);
                
                stim(:,1) = obj.generateStimulus();
                %stim(:,2) = obj.generateStimulus();
                
                obj.aoSession.queueOutputData(stim)                
                obj.aoSession.startBackground; % Start the session that receives start trigger first
                obj.y = obj.aiSession.startForeground; % both amp and signal monitor input
                
                voltage = obj.y(:,1);
                current = obj.y(:,1);
                
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
            ax1 = subplot(4,4,[1 2 3 5 6 7 9 10 11]);
            
            redlines = findobj(1,'Color',[1, 0, 0]);
            set(redlines,'color',[1 .8 .8]);
            bluelines = findobj(1,'Color',[0, 0, 1]);
            set(bluelines,'color',[.8 .8 1]);

            line(obj.stimx,obj.generateStimulus,'parent',ax1,'color',[0 0 1],'linewidth',1);
            line(obj.x,obj.y(:,2),'parent',ax1,'color',[1 0 0],'linewidth',1);
            box off; set(gca,'TickDir','out');
            switch obj.recmode
                case 'VClamp'
                    ylabel('I (pA)'); %xlim([0 max(t)]);
                case 'IClamp'
                    ylabel('V_m (mV)'); %xlim([0 max(t)]);
            end
            xlabel('Time (s)'); %xlim([0 max(t)]);
            
            ax2 = subplot(4,4,[13 14 15]);
            line(obj.stimx,obj.generateStimulus,'parent',ax2,'color',[.7 .7 .7],'linewidth',1);
            %line(obj.x,obj.sensorMonitor,'parent',ax2,'color',[0 0 1],'linewidth',1);
            box off; set(gca,'TickDir','out');

            ax3 = subplot(1,4,4);

            sgsvalue = obj.y(:,2);
            sgsfft = real(fft(sgsvalue).*conj(fft(sgsvalue)));
            sgsf = obj.params.sampratein/length(sgsvalue)*[0:length(sgsvalue)/2]; sgsf = [sgsf, fliplr(sgsf(2:end-1))];
            
            stim = obj.generateStimulus;
            stimfft = real(fft(stim).*conj(fft(stim)));
            stimf = obj.params.samprateout/length(stim)*[0:length(stim)/2]; stimf = [stimf, fliplr(stimf(2:end-1))];

            [C,IA,IB] = intersect(sgsf,stimf);
            stimratio = sgsfft(IA)./stimfft(IB);
            
            loglog(stimf,stimfft/max(stimfft(stimf>obj.params.freqstart & stimf<obj.params.freqstop))), hold on;
            loglog(sgsf,sgsfft/max(sgsfft(sgsf>obj.params.freqstart & sgsf<obj.params.freqstop)),'r'), hold on;
%             loglog(C,stimratio/max(stimratio(C>obj.params.freqstart & C<obj.params.freqstop/2)),'k'), hold on;
            
            %line(obj.x,obj.sensorMonitor,'parent',ax2,'color',[0 0 1],'linewidth',1);
            box off; set(gca,'TickDir','out');
            xlim([obj.params.freqstart obj.params.freqstop*.95])
        end

    end % methods
    
    methods (Access = protected)
                        
        function createAIAOSessions(obj)
            % configureAIAO is to start an acquisition routine
            
            obj.aiSession = daq.createSession('ni');
            obj.aiSession.addAnalogInputChannel('Dev1',0, 'Voltage'); % from amp
            
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
            defineParameters@FlySoundProtocol(obj);
            obj.params.sampratein = 10000;
            obj.params.samprateout = 10000;
            obj.params.steps = [-30 -20 -10 0 10 20 30];
            obj.params.stimDurInSec = 0.5;
            obj.params.preDurInSec = .5;
            obj.params.postDurInSec = .5;
            obj.params.durSweep = obj.params.stimDurInSec+obj.params.preDurInSec+obj.params.postDurInSec;
            
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