% Drive piezo with noise stimuli, control displacements, random

classdef PiezoNoise < PiezoProtocol
    
    properties (Constant)
        protocolName = 'PiezoNoise';
    end
    
    properties (SetAccess = protected)
        requiredRig = 'PiezoRig';
        analyses = {};
    end
    
    % The following properties can be set only by class methods
    properties (SetAccess = private)
    end
    
    events
    end
    
    methods
        
        function obj = PiezoNoise(varargin)
            obj = obj@PiezoProtocol(varargin{:});
            p = inputParser;
            p.addParameter('modusOperandi','Run',...
                @(x) any(validatestring(x,{'Run','Stim','Cal'})));
            parse(p,varargin{:});
            obj.modusOperandi = p.Results.modusOperandi;

            if strcmp(p.Results.modusOperandi,'Cal')
                notify(obj,'StimulusProblem',StimulusProblemData('CalibratingStimulus'))
            end

        end
        
        function varargout = getStimulus(obj,varargin)
            stimpnts = round(obj.params.samprateout*obj.params.preDurInSec+1:...
                obj.params.samprateout*(obj.params.preDurInSec+obj.params.stimDurInSec));
            
            standardstim = chirp(obj.x(stimpnts),obj.params.freqStart,obj.params.stimDurInSec,obj.params.freqEnd);
            obj.uncorrectedcommand(stimpnts) = obj.y(stimpnts) .* standardstim;
            calstim = obj.uncorrectedcommand;

            stimfn = which([obj.getCalibratedStimulusFileName,'.wav']);
            if ~isempty(stimfn)
                [stim,obj.params.samprateout] = audioread([obj.getCalibratedStimulusFileName,'.wav']);
                calstim(obj.x>=0 & obj.x <obj.params.stimDurInSec) = ...
                    obj.y(obj.x>=0 & obj.x <obj.params.stimDurInSec) .* ...
                    stim(1:obj.params.stimDurInSec*obj.params.samprateout);
            else
                % otherwise, figure out what to do
                obj.treatUncalibratedStimulus
            end
            
            if max(calstim > 10) || min(calstim < 0)
                notify(obj,'StimulusProblem',StimulusProblemData('StimulusOutsideBounds'))
            end
            
            obj.out.piezocommand = calstim * obj.params.displacement + obj.params.displacementOffset;
            obj.out.speakercommand = obj.y .* obj.uncorrectedcommand;

            varargout = {obj.out,...
                obj.out.piezocommand,...
                obj.out.speakercommand * obj.params.displacement + obj.params.displacementOffset};
        end
        
        function varargout = getCalibratedStimulus(obj)
            varargout{1} = obj.uncorrectedcommand * obj.params.displacement + obj.params.displacementOffset;
        end
        
        function fn = getCalibratedStimulusFileName(obj)
            fn = ['C:\Users\Anthony Azevedo\Code\FlySound\Rig Calibration\',...
                sprintf('%s_sdis%.0f_freqS%.0f_freqE%.0f',...
                obj.protocolName,...
                obj.params.stimDurInSec,...
                obj.params.freqStart,...
                obj.params.freqEnd)];
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
            obj.params.stddisplacements = .2;
            obj.params.displacement = obj.params.displacements(1);

            obj.params.ramptime = 0.04; %sec;
            
            obj.params.seed = 25;
            obj.params.besselN = 8;
            obj.params.besselW0 = 800;
            
            obj.params.stimDurInSec = 30;
            obj.params.preDurInSec = 2;
            obj.params.postDurInSec = 2;
            
            obj.params.durSweep = obj.params.stimDurInSec+obj.params.preDurInSec+obj.params.postDurInSec;
            
            obj.params.Vm_id = 0;
            
            obj.params = obj.getDefaults;
        end
        
        function setupStimulus(obj,varargin)
            setupStimulus@FlySoundProtocol(obj);
            obj.params.displacement = obj.params.displacements(1);
            stimfn = which([obj.getCalibratedStimulusFileName,'.wav']);
            if ~isempty(stimfn)
                [~,obj.params.samprateout] = audioread([obj.getCalibratedStimulusFileName,'.wav']);
            end
            
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
            obj.out.piezocommand = y;
            obj.uncorrectedcommand = y;
        end
    end % protected methods
    
    methods (Static)
    end
end % classdef
