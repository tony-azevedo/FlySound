% Control the Epifluorescence, control displacements
classdef PairedPiezoLEDFlash2T < FlySoundProtocol
    
    properties (Constant)
        protocolName = 'PairedPiezoLEDFlash2T';
    end
    
    properties (SetAccess = protected)
        requiredRig = 'PiezoEpi2TRig';
        analyses = {};
    end
    
    
    % The following properties can be set only by class methods
    properties (SetAccess = private)
        lightstim
    end
    
    events
    end
    
    methods
        
        function obj = PairedPiezoLEDFlash2T(varargin)
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
            commandstim = obj.y* obj.params.ndf + obj.params.background;
            totalstimpnts = obj.params.stimDurInSec*obj.params.sampratein;
            
            % Piezo
            y = obj.y*0;

            ramptime = abs(obj.params.displacement)/obj.params.speed;
            stimpnts = (1:round(obj.params.samprateout*obj.params.piezoDurInSec)) + round(obj.params.samprateout*(obj.params.preDurInSec-obj.params.piezoPreInSec));

            if ramptime*2>obj.params.piezoDurInSec
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
            
            y(stimpnts) = w*obj.params.displacement;
            obj.out.piezocommand = y+obj.params.displacementOffset;

            % LED
            switch obj.lightstim
                case 'LED_Bath'
                    obj.out.epicommand = commandstim;
%                     obj.out.epittl = obj.y;
%                     obj.out.epittl(obj.y==1) = substim;
                    varargout = {obj.out,obj.out.epicommand,obj.out.piezocommand,commandstim};
                                

                otherwise
                    [N,D] = rat(obj.params.ndf);
                    T = totalstimpnts/D;
                    substim = [ones(N,1); zeros(D-N,1)];
                    substim = repmat(substim,T,1);
                    
                    obj.out.epicommand = commandstim;
                    obj.out.epittl = obj.y;
                    obj.out.epittl(obj.y==1) = substim;
                    varargout = {obj.out,obj.out.epittl,obj.out.piezocommand,commandstim};
                    
            end
        end
        
    end % methods
    
    methods (Access = protected)
        
        function defineParameters(obj)
            obj.params.sampratein = 50000;
            obj.params.samprateout = 50000;
            
            % Epi
            obj.params.ndfs = 1;
            obj.params.ndf = obj.params.ndfs(1);
            obj.params.background = 0;

            % Piezo
            obj.params.displacements = 3;
            obj.params.displacement = obj.params.displacements(1);
            obj.params.speeds = 500;
            obj.params.speed = obj.params.speeds(1);
            obj.params.displacementOffset = 0;

            % Timing
            obj.params.stimDurInSec = 4;
            obj.params.preDurInSec = .5;
            obj.params.postDurInSec = .5;
            
            obj.params.piezoPreInSec = .3;
            obj.params.piezoDurInSec = .1;

            obj.params.durSweep = obj.params.stimDurInSec+obj.params.preDurInSec+obj.params.postDurInSec;

            obj.params = obj.getDefaults;
                        
        end
        
        function setupStimulus(obj,varargin)
            setupStimulus@FlySoundProtocol(obj);
            obj.params.ndf = obj.params.ndfs(1);
            obj.params.durSweep = obj.params.stimDurInSec+obj.params.preDurInSec+obj.params.postDurInSec;
            obj.x = makeTime(obj);
            obj.y = zeros(size(obj.x));
            obj.y(round(obj.params.samprateout*(obj.params.preDurInSec)+1): round(obj.params.samprateout*(obj.params.preDurInSec+obj.params.stimDurInSec))) = 1;
            obj.out.epicommand = obj.y;
            obj.out.epittl = obj.y;
            obj.lightstim = getacqpref('AcquisitionHardware','LightStimulus');
            
            
            obj.params.displacement = obj.params.displacements(1);
            obj.params.speed = obj.params.speeds(1); % volt per s
            
            if obj.params.preDurInSec<obj.params.piezoPreInSec
                error('Prelight stimulus period must include piezo period')
            end
            ramptime = abs(obj.params.displacement)/obj.params.speed;
            stimpnts = (1:round(obj.params.samprateout*obj.params.piezoDurInSec)) + round(obj.params.samprateout*(obj.params.preDurInSec-obj.params.piezoPreInSec));
            
            if ramptime*2>obj.params.piezoDurInSec
                warning('Stimulus is too slow to get to displacement');
                ramp = round(obj.params.piezoDurInSec*obj.params.samprateout/2);
                w = window(@triang,2*ramp);
            else
                ramp = round(ramptime*obj.params.samprateout);
                w = window(@triang,2*ramp);
                w = [w(1:ramp);...
                    ones(length(stimpnts)-length(w),1);...
                    w(ramp+1:end)];
            end
            y = zeros(size(obj.x));
            y(stimpnts) = w*obj.params.displacement+obj.params.displacementOffset;
            
            obj.out.piezocommand = y;

            
        end
        
    end % protected methods
    
    methods (Static)
    end
end % classdef
