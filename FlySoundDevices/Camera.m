classdef Camera < Device
    
    properties (Constant)
        deviceName = 'Camera';
    end
    
    properties (Hidden, SetAccess = protected)
    end
    
    properties (SetAccess = protected)
        gaincorrection
    end
    
    events
        %
    end
    
    methods
        function obj = Camera(varargin)
            % This and the transformInputs function are hard coded
            
            obj.inputLabels = {'exposure'};
            obj.inputUnits = {'V'};
            obj.inputPorts = 18;
            obj.outputLabels = {'trigger','shutter'};
            obj.outputUnits = {'V'};
            obj.outputPorts = [1 3];
        end
        
        function varargout = transformInputs(obj,inputstruct)
            inlabels = fieldnames(inputstruct);
            units = {};
            for il = 1:length(inlabels)
                if strcmp(inlabels{il},'exposure')
                    units = {'bit'};
                   
                    inputstruct.exposure = inputstruct.exposure > 2.5;
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
                
        function defineParameters(obj)
            obj.params.setup = 'x Frames, write in the rest of the information';
        end
    end
end
