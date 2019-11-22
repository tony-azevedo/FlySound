classdef LED_Arduino < Device
    
    properties (Constant)
    end
    
    properties (Hidden, SetAccess = protected)
    end
    
    properties 
        deviceName = 'LED_Arduino';
    end
    
    properties (SetAccess = protected)
    end
    
    events
        Abort
    end
    
    methods
        function obj = LED_Arduino(varargin)
            % This and the transformInputs function are hard coded
            
            obj.inputLabels = {};
            obj.inputUnits = {};
            obj.inputPorts = [];
%             obj.outputLabels = {'epicommand'};
%             obj.outputUnits = {'V'};
%             obj.outputPorts = [3];
            obj.digitalOutputLabels = {'epittl','abort','control'};
            obj.digitalOutputUnits = {'Bit','Bit','Bit'};
            obj.digitalOutputPorts = [31,29,28];
            obj.digitalInputLabels = {'arduino_output'};
            obj.digitalInputUnits = {'Bit'};
            obj.digitalInputPorts = [30];
        end
        
        function in = transformInputs(obj,in,varargin)
            %multiply Inputs by micron/volts
        end
        
        function out = transformOutputs(obj,out,varargin)
            %multiply outputs by volts/micron
            %out.epittl = 1-out.epittl; 
            out.epittl = out.epittl;
            out.control = out.control;
            % Assumes 0 is off, 1 is on, need to flip the bit for Lambda
            % but not for Arduino
        end

        function abort(obj,varargin)
            notify(obj,'Abort')
        end

        
    end
    
    methods (Access = protected)
        function setupDevice(obj)
        end
                
        function defineParameters(obj)
            obj.params.controlToggle = 10/30;
        end
    end
end
