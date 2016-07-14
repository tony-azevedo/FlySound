classdef PGRCamera < Device
    
    properties (Constant)
        
    end
    
    properties (Hidden, SetAccess = protected)
    end
    
    properties (SetAccess = protected)
        gaincorrection
    end
    
    properties
        deviceName = 'Camera';
    end

    events
        %
    end
    
    methods
        function obj = PGRCamera(varargin)
            % This and the transformInputs function are hard coded
            
            obj.digitalInputLabels = {'exposure'};
            obj.digitalInputUnits = {'Bit'};
            obj.digitalInputPorts = 'Port0/Line0';
            obj.digitalOutputLabels = {'trigger'};
            obj.digitalOutputUnits = {'Bit'};
            obj.digitalOutputPorts = 'Port0/Line2';
        end
        
        function varargout = transformInputs(obj,inputstruct)
            inlabels = fieldnames(inputstruct);
            units = {};
            for il = 1:length(inlabels)
                if strcmp(inlabels{il},'exposure')
                    units = {'bit'};
                   
                    inputstruct.exposure = inputstruct.exposure > 0.5;
                    inputstruct.exposure = ...
                        [inputstruct.exposure(2:end) - inputstruct.exposure(1:end-1); 0];
                    inputstruct.exposure = inputstruct.exposure > 0;
                end
            end
            varargout = {inputstruct,units};
        end
        
        function out = transformOutputs(obj,out)
            %multiply outputs by volts/micron
        end
    
    end
    
    methods (Access = protected)
        function setupDevice(obj)        
        end

        function defineParameters(obj)
            obj.params.setup = 'x Frames, write in the rest of the information';
        end
    end
end
