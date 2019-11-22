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
                    addlistener(obj.devices.epi,'Abort',@obj.turnOffEpi);
                    addlistener(obj,'EndRun',@obj.turnOffEpi);
            end
        end
        

    end
    
    methods (Access = protected)
        function turnOffEpi(obj,callingobj,evntdata,varargin)
            % Now set the abort channel off briefly before turning it back
            % on 
            
            output = obj.aoSession.UserData;
            if isempty(output)
                output = zeros(1,length(obj.outputchannelidx));
                
            else
                output = output.CurrentOutput;
                
            end
            output_a = output;
            for chidx = 1:length(obj.outputchannelidx)
                if contains(obj.aoSession.Channels(obj.outputchannelidx(chidx)).Name,'abort')
                    output_a(chidx) = 1;
                end
            end
            obj.aoSession.outputSingleScan(output_a);
            obj.aoSession.outputSingleScan(output);            
        end
    end
end
