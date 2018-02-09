% Inject current steps, control steps, stimDurInSec
classdef CurrentChirp < FlySoundProtocol

    properties (Constant)
        protocolName = 'CurrentChirp';
    end
    
    properties (SetAccess = protected)
        requiredRig = 'BasicEPhysRig';  %CameraEPhysRig BasicEPhysRig
        analyses = {}; %'average', 'dFoverF'
    end

    
    properties (Hidden)
    end
    
    % The following properties can be set only by class methods
    properties (SetAccess = private)
    end
    
    events
    end
    
    methods
        
        function obj = CurrentChirp(varargin)
            % In case more construction is needed
            obj = obj@FlySoundProtocol(varargin{:});
            if strcmp('off', getacqpref('AcquisitionHardware','cameraToggle'));
                obj.analyses = obj.analyses(~strcmp(obj.analyses,'dFoverF'));
            end
        end
        
        function varargout = getStimulus(obj,varargin)
            stimpnts = round(obj.params.samprateout*obj.params.preDurInSec+1:...
                obj.params.samprateout*(obj.params.preDurInSec+obj.params.stimDurInSec));
            
            standardstim = chirp(obj.x(stimpnts),obj.params.freqStart,obj.params.stimDurInSec,obj.params.freqEnd);
            obj.out.current(stimpnts) = obj.y(stimpnts) .* standardstim;
            obj.out.current = obj.out.current*obj.params.amp;
            varargout = {obj.out};
        end
                        
    end % methods
    
    methods (Access = protected)
                                
        function defineParameters(obj)
            obj.params.sampratein = 50000;
            obj.params.samprateout = 50000;
            obj.params.Vm_id = 0;
            
            obj.params.amps = [10 20 40];
            obj.params.amp = obj.params.amps(1);

            obj.params.ramptime = 0.04; %sec;

            obj.params.freqStart = 17;
            obj.params.freqEnd = 800;
            
            obj.params.stimDurInSec = 10;
            obj.params.preDurInSec = .5;
            obj.params.postDurInSec = .5;

            obj.params.durSweep = obj.params.stimDurInSec+obj.params.preDurInSec+obj.params.postDurInSec;
            obj.params = obj.getDefaults;

        end
        
        function setupStimulus(obj,varargin)
            setupStimulus@FlySoundProtocol(obj);
            obj.params.amp = obj.params.amps(1);

            obj.params.durSweep = obj.params.stimDurInSec+obj.params.preDurInSec+obj.params.postDurInSec;
            obj.x = makeOutTime(obj);
            obj.x = obj.x(:);

            y = makeOutTime(obj);
            y = y(:);
            y(:) = 0;

            stimpnts = round(obj.params.samprateout*obj.params.preDurInSec+1:...
                obj.params.samprateout*(obj.params.preDurInSec+obj.params.stimDurInSec));
            
            w = window(@triang,2*obj.params.ramptime*obj.params.samprateout);
            w = [w(1:obj.params.ramptime*obj.params.samprateout);...
                ones(length(stimpnts)-length(w),1);...
                w(obj.params.ramptime*obj.params.samprateout+1:end)];

            y(stimpnts) = w;
            obj.y = y;

            obj.out.current = obj.y;
        end
        
        
    end % protected methods
    
    methods (Static)
    end
end % classdef