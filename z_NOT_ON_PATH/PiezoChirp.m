classdef PiezoChirp < FlySoundProtocol
    
    properties (Constant)
        protocolName = 'PiezoChirp';
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
        
        function obj = PiezoChirp(varargin)
            % In case more construction is needed
            obj = obj@FlySoundProtocol(varargin{:});
        end

        function varargout = generateStimulus(obj,varargin)
            stim = obj.stim * obj.params.displacement; %*obj.dataBoilerPlate.displFactor;
            stim = stim + obj.params.displacementOffset;
            varargout = {stim,obj.x};
        end
        
        function run(obj,varargin)
            trialdata = runtimeParameters(obj,varargin{:});
            obj.writePrologueNotes()

            obj.aiSession.Rate = trialdata.sampratein;
            obj.aiSession.DurationInSeconds = trialdata.durSweep;

            obj.aoSession.Rate = trialdata.samprateout;

            stim = nan(length(obj.generateStimulus()),length((obj.aoSession.Channels)));
            current = nan(size(obj.x));
            voltage = nan(size(obj.x));
            for repeat = 1:trialdata.repeats

                obj.writeTrialNotes('displacement');
                
                stim(:,1) = obj.generateStimulus();
                stim(:,2) = obj.generateStimulus();
                obj.aoSession.wait;

                obj.aoSession.queueOutputData(stim)                
                obj.aoSession.startBackground; % Start the session that receives start trigger first
                obj.y = obj.aiSession.startForeground; % both amp and signal monitor input

                voltage(:) = obj.y(:,1);
                current(:) = obj.y(:,2);
                obj.sensorMonitor = obj.y(:,3);
                
                % apply scaling factors
                voltage = (voltage-trialdata.scaledvoltageoffset)*trialdata.scaledvoltagescale;
                % Note: collecting hard current here, not scaled
                % current
                current = current/trialdata.hardcurrentscale+trialdata.daqCurrentOffset; % in nA
                current = current*1000;
                 
                obj.y(:,1) = voltage;
                obj.y(:,2) = current; % 'pA'

                obj.saveData(trialdata,current,voltage,'sgsmonitor',obj.sensorMonitor) % TODO: save signal monitor
                
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
            
            ax2 = subplot(4,4,[13 14 15]);
            line(obj.stimx,obj.generateStimulus,'parent',ax2,'color',[.7 .7 .7],'linewidth',1);
            line(obj.x,obj.sensorMonitor,'parent',ax2,'color',[0 0 1],'linewidth',1);
            box off; set(gca,'TickDir','out');

            ax3 = subplot(3,4,[4 8]);

            sgsfft = real(fft(obj.y(:,3)).*conj(fft(obj.y(:,3))));
            sgsf = obj.params.sampratein/length(obj.y(:,3))*[0:length(obj.y(:,3))/2]; sgsf = [sgsf, fliplr(sgsf(2:end-1))];
            
            respfft = real(fft(obj.y(:,1)).*conj(fft(obj.y(:,1))));
            respf = obj.params.sampratein/length(obj.y(:,1))*[0:length(obj.y(:,1))/2]; respf = [respf, fliplr(respf(2:end-1))];
            
            %             stim = obj.generateStimulus;
            %             stimfft = real(fft(stim).*conj(fft(stim)));
            %             stimf = obj.params.samprateout/length(stim)*[0:length(stim)/2]; stimf = [stimf, fliplr(stimf(2:end-1))];

            [C,IA,IB] = intersect(respf,sgsf);
            stimratio = respfft(IA)./sgsfft(IB);
            
            %loglog(stimf,stimfft/max(stimfft(stimf>obj.params.freqstart & stimf<obj.params.freqstop))), hold on;
            loglog(sgsf,sgsfft/max(sgsfft(sgsf>obj.params.freqstart & sgsf<obj.params.freqstop)),'b'), hold on;
            loglog(respf,respfft/max(respfft(respf>obj.params.freqstart & respf<obj.params.freqstop)),'r'), hold on;
            loglog(C,stimratio/max(stimratio(C>obj.params.freqstart & C<obj.params.freqstop/2)),'k'), hold on;
            
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
            obj.aiSession.addAnalogInputChannel('Dev1',3, 'Voltage'); % from amp
            obj.aiSession.addAnalogInputChannel('Dev1',5, 'Voltage'); % PZT Sensor monitor
            
            % configure AO
            obj.aoSession = daq.createSession('ni');
            obj.aoSession.addAnalogOutputChannel('Dev1',1, 'Voltage'); % sound of chirp
            obj.aoSession.addAnalogOutputChannel('Dev1',2, 'Voltage'); % piezo
            
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
            obj.params.displacementOffset = 0;
            obj.params.sampratein = 10000;
            obj.params.samprateout = 40000;
            obj.params.displacement = 1;
            obj.params.ramptime = 0.1; %sec;
            obj.params.freqstart = 10; %Hz;
            obj.params.freqstop = 1000; %Hz
            obj.params.stimDurInSec = 5;
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
            
            w = window(@triang,2*obj.params.ramptime*obj.params.samprateout);
            w = [w(1:obj.params.ramptime*obj.params.samprateout);...
                ones(length(stimpnts)-length(w),1);...
                w(obj.params.ramptime*obj.params.samprateout+1:end)];
            
            stimtime = (stimpnts - stimpnts(1)+1)/obj.params.samprateout;
            
            stim(stimpnts) = ...
                w.*...
                chirp(stimtime,obj.params.freqstart,stimtime(end),obj.params.freqstop)';
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