classdef LED_Arduino_Acquisition < Device
    
    properties (Constant)
    end
    
    properties (Hidden, SetAccess = protected)
    end
    
    properties 
        deviceName = 'LED_Arduino_Acquisition';
    end
    
    properties (SetAccess = protected)
    end
    
    events
        Abort
        Override
        ControlFlag
    end
    
    methods
        function obj = LED_Arduino_Acquisition(varargin)
            % This and the transformInputs function are hard coded
            
            obj.inputLabels = {};
            obj.inputUnits = {};
            obj.inputPorts = [];
%             obj.outputLabels = {'epicommand'};
%             obj.outputUnits = {'V'};
%             obj.outputPorts = [3];
            %obj.digitalOutputLabels = {'epittl','abort','control'};
            %obj.digitalOutputUnits = {'Bit','Bit','Bit'};
            %obj.digitalOutputPorts = [31,29,28];
            obj.digitalInputLabels = {'arduino_output'}; %,'trial_duration'};
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

        function override(obj,varargin)
            notify(obj,'Override')
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
