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
            obj.stimx = ((1:obj.params.samprateout*(obj.params.preDurInSec+obj.params.stimDurInSec+obj.params.postDurInSec))-obj.params.preDurInSec)/obj.params.samprateout;
            obj.x = ((1:obj.params.sampratein*(obj.params.preDurInSec+obj.params.stimDurInSec+obj.params.postDurInSec))-obj.params.preDurInSec)/obj.params.sampratein;
        end

        function varargout = generateStimulus(obj,varargin)
            global globalPiezoChirpStimulus
            global freqstart
            global freqstop
            global ramptime
            
            if isempty(globalPiezoChirpStimulus) ||...
                    length(globalPiezoChirpStimulus) ~= obj.params.samprateout*(obj.params.preDurInSec+obj.params.stimDurInSec+obj.params.postDurInSec) || ...
                    isempty(freqstart) || isempty(freqstop) || isempty(ramptime) || ...
                    freqstart ~= obj.params.freqstart || freqstop ~= obj.params.freqstop || ramptime ~= obj.params.ramptime

                freqstart = obj.params.freqstart;
                freqstop = obj.params.freqstop;
                ramptime = obj.params.ramptime;
                
                globalPiezoChirpStimulus = (1:obj.params.samprateout*(obj.params.preDurInSec+obj.params.stimDurInSec+obj.params.postDurInSec));
                globalPiezoChirpStimulus = globalPiezoChirpStimulus(:);
                globalPiezoChirpStimulus(:) = 0;
                
                stimpnts = obj.params.samprateout*obj.params.preDurInSec+1:...
                    obj.params.samprateout*(obj.params.preDurInSec+obj.params.stimDurInSec);
                
                w = window(@triang,2*obj.params.ramptime*obj.params.samprateout);
                w = [w(1:obj.params.ramptime*obj.params.samprateout);...
                    ones(length(stimpnts)-length(w),1);...
                    w(obj.params.ramptime*obj.params.samprateout+1:end)];
                
                stimtime = (stimpnts - stimpnts(1)+1)/obj.params.samprateout;
                
                globalPiezoChirpStimulus(stimpnts) = ...
                    w.*...
                    chirp(stimtime,obj.params.freqstart,stimtime(end),obj.params.freqstop)';
                
            end            
            stim = globalPiezoChirpStimulus * obj.params.displacement; %*obj.dataBoilerPlate.displFactor;
            stim = stim + obj.params.displacementOffset;
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
                stim(:,2) = obj.generateStimulus();
                
                obj.aoSession.queueOutputData(stim)                
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
            obj.aiSession.addAnalogInputChannel('Dev1',3, 'Voltage'); % PZT Sensor monitor
            
            % configure AO
            obj.aoSession = daq.createSession('ni');
            obj.aoSession.addAnalogOutputChannel('Dev1',2, 'Voltage');
            obj.aoSession.addAnalogOutputChannel('Dev1',1, 'Voltage');
            
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