classdef ContinuousRig < Rig
    
    properties (Constant,Abstract)
        rigName;
    end
    
    properties (Constant)
        IsContinuous = true;
    end

    properties (Hidden, SetAccess = protected)
    end
    
    properties (SetAccess = protected)
    end
    
    events
        %InsufficientFunds, notify(BA,'InsufficientFunds')
    end
    
    methods
        function obj = ContinuousRig(varargin)
            ...
        end
    end
    
    methods (Abstract)
        stop(obj)
    end
end
