classdef TwoTrodeRig < TwoAmpRig
    % current hierarchy:
    
    properties (Constant)
        rigName = 'TwoTrodeRig';
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
        
        function obj = TwoTrodeRig(varargin)

        end
        
        
    end


    methods (Access = protected)
        
        
    end
end

