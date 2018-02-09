% Move the Piezo with steps, control displacements
classdef ManipulatorMove < FlySoundProtocol
    
    properties (Constant)
        protocolName = 'ManipulatorMove';
    end
    
    properties (SetAccess = protected)
        requiredRig = 'M285Rig';
        analyses = {};
    end
    
    
    % The following properties can be set only by class methods
    properties (SetAccess = private)
    end
    
    events
    end
    
    methods
        
        function obj = ManipulatorMove(varargin)
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
            varargout = {obj.out,obj.out.commandnorm};
        end
        
    end % methods
    
    methods (Access = protected)
        
        function defineParameters(obj)
            obj.params.sampratein = 10000;
            obj.params.samprateout = 10000;
            obj.params.pause = 1;
            obj.params.velocity = 5000;
            obj.params.coordinate = {[-100, 0, 0], [-200 0 0]};
            obj.params.return = 1;
            obj.params.stimDurInSec = 1;
            obj.params.preDurInSec = 1;
            obj.params.postDurInSec = 1;
            obj.params.durSweep = obj.params.stimDurInSec+obj.params.preDurInSec+obj.params.postDurInSec;
            
            obj.params.Vm_id = 0;
            
            obj.params = obj.getDefaults;
        end
        
        function setupStimulus(obj,varargin)
            setupStimulus@FlySoundProtocol(obj);
            nmoves = length(obj.params.coordinate);
            stimudur = nmoves*obj.params.pause + nmoves*.1;
            
            obj.params.stimDurInSec = stimudur;
            obj.params.durSweep = obj.params.stimDurInSec+obj.params.preDurInSec+obj.params.postDurInSec;
            obj.x = makeTime(obj);
            obj.y = zeros(size(obj.x));
            for i = 1:nmoves
                obj.y(obj.x>=(i-1)*(obj.params.pause+.1) & obj.x<i*(obj.params.pause+.1)) = norm(obj.params.coordinate{i},2);
            end
            if ~obj.params.return
                obj.y(obj.x>=i*(obj.params.pause+.1)) = norm(obj.params.coordinate{i},2);
            end
                
            obj.out.commandnorm = obj.y;
        end
        
    end % protected methods
    
    methods (Static)
    end
end % classdef
