classdef PiezoStep < FlySoundProtocol
    properties (Hidden)
        
    end
    
    properties (SetAccess = private)
        piezo_type = 'Physik Instrumente, P-841.2';
        staticDisp = 5; % TODO: I want to be able to use -10 + 10V
        % staticDisp = static voltage output to piezo; should usually be set to 5V
        % so that the medial and lateral directions can be used equally
        % AO = analogoutput ('nidaq', 'Dev1');
    end
    % Define an event called InsufficientFunds
    events
        %InsufficientFunds
    end
    methods
        function obj = PiezoStep(varargin)
            obj = obj@FlySoundProtocol(varargin{:});
            obj.piezo_type = 'Physik Instrumente, P-841.2';

        end

        function uncapitalizedStandardMethod(obj)
        end
    end
end