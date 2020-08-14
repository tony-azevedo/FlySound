% Deliver continous voltage steps,check the seal and the input resistance
classdef AcquireWithEpiFeedback < FlySoundProtocol
    
    properties (Constant)
        protocolName = 'AcquireWithEpiFeedback';
    end
    
    properties (SetAccess = protected)
        requiredRig = 'ContinuousEpiFB2TRig';
        analyses = {};
    end
    
    properties (Hidden)
    end
    
    properties (SetAccess = private)
    end
    
    events
    end
    
    methods
        
        function obj = AcquireWithEpiFeedback(varargin)
            obj = obj@FlySoundProtocol(varargin{:});
        end

        function varargout = getStimulus(obj,varargin)
            varargout = {obj.out,obj.x};
        end
                
          
    end
    methods (Access = protected)
                                                       
        function defineParameters(obj)
            obj.params.sampratein = 50000;
            obj.params.samprateout = 50000;
            
            obj.params.stimDurInSec = .8;
            obj.params.preDurInSec = .1;
            obj.params.postDurInSec = .1;
            obj.params.durSweep = obj.params.stimDurInSec+obj.params.preDurInSec+obj.params.postDurInSec;

            obj.params.ttlval = false;
            obj.params.Vm_id = 0;
            obj.params = obj.getDefaults;
        end
        
        function setupStimulus(obj,varargin)
            obj.params.durSweep = obj.params.stimDurInSec+obj.params.preDurInSec+obj.params.postDurInSec;
            obj.x = makeOutTime(obj);
            obj.x = obj.x(:);

            obj.y = false(size(obj.x));
            % obj.out.epicommand = commandstim;
            obj.out.epittl = obj.y + obj.params.ttlval;
            %varargout = {obj.out,obj.out.epittl};
        end
        
    end % protected methods
    
    methods (Static)
    end
end % classdef