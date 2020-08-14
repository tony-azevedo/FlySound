classdef FB2TRig < TwoAmpRig & EpiOrLEDRig
    % current hierarchy:
    
    properties (Constant)
        rigName = 'FB2TRig';
        IsContinuous = false;
    end
    
    methods
        function obj = FB2TRig(varargin)
            % Just add the arduino (used to depend on light
            obj.addDevice('epi','LED_Arduino');
            addlistener(obj.devices.epi,'ControlFlag',@obj.setArduinoControl);
            addlistener(obj.devices.epi,'Abort',@obj.turnOffEpi);
            addlistener(obj,'EndRun',@obj.turnOffEpi);
            
            % 
            obj.addDevice('forceprobe','Position_Arduino')
        end
        

    end
    
    methods (Access = protected)
    end
end
