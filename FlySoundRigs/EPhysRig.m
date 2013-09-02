classdef EPhysRig < Rig
    
    properties (Constant,Abstract)
        rigName;
        IsContinuous;
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
                obj.addDevice('amplifier','AxoPatch200B');
            end
        end
        
        function in = run(obj,protocol,varargin)
            obj.devices.amplifier.getmode;
            obj.devices.amplifier.getgain;
            in = run@Rig(obj,protocol,varargin{:});
        end
    end
    
    
    
    methods (Access = protected)
    end
end
