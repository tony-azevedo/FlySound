% Inject sine wave currents, control freqs, amps, ramptime
classdef CurrentSine < FlySoundProtocol
    
    properties (Constant)
        protocolName = 'CurrentSine';
    end
    
    properties (SetAccess = protected)
        requiredRig = 'BasicEPhysRig';
        analyses = {'average'};
    end
    
    properties (Hidden)
    end
    
    % The following properties can be set only by class methods
    properties (SetAccess = private)
    end
    
    events
    end
    
    methods
        
        function obj = CurrentSine(varargin)
            % In case more construction is needed
            obj = obj@FlySoundProtocol(varargin{:});
        end
        
        function varargout = getStimulus(obj,varargin)
            % obj.out.speakercommand = obj.y .*sin(2*pi*obj.params.freq*obj.x);
            
            obj.out.current = obj.y .*sin(2*pi*obj.params.freq*obj.x) * obj.params.amp;
            varargout = {obj.out};
        end
                        
    end % methods
    
    methods (Access = protected)
                                
        function defineParameters(obj)
            obj.params.sampratein = 50000;
            obj.params.samprateout = 50000;
            obj.params.Vm_id = 0;
            
            obj.params.freqs = 25 * sqrt(2) .^ (0:10);
            obj.params.freq = obj.params.freqs(1); % Hz

            obj.params.ramptime = 0.02; %sec;
            
            obj.params.amps = [10 20 30];
            obj.params.amp = obj.params.amps(1);
            
            obj.params.stimDurInSec = 0.2;
            obj.params.preDurInSec = .5;
            obj.params.postDurInSec = .5;
            obj.params.durSweep = obj.params.stimDurInSec+obj.params.preDurInSec+obj.params.postDurInSec;
            obj.params = obj.getDefaults;

        end
        
        function setupStimulus(obj,varargin)
            setupStimulus@FlySoundProtocol(obj);
            obj.params.freq = obj.params.freqs(1); % Hz
            obj.params.amp = obj.params.amps(1);

            obj.params.durSweep = obj.params.stimDurInSec+obj.params.preDurInSec+obj.params.postDurInSec;
            obj.x = makeTime(obj);
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
            setupStimulus@FlySoundProtocol(obj);

        end
        
        
    end % protected methods
    
    methods (Static)
    end
end % classdef