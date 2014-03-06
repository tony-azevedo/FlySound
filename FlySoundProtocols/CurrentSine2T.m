% Inject sine wave currents into Electrode 1 control freqs, amps, ramptime
classdef CurrentSine2T < CurrentSine
    
    properties (Constant)
    end
    
    properties (SetAccess = protected)
    end
    
    properties (Hidden)
    end
    
    % The following properties can be set only by class methods
    properties (SetAccess = private)
    end
    
    events
    end
    
    methods
        
        function obj = CurrentSine2T(varargin)
            % In case more construction is needed
            obj = obj@CurrentSine(varargin{:});
            obj.requiredRig = 'TwoTrodeRig';
            obj.analyses = {};

        end
        
        function varargout = getStimulus(obj,varargin)
            % obj.out.speakercommand = obj.y .*sin(2*pi*obj.params.freq*obj.x);
            
            obj.out.current_1 = obj.y .*sin(2*pi*obj.params.freq*obj.x) * obj.params.amp;
            varargout = {obj.out};
        end
                        
    end % methods
    
    methods (Access = protected)
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
            obj.out.current_1 = obj.y;
            setupStimulus@FlySoundProtocol(obj);
        end
        
    end % protected methods
    
    methods (Static)
    end
end % classdef