% Create protocol to deliver a sine pulse to an antenna
%   p = PiezoSine(<paramname>,paramname,'modusOperandi',<'Run','Stim','Cal'>)

classdef PiezoSine < FlySoundProtocol
    properties (Constant)
        protocolName = 'PiezoSine';
    end
    
    properties (Hidden)
        sensorMonitor
    end
    
    % The following properties can be set only by class methods
    properties (SetAccess = private)
        gaincorrection
    end
    
    events
        %InsufficientFunds, notify(BA,'InsufficientFunds')
    end
    
    methods
        
        function obj = PiezoSine(varargin)
            obj = obj@FlySoundProtocol(varargin{:});
            p = inputParser;
            p.addParamValue('modusOperandi','Run',...
                @(x) any(validatestring(x,{'Run','Stim','Cal'})));
            parse(p,varargin{:});
            
            if strcmp(p.Results.modusOperandi,'Cal')
                    % obj.comment('Calibrating!  Not using calibration folder')
                    warning('PiezoSine is not being corrected!  No available correction file')
                    obj.gaincorrection = [];
            
            else 
                correctionfiles = dir('C:\Users\Anthony Azevedo\Code\FlySound\Rig Calibration\PiezoSineCorrection*.mat');
                if ~isempty(correctionfiles)
                    cfdate = correctionfiles(1).date;
                    cf = 1;
                    cfdate = datenum(cfdate);
                    for d = 2:length(correctionfiles)
                        if cfdate < datenum(correctionfiles(d).date)
                            cfdate = datenum(correctionfiles(d).date);
                            cf = d;
                        end
                    end
                    temp = load(correctionfiles(cf).name);
                    obj.gaincorrection = temp.d;
                else
                    obj.comment('PiezoSine is not being corrected!  No available correction file')
                    warning('PiezoSine is not being corrected!  No available correction file')
                    obj.gaincorrection = [];
                end
            end
        end

        function varargout = generateStimulus(obj,varargin)
            if ~isempty(obj.gaincorrection)
                gain = obj.gaincorrection.gain(...
                    round(obj.gaincorrection.displacement*10)/10 == round(obj.params.displacement*10)/10,...
                    round(obj.gaincorrection.freqs*10)/10 == round(obj.params.freq*10)/10);
                offset = obj.gaincorrection.offset(...
                    round(obj.gaincorrection.displacement*10)/10 == round(obj.params.displacement*10)/10,...
                    round(obj.gaincorrection.freqs*10)/10 == round(obj.params.freq*10)/10);
                if isempty(gain) || isempty(offset)
                    gain = 1;
                    offset = 0;
                    obj.comment('PiezoSine Stimulus is uncalibrated');
                    warning('PiezoSine Stimulus is uncalibrated!')
                end
            else gain = 1; offset = 0;
            end
            if obj.params.displacement*gain + obj.params.displacementOffset + offset >= 10 || ...
                    obj.params.displacementOffset+offset-obj.params.displacement*gain >= 10
                gain = 1;
                offset = 0;
                obj.warn('Calibrated Stimulus outside bounds!');
            end
            commandstim = obj.stim.*sin(2*pi*obj.params.freq*obj.stimx);
            commandstim = commandstim * obj.params.displacement; 
            calstim = commandstim *gain; 
            commandstim = commandstim+obj.params.displacementOffset;
            calstim = calstim+obj.params.displacementOffset+offset;
            varargout = {calstim,commandstim};
        end
        
        function run(obj,varargin)
            trialdata = runtimeParameters(obj,varargin{:});
            obj.writePrologueNotes()

            obj.aiSession.Rate = trialdata.sampratein;
            obj.aiSession.DurationInSeconds = trialdata.durSweep;

            obj.aoSession.Rate = trialdata.samprateout;

            stim = nan(length(obj.generateStimulus()),length((obj.aoSession.Channels)));
            tic
            for repeat = 1:trialdata.repeats
                for vi = 1:length(obj.params.freqs)
                    obj.params.freq = obj.params.freqs(vi);
                    trialdata.freq = obj.params.freq;

                    obj.writeTrialNotes('freq');
                    stim(:,1) = obj.generateStimulus();
                    stim(:,2) = stim(:,1);
                    tic
                    obj.aoSession.wait;
                    obj.aoSession.queueOutputData(stim)
                    fprintf('AoSession Wait: '),toc
                    obj.aoSession.startBackground; % Start the session that receives start trigger first
                    fprintf('AoSession Backgroud: '),toc
                    obj.y = obj.aiSession.startForeground; % both amp and signal monitor input
                    fprintf('Trial in foreground: '),toc
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
                    obj.y(:,2) = current; % 'pA'
                    
                    obj.saveData(trialdata,current,voltage,'sgsmonitor',obj.sensorMonitor) % TODO: save signal monitor
                    obj.displayTrial()
                end
            end
        end
                
        function displayTrial(obj)
            figure(1);
            ax1 = subplot(4,1,[1 2 3]);
            
            redlines = findobj(1,'Color',[1, 0, 0]);
            set(redlines,'color',[1 .8 .8]);
            bluelines = findobj(1,'Color',[0, 0, 1]);
            set(bluelines,'color',[.8 .8 1]);
            line(obj.x,obj.y(:,1),'parent',ax1,'color',[1 0 0],'linewidth',1);
            box off; set(gca,'TickDir','out');
            switch obj.recmode
                case 'VClamp'
                    ylabel('I (pA)'); %xlim([0 max(t)]);
                case 'IClamp'
                    ylabel('V_m (mV)'); %xlim([0 max(t)]);
            end
            xlabel('Time (s)'); %xlim([0 max(t)]);
            
            ax2 = subplot(4,1,4);
            [~,commandstim] = obj.generateStimulus;
            line(obj.stimx,commandstim,'parent',ax2,'color',[.7 .7 .7],'linewidth',1);
            line(obj.x,obj.sensorMonitor,'parent',ax2,'color',[0 0 1],'linewidth',1);
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
            obj.aoSession.addAnalogOutputChannel('Dev1',1, 'Voltage'); % sound of chirp
            obj.aoSession.addAnalogOutputChannel('Dev1',2, 'Voltage');
            
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
            obj.params.displacementOffset = 5;
            obj.params.sampratein = 10000;
            obj.params.samprateout = 40000;
            obj.params.displacement = 1;
            obj.params.ramptime = 0.001; %sec;

            % obj.params.cycles = 10; 
            obj.params.freq = 256; % Hz
            obj.params.freqs = [256]; % Hz
            obj.params.stimDurInSec = .5; % obj.params.cycles/obj.params.freq;
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
            obj.params.freq = obj.params.freqs(1);
            stim = (1:obj.params.samprateout*(obj.params.preDurInSec+obj.params.stimDurInSec+obj.params.postDurInSec));
            stim = stim(:);
            stim(:) = 0;

            stimpnts = obj.params.samprateout*obj.params.preDurInSec+1:...
                obj.params.samprateout*(obj.params.preDurInSec+obj.params.stimDurInSec);
            
            w = window(@triang,2*obj.params.ramptime*obj.params.samprateout);
            w = [w(1:obj.params.ramptime*obj.params.samprateout);...
                ones(length(stimpnts)-length(w),1);...
                w(obj.params.ramptime*obj.params.samprateout+1:end)];

            stim(stimpnts) = w;
            
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