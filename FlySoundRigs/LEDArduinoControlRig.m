classdef LEDArduinoControlRig < EpiOrLEDRig
    % current hierarchy:
    
    properties (Constant)
        rigName = 'LEDArduinoControlRig';
        IsContinuous = false;
    end
    
    methods
        function obj = LEDArduinoControlRig(varargin)
            % Just add the arduino (used to depend on light
            % obj.addDevice('epi','LED_Arduino');
            obj.addDevice('epi','LED_Arduino_Control')
            addlistener(obj.devices.epi,'ControlFlag',@obj.setArduinoControl);
            addlistener(obj.devices.epi,'RoutineFlag',@obj.setArduinoControl);
            addlistener(obj.devices.epi,'Abort',@obj.turnOffEpi);
            addlistener(obj,'EndRun_Control',@obj.turnOffEpi);
            addlistener(obj,'EndTimer_Control',@obj.turnOffEpi);
            obj.addDevice('refchan','ReferenceChannelControl')
            
            % Don't add the force probe, this will be in the continuous
            % rig
            % obj.addDevice('forceprobe','Position_Arduino')
        end
        

    end
    
    methods (Access = protected)
    end
end
