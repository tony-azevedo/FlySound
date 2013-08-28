classdef PiezoRig < EPhysRig
    
    properties (Constant)
        rigName = 'PiezoRig';
    end
    
    
    methods
        function obj = PiezoRig(varargin)
            obj.addDevice('piezo','Piezo');
        end
    end
    
    methods (Access = protected)
    end
end
