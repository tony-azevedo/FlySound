classdef Epi2TRig < TwoAmpRig
    % current hierarchy:
    
    properties (Constant)
        rigName = 'Epi2TRig';
        IsContinuous = false;
    end
    
    methods
        function obj = Epi2TRig(varargin)
            % setpref('AcquisitionHardware','LightStimulus','LED_Red')
            % 'Epiflourescence'
            lightstim = getpref('AcquisitionHardware','LightStimulus');
            switch lightstim
                case 'LED_Red'
                    obj.addDevice('epi','LED_Red');
                case 'LED_Blue'
                    obj.addDevice('epi','LED_Blue');
                case 'LED_Bath'
                    obj.addDevice('epi','LED_Bath');
            end
        end
        

    end
    
    methods (Access = protected)
    end
end
