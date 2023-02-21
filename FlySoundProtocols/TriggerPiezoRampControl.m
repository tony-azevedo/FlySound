% Set up a dac that controls the piezo device, to deliver a voltage change
% trigger the dac, e.g. at time 0.
classdef TriggerPiezoRampControl < ControlProtocol

    properties
        cue
    end
    
    properties (Constant)
        protocolName = 'TriggerPiezoRampControl';
        stimulusHash = 3.8;
        % map = load('controlProtocolRefValueMap');
        % 
    end
    
    properties (SetAccess = protected)
        requiredRig = 'TriggerPiezoControlRig';
        analyses = {};
        normalizedcue
    end
        
    events
    end
    
    methods
        
        function obj = TriggerPiezoRampControl(varargin)
            obj = obj@ControlProtocol(varargin{:});
            p = inputParser;
            p.addParameter('modusOperandi','Run',...
                @(x) any(validatestring(x,{'Run','Stim','Cal'})));
            parse(p,varargin{:});
            
            if strcmp(p.Results.modusOperandi,'Cal')
                notify(obj,'StimulusProblem',StimulusProblemData('CalibratingStimulus'))
            end
        end
        
        function varargout = getStimulus(obj,varargin)
            % the "cue" is the stimulus that will be put on the triggered dac
            obj.cue = obj.normalizedcue*obj.params.displacement+obj.params.background;
            
            % obj.out.piezotrigger = obj.out.piezotrigger; % just a
            % reminder to set this in setup
            
            obj.out.refchan(1:end-1) = obj.stimulusHash;
            varargout = {obj.out,obj.out.epittl,obj.out.piezotrigger,obj.out.refchan}; 
            % note, the "cue" is not included here, just the trigger
        end
        
        function setParams(obj,varargin)
            % can't set the stimDurInSec in this method
            % have to set the cueStimDurInSec, which is the length of the
            % piezo stimulus
            currentStimDur = obj.params.stimDurInSec;
            setParams@ControlProtocol(obj,varargin{:})
            if obj.params.stimDurInSec ~= currentStimDur || obj.params.stimDurInSec ~= 0
                warning('stimDurInSec has to be 0. To change the triggerPiezoRamp duration, set cueStimDurInSec')
                obj.params.stimDurInSec = 0;
            end
        end
        
    end % methods
    
    methods (Access = protected)
        
        function defineParameters(obj)
            % rmacqpref('defaultsLEDFlashWithPiezoCueControl')
            obj.params.sampratein = 50000;
            obj.params.samprateout = 50000;
            obj.params.ndfs = 1;
            obj.params.ndf = obj.params.ndfs(1);
            obj.params.displacements = [-5 -2.5 2.5 5];
            obj.params.displacement = obj.params.displacements(1);
            obj.params.background = 5;
            obj.params.stimDurInSec = 0; % the cue stim dur sets the length of the ramp
            obj.params.preDurInSec = 1;
            obj.params.cueStimDurInSec = .3;
            obj.params.cueRampDurInSec = .07;
            obj.params.posttriggerdelay = 0; % could delay the stimulus, for some reason
            
            % the durSweep for this protocol is preDurInSec + postDurInSec
            obj.params.postDurInSec = 5; % the trigger is a hard coded step that occurs at time 0
            
            % stimDurInSec should be 0
            obj.params.durSweep = obj.params.stimDurInSec+obj.params.preDurInSec+obj.params.postDurInSec;
            
            obj.params.stimhashval = obj.stimulusHash;
            
            obj.params.Vm_id = 0;
            
            obj.params = obj.getDefaults;
        end
        
        function setupStimulus(obj,varargin)
            setupStimulus@FlySoundProtocol(obj);
            obj.params.ndf = obj.params.ndfs(1);
            obj.params.displacement = obj.params.displacements(1);
            
            obj.params.durSweep = obj.params.stimDurInSec+obj.params.preDurInSec+obj.params.postDurInSec;
            obj.x = makeTime(obj);
            obj.y = zeros(size(obj.x));
            
            % Normally a stimulus is set up here, but for
            % triggerPiezo stimuli, there is only a trigger and a cue
            % obj.y(round(obj.params.samprateout*(obj.params.preDurInSec)+1): round(obj.params.samprateout*(obj.params.preDurInSec+obj.params.stimDurInSec))) = 1;
            
            triggerstart = obj.params.preDurInSec+obj.params.posttriggerdelay;
            cuetrigger = zeros(size(obj.x)); 
            % cue trigger is hard coded at 1 ms. The rising phase triggers
            % the cue.
            cuetrigger(round(triggerstart*obj.params.samprateout)+(1:.001*obj.params.samprateout)) = 1;

            stimpnts = round(obj.params.samprateout*obj.params.cueStimDurInSec);
            ramp = round(obj.params.cueRampDurInSec*obj.params.samprateout);
            w = window(@triang,2*ramp);
            w = [w(1:ramp);...
                ones(stimpnts-length(w),1);...
                w(ramp+1:end)];
            
            postcue = max([obj.params.posttriggerdelay,0.01]); % add at least 10 ms to the end of cue
            obj.normalizedcue = [...
                zeros(obj.params.samprateout*obj.params.posttriggerdelay,1);  % the short delay
                w;                                                            % the ramp
                zeros(obj.params.samprateout*postcue,1)]; % and a little afterward
            obj.cue = obj.normalizedcue;               % set for now, will be scaled and offset
            
            obj.out.epittl = obj.y;  % 
            obj.out.piezotrigger = cuetrigger;
            obj.out.refchan = obj.y*0;
        end
        
    end % protected methods
    
    methods (Static)
    end
end % classdef
