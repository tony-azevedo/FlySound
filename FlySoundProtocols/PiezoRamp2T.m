% Move the Piezo with steps, control displacements
classdef PiezoRamp2T < FlySoundProtocol
    
    properties (Constant)
        protocolName = 'PiezoRamp2T';
    end
    
    properties (SetAccess = protected)
        requiredRig = 'Piezo2TRig';
        analyses = {};
    end
    
    
    % The following properties can be set only by class methods
    properties (SetAccess = private)
    end
    
    events
    end
    
    methods
        
        function obj = PiezoRamp2T(varargin)
            obj = obj@FlySoundProtocol(varargin{:});
            p = inputParser;
            p.addParameter('modusOperandi','Run',...
                @(x) any(validatestring(x,{'Run','Stim','Cal'})));
            parse(p,varargin{:});
            
            if strcmp(p.Results.modusOperandi,'Cal')
                notify(obj,'StimulusProblem',StimulusProblemData('CalibratingStimulus'))
            end
        end
        
        function varargout = getStimulus(obj,varargin)            
            obj.y(:) = 0;

            ramptime = abs(obj.params.displacement)/obj.params.speed;
            stimpnts = round(obj.params.samprateout*obj.params.preDurInSec+1:...
                obj.params.samprateout*(obj.params.preDurInSec+obj.params.stimDurInSec));

            if ramptime*2>obj.params.stimDurInSec
                warning('Stimulus is too slow to get to displacement');
                ramp = round(obj.params.stimDurInSec*obj.params.samprateout/2);
                w = window(@triang,2*ramp);
            else
                ramp = round(ramptime*obj.params.samprateout);
                w = window(@triang,2*ramp);
                w = [w(1:ramp);...
                    ones(length(stimpnts)-length(w),1);...
                    w(ramp+1:end)];
            end
            
            obj.y(stimpnts) = w*obj.params.displacement;
            obj.out.piezocommand = obj.y+obj.params.displacementOffset;

            varargout = {obj.out,obj.out.piezocommand,obj.y};

        end
        
    end % methods
    
    methods (Access = protected)
        
        function defineParameters(obj)
            obj.params.sampratein = 10000;
            obj.params.samprateout = 10000;
            obj.params.displacements = [2.5];
            obj.params.displacement = obj.params.displacements(1);
            obj.params.speeds = 100*[3 1 .3];
            obj.params.speed = obj.params.displacements(1);
            obj.params.displacementOffset = 0;
            obj.params.stimDurInSec = .5;
            obj.params.preDurInSec = .2;
            obj.params.postDurInSec = .1;
            obj.params.durSweep = obj.params.stimDurInSec+obj.params.preDurInSec+obj.params.postDurInSec;
            
            obj.params.Vm_id = 0;
            
            obj.params = obj.getDefaults;
        end
        
        function setupStimulus(obj,varargin)
            setupStimulus@FlySoundProtocol(obj);
            obj.params.displacement = obj.params.displacements(1);
            obj.params.speed = obj.params.speeds(1); % volt per s
            obj.params.durSweep = obj.params.stimDurInSec+obj.params.preDurInSec+obj.params.postDurInSec;
            obj.x = makeTime(obj);
            y = obj.x(:);
            y(:) = 0;

            ramptime = abs(obj.params.displacement)/obj.params.speed;
            stimpnts = round(obj.params.samprateout*obj.params.preDurInSec+1:...
                obj.params.samprateout*(obj.params.preDurInSec+obj.params.stimDurInSec));

            if ramptime*2>obj.params.stimDurInSec
                warning('Stimulus is too slow to get to displacement');
                ramp = round(obj.params.stimDurInSec*obj.params.samprateout/2);
                w = window(@triang,2*ramp);
            else
                ramp = round(ramptime*obj.params.samprateout);
                w = window(@triang,2*ramp);
                w = [w(1:ramp);...
                    ones(length(stimpnts)-length(w),1);...
                    w(ramp+1:end)];
            end
            
            y(stimpnts) = w*obj.params.displacement+obj.params.displacementOffset;
            obj.y = y;
            obj.out.piezocommand = obj.y;
        end
        
    end % protected methods
    
    methods (Static)
    end
end % classdef
