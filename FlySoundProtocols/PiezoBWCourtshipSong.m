% Move the Piezo to mimic courtship song, control displacements
classdef PiezoBWCourtshipSong < PiezoProtocol

    properties (Constant)
        protocolName = 'PiezoBWCourtshipSong';
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
        
        function obj = PiezoBWCourtshipSong(varargin)
            obj = obj@PiezoProtocol(varargin{:});
            p = inputParser;
            p.addParameter('modusOperandi','Run',...
                @(x) any(validatestring(x,{'Run','Stim','Cal'})));
            parse(p,varargin{:});
            obj.modusOperandi = p.Results.modusOperandi;
        end
        
        function varargout = getStimulus(obj,varargin)
            commandstim = obj.uncorrectedcommand * obj.params.displacement + obj.params.displacementOffset;
            if strcmp(obj.modusOperandi,'Cal')
                notify(obj,'StimulusProblem',StimulusProblemData('CalibratingStimulus'));
            end
            calstim = obj.y * obj.params.displacement + obj.params.displacementOffset;
            if max(calstim > 10) || min(calstim < 0)
                notify(obj,'StimulusProblem',StimulusProblemData('StimulusOutsideBounds'))
            end
            obj.out.piezocommand = calstim;
            obj.out.speakercommand = obj.uncorrectedcommand;
            varargout = {obj.out,calstim,commandstim};
        end
        
        function varargout = getCalibratedStimulus(obj)
            varargout{1} = obj.y * obj.params.displacement + obj.params.displacementOffset;
        end
        
        function fn = getCalibratedStimulusFileName(obj)
            fn = ['C:\Users\Anthony Azevedo\Code\FlySound\Rig Calibration\',...
                sprintf('%s',...
                obj.protocolName)];
        end

        
    end % methods
    
    methods (Access = protected)
        
        function defineParameters(obj)
            % rmpref('defaultsPiezoCourtshipSong')
            obj.params.displacementOffset = 5;
            obj.params.sampratein = 40000;
            [stim,obj.params.samprateout] = audioread([obj.getCalibratedStimulusFileName,'.wav']);
            obj.params.sampratein = obj.params.samprateout;
            obj.params.displacements = .1;
            obj.params.displacement = obj.params.displacements(1);

            obj.params.ramptime = 0.04; %sec;
            
            obj.params.stimDurInSec = length(stim)/obj.params.samprateout;
            obj.params.preDurInSec = .4;
            obj.params.postDurInSec = .3;
            obj.params.durSweep = obj.params.stimDurInSec+obj.params.preDurInSec+obj.params.postDurInSec;
            
            obj.params.Vm_id = 0;
            
            obj.params = obj.getDefaults;
        end
        
        function setupStimulus(obj,varargin)
            setupStimulus@FlySoundProtocol(obj);

            stimfn = which([obj.getCalibratedStimulusFileName,'.wav']);
            if ~isempty(stimfn)
                [stim,obj.params.samprateout] = audioread([obj.getCalibratedStimulusFileName,'.wav']);
                [standardstim] = audioread('CourtshipSong_Standard.wav');
                standardstim = flipud(standardstim);
            else
                [standardstim,obj.params.samprateout] = audioread('CourtshipSong_Standard.wav');
                standardstim = flipud(standardstim);
                stim = standardstim;
            end
            obj.params.stimDurInSec = length(standardstim)/obj.params.samprateout;

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
            
            y(stimpnts) = w.*stim;
            obj.y = y;
            obj.out.piezocommand = y;
            obj.uncorrectedcommand = y;
            obj.uncorrectedcommand(stimpnts) = w.*standardstim;

            if isempty(stimfn)
                audiowrite([obj.getCalibratedStimulusFileName,'.wav'],...
                    stim,...
                    obj.params.samprateout,...
                    'BitsPerSample',32);
            end
            
            if strcmp(obj.modusOperandi,'Cal')
                notify(obj,'StimulusProblem',StimulusProblemData('CalibratingStimulus'));
            end
            
        end
    end % protected methods
    
    methods (Static)
    end
end % classdef
