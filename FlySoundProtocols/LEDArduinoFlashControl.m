% Control the Epifluorescence, control displacements
classdef LEDArduinoFlashControl < FlySoundProtocol
    
    properties (Constant)
        protocolName = 'LEDArduinoFlashControl';
    end
    
    properties (SetAccess = protected)
        requiredRig = 'LEDArduinoControlRig';
        analyses = {};
    end
        
    events
    end
    
    methods
        
        function obj = LEDArduinoFlashControl(varargin)
            obj = obj@FlySoundProtocol(varargin{:});
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
            obj.out.refchan(1:end-1) = obj.params.stimhashval;
            varargout = {obj.out,obj.out.epittl,obj.out.refchan};
        end
        
    end % methods
    
    methods (Access = protected)
        
        function defineParameters(obj)
            obj.params.sampratein = 50000;
            obj.params.samprateout = 50000;
            obj.params.ndfs = 1;
            obj.params.ndf = obj.params.ndfs(1);
            obj.params.background = 0;
            obj.params.stimDurInSec = 4;
            obj.params.preDurInSec = .5;
            obj.params.postDurInSec = .5;
            obj.params.durSweep = obj.params.stimDurInSec+obj.params.preDurInSec+obj.params.postDurInSec;
            obj.params.stimhashval = 1.2;
            
            obj.params.Vm_id = 0;
            
            obj.params = obj.getDefaults;
        end
        
        function setupStimulus(obj,varargin)
            setupStimulus@FlySoundProtocol(obj);
            obj.params.ndf = obj.params.ndfs(1);
            obj.params.durSweep = obj.params.stimDurInSec+obj.params.preDurInSec+obj.params.postDurInSec;
            obj.x = makeTime(obj);
            obj.y = zeros(size(obj.x));
            obj.y(round(obj.params.samprateout*(obj.params.preDurInSec)+1): round(obj.params.samprateout*(obj.params.preDurInSec+obj.params.stimDurInSec))) = 1;
            
            obj.out.epittl = obj.y;
            obj.out.refchan = obj.y*0;
        end
        
    end % protected methods
    
    methods (Static)
    end
end % classdef
