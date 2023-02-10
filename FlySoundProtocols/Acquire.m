% Deliver continous voltage steps,check the seal and the input resistance
classdef Acquire < FlySoundProtocol
    
    properties (Constant)
        protocolName = 'Acquire';
    end
    
    properties (SetAccess = protected)
        requiredRig = 'ContinuousInRig';
        analyses = {};
    end
    
    properties (Hidden)
    end
    
    properties (SetAccess = private)
    end
    
    events
    end
    
    methods
        
        function obj = Acquire(varargin)
            obj = obj@FlySoundProtocol(varargin{:});
        end

        function varargout = getStimulus(obj,varargin)
            varargout = {obj.out,obj.x};
        end
                
          
    end
    methods (Access = protected)
                                                       
        function defineParameters(obj)
            obj.params.sampratein = 50000;
            obj.params.samprateout = 10000;
            
            obj.params.stimDurInSec = .8;
            obj.params.preDurInSec = .1;
            obj.params.postDurInSec = .1;
            obj.params.durSweep = obj.params.stimDurInSec+obj.params.preDurInSec+obj.params.postDurInSec;

            obj.params.Vm_id = 0;
            obj.params = obj.getDefaults;
        end
        
        function setupStimulus(obj,varargin)
            obj.params.durSweep = obj.params.stimDurInSec+obj.params.preDurInSec+obj.params.postDurInSec;
            obj.x = makeOutTime(obj);
            obj.x = obj.x(:);

            obj.y = zeros(size(obj.x));
            obj.out.voltage = obj.y;
            obj.out.current = obj.y;
        end
                        
    end % protected methods
    
    methods (Static)
    end
end % classdef