classdef SealTest < FlySoundProtocol
    
    properties (Constant)
        protocolName = 'SealTest';
    end
    
    properties (Hidden)
    end
    
    % The following properties can be set only by class methods
    properties (SetAccess = private)
        listener
    end
    
    events
        %InsufficientFunds, notify(BA,'InsufficientFunds')
    end
    
    methods
        
        function obj = SealTest(varargin)
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
            if ~strcmp(trialdata.recmode,'VClamp')
                error('Not in Voltage Clamp (VClamp)');
            end
            obj.writePrologueNotes()

            obj.aoSession.Rate = trialdata.samprateout;

            stim = nan(length(obj.generateStimulus()),length((obj.aoSession.Channels)));
            stim(:,1) = obj.generateStimulus();

            obj.aoSession.queueOutputData(stim)
            obj.aoSession.startBackground; % Start the session that receives start trigger first
        end
        
        function stop(obj)
            obj.aoSession.stop;
            obj.aoSession.IsContinuous = false;

            stim = zeros(obj.aoSession.Rate*0.001,1);
            obj.aoSession.queueOutputData(stim(:));
            obj.aoSession.startBackground;
            obj.aoSession.wait;
            obj.aoSession.IsContinuous = true;
       end
          
    end
    methods (Access = protected)
                        
        function createAIAOSessions(obj)
            % configureAIAO is to start an acquisition routine
            
            obj.aoSession = daq.createSession('ni');
            obj.aoSession.addAnalogOutputChannel('cDAQ1Mod1','ao1', 'Voltage'); % Output channel
            obj.aoSession.IsContinuous = true;
            obj.listener = obj.aoSession.addlistener('DataRequired',@(src,event) src.queueOutputData(obj.generateStimulus));
        end
                
        function createDataStructBoilerPlate(obj)
            % TODO, make this a map.Container array, so you can add
            % whatever keys you want.  Or cell array of maps?  Or a java
            % hashmap?            
            createDataStructBoilerPlate@FlySoundProtocol(obj);
            dbp = obj.dataBoilerPlate;
            dbp.recgain = 1;
            dbp.recmode = 'VClamp';

            dbp.headstagegain = .01;
            dbp.daqCurrentOffset = 0.0000; 
            dbp.daqout_to_current = 10*dbp.headstagegain; % m, multiply DAQ voltage to get nA injected
            dbp.daqout_to_current_offset = 0;  % b, add to DAQ voltage to get the right offset
            
            dbp.daqout_to_voltage = .02; % m, multiply DAQ voltage to get mV injected (combines voltage divider and input factor) ie 1 V should give 2mV
            dbp.daqout_to_voltage_offset = 0;  % b, add to DAQ voltage to get the right offset
            
            dbp.hardcurrentscale = .010/(dbp.rearcurrentswitchval*dbp.headstagegain); % [V]/current scal gives nA;
            dbp.hardcurrentoffset = 0; % -6.6238/1000;
            dbp.hardvoltagescale = 1/(10); % reads 10X Vm, mult by 1/10 to get actual reading in V, multiply in code to get mV
            dbp.hardvoltageoffset = 0; % -6.2589/1000; % in V, reads 10X Vm, mult by 1/10 to get actual reading in V, multiply in code to get mV
                        
            obj.dataBoilerPlate = dbp;

        end
        
        function trialdata = runtimeParameters(obj,varargin)
            trialdata = runtimeParameters@FlySoundProtocol(obj,varargin{:});
            trialdata.recgain = 1;
            trialdata.recmode = 'VClamp';

            obj.dataBoilerPlate.scaledcurrentscale = 1000/(obj.recgain*obj.dataBoilerPlate.headstagegain); % [mV/V]/gainsetting gives pA
            obj.dataBoilerPlate.scaledvoltagescale = 1000/(obj.recgain); % mV/gainsetting gives mV                        
        end
        
        function defineParameters(obj)
            obj.params.sampratein = 100000;
            obj.params.samprateout = 100000;
            obj.params.stepamp = 5; %mV;
            obj.params.stepdur = .02; %sec;
            obj.params.pulses = 20;
            %             obj.params.stimDurInSec = 2;
            %             obj.params.preDurInSec = .5;
            %             obj.params.postDurInSec = .5;
            obj.params.durSweep = obj.params.stepdur*(2*obj.params.pulses+2);
            
            obj.params.Vm_id = 0;
            obj.params = obj.getDefaults;
        end
        
        function setupStimulus(obj,varargin)
            obj.params.durSweep = obj.params.stepdur*(2*obj.params.pulses);
            obj.stimx = (1:obj.params.samprateout*obj.params.durSweep)/obj.params.samprateout;
            obj.stimx = obj.stimx(:);
            
            stim = zeros(2*obj.params.pulses,obj.params.stepdur*obj.params.samprateout);
            stim(2:2:2*obj.params.pulses,:) = 1;
            stim = stim';
            stim = stim(:);
            
            obj.stim = stim * obj.params.stepamp;            
            obj.x = (1:obj.params.sampratein*obj.params.durSweep)/obj.params.sampratein;
            obj.x = obj.x(:);
            obj.y = obj.x;
        end
                        
    end % protected methods
    
    methods (Static)
    end
end % classdef