classdef ReferenceChannelAcquisition < Device
    
    properties (Constant)
    end
    
    properties (Hidden, SetAccess = protected)
    end
    
    properties 
        deviceName = 'ReferenceChannelAcquisition';
    end
    
    properties (SetAccess = protected)
    end
    
    events
        Abort
        Override
        ControlFlag
    end
    
    methods
        function obj = ReferenceChannelAcquisition(varargin)
            obj.inputLabels = {'refchan'};
            obj.inputUnits = {'V'};
            obj.inputPorts = [3];
        end
        
        function in = transformInputs(obj,in,varargin)
            %multiply Inputs by micron/volts
        end
        
        function out = transformOutputs(obj,out,varargin)
            % 
        end
        
    end
    
    methods (Access = protected)
        function setupDevice(obj)
        end
                
        function defineParameters(obj)
            obj.params.refchanAI = 3;
        end
    end
end
