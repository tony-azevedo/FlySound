% Control the Epifluorescence, control displacements
classdef EpiFlash2TTrain < FlySoundProtocol
    
    properties (Constant)
        protocolName = 'EpiFlash2TTrain';
    end
    
    properties (SetAccess = protected)
        requiredRig = 'Epi2TRig';
        analyses = {};
    end
    
    
    % The following properties can be set only by class methods
    properties (SetAccess = private)
    end
    
    events
    end
    
    methods
        
        function obj = EpiFlash2TTrain(varargin)
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
            lightstim = getpref('AcquisitionHardware','LightStimulus');
            switch lightstim
                case 'LED_Bath'
                    obj.out.epicommand = commandstim;
%                     obj.out.epittl = obj.y;
%                     obj.out.epittl(obj.y==1) = substim;
                    varargout = {obj.out,obj.out.epicommand,commandstim};
                otherwise
                    [N,D] = rat(obj.params.ndf);
                    T = totalstimpnts/D;
                    substim = [ones(N,1); zeros(D-N,1)];
                    substim = repmat(substim,T,1);
                    
                    %             obj.out.epicommand = commandstim;
                    obj.out.epittl = obj.y;
                    obj.out.epittl(obj.y==1) = substim;
                    varargout = {obj.out,obj.out.epittl,commandstim};
                    
            end
        end
        
    end % methods
    
    methods (Access = protected)
        
        function defineParameters(obj)
            obj.params.sampratein = 10000;
            obj.params.samprateout = 10000;
            obj.params.ndfs = 1;
            obj.params.ndf = obj.params.ndfs(1);
            obj.params.background = 0;
            obj.params.nrepeats = 10;
            obj.params.flashDurInSec = .05;
            obj.params.cycleDurInSec = 1;
            obj.params.stimDurInSec = obj.params.nrepeats*obj.params.cycleDurInSec;
            obj.params.preDurInSec = .5;
            obj.params.postDurInSec = .5;
            obj.params.durSweep = obj.params.stimDurInSec+obj.params.preDurInSec+obj.params.postDurInSec;
            
            obj.params.Vm_id = 0;
            
            obj.params = obj.getDefaults;
        end
        
        function setupStimulus(obj,varargin)
            setupStimulus@FlySoundProtocol(obj);
            obj.params.ndf = obj.params.ndfs(1);
            obj.params.stimDurInSec = obj.params.nrepeats*obj.params.cycleDurInSec;
            obj.params.durSweep = obj.params.stimDurInSec+obj.params.preDurInSec+obj.params.postDurInSec;
            obj.x = makeTime(obj);
            obj.y = zeros(size(obj.x));
            
            flash = zeros(obj.params.cycleDurInSec*obj.params.samprateout,1);
            flash(1:obj.params.flashDurInSec*obj.params.samprateout) = 1;
            flashes = repmat(flash,1,obj.params.nrepeats);
            flashes = flashes(:);
            obj.y(obj.params.samprateout*(obj.params.preDurInSec)+1: obj.params.samprateout*(obj.params.preDurInSec+obj.params.stimDurInSec)) = flashes;

            obj.out.epicommand = obj.y;
            obj.out.epittl = obj.y;
        end
        
    end % protected methods
    
    methods (Static)
    end
end % classdef
