classdef Epi2TRig < TwoAmpRig
    % current hierarchy:
    
    properties (Constant)
        rigName = 'Epi2TRig';
        IsContinuous = false;
    end
    
    methods
        function obj = Epi2TRig(varargin)
            % setacqpref('AcquisitionHardware','LightStimulus','LED_Red')
            % 'Epiflourescence'
            lightstim = getacqpref('AcquisitionHardware','LightStimulus');
            switch lightstim
                case 'LED_Red'
                    obj.addDevice('epi','LED_Red');
                case 'LED_Blue'
                    obj.addDevice('epi','LED_Blue');
                case 'LED_Bath'
                    obj.addDevice('epi','LED_Bath');
                case 'LED_Arduino'
                    obj.addDevice('epi','LED_Arduino');
                    addlistener(obj.devices.epi,'ControlFlag',@obj.setArduinoControl);
                    addlistener(obj.devices.epi,'Abort',@obj.turnOffEpi);
                    addlistener(obj,'EndRun',@obj.turnOffEpi);
            end
        end
        

    end
    
    methods (Access = protected)
    end
end
