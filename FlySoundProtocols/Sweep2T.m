% Collect data
classdef Sweep2T < Sweep
    
    properties (Constant)
    end
    
    properties (SetAccess = protected)
    end
    
    properties (SetAccess = protected)
    end

    
    methods
        
        function obj = Sweep2T(varargin)
            obj.requiredRig = 'TwoTrodeRig';
            obj.analyses = {};
        end
        
        function varargout = getStimulus(obj,varargin)
            varargout = {obj.out,obj.x};
        end
        
    end % methods
    
    methods (Access = protected)
                        
        function defineParameters(obj)
            obj.params.sampratein = 50000;
            obj.params.samprateout = 50000;
            obj.params.durSweep = 5;
            obj.params.Vm_id = 0;
            obj.params = obj.getDefaults;
        end
       
        function setupStimulus(obj,varargin)
            obj.x = makeOutTime(obj);
            obj.out.zeros = obj.x;
        end
                
    end % protected methods
    
    methods (Static)
    end
end % classdef
