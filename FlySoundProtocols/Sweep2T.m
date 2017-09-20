
% Collect data
classdef Sweep2T < FlySoundProtocol
    
    properties (Constant)
        protocolName = 'Sweep2T';
    end
    
    properties (SetAccess = protected)
        requiredRig = 'TwoTrodeRig';
        analyses = {};
    end
    
    properties (SetAccess = protected)
    end

    
    methods
        
        function obj = Sweep2T(varargin)
        end
        
        function varargout = getStimulus(obj,varargin)
            varargout = {obj.out,obj.x};
        end
        
    end % methods
    
    methods (Access = protected)
                        
        function defineParameters(obj)
            obj.params.sampratein = 10000;
            obj.params.samprateout = 10000;
            obj.params.durSweep = 5;
            obj.params.holdingCurrent = 0;
            obj.params.holdingPotential = 0;
            obj.params = obj.getDefaults;
        end
       
        function setupStimulus(obj,varargin)
            obj.x = makeOutTime(obj);
            if obj.params.holdingPotential ~= 0 && obj.params.holdingCurrent ~= 0
                obj.params.holdingPotential = 0;
                obj.params.holdingCurrent = 0;                
            end
            obj.out.voltage_1 = ones(size(obj.x))*obj.params.holdingPotential;
            obj.out.current_1 = ones(size(obj.x))*obj.params.holdingCurrent;
        end
                
    end % protected methods
    
    methods (Static)
    end
end % classdef
