% Drive piezo with frequency sweep, control displacements, freqStart,
% freqEnd, stimDurInSec
classdef SpeakerChirp < FlySoundProtocol
    
    properties (Constant)
        protocolName = 'SpeakerChirp';
    end
    
    properties (SetAccess = protected)
        requiredRig = 'ImagingSpeakerRig';
        analyses = {};
    end
    
    % The following properties can be set only by class methods
    properties (SetAccess = private)
    end
    
    events
    end
    
    methods
        
        function obj = SpeakerChirp(varargin)
            obj = obj@FlySoundProtocol(varargin{:});
        end
        
        function varargout = getStimulus(obj,varargin)
            stimpnts = round(obj.params.samprateout*obj.params.preDurInSec+1:...
                obj.params.samprateout*(obj.params.preDurInSec+obj.params.stimDurInSec));
            
            standardstim = chirp(obj.x(stimpnts),obj.params.freqStart,obj.params.stimDurInSec,obj.params.freqEnd);
            obj.out.speakercommand(stimpnts) = obj.y(stimpnts) .* standardstim;
            
            if max(obj.out.speakercommand > 10) || min(obj.out.speakercommand < -10)
                notify(obj,'StimulusProblem',StimulusProblemData('StimulusOutsideBounds'))
            end
            
            obj.out.speakercommand = obj.out.speakercommand * obj.params.displacement;

            varargout = {obj.out,...
                obj.out.speakercommand};
        end
        
    end % methods
    
    methods (Access = protected)
        
        function defineParameters(obj)
            % rmpref('defaultsPiezoCourtshipSong')
            obj.params.displacementOffset = 5;
            obj.params.sampratein = 50000;
            obj.params.samprateout = 50000;
            % [stim,obj.params.samprateout] = wavread('CourtshipSong.wav');
            % stim = flipud(stim);
            
            obj.params.sampratein = obj.params.samprateout;
            obj.params.displacements = .1;
            obj.params.displacement = obj.params.displacements(1);

            obj.params.ramptime = 0.04; %sec;
            
            obj.params.freqStart = 25;
            obj.params.freqEnd = 800;
            
            obj.params.stimDurInSec = 10;
            obj.params.preDurInSec = .5;
            obj.params.postDurInSec = .5;
            
            obj.params.durSweep = obj.params.stimDurInSec+obj.params.preDurInSec+obj.params.postDurInSec;
            
            obj.params.Vm_id = 0;
            
            obj.params = obj.getDefaults;
        end
        
        function setupStimulus(obj,varargin)
            setupStimulus@FlySoundProtocol(obj);
            obj.params.displacement = obj.params.displacements(1);
            
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
            
            % Allocate
            obj.out.speakercommand = y;
        end
    end % protected methods
    
    methods (Static)
    end
end % classdef
