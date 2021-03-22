% Control the Epifluorescence, control displacements
classdef ControlProtocol < FlySoundProtocol

    properties
    end
    
    properties (Constant,Abstract)
        stimulusHash
    end
    
    properties (SetAccess = protected)
    end
        
    events
    end
    
    methods
        
        function obj = ControlProtocol(varargin)
            ...            
        end
                
    end % methods
    
    methods (Access = protected)        
    end % protected methods
    
    methods (Static)
    end
end % classdef
