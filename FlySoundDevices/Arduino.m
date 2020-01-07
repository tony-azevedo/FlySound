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
        Abort
    end
    
    methods
        function obj = Arduino(varargin)
            
            obj.inputLabels = {};
            obj.inputUnits = {};
            obj.inputPorts = [];

            obj.digitalOutputLabels = {'ttl','abort','control'};
            obj.digitalOutputUnits = {'Bit','Bit','Bit'};
            obj.digitalOutputPorts = [31,29,28];
            obj.digitalInputLabels = {'arduino_output'};
            obj.digitalInputUnits = {'Bit'};
            obj.digitalInputPorts = [30];

        end
        
        function in = transformInputs(obj,in,varargin)
            
        end
        
        function out = transformOutputs(obj,out,varargin)
            %out.ttl = out.ttl;
            out.control = 0.*out.ttl+obj.params.controlToggle;
        end
        
        function abort(obj,varargin)
            notify(obj,'Abort')
        end
        
        function setParams(obj,varargin)
            setParams@Device(obj,varargin{:})
            notify(obj,'ControlFlag')
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
