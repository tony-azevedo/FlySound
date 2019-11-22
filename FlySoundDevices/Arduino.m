classdef Arduino < Device
    
    properties (Constant)
    end
    
    properties (Hidden, SetAccess = protected)
    end
    
    properties 
        deviceName = 'Arduino';
    end
    
    properties (SetAccess = protected)
        gaincorrection
    end
    
    events
        
    end
    
    methods
        function obj = Arduino(varargin)
            
            obj.inputLabels = {};
            obj.inputUnits = {};
            obj.inputPorts = [];

            obj.digitalOutputLabels = {'ttl'};
            obj.digitalOutputUnits = {'Bit'};
            obj.digitalOutputPorts = [31];
            obj.digitalInputLabels = {'arduino_output'};
            obj.digitalInputUnits = {'Bit'};
            obj.digitalInputPorts = [30];

        end
        
        function in = transformInputs(obj,in,varargin)
            
        end
        
        function out = transformOutputs(obj,out,varargin)
            %out.stimttl = out.stimttl;
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
