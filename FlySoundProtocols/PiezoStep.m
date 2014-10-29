% Move the Piezo with steps, control displacements
classdef PiezoStep < FlySoundProtocol
    
    properties (Constant)
        protocolName = 'PiezoStep';
    end
    
    properties (SetAccess = protected)
        requiredRig = 'PiezoRig';
        analyses = {};
    end
    
    
    % The following properties can be set only by class methods
    properties (SetAccess = private)
    end
    
    events
    end
    
    methods
        
        function obj = PiezoStep(varargin)
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
            commandstim = obj.y* obj.params.displacement + obj.params.displacementOffset;
            obj.out.piezocommand = commandstim;
            varargout = {obj.out,obj.out.piezocommand,commandstim};
        end
        
    end % methods
    
    methods (Access = protected)
        
        function defineParameters(obj)
            obj.params.sampratein = 50000;
            obj.params.samprateout = 50000;
            obj.params.displacements = [-1 -.3 -.1 .1 .3 1];
            obj.params.displacement = obj.params.displacements(1);
            obj.params.displacementOffset = 5;
            obj.params.stimDurInSec = .5;
            obj.params.preDurInSec = 1.5;
            obj.params.postDurInSec = 1;
            obj.params.durSweep = obj.params.stimDurInSec+obj.params.preDurInSec+obj.params.postDurInSec;
            
            obj.params.Vm_id = 0;
            
            obj.params = obj.getDefaults;
        end
        
        function setupStimulus(obj,varargin)
            setupStimulus@FlySoundProtocol(obj);
            obj.params.displacement = obj.params.displacements(1);
            obj.params.durSweep = obj.params.stimDurInSec+obj.params.preDurInSec+obj.params.postDurInSec;
            obj.x = makeTime(obj);
            obj.y = zeros(size(obj.x));
            obj.y(obj.params.samprateout*(obj.params.preDurInSec)+1: obj.params.samprateout*(obj.params.preDurInSec+obj.params.stimDurInSec)) = 1;
            obj.out.piezocommand = obj.y;
        end
        
    end % protected methods
    
    methods (Static)
    end
end % classdef
