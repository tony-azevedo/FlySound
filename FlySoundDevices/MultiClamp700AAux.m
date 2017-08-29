classdef MultiClamp700AAux < MultiClamp700A
    
    properties
    end
    
    properties (SetAccess = protected)
    end

    properties (Hidden, SetAccess = protected)
    end
    
    methods
        function obj = MultiClamp700AAux(varargin)
            obj = obj@MultiClamp700A(varargin{:});
            obj.deviceName = 'MultiClamp700AAux';

            % This and the transformInputs function are hard coded
            obj.inputLabels = {'primary','secondary'};
            obj.inputUnits = {'mV','pA'};
            obj.inputPorts = [2 4];
            obj.outputLabels = {'scaled'};
            obj.outputUnits = {'pA'};
            obj.outputPorts = 1;

            obj.setModeSession;
            obj.mode = 'VClamp';
            obj.getmode;
            obj.setGainSession;
            obj.getgain;

        end
        
    end

    
    methods (Static)
        %         function mccmode = subclassModeFunction
        %             tic
        %             fprintf(1,'\nGetting %s mode:\n',mfilename);
        %             mccmode = MCCGetModeAux;
        %             toc
        %         end
        %
        %         function varargout = subclassGainFunction
        %             tic
        %             fprintf(1,'\nGetting %s gain:\n',mfilename);
        %             [gain1,primarySignal,gain2,secondarySignal] = MCCGetGainAux;
        %             varargout = {gain1,primarySignal,gain2,secondarySignal};
        %             toc
        %         end
        
        function mccmode = subclassModeFunction
            mccmode = 'mode2';
        end
        
        function varargout = subclassGainFunction
            varargout = {'gain2'};
        end

    end

end
