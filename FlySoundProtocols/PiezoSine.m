% Move the Piezo to with sine waves, control displacements, freqs, ramptime
classdef PiezoSine < PiezoProtocol
    properties (Constant)
        protocolName = 'PiezoSine';
    end
    
    properties (SetAccess = protected)
        requiredRig = 'PiezoRig';
        analyses = {''};
    end
    
    % The following properties can be set only by class methods
    properties (SetAccess = private)
        gaincorrection  % set this property when setting up the stimulus, 
    end
    
    events
    end
    
    methods
        
        function obj = PiezoSine(varargin)
            obj = obj@PiezoProtocol(varargin{:});
            p = inputParser;
            p.addParameter('modusOperandi','Run',...
                @(x) any(validatestring(x,{'Run','Stim','Cal'})));
            parse(p,varargin{:});
            obj.modusOperandi = p.Results.modusOperandi;
        end
        
        function varargout = getStimulus(obj,varargin)
            obj.uncorrectedcommand = sin(2*pi*obj.params.freq*obj.x);
            calstim = obj.y .* obj.uncorrectedcommand;
            
            stimfn = which([obj.getCalibratedStimulusFileName,'.wav']);
            % If the calibrated stimulus file exists, load it
            if ~isempty(stimfn)
                [stim,obj.params.samprateout] = audioread([obj.getCalibratedStimulusFileName,'.wav']);
                calstim(obj.x>=0 & obj.x <obj.params.stimDurInSec-eps) = ...
                    obj.y(obj.x>=0 & obj.x <obj.params.stimDurInSec-eps) .* ...
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

            varargout = {...
                obj.out,...
                obj.out.piezocommand,...
                obj.out.speakercommand * obj.params.displacement + obj.params.displacementOffset};
        end
        
        
        function varargout = getCalibratedStimulus(obj)
        end
        
        function fn = getCalibratedStimulusFileName(obj)
            fn = ['C:\Users\Anthony Azevedo\Code\FlySound\Rig Calibration\',...
                sprintf('%s_freq%.0f',...
                obj.protocolName,...
                obj.params.freq)];
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
            stimfn = which([obj.getCalibratedStimulusFileName,'.wav']);
            if ~isempty(stimfn)
                [~,obj.params.samprateout] = audioread([obj.getCalibratedStimulusFileName,'.wav']);
            end
            
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
            obj.out.piezocommand = y;
            obj.uncorrectedcommand = y;
        end
    end % protected methods
    
    methods (Static)
    end
end % classdef
