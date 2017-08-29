classdef LED_Bath < Device
    
    properties (Constant)
    end
    
    properties (Hidden, SetAccess = protected)
    end
    
    properties 
        deviceName = 'LED_Bath';
    end
    
    properties (SetAccess = protected)
        gaincorrection
    end
    
    events
        %InsufficientFunds, notify(BA,'InsufficientFunds')
    end
    
    methods
        function obj = LED_Bath(varargin)
            % This and the transformInputs function are hard coded
            
            obj.inputLabels = {};
            obj.inputUnits = {};
            obj.inputPorts = [];
%             obj.outputLabels = {'epicommand'};
%             obj.outputUnits = {'V'};
%             obj.outputPorts = [3];
            obj.digitalOutputLabels = {'epittl'};
            obj.digitalOutputUnits = {'Bit'};
            obj.digitalOutputPorts = [28];

        end
        
        function in = transformInputs(obj,in,varargin)
            %multiply Inputs by micron/volts
        end
        
        function out = transformOutputs(obj,out,varargin)
            %multiply outputs by volts/micron
        end
    
    end
    
    methods (Access = protected)
        function setupDevice(obj)
        end
                
        function defineParameters(obj)
            obj.params.powerPerVolt = 10/30;
        end
    end
end
