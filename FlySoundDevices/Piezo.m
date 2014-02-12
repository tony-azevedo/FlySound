classdef Piezo < Device
    
    properties (Constant)
        deviceName = 'Piezo';
    end
    
    properties (Hidden, SetAccess = protected)
    end
    
    properties (SetAccess = protected)
        gaincorrection
    end
    
    events
        %InsufficientFunds, notify(BA,'InsufficientFunds')
    end
    
    methods
        function obj = Piezo(varargin)
            % This and the transformInputs function are hard coded
            
            obj.inputLabels = {'sgsmonitor'};
            obj.inputUnits = {'V'};
            obj.inputPorts = 2;
            obj.outputLabels = {'piezocommand'};
            obj.outputUnits = {'V'};
            obj.outputPorts = [2];
        end
        
        function in = transformInputs(obj,in)
            %multiply Inputs by micron/volts
        end
        
        function out = transformOutputs(obj,out)
            %multiply outputs by volts/micron
        end
    
    end
    
    methods (Access = protected)
                
        function defineParameters(obj)
            obj.params.voltsPerMicron = 10/30;
        end
    end
end
