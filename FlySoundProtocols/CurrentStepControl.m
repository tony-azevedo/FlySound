% Inject current steps, control steps, stimDurInSec
classdef CurrentStepControl < ControlProtocol

    properties (Constant)
        protocolName = 'CurrentStepControl';
        stimulusHash = .7;
    end
    
    properties (SetAccess = protected)
        requiredRig = 'OneTrodeControlRig';  %CameraEPhysRig BasicEPhysRig
        analyses = {}; %'average', 'dFoverF'
    end

    
    properties (Hidden)
    end
    
    % The following properties can be set only by class methods
    properties (SetAccess = private)
    end
    
    events
    end
    
    methods
        
        function obj = CurrentStepControl(varargin)
            % In case more construction is needed
            obj = obj@ControlProtocol(varargin{:});
        end
        
        function varargout = getStimulus(obj,varargin)
            obj.out.refchan(1:end-1) = obj.stimulusHash;
            obj.out.current = obj.y * obj.params.step;
            varargout = {obj.out};
        end
                        
    end % methods
    
    methods (Access = protected)
                                
        function defineParameters(obj)
            % rmacqpref('defaultsCurrentStep_Control')
            obj.params.sampratein = 50000;
            obj.params.samprateout = 50000;
            obj.params.Vm_id = 0;
            
            obj.params.steps = [-.25 .25 5 1]*100;
            obj.params.step = obj.params.steps(1);
            
            obj.params.stimDurInSec = 0.5;
            obj.params.preDurInSec = 0.5;
            obj.params.postDurInSec = 1.5;
            obj.params.durSweep = obj.params.stimDurInSec+obj.params.preDurInSec+obj.params.postDurInSec;
            obj.params = obj.getDefaults;
            obj.params.stimhashval = obj.stimulusHash;
        end
        
        function setupStimulus(obj,varargin)
            setupStimulus@FlySoundProtocol(obj);
            obj.params.step = obj.params.steps(1);

            obj.params.durSweep = obj.params.stimDurInSec+obj.params.preDurInSec+obj.params.postDurInSec;
            obj.x = makeTime(obj);
            obj.y = zeros(size(obj.x));
            obj.y(...
                round(obj.params.samprateout*(obj.params.preDurInSec))+1:...
                round(obj.params.samprateout*(obj.params.preDurInSec+obj.params.stimDurInSec))) = 1;
            obj.out.current = obj.y;
            obj.out.refchan = obj.y*0;
        end
        
        
    end % protected methods
    
    methods (Static)
    end
end % classdef