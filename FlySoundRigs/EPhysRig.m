classdef EPhysRig < Rig
    
    properties (Constant,Abstract)
        rigName;
    end
    
    properties (Hidden, SetAccess = protected)
    end
    
    properties (SetAccess = protected)
    end
    
    events
        %InsufficientFunds, notify(BA,'InsufficientFunds')
    end
    
    methods
        function obj = EPhysRig(varargin)
            % setpref('AcquisitionHardware','Amplifier','Amplifier') % AxoClamp2B
            acqhardware = getpref('AcquisitionHardware');
            if isfield(acqhardware,'Amplifier')
                obj.addDevice('amplifier',acqhardware.Amplifier);
            else
                obj.addDevice('amplifier','Amplifier');
            end
        end
    end
    
    methods (Access = protected)
    end
end
