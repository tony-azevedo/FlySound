classdef ForceProbe2TRig < TwoAmpRig
    % current hierarchy:
    
    properties (Constant)
        rigName = 'ForceProbe2TRig';
        IsContinuous = false;
    end
    
    properties (Hidden, SetAccess = protected)
    end
    
    properties (SetAccess = protected)
    end
    
    events
        %InsufficientFunds, notify(BA,'InsufficientFunds')
    end
    
    methods
        
        function obj = ForceProbe2TRig(varargin)
            obj.addDevice('forceprobe','Position_Arduino')
        end
        
        
    end


    methods (Access = protected)
        
        
    end
end

