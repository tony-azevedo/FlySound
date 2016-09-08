classdef M285 < Device
    
    properties (Constant)
    end
    
    properties (Hidden, SetAccess = protected)
    end
    
    properties 
        deviceName = 'M285';
    end
    
    properties (SetAccess = protected)
        gaincorrection
    end
    
    events
        %InsufficientFunds, notify(BA,'InsufficientFunds')
    end
    
    methods
        function obj = M285(varargin)
            % This and the transformInputs function are hard coded
            
            obj.inputLabels = {'sgsmonitor'};
            obj.inputUnits = {'V'};
            obj.inputPorts = 2;
            obj.outputLabels = {'piezocommand'};
            obj.outputUnits = {'V'};
            obj.outputPorts = [1];
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
            obj.params.voltsPerMicron = 10/30;
        end
    end
end
