% Inject current steps, control steps, stimDurInSec
classdef CurrentStep2T < CurrentStep

    properties (Constant)
    end
    
    properties (SetAccess = protected)
    end

    
    properties (Hidden)
    end
    
    % The following properties can be set only by class methods
    properties (SetAccess = private)
    end
    
    events
    end
    
    methods
        
        function obj = CurrentStep2T(varargin)
            % In case more construction is needed
            obj = obj@CurrentStep(varargin{:});
            obj.requiredRig = 'TwoTrodeRig';  %CameraEPhysRig BasicEPhysRig
            obj.analyses = {}; %'average', 'dFoverF'
            
        end
        
        function varargout = getStimulus(obj,varargin)
            obj.out.current_1 = obj.y * obj.params.step;
            varargout = {obj.out};
        end
                        
    end % methods
    
    methods (Access = protected)
        function setupStimulus(obj,varargin)
            setupStimulus@CurrentStep(obj);
            obj.out = rmfield(obj.out,'current');
        end
                
    end % protected methods
    
    methods (Static)
    end
end % classdef