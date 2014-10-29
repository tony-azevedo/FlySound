classdef TwoPhotonSystem < Device
    
    properties (Constant)
        
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
        function obj = TwoPhotonSystem(varargin)
            obj.deviceName = 'TwoPhotonSystem';
            % This and the transformInputs function are hard coded
            
            obj.inputLabels = {'mirrorslow','mirrorfast'};%'exposure'};
            obj.inputUnits = {'V','V'};
            obj.inputPorts = [8,9];
            obj.outputLabels = {'trigger'};%,'shutter'};
            obj.outputUnits = {'V'};
            obj.outputPorts = [1];% 3];
        end
        
        function varargout = transformInputs(obj,inputstruct)
            units = {};
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
