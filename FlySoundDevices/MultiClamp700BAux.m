classdef MultiClamp700BAux < MultiClamp700B
    
    properties
    end
    
    properties (SetAccess = protected)
    end

    properties (Hidden, SetAccess = protected)
    end
    
    methods
        function obj = MultiClamp700BAux(varargin)
            obj = obj@MultiClamp700B(varargin{:});
            obj.deviceName = 'MultiClamp700BAux';

            % This and the transformInputs function are hard coded
            obj.inputLabels = {'primary','secondary'};
            obj.inputUnits = {'mV','pA'};
            obj.inputPorts = [2 5];
            obj.outputLabels = {'scaled'};
            obj.outputUnits = {'pA'};
            obj.outputPorts = 2;

            obj.setModeSession;
            obj.mode = 'VClamp';
            obj.getmode;
            obj.setGainSession;
            obj.getgain;

        end            
        
    end

    methods (Static)
        function mccmode = subclassModeFunction
            tic
            fprintf(1,'\nGetting %s mode:\n',mfilename);
            mccmode = MCCGetModeAux;
            toc
        end
        
        function varargout = subclassGainFunction
            tic
            fprintf(1,'\nGetting %s gain:\n',mfilename);
            [gain1,primarySignal,gain2,secondarySignal] = MCCGetGainAux;
            varargout = {gain1,primarySignal,gain2,secondarySignal};
            toc
        end
    end

end
