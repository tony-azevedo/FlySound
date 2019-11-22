classdef PiezoArduino2TRig < TwoAmpRig
    % current hierarchy:
    
    properties (Constant)
        rigName = 'PiezoArduino2TRig';
        IsContinuous = false;
    end
    
    methods
        function obj = PiezoArduino2TRig(varargin)
            obj.addDevice('arduino','Arduino');
            obj.addDevice('triggeredpiezo','TriggeredPiezo');
        end

    end
    
    methods (Access = protected)
    end
end
