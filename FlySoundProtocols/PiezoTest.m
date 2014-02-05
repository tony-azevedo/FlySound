% Deliver continous voltage steps,check the seal and the input resistance
classdef PiezoTest < FlySoundProtocol
    
    properties (Constant)
        protocolName = 'PiezoTest';
    end
    
    properties (SetAccess = protected)
        requiredRig = 'ContinuousOutPiezoRig';
        analyses = {};
    end
    
    properties (Hidden)
    end
    
    properties (SetAccess = private)
    end
    
    events
    end
    
    methods
        
        function obj = PiezoTest(varargin)
            obj = obj@FlySoundProtocol(varargin{:});
        end

        function varargout = getStimulus(obj,varargin)
            varargout = {obj.out,obj.x};
        end
                
          
    end
    methods (Access = protected)
                                                       
        function defineParameters(obj)
            obj.params.sampratein = 100000;
            obj.params.samprateout = 100000;
            obj.params.stepamp = 1; %mV;
            obj.params.stepOffset = 5; %mV;
            obj.params.stepdur = .1; %sec;
            obj.params.pulses = 20;
            %             obj.params.stimDurInSec = 2;
            %             obj.params.preDurInSec = .5;
            %             obj.params.postDurInSec = .5;
            obj.params.durSweep = obj.params.stepdur*(2*obj.params.pulses);
            
            obj.params.Vm_id = 0;
            obj.params = obj.getDefaults;
        end
        
        function setupStimulus(obj,varargin)
            obj.params.durSweep = obj.params.stepdur*(2*obj.params.pulses);
            obj.x = makeOutTime(obj);
            obj.x = obj.x(:);

            obj.y = zeros(2*obj.params.pulses,obj.params.stepdur*obj.params.samprateout);
            obj.y(1:2:2*obj.params.pulses,:) = 1;
            obj.y = obj.y';
            obj.y = obj.y(:);

            obj.y = obj.y * obj.params.stepamp + obj.params.stepOffset;
            obj.out.piezocommand = obj.y;
        end
                        
    end % protected methods
    
    methods (Static)
    end
end % classdef