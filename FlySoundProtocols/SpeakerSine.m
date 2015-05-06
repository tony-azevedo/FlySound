% Move the Piezo to with sine waves, control displacements, freqs, ramptime
classdef SpeakerSine < FlySoundProtocol
    properties (Constant)
        protocolName = 'SpeakerSine';
    end
    
    properties (SetAccess = protected)
        requiredRig = 'ImagingSpeakerRig';
        analyses = {};
    end
    
    % The following properties can be set only by class methods
    properties (SetAccess = private)
        gaincorrection  % set this property when setting up the stimulus, 
    end
    
    events
    end
    
    methods
        
        function obj = SpeakerSine(varargin)
            obj = obj@FlySoundProtocol(varargin{:});
            p = inputParser;
        end
        
        function varargout = getStimulus(obj,varargin)
            calstim = obj.y .* sin(2*pi*obj.params.freq*obj.x);
            
            
            if max(calstim > 10) || min(calstim < -10)
                notify(obj,'StimulusProblem',StimulusProblemData('StimulusOutsideBounds'))
            end
            
            obj.out.speakercommand = calstim .* obj.params.displacement;

            varargout = {...
                obj.out,...
                calstim};
        end
        
                        
    end % methods
    
    methods (Access = protected)
        
        function defineParameters(obj)
            % rmpref('defaultsPiezoSine')
            obj.params.displacementOffset = 5;
            obj.params.sampratein = 50000;
            obj.params.samprateout = 50000;
            obj.params.displacements = 0.05*sqrt(2).^(0:6);
            obj.params.displacement = obj.params.displacements(1);
            
            obj.params.ramptime = 0.04; %sec;
            
            % obj.params.cycles = 10;
            obj.params.freq = 25; % Hz
            obj.params.freqs = 25 * sqrt(2) .^ (0:10);
            obj.params.stimDurInSec = 2; % obj.params.cycles/obj.params.freq;
            obj.params.preDurInSec = .4;
            obj.params.postDurInSec = .3;
            obj.params.durSweep = obj.params.stimDurInSec+obj.params.preDurInSec+obj.params.postDurInSec;
            
            obj.params.Vm_id = 0;
            
            obj.params = obj.getDefaults;
        end
        
        function setupStimulus(obj,varargin)
            setupStimulus@FlySoundProtocol(obj);
            obj.params.durSweep = obj.params.stimDurInSec+obj.params.preDurInSec+obj.params.postDurInSec;
            
            obj.params.freq = obj.params.freqs(1);
            
            obj.x = makeOutTime(obj);
            obj.x = obj.x(:);
            obj.params.displacement = obj.params.displacements(1);
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
            
            % Allocate
            obj.out.speakercommand = y;
        end
    end % protected methods
    
    methods (Static)
    end
end % classdef
