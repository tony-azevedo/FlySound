% Move the Piezo with square waves, control displacements, cycles,
% cycleDurInSec
classdef PiezoSquareWave < FlySoundProtocol
    
    properties (Constant)
        protocolName = 'PiezoSquareWave';
    end
    
    properties (SetAccess = protected)
        requiredRig = 'PiezoRig';
        analyses = {};
    end
    
    
    % The following properties can be set only by class methods
    properties (SetAccess = private)
        gaincorrection
    end
    
    events
    end
    
    methods
        
        function obj = PiezoSquareWave(varargin)
            obj = obj@FlySoundProtocol(varargin{:});
            p = inputParser;
            p.addParameter('modusOperandi','Run',...
                @(x) any(validatestring(x,{'Run','Stim','Cal'})));
            parse(p,varargin{:});
            
            if strcmp(p.Results.modusOperandi,'Cal')
                notify(obj,'StimulusProblem',StimulusProblemData('CalibratingStimulus'))
                obj.gaincorrection = [];
            else
                correctionfiles = dir('C:\Users\Anthony Azevedo\Code\FlySound\Rig Calibration\PiezoSineCorrection*.mat');
                if ~isempty(correctionfiles)
                    cfdate = correctionfiles(1).date;
                    cf = 1;
                    cfdate = datenum(cfdate);
                    for d = 2:length(correctionfiles)
                        if cfdate < datenum(correctionfiles(d).date)
                            cfdate = datenum(correctionfiles(d).date);
                            cf = d;
                        end
                    end
                    temp = load(correctionfiles(cf).name);
                    obj.gaincorrection = temp.d;
                else
                    notify(obj,'StimulusProblem',StimulusProblemData('UncorrectedStimulus'))
                    obj.gaincorrection = [];
                end
            end
        end
        
        function varargout = getStimulus(obj,varargin)
            if ~isempty(obj.gaincorrection)
                offset = obj.gaincorrection.offset(...
                    round(obj.gaincorrection.displacement*1000)/1000 == round(obj.params.displacement*1000)/1000,...
                    1);
                if isempty(offset)
                    offset = 0;
                    notify(obj,'StimulusProblem',StimulusProblemData('UncalibratedStimulus'))
                end
            else
                offset = 0;
            end
            commandstim = obj.y* obj.params.displacement;%*obj.dataBoilerPlate.displFactor;
            commandstim = commandstim + obj.params.displacementOffset;
            calstim = commandstim+offset;
            obj.out.piezocommand = calstim;
            varargout = {obj.out,calstim,commandstim};
        end
        
    end % methods
    
    methods (Access = protected)
        
        function defineParameters(obj)
            % rmpref('defaultsPiezoSquareWave')
            obj.params.sampratein = 50000;
            obj.params.samprateout = 50000;
            obj.params.displacement = 1;
            obj.params.displacements = [3];
            obj.params.displacementOffset = 5;
            obj.params.cycleDurInSec = .1;
            
            obj.params.cycles = 3;
            obj.params.stimDurInSec = obj.params.cycles*obj.params.cycleDurInSec;
            obj.params.preDurInSec = .2;
            obj.params.postDurInSec = .1;
            obj.params.durSweep = obj.params.stimDurInSec+obj.params.preDurInSec+obj.params.postDurInSec;
            
            obj.params.Vm_id = 0;
            
            obj.params = obj.getDefaults;
        end
        
        function setupStimulus(obj,varargin)
            setupStimulus@FlySoundProtocol(obj);
            obj.params.displacement = obj.params.displacements(1);

            obj.params.stimDurInSec = obj.params.cycles*obj.params.cycleDurInSec;
            obj.params.durSweep = obj.params.stimDurInSec+obj.params.preDurInSec+obj.params.postDurInSec;
            obj.x = makeTime(obj);
            obj.y = zeros(size(obj.x));
            insert = ones(obj.params.samprateout*(obj.params.cycleDurInSec/2),...
                2*obj.params.cycles);
            insert(:,2:2:2*obj.params.cycles) = -1 * insert(:,2:2:2*obj.params.cycles);
            insert = insert(:);
            obj.y(obj.params.samprateout*(obj.params.preDurInSec)+1: obj.params.samprateout*(obj.params.preDurInSec+obj.params.stimDurInSec)) = insert;
            obj.out.piezocommand = obj.y;
        end
        
    end % protected methods
    
    methods (Static)
    end
end % classdef

%         function displayTrial(obj)
%             figure(1);
%             ax1 = subplot(4,1,[1 2 3]);
%
%             redlines = findobj(1,'Color',[1, 0, 0]);
%             set(redlines,'color',[1 .8 .8]);
%             line(obj.x,obj.y(1:length(obj.x),1),'parent',ax1,'color',[1 0 0],'linewidth',1);
%             box off; set(gca,'TickDir','out');
%             switch obj.recmode
%                 case 'VClamp'
%                     ylabel('I (pA)'); %xlim([0 max(t)]);
%                 case 'IClamp'
%                     ylabel('V_m (mV)'); %xlim([0 max(t)]);
%             end
%             xlabel('Time (s)'); %xlim([0 max(t)]);
%
%             ax2 = subplot(4,1,4);
%             bluelines = findobj(1,'Color',[0, 0, 1]);
%             set(bluelines,'color',[.8 .8 1]);
%             [~,y] = obj.generateStimulus;
%             line(obj.stimx,y(1:length(obj.stimx)),'parent',ax2,'color',[.7 .7 .7],'linewidth',1);
%             line(obj.x,obj.sensorMonitor(1:length(obj.x)),'parent',ax2,'color',[0 0 1],'linewidth',1);
%             box off; set(gca,'TickDir','out');
%
%         end
