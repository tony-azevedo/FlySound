% Inject voltage steps to check the seal and the input resistance
classdef SealAndLeak < FlySoundProtocol
    
    properties (Constant)
        protocolName = 'SealAndLeak';
    end
    
    properties (SetAccess = protected)
        requiredRig = 'BasicEPhysRig';
        analyses = {'calculateSealMeasurements'};
    end
    
    properties (Hidden)
    end
    
    properties (SetAccess = private)
    end
    
    events
    end
    
    methods
        
        function obj = SealAndLeak(varargin)
            % In case more construction is needed
            obj = obj@FlySoundProtocol(varargin{:});
        end

        function varargout = getStimulus(obj,varargin)
            varargout = {obj.out,obj.x};
        end
        
        function status = adjustRig(obj,rig)
            adjustRig@FlySoundProtocol(obj,rig);
            status = 1;
            rig.setParams('testvoltagestepamp',0);
            rig.setParams('teststep_start',0);
            rig.setParams('teststep_dur',0);
        end

    end % methods
    
    methods (Access = protected)
                                
        function defineParameters(obj)
            % rmpref('defaultsSealAndLeak')
            obj.params.sampratein = 50000;
            obj.params.samprateout = 50000;
            obj.params.stepamp = 5; %mV;
            obj.params.stepdur = 0.01; %sec;
            obj.params.pulses = 20;
            obj.params.durSweep = obj.params.stepdur*(2*obj.params.pulses+2);
            
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

            obj.y = obj.y * obj.params.stepamp;
            obj.out.voltage = obj.y;
        end
    end % protected methods
    
    methods (Static)
    end
end % classdef


