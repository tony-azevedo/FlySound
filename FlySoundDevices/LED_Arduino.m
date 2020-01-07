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
        ControlFlag
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
            out.control = 0.*out.epittl+obj.params.controlToggle;
        end
        
        function setParams(obj,varargin)
            setParams@Device(obj,varargin{:})
            notify(obj,'ControlFlag')
        end

        function abort(obj,varargin)
            notify(obj,'Abort')
        end

        
    end
    
    methods (Access = protected)
        function setupDevice(obj)
        end
                
        function defineParameters(obj)
            obj.params.controlToggle = 0;
        end
    end
end
