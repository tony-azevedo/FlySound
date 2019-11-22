classdef Arduino2TRig < TwoAmpRig
    % current hierarchy:
    
    properties (Constant)
        rigName = 'Arduino2TRig';
        IsContinuous = false;
    end
    
    methods
        function obj = Arduino2TRig(varargin)
            obj.addDevice('arduino','Arduino');
        end

    end
    
    methods (Access = protected)
    end
end
