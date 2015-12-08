% Drive piezo with frequency sweep, control displacements, freqStart,
% freqEnd, stimDurInSec
classdef PiezoFM < PiezoProtocol
    
    properties (Constant)
        protocolName = 'PiezoFM';
    end
    
    properties (SetAccess = protected)
        requiredRig = 'PiezoRig';
        analyses = {''};
    end
    
    % The following properties can be set only by class methods
    properties (SetAccess = private)

    end
    
    events
    end
    
    methods
        
        function obj = PiezoFM(varargin)
            obj = obj@PiezoProtocol(varargin{:});
            p = inputParser;
            p.addParameter('modusOperandi','Run',...
                @(x) any(validatestring(x,{'Run','Stim','Cal'})));
            parse(p,varargin{:});
            obj.modusOperandi = p.Results.modusOperandi;
        end
        
        function varargout = getStimulus(obj,varargin)
            
            envelope = 1-...
                obj.params.modulationDepth *...
                cos(2 * pi * obj.params.freqEnvelope * obj.x);
            standardstim =  envelope.*...
                sin(2 * pi * obj.params.freqCarrier * obj.x);

            obj.uncorrectedcommand = obj.y .* standardstim;
            calstim = obj.uncorrectedcommand;

            stimfn = which([obj.getCalibratedStimulusFileName,'.wav']);
            if ~isempty(stimfn)
                [stim,obj.params.samprateout] = audioread([obj.getCalibratedStimulusFileName,'.wav']);
                calstim(obj.x>=0 & obj.x <obj.params.stimDurInSec-eps) = ...
                    obj.y(obj.x>=0 & obj.x <obj.params.stimDurInSec-eps) .* ...
                    stim(1:obj.params.stimDurInSec*obj.params.samprateout);
            else
                % otherwise, figure out what to do
                obj.treatUncalibratedStimulus
            end

            commandstim = obj.uncorrectedcommand * obj.params.displacement + obj.params.displacementOffset;
            calstim = calstim * obj.params.displacement + obj.params.displacementOffset;
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
            fn = ['C:\Users\Anthony Azevedo\Code\FlySound\StimulusWaves\',...
                sprintf('%s_freqC%.0f_freqE%.0f_modD%.0f',...
                obj.protocolName,...
                obj.params.freqCarrier,...
                obj.params.freqEnvelope,...
                obj.params.modulationDepth)];
        end

    end % methods
    
    methods (Access = protected)
        
        function defineParameters(obj)
            % rmpref('defaultsPiezoAM')
            obj.params.displacementOffset = 5;
            obj.params.sampratein = 50000;
            obj.params.samprateout = 50000;
            
            obj.params.sampratein = obj.params.samprateout;
            obj.params.displacements = [1  10] * .05;
            obj.params.displacement = obj.params.displacements(1);

            obj.params.ramptime = 0.04; %sec;
                        
            obj.params.freqCarriers = [50, 100, 141, 200];
            obj.params.freqCarrier = obj.params.freqCarriers(1);
            obj.params.freqEnvelopes = [.5];
            obj.params.freqEnvelope = obj.params.freqEnvelopes(1);
            obj.params.modulationDepths = 60;
            obj.params.modulationDepth = obj.params.modulationDepths(1);
            
            obj.params.stimDurInSec = 10;
            obj.params.preDurInSec = .5;
            obj.params.postDurInSec = .5;
            
            obj.params.durSweep = obj.params.stimDurInSec+obj.params.preDurInSec+obj.params.postDurInSec;
            
            obj.params.Vm_id = 0;
            
            obj.params = obj.getDefaults;
        end
        
        function setupStimulus(obj,varargin)
            setupStimulus@FlySoundProtocol(obj);
            
            obj.params.freqCarrier = obj.params.freqCarriers(1);
            obj.params.freqEnvelope = obj.params.freqEnvelopes(1);
            obj.params.modulationDepth = obj.params.modulationDepths(1);
            obj.params.displacement = obj.params.displacements(1);

            stimfn = which([obj.getCalibratedStimulusFileName,'.wav']);
            if ~isempty(stimfn)
                [stim,obj.params.samprateout] = audioread([obj.getCalibratedStimulusFileName,'.wav']);
            end
            obj.params.durSweep = obj.params.stimDurInSec+obj.params.preDurInSec+obj.params.postDurInSec;
            obj.x = makeOutTime(obj);
            obj.x = obj.x(:);
            y = obj.x;
            y(:) = 0;
                
            stimpnts = round(obj.params.samprateout*obj.params.preDurInSec+1:...
                obj.params.samprateout*(obj.params.preDurInSec+obj.params.stimDurInSec));

            w = window(@triang,2*obj.params.ramptime*obj.params.samprateout);
            w = [w(1:obj.params.ramptime*obj.params.samprateout);...
                ones(length(stimpnts)-length(w),1);...
                w(obj.params.ramptime*obj.params.samprateout+1:end)];
            
            envelope = 1-...
                obj.params.modulationDepth *...
                cos(2 * pi * obj.params.freqEnvelope * obj.x(stimpnts));
            standardstim =  envelope.*...
                sin(2 * pi * obj.params.freqCarrier * obj.x(stimpnts));
            
            if isempty(stimfn)
                stim = standardstim;
            else
                stim = stim(1:length(stimpnts));
            end
            
            obj.y = y;
            obj.y(stimpnts) = w;
            
            y(stimpnts) = w.*stim;
            
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
