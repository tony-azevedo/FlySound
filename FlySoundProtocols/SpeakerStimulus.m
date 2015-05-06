% Move the Piezo with arbitrary stimulus
classdef SpeakerStimulus < FlySoundProtocol

    properties (Constant)
        protocolName = 'SpeakerStimulus';
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
        
        function obj = SpeakerStimulus(varargin)
            obj = obj@FlySoundProtocol(varargin{:});
        end
        
        function varargout = getStimulus(obj,varargin)

            calstim = obj.y * obj.params.amp;
            if max(calstim > 10) || min(calstim < -10)
                notify(obj,'StimulusProblem',StimulusProblemData('StimulusOutsideBounds'))
            end
            obj.out.speakercommand = calstim;
            varargout = {obj.out,calstim,calstim};
        end
        
        function varargout = getCalibratedStimulus(obj)
            varargout{1} = obj.y * obj.params.amp;
        end
        
        function fn = getCalibratedStimulusFileName(obj)
            fn = ['C:\Users\Anthony Azevedo\Code\FlySound\StimulusWaves\',...
                obj.params.stimulusName];
        end
        
        function showCalibratedStimulusNames(obj)
            fns = dir('C:\Users\Anthony Azevedo\Code\FlySound\StimulusWaves\');
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
            % rmpref('defaultsSpeakerStimulus')
            obj.params.ampOffset = 5;
            obj.params.stimulusName = 'Basic';
            
            obj.params.sampratein = 40000;
            [stim,obj.params.samprateout] = audioread([obj.getCalibratedStimulusFileName '.wav']);
            obj.params.sampratein = obj.params.samprateout;
            obj.params.amps = .1;
            obj.params.amp = obj.params.amps(1);

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
            obj.params.amp = obj.params.amps(1);

            stimfn = which([obj.getCalibratedStimulusFileName,'.wav']);
            if ~isempty(stimfn)
                [stim,obj.params.samprateout] = audioread([obj.getCalibratedStimulusFileName,'.wav']);
                [standardstim] = audioread([obj.getCalibratedStimulusFileName '_Standard.wav']);
            else
                [standardstim,obj.params.samprateout] = audioread([obj.getCalibratedStimulusFileName '_Standard.wav']);
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
                obj.params.samprateout*(obj.params.preDurInSec)+length(stim));
            
            w = window(@triang,2*obj.params.ramptime*obj.params.samprateout);
            w = [w(1:obj.params.ramptime*obj.params.samprateout);...
                ones(length(stimpnts)-length(w),1);...
                w(obj.params.ramptime*obj.params.samprateout+1:end)];
            
            y(stimpnts) = w.*stim;
            obj.y = y;
            obj.out.speakercommand = y;
            
        end
    end % protected methods
    
    methods (Static)
    end
end % classdef
