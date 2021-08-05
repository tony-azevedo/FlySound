% Control the Epifluorescence, control displacements
classdef LEDFlashWithTriggeredCueControl < ControlProtocol

    properties
        cue
    end
    
    properties (Constant)
        protocolName = 'LEDFlashWithTriggeredCueControl';
        stimulusHash = 3.4;
    end
    
    properties (SetAccess = protected)
        requiredRig = 'LEDArduinoTriggeredPiezoControlRig';
        analyses = {};
    end
        
    events
    end
    
    methods
        
        function obj = LEDFlashWithPiezoCueControl(varargin)
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
            obj.out.piezocommand = obj.cue*obj.params.displacement+obj.params.background;
            obj.out.refchan(1:end-1) = obj.stimulusHash;
            varargout = {obj.out,obj.out.epittl,obj.out.piezocommand,obj.out.refchan};
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
            
            if obj.params.cueDelayDurInSec+obj.params.cueStimDurInSec > obj.params.preDurInSec
                warning('Cue and subsequent delay are longer than preperiod. Shortening duration to accomodate')
                obj.params.cueStimDurInSec = obj.params.preDurInSec - obj.params.cueDelayDurInSec;
                if obj.params.cueStimDurInSec <= .1
                    warning('Cue is too short. Setting cue to 0.1 s, ramp to .05 s.')
                    obj.params.cueStimDurInSec = .1;
                    obj.params.cueRampDurInSec = 0.05;
                    obj.params.cueDelayDurInSec = obj.params.preDurInSec - obj.params.cueStimDurInSec;
                    if obj.params.cueDelayDurInSec <0
                        warning('Preperiod is too short. Lengthening preperiod to accomodate')
                       obj.params.cueDelayDurInSec = 0;
                        obj.params.preDurInSec = obj.params.cueStimDurInSec;
                    end
                end
            end
            stimpnts = round(obj.params.samprateout*obj.params.cueStimDurInSec);
            precue = obj.params.preDurInSec-obj.params.cueStimDurInSec - obj.params.cueDelayDurInSec;
            obj.cue = zeros(size(obj.x));
            ramp = round(obj.params.cueRampDurInSec*obj.params.samprateout);
            w = window(@triang,2*ramp);
            w = [w(1:ramp);...
                ones(stimpnts-length(w),1);...
                w(ramp+1:end)];
            
            obj.cue(round(obj.params.samprateout*(precue)+1): round(obj.params.samprateout*(precue+obj.params.cueStimDurInSec))) = w;

            obj.out.epittl = obj.y;
            obj.out.piezocommand = obj.cue;
            obj.out.refchan = obj.y*0;
        end
        
    end % protected methods
    
    methods (Static)
    end
end % classdef
