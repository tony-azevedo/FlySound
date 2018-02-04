% Step to voltages of different values, control plateauDirInSec, plateaux,
% randomize
classdef VoltagePlateau < FlySoundProtocol
  
    properties (Constant)
        protocolName = 'VoltagePlateau';
    end
    
    properties (SetAccess = protected)
        requiredRig = 'BasicEPhysRig';  %CameraEPhysRig BasicEPhysRig
        analyses = {}; %'average','dFoverF'
    end

    
    properties (Hidden)
    end
    
    % The following properties can be set only by class methods
    properties (SetAccess = private)
    end
    
    events
    end
    
    methods
        
        function obj = VoltagePlateau(varargin)
            % In case more construction is needed
            obj = obj@FlySoundProtocol(varargin{:});
            if strcmp('off', getacqpref('AcquisitionHardware','cameraToggle'));
                obj.analyses = obj.analyses(~strcmp(obj.analyses,'dFoverF'));
            end
        end
        
        function varargout = getStimulus(obj,varargin)
            obj.out.voltage = obj.y;
            varargout = {obj.out};
        end
                        
    end % methods
    
    methods (Access = protected)
                                
        function defineParameters(obj)
            % rmacqpref('defaultsCurrentPlateau')
            obj.params.sampratein = 50000;
            obj.params.samprateout = 50000;
            
            obj.params.plateaux = [-30 -20 -10 0 10 20 30];
            obj.params.plateau = obj.params.plateaux(1);
            
            obj.params.plateauDurInSec = 0.2;
            obj.params.stimDurInSec = obj.params.plateauDurInSec * length(obj.params.plateaux);
            obj.params.preDurInSec = .5;
            obj.params.postDurInSec = .5;

            obj.params.randomize = 0;

            obj.params.durSweep = obj.params.stimDurInSec+...
                obj.params.preDurInSec + ...
                obj.params.postDurInSec;
            obj.params = obj.getDefaults;

        end
        
        function setupStimulus(obj,varargin)
            setupStimulus@FlySoundProtocol(obj);
            obj.params.plateau = obj.params.plateaux(1);
            obj.params.stimDurInSec = obj.params.plateauDurInSec * length(obj.params.plateaux);

            obj.params.durSweep = obj.params.stimDurInSec+...
                obj.params.preDurInSec + ...
                obj.params.postDurInSec;
            obj.x = makeTime(obj);
            
            if obj.params.randomize
                plateaux_vec = obj.params.plateaux(randperm(length(obj.params.plateaux)));
            else
                plateaux_vec = obj.params.plateaux;
            end

            plateaux = ones(...
                obj.params.plateauDurInSec*obj.params.samprateout,...
                length(obj.params.plateaux));
            plateaux = plateaux .* repmat(...
                plateaux_vec,...
                obj.params.plateauDurInSec*obj.params.samprateout,...
                1);
            
            obj.y = zeros(size(obj.x));
            obj.y(...
                obj.params.samprateout*(obj.params.preDurInSec)+1:...
                round(obj.params.samprateout*(obj.params.preDurInSec+obj.params.stimDurInSec)))...
                = plateaux(:)';                        
            
            obj.out.voltage = obj.y;
        end
        
        
    end % protected methods
    
    methods (Static)
    end
end % classdef