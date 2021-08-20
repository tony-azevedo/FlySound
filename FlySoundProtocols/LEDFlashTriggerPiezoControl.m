% Control the Epifluorescence, control displacements
classdef LEDFlashTriggerPiezoControl < ControlProtocol

    properties
        cue
    end
    
    properties (Constant)
        protocolName = 'LEDFlashTriggerPiezoControl';
        stimulusHash = 2.7;
        % map = load('controlProtocolRefValueMap');
        % 
    end
    
    properties (SetAccess = protected)
        requiredRig = 'LEDArduinoTriggerPiezoControlRig';
        analyses = {};
        normalizedcue
    end
        
    events
    end
    
    methods
        
        function obj = LEDFlashTriggerPiezoControl(varargin)
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
            obj.out.epittl = obj.y*obj.params.ndf;
            obj.cue = obj.normalizedcue*obj.params.displacement+obj.params.background;
            % obj.out.piezotrigger = obj.out.piezotrigger;
            obj.out.refchan(1:end-1) = obj.stimulusHash;
            varargout = {obj.out,obj.out.epittl,obj.out.piezotrigger,obj.out.refchan};
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
            obj.params.stimDurInSec = 4;
            obj.params.preDurInSec = 1;
            obj.params.cueDelayDurInSec = .5;
            obj.params.cueStimDurInSec = .3;
            obj.params.cueRampDurInSec = .07;
            obj.params.posttriggerdelay = .05;
            obj.params.postDurInSec = .5;
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
            obj.y(round(obj.params.samprateout*(obj.params.preDurInSec)+1): round(obj.params.samprateout*(obj.params.preDurInSec+obj.params.stimDurInSec))) = 1;
            
            if obj.params.cueDelayDurInSec+obj.params.cueStimDurInSec + obj.params.posttriggerdelay> obj.params.preDurInSec
                warning('Trigger delay, cue and subsequent delay are longer than preperiod. Lengtheninng preperiod to accomodate')
                obj.params.preDurInSec = obj.params.cueDelayDurInSec+obj.params.cueStimDurInSec + obj.params.posttriggerdelay +.1;
            end
            stimpnts = round(obj.params.samprateout*obj.params.cueStimDurInSec);
            precue = obj.params.preDurInSec-obj.params.cueStimDurInSec - obj.params.cueDelayDurInSec;
            
            triggerstart = precue - obj.params.posttriggerdelay;
            cuetrigger = zeros(size(obj.x)); 
            cuetrigger(round(triggerstart*obj.params.samprateout)+(1:.001*obj.params.samprateout)) = 1;

            ramp = round(obj.params.cueRampDurInSec*obj.params.samprateout);
            w = window(@triang,2*ramp);
            w = [w(1:ramp);...
                ones(stimpnts-length(w),1);...
                w(ramp+1:end)];
            
            obj.normalizedcue = [zeros(obj.params.samprateout*obj.params.posttriggerdelay,1); w;  zeros(obj.params.samprateout*obj.params.posttriggerdelay,1)];
            obj.cue = obj.normalizedcue;
            
            obj.out.epittl = obj.y;
            obj.out.piezotrigger = cuetrigger;
            obj.out.refchan = obj.y*0;
        end
        
    end % protected methods
    
    methods (Static)
    end
end % classdef
