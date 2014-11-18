% Step to voltages of different values, control plateauDirInSec, plateaux,
% randomize
classdef VoltageCommand < FlySoundProtocol
  
    properties (Constant)
        protocolName = 'VoltageCommand';
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
        
        function obj = VoltageCommand(varargin)
            % In case more construction is needed
            obj = obj@FlySoundProtocol(varargin{:});
            if strcmp('off', getpref('AcquisitionHardware','cameraToggle'));
                obj.analyses = obj.analyses(~strcmp(obj.analyses,'dFoverF'));
            end
        end
        
        function varargout = getStimulus(obj,varargin)
            obj.out.voltage = obj.y;
            varargout = {obj.out};
        end
        
        function fn = getCommandFileName(obj)
            fn = ['C:\Users\Anthony Azevedo\Code\FlySound\CommandWaves\',...
                obj.params.stimulusName];
        end

        function showCommandNames(obj)
            fns = dir('C:\Users\Anthony Azevedo\Code\FlySound\CommandWaves\');
            fns = fns(3:end);
            str = '';
            for fn_ind = 1:length(fns)
                if ~isempty(regexp(fns(fn_ind).name,'Standard', 'once'));
                    continue
                end
                if ~isempty(regexp(fns(fn_ind).name,obj.params.stimulusName, 'once'));
                    str = [str '{' fns(fn_ind).name '}' '\n'];
                else
                    str = [str ' ' fns(fn_ind).name '\n'];
                end
            end
            fprintf(str)
        end

    end % methods
    
    methods (Access = protected)
                                
        function defineParameters(obj)
            % rmpref('defaultsVoltageCommand')
            obj.params.sampratein = 50000;
            obj.params.samprateout = 50000;
            
            obj.params.stimulusName = 'Basic';
            [stim,obj.params.samprateout] = audioread([obj.getCommandFileName '.wav']);
                        
            obj.params.stimDurInSec = length(stim)/obj.params.samprateout;
            obj.params.preDurInSec = .5;
            obj.params.postDurInSec = .5;

            obj.params.durSweep = obj.params.stimDurInSec+...
                obj.params.preDurInSec + ...
                obj.params.postDurInSec;
            obj.params = obj.getDefaults;

        end
        
        function setupStimulus(obj,varargin)
            setupStimulus@FlySoundProtocol(obj);

            [stim,obj.params.samprateout] = audioread([obj.getCommandFileName '.wav']);
            obj.params.stimDurInSec = length(stim)/obj.params.samprateout;

            obj.params.durSweep = obj.params.stimDurInSec+...
                obj.params.preDurInSec + ...
                obj.params.postDurInSec;
            
            obj.x = makeTime(obj);
            obj.x = obj.x(:);

            y = makeOutTime(obj);
            y = y(:);
            y(:) = 0;

            stimpnts = round(obj.params.samprateout*obj.params.preDurInSec+1:...
                obj.params.samprateout*(obj.params.preDurInSec+obj.params.stimDurInSec));

            y(stimpnts) = stim;

            obj.y = zeros(size(obj.x));
            obj.y = y;                        
            
            obj.out.voltage = obj.y;
        end
        
        
    end % protected methods
    
    methods (Static)
    end
end % classdef